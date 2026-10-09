using System.Text;
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;
using Newtonsoft.Json;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The audit copy of every list email (James, 2026-10-09): the finished
    /// text, who it went to and who sent it, kept as one JSON file per send in
    /// the private `email-audit` blob container — no table, no 8,000-character
    /// cap, and a BH3-sized recipient list costs nothing. The path is recorded
    /// on the send's LOG.GeneralLog row, which the Usage Data monitor counts.
    ///
    /// Path: email-audit/{yyyy}/{MM}/{kind}_{eventId or kennel}_{utc}.json
    /// </summary>
    public static class EmailAudit
    {
        public const string Container = "email-audit";

        public sealed class Record
        {
            public string Kind = "";            // send | preview | announcement
            public DateTimeOffset SentAt = DateTimeOffset.UtcNow;
            public Guid? EventId;
            public string Run = "";
            public Guid? KennelId;
            public string Kennel = "";
            public Guid? SenderId;
            public string Sender = "";
            public string Instruction = "";
            public string Subject = "";
            public string Html = "";
            public string PlainText = "";
            public List<object> Recipients = new();
            public List<object> MovedIn = new();
            public List<object> MovedOut = new();
            public int RecipientCount => Recipients.Count;
        }

        /// <summary>Writes the record and returns its blob path, or null when the store is not configured or refused.</summary>
        public static async Task<string?> WriteAsync(Record r)
        {
            string? conn = Environment.GetEnvironmentVariable("HC_BLOB_STORAGE_CONNECTION_STRING");
            if (string.IsNullOrEmpty(conn)) return null;
            try
            {
                var container = new BlobServiceClient(conn).GetBlobContainerClient(Container);
                await container.CreateIfNotExistsAsync(PublicAccessType.None);
                string who = r.EventId?.ToString("D") ?? r.KennelId?.ToString("D") ?? "all";
                string path = $"{r.SentAt:yyyy}/{r.SentAt:MM}/{r.Kind}_{who}_{r.SentAt:yyyyMMddTHHmmssZ}.json";
                string json = JsonConvert.SerializeObject(r, Formatting.Indented);
                await container.GetBlobClient(path).UploadAsync(
                    new BinaryData(Encoding.UTF8.GetBytes(json)),
                    new BlobUploadOptions { HttpHeaders = new BlobHttpHeaders { ContentType = "application/json" } });
                return path;
            }
            catch (Exception ex)
            {
                await HcListMail.LogFailureAsync("EmailAudit", "-", ex.Message, r.EventId);
                return null;
            }
        }

    }
}
