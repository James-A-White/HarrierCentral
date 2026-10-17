using System.Data;
using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json.Linq;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Sign in with Apple / Google, the VERIFIED rebuild (E1.F1.S8, James
    /// 2026-10-17). The old path (hcapp_processThirdPartyLogin, now refused)
    /// believed the provider id and email the phone sent. Here the phone sends
    /// the provider's SIGNED identity token and the raw nonce it made for this
    /// attempt; the server checks the token itself —
    ///   Apple:  RS256 signature against Apple's published keys (cached,
    ///           refreshed on an unknown key id), iss https://appleid.apple.com,
    ///           aud our bundle id (APPLE_SIGNIN_AUDIENCES, default
    ///           com.harriercentral.app), not expired, nonce = SHA-256(raw nonce).
    ///   Google: Google.Apis.Auth's GoogleJsonWebSignature (signature, issuer,
    ///           expiry) with aud our OAuth client ids (GOOGLE_SIGNIN_CLIENT_IDS,
    ///           '|'-separated; Google is OFF until it is set), nonce checked
    ///           when the token carries one.
    /// — and only then takes the stable id ('sub') and the email from INSIDE
    /// the token to HC6.nonApi_thirdPartySignIn, which finds, links or creates
    /// the hasher and returns its reset code. The app signs the phone in with
    /// that code through hcapp_authorizeDevice, as with an emailed code.
    ///
    /// POST { provider: "apple"|"google", identityToken, rawNonce,
    ///        firstName?, lastName?, hcVersion? }
    /// 200 { resetCode, isNewAccount, linked } · 401 not verified ·
    /// 503 provider not configured · 403 account removed · 500 otherwise.
    /// </summary>
    public class ThirdPartySignIn
    {
        private readonly ILogger<ThirdPartySignIn> _log;
        public ThirdPartySignIn(ILogger<ThirdPartySignIn> log) { _log = log; }

        private static readonly HttpClient Http = new() { Timeout = TimeSpan.FromSeconds(15) };
        private static (DateTime at, JArray keys)? appleKeys;
        private static readonly TimeSpan Skew = TimeSpan.FromMinutes(2);

        [Function("ThirdPartySignIn")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {
            JObject body;
            try { body = JObject.Parse(await new StreamReader(req.Body).ReadToEndAsync()); }
            catch { return Fail(400, "That request could not be read."); }
            string provider = (body.Value<string>("provider") ?? "").Trim().ToLowerInvariant();
            string token = body.Value<string>("identityToken") ?? "";
            string rawNonce = body.Value<string>("rawNonce") ?? "";
            string? hcVersion = body.Value<string>("hcVersion");
            if (token.Length == 0) return Fail(400, "Missing identity token.");

            Identity? id;
            string? why;
            try
            {
                switch (provider)
                {
                    case "apple":
                        (id, why) = await VerifyAppleAsync(token, rawNonce);
                        break;
                    case "google":
                        string[] clients = (Environment.GetEnvironmentVariable("GOOGLE_SIGNIN_CLIENT_IDS") ?? "")
                            .Split('|', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
                        if (clients.Length == 0) return Fail(503, "Google sign-in is not available yet. Please use the code we email you.");
                        (id, why) = await VerifyGoogleAsync(token, rawNonce, clients);
                        break;
                    default:
                        return Fail(400, "Unknown sign-in provider.");
                }
            }
            catch (Exception ex)
            {
                (id, why) = (null, "verification error: " + ex.Message);
            }
            if (id == null)
            {
                _log.LogWarning("ThirdPartySignIn {Provider}: not verified — {Why}", provider, why);
                await LogAsync(hcVersion, "Third-party sign-in not verified", $"provider={provider}: {why}");
                return Fail(401, "We couldn't confirm that sign-in. Please try again, or sign in with the code we email you.");
            }

            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return Fail(500, "Sign-in is not set up on the server.");
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand("[HC6].[nonApi_thirdPartySignIn]", conn) { CommandType = CommandType.StoredProcedure, CommandTimeout = 30 };
                cmd.Parameters.Add("@provider", SqlDbType.NVarChar, 20).Value = provider;
                cmd.Parameters.Add("@providerUserId", SqlDbType.NVarChar, 255).Value = id.Subject;
                cmd.Parameters.Add("@email", SqlDbType.NVarChar, 250).Value = (object?)id.Email ?? DBNull.Value;
                cmd.Parameters.Add("@emailVerified", SqlDbType.SmallInt).Value = id.EmailVerified ? 1 : 0;
                cmd.Parameters.Add("@firstName", SqlDbType.NVarChar, 250).Value = (object?)Trim(body.Value<string>("firstName"), 250) ?? DBNull.Value;
                cmd.Parameters.Add("@lastName", SqlDbType.NVarChar, 250).Value = (object?)Trim(body.Value<string>("lastName"), 250) ?? DBNull.Value;
                cmd.Parameters.Add("@hcVersion", SqlDbType.NVarChar, 50).Value = (object?)Trim(hcVersion, 50) ?? DBNull.Value;
                using var r = await cmd.ExecuteReaderAsync();
                if (!await r.ReadAsync()) return Fail(500, "Sign-in failed. Please try again.");
                if (Convert.ToInt32(r["Success"]) != 1)
                {
                    string msg = r["ErrorMessage"] as string ?? "";
                    return msg.Contains("removed", StringComparison.OrdinalIgnoreCase)
                        ? Fail(403, msg)
                        : Fail(500, "Sign-in failed. Please try again.");
                }
                if (!await r.NextResultAsync() || !await r.ReadAsync()) return Fail(500, "Sign-in failed. Please try again.");
                _log.LogInformation("ThirdPartySignIn {Provider}: ok (new={New}, linked={Linked})", provider, r["IsNewAccount"], r["Linked"]);
                return new OkObjectResult(new
                {
                    resetCode = r["ResetCode"] as string,
                    isNewAccount = Convert.ToInt32(r["IsNewAccount"]) == 1,
                    linked = Convert.ToInt32(r["Linked"]) == 1,
                });
            }
            catch (Exception ex)
            {
                _log.LogError(ex, "ThirdPartySignIn: database step failed");
                await LogAsync(hcVersion, "Unhandled exception in ThirdPartySignIn", ex.Message);
                return Fail(500, "Sign-in failed. Please try again.");
            }
        }

        internal sealed record Identity(string Subject, string? Email, bool EmailVerified);

        // ── Apple ──────────────────────────────────────────────────────────

        internal static async Task<(Identity?, string?)> VerifyAppleAsync(string token, string rawNonce)
        {
            string[] parts = token.Split('.');
            if (parts.Length != 3) return (null, "malformed token");
            JObject header = JObject.Parse(Encoding.UTF8.GetString(B64Url(parts[0])));
            if ((string?)header["alg"] != "RS256") return (null, "unexpected alg");
            string kid = (string?)header["kid"] ?? "";

            JObject? jwk = FindKey(await AppleKeysAsync(false), kid) ?? FindKey(await AppleKeysAsync(true), kid);
            if (jwk == null) return (null, "unknown key id");
            using RSA rsa = RSA.Create();
            rsa.ImportParameters(new RSAParameters { Modulus = B64Url((string)jwk["n"]!), Exponent = B64Url((string)jwk["e"]!) });
            bool signed = rsa.VerifyData(Encoding.ASCII.GetBytes(parts[0] + "." + parts[1]), B64Url(parts[2]),
                                         HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            if (!signed) return (null, "bad signature");

            JObject c = JObject.Parse(Encoding.UTF8.GetString(B64Url(parts[1])));
            if ((string?)c["iss"] != "https://appleid.apple.com") return (null, "wrong issuer");
            string[] audiences = (Environment.GetEnvironmentVariable("APPLE_SIGNIN_AUDIENCES") ?? "com.harriercentral.app")
                .Split('|', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
            string? aud = (string?)c["aud"];
            if (aud == null || !audiences.Contains(aud)) return (null, "wrong audience");
            long now = DateTimeOffset.UtcNow.ToUnixTimeSeconds();
            if ((c.Value<long?>("exp") ?? 0) < now - (long)Skew.TotalSeconds) return (null, "expired");
            if ((c.Value<long?>("iat") ?? 0) > now + (long)Skew.TotalSeconds) return (null, "issued in the future");
            // The app sends Apple the SHA-256 of a fresh random nonce and us the
            // raw value: a captured token cannot be replayed without that value.
            if (rawNonce.Length < 16) return (null, "missing nonce");
            if (!string.Equals((string?)c["nonce"], Sha256Hex(rawNonce), StringComparison.OrdinalIgnoreCase)) return (null, "nonce mismatch");

            string? sub = (string?)c["sub"];
            if (string.IsNullOrEmpty(sub)) return (null, "no subject");
            string? email = (string?)c["email"];
            bool verified = IsTrue(c["email_verified"]);
            return (new Identity(sub, email, verified), null);
        }

        private static async Task<JArray> AppleKeysAsync(bool force)
        {
            if (!force && appleKeys is { } k && DateTime.UtcNow - k.at < TimeSpan.FromHours(6)) return k.keys;
            string json = await Http.GetStringAsync("https://appleid.apple.com/auth/keys");
            var keys = (JArray)JObject.Parse(json)["keys"]!;
            appleKeys = (DateTime.UtcNow, keys);
            return keys;
        }

        private static JObject? FindKey(JArray keys, string kid) =>
            keys.OfType<JObject>().FirstOrDefault(k => (string?)k["kid"] == kid && (string?)k["kty"] == "RSA");

        // ── Google ─────────────────────────────────────────────────────────

        private static async Task<(Identity?, string?)> VerifyGoogleAsync(string token, string rawNonce, string[] clients)
        {
            var p = await Google.Apis.Auth.GoogleJsonWebSignature.ValidateAsync(token,
                new Google.Apis.Auth.GoogleJsonWebSignature.ValidationSettings { Audience = clients, Clock = null });
            if (!string.IsNullOrEmpty(p.Nonce)
                && !string.Equals(p.Nonce, rawNonce, StringComparison.Ordinal)
                && !string.Equals(p.Nonce, Sha256Hex(rawNonce), StringComparison.OrdinalIgnoreCase))
                return (null, "nonce mismatch");
            if (string.IsNullOrEmpty(p.Subject)) return (null, "no subject");
            return (new Identity(p.Subject, p.Email, p.EmailVerified), null);
        }

        // ── Helpers ────────────────────────────────────────────────────────

        internal static byte[] B64Url(string s)
        {
            string t = s.Replace('-', '+').Replace('_', '/');
            switch (t.Length % 4) { case 2: t += "=="; break; case 3: t += "="; break; }
            return Convert.FromBase64String(t);
        }

        internal static string Sha256Hex(string s) =>
            Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(s))).ToLowerInvariant();

        private static bool IsTrue(JToken? t) =>
            t != null && (t.Type == JTokenType.Boolean ? t.Value<bool>() : string.Equals(t.ToString(), "true", StringComparison.OrdinalIgnoreCase));

        private static string? Trim(string? s, int max) =>
            string.IsNullOrWhiteSpace(s) ? null : (s.Trim().Length > max ? s.Trim()[..max] : s.Trim());

        private static async Task LogAsync(string? hcVersion, string name, string detail)
        {
            string? cs = Environment.GetEnvironmentVariable("HcDbConnectionString");
            if (cs == null) return;
            try
            {
                using var conn = new SqlConnection(cs);
                await conn.OpenAsync();
                using var cmd = new SqlCommand(
                    "INSERT HC.ErrorLog (id, HcVersion, ErrorName, ErrorDescription, ProcName, userId) VALUES (NEWID(), @v, @n, @d, 'ThirdPartySignIn', NULL);", conn);
                cmd.Parameters.Add("@v", SqlDbType.NVarChar, 50).Value = Trim(hcVersion, 50) ?? "<api>";
                cmd.Parameters.Add("@n", SqlDbType.NVarChar, 200).Value = name;
                cmd.Parameters.Add("@d", SqlDbType.NVarChar, -1).Value = detail.Length > 500 ? detail[..500] : detail;
                await cmd.ExecuteNonQueryAsync();
            }
            catch { /* best effort */ }
        }

        private static IActionResult Fail(int status, string message) =>
            new ObjectResult(new { errorUserMessage = message }) { StatusCode = status };
    }
}
