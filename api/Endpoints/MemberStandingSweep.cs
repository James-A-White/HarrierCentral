using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using System.Data;

namespace HcWebApi
{
    /// <summary>
    /// Daily sweep for the automated MEMBER bit (0x0001) of
    /// HC.HasherKennelMap.KennelStanding. All logic lives in
    /// HC6.nonApi_sweepMemberStanding — this function is only the clock.
    /// The API shim is the consolidation point for scheduled automation
    /// (KennelStanding design of record, 2026-07-06).
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
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "MemberStandingSweep failed");
            }
        }
    }
}
