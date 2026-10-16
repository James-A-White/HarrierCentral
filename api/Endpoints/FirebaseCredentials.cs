using Azure.Storage.Blobs;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The Firebase service-account JSON every push is signed with. One reader,
    /// so the five push paths cannot drift.
    ///
    /// Where it comes from, in order:
    ///   1. The app setting FIREBASE_CREDENTIALS_JSON — a Key Vault reference
    ///      (`@Microsoft.KeyVault(SecretUri=…)`, E18.F3.S6), resolved by the
    ///      platform, so the key never sits in code, storage or the portal.
    ///   2. Otherwise the PRIVATE `credentials` container, read with the storage
    ///      connection string (2026-10-16: the container used to allow anonymous
    ///      reads and its URL was in this public repo).
    /// A setting that fails to resolve arrives as the literal reference text,
    /// not JSON — that is treated as absent, so a misconfigured vault falls
    /// back to the blob instead of breaking every push.
    /// </summary>
    internal static class FirebaseCredentials
    {
        private const string SettingName = "FIREBASE_CREDENTIALS_JSON";
        private const string Container = "credentials";
        private const string BlobName = "firebase_credentials.json";

        /// <summary>The JSON, or null when it cannot be read (logged by the caller).</summary>
        public static async Task<string?> LoadJsonAsync(CancellationToken ct = default)
        {
            string? fromSetting = Environment.GetEnvironmentVariable(SettingName);
            if (!string.IsNullOrWhiteSpace(fromSetting) && fromSetting.TrimStart().StartsWith("{"))
                return fromSetting;

            string? conn = Environment.GetEnvironmentVariable("HC_BLOB_STORAGE_CONNECTION_STRING");
            if (string.IsNullOrEmpty(conn)) return null;
            var blob = new BlobServiceClient(conn).GetBlobContainerClient(Container).GetBlobClient(BlobName);
            var result = await blob.DownloadContentAsync(ct);
            return result.Value.Content.ToString();
        }
    }
}
