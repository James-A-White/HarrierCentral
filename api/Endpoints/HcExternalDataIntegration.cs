using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;

namespace HcWebApi.Endpoints
{
    public class HcExternalDataIntegration
    {
        private readonly ILogger<HcExternalDataIntegration> log;

        // Persists across timer invocations for the lifetime of the host process
        private static volatile Dictionary<string, DateTime> _lastIntegrationRunTimes = new();
        private static int _sequenceNumber = 0;

        public HcExternalDataIntegration(ILogger<HcExternalDataIntegration> logger)
        {
            log = logger;
        }

        [Function("HcExternalDataIntegration")]
        public async Task Run([TimerTrigger("0 */1 * * * *")] TimerInfo myTimer)
        {
            DateTime baseTime = DateTime.Now;

            log.LogInformation("HcExternalDataIntegration triggered at: {Now}", baseTime);

            if (myTimer.ScheduleStatus is not null)
            {
                log.LogInformation("Next timer schedule at: {Next}", myTimer.ScheduleStatus.Next);
            }

            int min = (int)baseTime.TimeOfDay.TotalMinutes;
            log.LogInformation("Minutes = {Min}", min);

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            const string query = @"
                SELECT
                    IntegrationId,
                    IntegrationName,
                    IntegrationAbbreviation,
                    Interval,
                    Direction,
                    Type,
                    Enabled,
                    CustomUrl,
                    HttpRequestType,
                    IntegrationMethodName,
                    LocationFieldName,
                    LatLonExtractionRegex,
                    IntervalOffset,
                    MaxLat,
                    MinLat,
                    MaxLon,
                    MinLon,
                    Removed,
                    updatedAt
                FROM HC.Integration
                WHERE Removed = 0 AND Enabled != 0 AND IntegrationId > 0";

            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();

                using SqlCommand cmd = new(query, conn);
                using SqlDataReader rows = await cmd.ExecuteReaderAsync();

                while (await rows.ReadAsync())
                {
                    string integrationId           = rows.GetValue(0).ToString()!.Trim();
                    string integrationName         = rows.GetValue(1).ToString()!.Trim();
                    string integrationAbbreviation = rows.GetValue(2).ToString()!.Trim();
                    int    interval                = rows.GetInt16(3);
                    // ordinals 4 (Direction), 5 (Type), 6 (Enabled) not used in scheduling logic
                    string customUrl               = rows.GetValue(7).ToString()!.Trim();
                    // ordinal 8 (HttpRequestType) not used directly here
                    string integrationMethodName   = rows.GetValue(9).ToString()!.Trim();
                    // ordinals 10 (LocationFieldName), 11 (LatLonExtractionRegex) not used directly
                    int     intervalOffset         = rows.GetInt16(12);
                    decimal maxLat                 = rows.GetDecimal(13);
                    decimal minLat                 = rows.GetDecimal(14);
                    decimal maxLon                 = rows.GetDecimal(15);
                    decimal minLon                 = rows.GetDecimal(16);

                    intervalOffset = intervalOffset % interval;

                    bool isDue = !_lastIntegrationRunTimes.ContainsKey(integrationId)
                        || ((int)baseTime.TimeOfDay.TotalMinutes) % interval == intervalOffset
                        || ((int)(baseTime - _lastIntegrationRunTimes[integrationId]).TotalMinutes) >= interval;

                    if (!isDue) continue;

                    int seqNum = Interlocked.Increment(ref _sequenceNumber);
                    _lastIntegrationRunTimes[integrationId] = baseTime;

                    object[] metrics = new object[10];
                    LogRunJob(connectionString, int.Parse(integrationId), seqNum, isStart: true, metrics);

                    try
                    {
                        switch (integrationMethodName)
                        {
                            case "GenericJsonQuery":
                                log.LogInformation(
                                    "Calling GenericJsonQuery for {Name} at {Time}",
                                    integrationName, baseTime.ToShortTimeString());
                                metrics = await GenericJsonQuery.ImportEvents(
                                    connectionString, log, customUrl, integrationId,
                                    integrationName, baseTime, maxLat, minLat, maxLon, minLon);
                                log.LogInformation(
                                    "GenericJsonQuery completed for {Name} at {Time}",
                                    integrationName, baseTime.ToShortTimeString());
                                break;

                            // TODO: IntFacebook not yet ported to this API project
                            case "IntFacebook":
                                log.LogWarning(
                                    "IntFacebook integration skipped — not yet implemented in HC6 API (integration: {Name})",
                                    integrationName);
                                break;

                            default:
                                log.LogWarning(
                                    "Unknown integration method '{Method}' for integration '{Name}'",
                                    integrationMethodName, integrationName);
                                break;
                        }
                    }
                    catch (Exception ex)
                    {
                        log.LogError(
                            "Integration '{Name}' failed: {Message}",
                            integrationName, ex.Message);
                    }
                    finally
                    {
                        LogRunJob(connectionString, int.Parse(integrationId), seqNum, isStart: false, metrics);
                    }
                }
            }
            catch (Exception ex)
            {
                log.LogError("HcExternalDataIntegration error: {Message}", ex.Message);
            }
        }

