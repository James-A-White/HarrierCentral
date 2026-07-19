using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;

namespace HcWebApi
{
    /// <summary>
    /// Daily scheduled automation (the API shim is the consolidation point —
    /// KennelStanding design of record, 2026-07-06). Runs, in order:
    ///   1. HC6.nonApi_sweepMemberStanding — the automated MEMBER bit (0x0001)
    ///      of HC.HasherKennelMap.KennelStanding.
    ///   2. HC6.nonApi_updateRunCountsForAllUsers — a full recompute of the
    ///      stamped run-count summaries (HcTotalRunCount etc.) so any count that
    ///      went stale outside the per-change triggers (migrations, direct edits,
    ///      missed triggers) self-heals nightly.
    /// All logic lives in the SPs — this function is only the clock.
    /// </summary>
    public class MemberStandingSweep
    {
        private readonly ILogger<MemberStandingSweep> _logger;

        public MemberStandingSweep(ILogger<MemberStandingSweep> logger)
        {
            _logger = logger;
        }

        // 03:10 UTC daily — quiet hours for the (mostly European) user base.
        [Function("MemberStandingSweep")]
        public async Task Run([TimerTrigger("0 10 3 * * *")] TimerInfo myTimer)
        {
            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            try
            {
                using SqlConnection conn = new(connectionString);
                await conn.OpenAsync();

                using SqlCommand cmd = new("HC6.nonApi_sweepMemberStanding", conn)
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandTimeout = 120,
                };
                cmd.Parameters.AddWithValue("@graceDays", 0);

                object? result = await cmd.ExecuteScalarAsync();
                _logger.LogInformation(
                    "MemberStandingSweep completed — rowsChanged={RowsChanged}",
                    result ?? 0);

                // Full nightly recompute of run-count summaries so any stale
                // HcTotalRunCount (etc.) self-heals. No @updatedSince = all users.
                using SqlCommand runCountsCmd = new("HC6.nonApi_updateRunCountsForAllUsers", conn)
                {
                    CommandType = CommandType.StoredProcedure,
                    CommandTimeout = 600,
                };
                await runCountsCmd.ExecuteNonQueryAsync();
                _logger.LogInformation("Run-count recompute (all users) completed");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "MemberStandingSweep / run-count recompute failed");
            }
        }
    }
}
