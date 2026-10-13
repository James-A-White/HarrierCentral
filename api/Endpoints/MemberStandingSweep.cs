using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;

namespace HcWebApi
{
    /// <summary>
    /// Daily scheduled automation (the API shim is the consolidation point —
    /// KennelStanding design of record, 2026-07-06). Runs:
    ///   HC6.nonApi_updateRunCountsForAllUsers — a full recompute of the
    ///      stamped run-count summaries (HcTotalRunCount etc.) so any count that
    ///      went stale outside the per-change triggers (migrations, direct edits,
    ///      missed triggers) self-heals nightly.
    /// All logic lives in the SPs — this function is only the clock.
    /// It also swept the automated MEMBER bit (0x0001) of KennelStanding until
    /// 2026-10-13, when James retired the bit: nothing read it, membership is
    /// MembershipExpirationDate, and each night's sweep re-synced every lapsed
    /// row to every phone for nothing. The function keeps its name because
    /// renaming an Azure Function changes its identity.
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
                _logger.LogError(ex, "Nightly run-count recompute failed");
            }
        }
    }
}
