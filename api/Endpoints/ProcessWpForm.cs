using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;
using System.Web;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// Handles WordPress form submissions for new kennel sign-ups.
    /// Accepts GET/POST, calls [EXT].[ImportNewKennel] with the form data as JSON,
    /// then redirects the browser to a confirmation page.
    /// </summary>
    public class ProcessWpForm
    {
        private readonly ILogger<ProcessWpForm> _log;

        public ProcessWpForm(ILogger<ProcessWpForm> logger)
        {
            _log = logger;
        }

        [Function("ProcessWpForm")]
        public async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequest req)
        {
            const string defaultRedirectUrl = "https://www.harriercentral.com/";

            if (!req.QueryString.HasValue)
                return new RedirectResult(defaultRedirectUrl, permanent: true);

            var collection = HttpUtility.ParseQueryString(req.QueryString.Value!);
            string? formName = collection["form_name"];

            if (formName != "KennelFbSignup" && formName != "KennelSignup")
                return new RedirectResult(defaultRedirectUrl, permanent: true);

            string redirectUrl = formName == "KennelFbSignup"
                ? "https://harriercentral.com/index.php/next-steps-for-adding-kennel/"
                : "https://harriercentral.com/index.php/next-steps-for-adding-standalone-kennel/";

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set.");

            string jsonData = System.Text.Json.JsonSerializer.Serialize(
                collection.AllKeys.ToDictionary(k => k!, k => collection[k]));

            _log.LogInformation("ProcessWpForm: formName={FormName}", formName);

            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();

                using SqlCommand cmd = new("[EXT].[ImportNewKennel]", conn);
                cmd.CommandType = CommandType.StoredProcedure;
                cmd.Parameters.AddWithValue("@jsonData", jsonData);

                using SqlDataReader reader = await cmd.ExecuteReaderAsync();
                while (await reader.ReadAsync())
                    _log.LogInformation("ImportNewKennel: {Result}", reader.GetValue(0));
            }
            catch (Exception ex)
            {
                _log.LogError("ProcessWpForm error: {Type} — {Message}", ex.GetType().Name, ex.Message);
            }

            return new RedirectResult(redirectUrl, permanent: true);
        }
    }
}