        private static void LogRunJob(
            string connectionString,
            int integrationId,
            int seqNum,
            bool isStart,
            object[] metrics)
        {
            try
            {
                using SqlConnection conn = new(connectionString);
                conn.Open();

                string sql;
                SqlParameter[] parameters;

                if (isStart)
                {
                    sql = @"INSERT HC.IntegrationJob (IntegrationId, SequenceNumber, StartedAt)
                            VALUES (@integrationId, @seqNum, @startTime)";

                    parameters =
                    [
                        new SqlParameter("@integrationId", integrationId),
                        new SqlParameter("@seqNum",        seqNum),
                        new SqlParameter("@startTime",     DateTime.Now),
                    ];
                }
                else
                {
                    sql = @"UPDATE HC.IntegrationJob SET
                               EndedAt              = @endedAt,
                               RecordsRead          = @recordsRead,
                               RecordsWritten       = @recordsWritten,
                               RecordsSuccessInfo   = @recordsSuccessInfo,
                               RecordsFailedInfo    = @recordsFailedInfo,
                               ErrorCount           = @errorCount,
                               ErrorInfo            = @errorInfo,
                               KennelsSucceeded     = @kennelsSucceeded,
                               KennelsSucceededInfo = @kennelsSucceededInfo,
                               KennelsFailed        = @kennelsFailed,
                               KennelsFailedInfo    = @kennelsFailedInfo
                           WHERE IntegrationId = @integrationId
                             AND SequenceNumber = @seqNum
                             AND StartedAt > DATEADD(minute, -10, GETDATE())";

                    string errorInfo = metrics.Length > 5 ? metrics[5]?.ToString() ?? "" : "";
                    if (errorInfo.Length > 4000)
                        errorInfo = errorInfo[..4000];

                    parameters =
                    [
                        new SqlParameter("@integrationId",        integrationId),
                        new SqlParameter("@seqNum",               seqNum),
                        new SqlParameter("@endedAt",              DateTime.Now),
                        new SqlParameter("@recordsRead",          metrics.Length > 0 ? metrics[0] : DBNull.Value),
                        new SqlParameter("@recordsWritten",       metrics.Length > 1 ? metrics[1] : DBNull.Value),
                        new SqlParameter("@recordsSuccessInfo",   metrics.Length > 2 ? metrics[2] : DBNull.Value),
                        new SqlParameter("@recordsFailedInfo",    metrics.Length > 3 ? metrics[3] : DBNull.Value),
                        new SqlParameter("@errorCount",           metrics.Length > 4 ? metrics[4] : DBNull.Value),
                        new SqlParameter("@errorInfo",            errorInfo),
                        new SqlParameter("@kennelsSucceeded",     metrics.Length > 6 ? metrics[6] : DBNull.Value),
                        new SqlParameter("@kennelsSucceededInfo", metrics.Length > 7 ? metrics[7] : DBNull.Value),
                        new SqlParameter("@kennelsFailed",        metrics.Length > 8 ? metrics[8] : DBNull.Value),
                        new SqlParameter("@kennelsFailedInfo",    metrics.Length > 9 ? metrics[9] : DBNull.Value),
                    ];
                }

                using SqlCommand cmd = new(sql, conn);
                cmd.Parameters.AddRange(parameters);
                cmd.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                // Don't throw — job logging failure must not abort the integration run
                Console.WriteLine($"LogRunJob error: {ex.Message}");
            }
        }
    }
}
