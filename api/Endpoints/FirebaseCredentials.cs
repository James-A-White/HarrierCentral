using Azure.Storage.Blobs;

namespace HcWebApi.Endpoints
{
    /// <summary>
    /// The Firebase service-account JSON every push is signed with — read from
    /// the PRIVATE `credentials` container with the storage connection string,
    /// never over an anonymous URL (2026-10-16, permissions audit: the
    /// container allowed anonymous reads and the URL was in this public repo,
    /// so anyone could fetch the key). One reader, so the five push paths
    /// cannot drift back to the public URL.
    /// </summary>
    internal static class FirebaseCredentials
    {
        private const string Container = "credentials";
        private const string BlobName = "firebase_credentials.json";

        /// <summary>The JSON, or null when it cannot be read (logged by the caller).</summary>
        public static async Task<string?> LoadJsonAsync(CancellationToken ct = default)
        {
            string? conn = Environment.GetEnvironmentVariable("HC_BLOB_STORAGE_CONNECTION_STRING");
            if (string.IsNullOrEmpty(conn)) return null;
            var blob = new BlobServiceClient(conn).GetBlobContainerClient(Container).GetBlobClient(BlobName);
            var result = await blob.DownloadContentAsync(ct);
            return result.Value.Content.ToString();
        }
    }
}
