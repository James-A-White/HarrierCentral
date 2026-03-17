

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
                String? email = "";

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
                    if (result == null || result?.email == null)
                    {
                        return new BadRequestObjectResult("Email address is required.");
                    }

                    email = result!.email;

                }


                string updateText2 = $"EXEC HC.nonApi_getUserInviteCode @email=N'{email}'";
                string inviteCode = "No code found";
                bool success = false;


                using (SqlConnection conn4 = new SqlConnection(connectionStr))
                {

                    using (SqlCommand updateCmd2 = new SqlCommand(updateText2, conn4))
                    {
                        conn4.Open();

                        try
                        {
                            // Execute the command and log the # rows affected.
                            using (SqlDataReader updateRows2 = updateCmd2.ExecuteReader())
                            {
                                // log.LogInformation(updateText);

                                while (updateRows2.Read())
                                {
                                    log.LogInformation(updateText2);
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
                            log.LogInformation("----- " + updateText2);

                            RecordErrorInDB(log, connectionStr, ex.GetType().Name, ex.Message, "Add remove HC App SQL query failed", updateText2);
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
                return new BadRequestObjectResult($"Error processing email invite code request: {ex.ToString()}, {ex.Message}");
            }

            return new OkObjectResult(userMessage);
        }

        static void RecordErrorInDB(ILogger log, String connectionStr, String errorType, String message, String method, String inputText)
        {
            using (SqlConnection conn3 = new SqlConnection(connectionStr))
            {
                string renumberCommand = $"EXEC HC.nonApi_logError @errorType='{errorType}',@message=N'{message}', @location=N'{method}', @inputText=N'{inputText}'";

                using (SqlCommand updateCmd = new SqlCommand(renumberCommand, conn3))
                {
                    conn3.Open();

                    try
                    {
                        //Execute the command and log the # rows affected.
                        using (SqlDataReader updateRows = updateCmd.ExecuteReader())
                        {
                            //log.LogInformation(updateText);

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


