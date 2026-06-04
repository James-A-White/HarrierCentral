

using Newtonsoft.Json;
using Microsoft.Extensions.Logging;

using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;

using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;


// localhost:7071/api/EmailInviteCode?email=james@jamesawhite.com

namespace HcWebApi.Endpoints
{
    public class EmailInviteCode
    {
        private readonly ILogger<SendKennelRunStatsReport> log;

        //private TableClient _tableClient;

        public EmailInviteCode(ILogger<SendKennelRunStatsReport> logger)
        {
            log = logger;
        }

        [Function("EmailInviteCode")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)

        {
            log.LogInformation("EmailInviteCode triggered by HTTP Request");

            string userMessage = "An error occurred while requesting your invite code. Please try again in a few minutes";

            string connectionStr = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            try
            {
                String? email = null;
                String? publicHasherId = null;

                if (req.QueryString.HasValue)
                {
                    email = req.Query["email"];
                    if (string.IsNullOrEmpty(email))
                    {
                        return new BadRequestObjectResult("Email address is required.");
                    }
                }
                else
                {
                    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                    dynamic result = JsonConvert.DeserializeObject(requestBody)!;
                    email = (string?)result?.email;
                    publicHasherId = (string?)result?.publicHasherId;

                    if (string.IsNullOrEmpty(email) && string.IsNullOrEmpty(publicHasherId))
                    {
                        return new BadRequestObjectResult("Email address or publicHasherId is required.");
                    }
                }

                string inviteCode = "No code found";
                bool success = false;

                if (!string.IsNullOrEmpty(publicHasherId))
                {
                    // New path: look up email + invite code by publicHasherId — email stays server-side
                    using (SqlConnection conn = new SqlConnection(connectionStr))
                    {
                        using (SqlCommand cmd = new SqlCommand("HC.nonApi_getUserInviteCodeByPublicHasherId", conn))
                        {
                            cmd.CommandType = System.Data.CommandType.StoredProcedure;
                            cmd.Parameters.AddWithValue("@publicHasherId", Guid.Parse(publicHasherId));
                            conn.Open();
                            try
                            {
                                using (SqlDataReader reader = cmd.ExecuteReader())
                                {
                                    if (reader.Read())
                                    {
                                        email = reader["Email"]?.ToString();
                                        inviteCode = reader["InviteCode"]?.ToString() ?? inviteCode;
                                        if (!string.IsNullOrEmpty(email) && inviteCode.Length == 6)
                                        {
                                            success = true;
                                            userMessage = "An invite code has been sent to their email address.";
                                        }
                                    }
                                    else
                                    {
                                        userMessage = "No matching account found for the selected hasher.";
                                    }
                                }
                            }
                            catch (System.Exception ex)
                            {
                                log.LogInformation("----- HC.nonApi_getUserInviteCodeByPublicHasherId failed --- " + ex.Message);
                                RecordErrorInDB(log, connectionStr, ex.GetType().Name, ex.Message,
                                    "HC.nonApi_getUserInviteCodeByPublicHasherId", publicHasherId);
                            }
                        }
                    }
                }
                else
                {
                    // Existing path: look up invite code by email address
                    using (SqlConnection conn4 = new SqlConnection(connectionStr))
                    {
                        using (SqlCommand updateCmd2 = new SqlCommand("HC.nonApi_getUserInviteCode", conn4))
                        {
                            updateCmd2.CommandType = System.Data.CommandType.StoredProcedure;
                            updateCmd2.Parameters.AddWithValue("@email", email);
                            conn4.Open();

                            try
                            {
                                using (SqlDataReader updateRows2 = updateCmd2.ExecuteReader())
                                {
                                    while (updateRows2.Read())
                                    {
                                        log.LogInformation("HC.nonApi_getUserInviteCode executed");
                                        log.LogInformation(updateRows2.GetValue(0).ToString() + " Invite Code generated");
                                        inviteCode = updateRows2.GetValue(0).ToString()?.Replace("URC:", "") ?? inviteCode;
                                        if (inviteCode.Length == 6)
                                        {
                                            success = true;
                                            userMessage = "An invite code has been sent to your email address. Please check your email and use the invite code you received to set up the Harrier Central app.";
                                        }
                                        else
                                        {
                                            success = false;
                                            userMessage = inviteCode;
                                        }
                                    }
                                }
                            }
                            catch (System.Exception ex)
                            {
                                log.LogInformation("----- Add remove HC App SQL query failed --- " + ex.Message);
                                log.LogInformation("----- " + ex.GetType().Name);
                                RecordErrorInDB(log, connectionStr, ex.GetType().Name, ex.Message, "Add remove HC App SQL query failed", "HC.nonApi_getUserInviteCode");
                            }
                        }
                    }
                }

                if (success)
                {
                    await Utilities.SendEmailAsync(
                        "https://prod-46.northeurope.logic.azure.com:443/workflows/ea2b7fd09a8d407fa58ab04b64638217/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aqjP-q4tvhj-S9aemqQKFGP5ZQYBWOBFTL_KSUvcVl8",
                        "james@defenceinnovation.eu",
                        email,
                        $"Here's your Harrier Central Invite Code",
                        $"Hello. <br><br>Please use this six letter code <h1><strong>{inviteCode}</strong></h1> to re-connect your Harrier Central app to your account. Please note, this code is comprised only of letters and does not contain any numbers.<br><br>If you are not attempting to reset your Harrier Central account you are receiving this email because someone attempted to set up the Harrier Central app using your email address.<br><br>Thanks! <br><br>The Harrier Central support team.",
                        null
                    );


                    // SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient(Environment.GetEnvironmentVariable("SENDGRID_API_KEY"));

                    // // Send a Single Email using the Mail Helper
                    // var from = new EmailAddress("email.service@harriercentral.com", "Harrier Central Service");
                    // var subject = $"Here's your Harrier Central Invite Code";
                    // var to = new EmailAddress(email, email);
                    // var plainTextContent = $"Hello. \n\nPlease use this six letter code '{inviteCode}' to re-connect your Harrier Central app to your account.\n\nIf you are not attempting to reset your Harrier Central account you are receiving this email because someone attempted to set up the Harrier Central app using your email address.\n\nThanks! \n\nThe Harrier Central support team.";
                    // var htmlContent = $"Hello. <br><br>Please use this six letter code <h1><strong>{inviteCode}</strong></h1> to re-connect your Harrier Central app to your account. Please note, this code is comprised only of letters and does not contain any numbers.<br><br>If you are not attempting to reset your Harrier Central account you are receiving this email because someone attempted to set up the Harrier Central app using your email address.<br><br>Thanks! <br><br>The Harrier Central support team.";
                    // var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

                    // var response = await mailClient.SendEmailAsync(msg);
                }
            }

            catch (System.Exception ex)
            {
                log.LogError("Error processing email invite code request: {Message}", ex.Message);
                return new ObjectResult(new { success = false, message = "An unexpected error occurred." }) { StatusCode = 500 };
            }

            return new OkObjectResult(userMessage);
        }

        static void RecordErrorInDB(ILogger log, String connectionStr, String errorType, String message, String method, String inputText)
        {
            using (SqlConnection conn3 = new SqlConnection(connectionStr))
            {
                using (SqlCommand updateCmd = new SqlCommand("HC.nonApi_logError", conn3))
                {
                    updateCmd.CommandType = System.Data.CommandType.StoredProcedure;
                    updateCmd.Parameters.AddWithValue("@errorType", errorType);
                    updateCmd.Parameters.AddWithValue("@message", message);
                    updateCmd.Parameters.AddWithValue("@location", method);
                    updateCmd.Parameters.AddWithValue("@inputText", inputText);
                    conn3.Open();

                    try
                    {
                        //Execute the command and log the # rows affected.
                        using (SqlDataReader updateRows = updateCmd.ExecuteReader())
                        {
                            while (updateRows.Read())
                            {
                                log.LogInformation(updateRows.GetValue(0).ToString());
                            }
                        }
                    }

                    catch (System.Exception ex)
                    {
                        log.LogInformation("----- " + ex.GetType().Name);
                        log.LogInformation("----- " + ex.Message);
                    }

                }
            }
        }


    }


}


