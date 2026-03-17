// using Microsoft.AspNetCore.Http;
// using Microsoft.AspNetCore.Mvc;
// using Microsoft.Azure.Functions.Worker;
// using Microsoft.Data.SqlClient;

// using Microsoft.Extensions.Logging;
// using Newtonsoft.Json;
// using Newtonsoft.Json.Linq;

// using OfficeOpenXml;

// // http://localhost:7071/api/SendPaymentReport?deviceId=723BB72E-3737-4B53-A3A9-D5B812AD930C&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&eventId=AE3974C4-2641-49E2-B1BA-1B7F24B88D09&eventName=test&userName=Opee&emailAddress=james@defenceinnovation.eu

// namespace HcWebApi.Endpoints
// {
//     public class SendKennelInviteCodes
//     {
//         private readonly ILogger<SendKennelInviteCodes> log;

//         //private TableClient _tableClient;

//         public SendKennelInviteCodes(ILogger<SendKennelInviteCodes> logger)
//         {
//             log = logger;
//         }

//         [Function("SendKennelInviteCodes")]
//         public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
//         {

//             log.LogInformation("SendPaymentReport triggered by HTTP Request");

//             int recordCount = -1;
//             string isPreview = "yes";

//             try
//             {
//                 string deviceId = "";
//                 string kennelId = "";
//                 string emailAddress = "";
//                 string accessToken = "";
//                 string kennelName = "";
//                 string userName = "";

//                 if (req.QueryString.HasValue)
//                 {
//                     deviceId = req.Query.TryGetValue("deviceId", out var userIdVal) ? userIdVal.ToString() : "";
//                     kennelId = req.Query.TryGetValue("kennelId", out var kennelIdVal) ? kennelIdVal.ToString() : "";
//                     emailAddress = req.Query.TryGetValue("emailAddress", out var emailVal) ? emailVal.ToString() : "";
//                     accessToken = req.Query.TryGetValue("accessToken", out var token) ? token.ToString() : "";
//                     kennelName = req.Query.TryGetValue("kennelName", out var kennelVal) ? kennelVal.ToString() : "";
//                     userName = req.Query.TryGetValue("userName", out var userNameVal) ? userNameVal.ToString() : "";
//                     isPreview = req.Query.TryGetValue("isPreview", out var previewVal) ? previewVal.ToString() : "";

//                 }
//                 else
//                 {
//                     string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
//                     dynamic? result = JsonConvert.DeserializeObject<JObject>(requestBody);

//                     if (result == null)
//                     {
//                         return new BadRequestObjectResult("Invalid JSON in request body.");
//                     }

//                     userName = result.userName;
//                     kennelId = result.kennelId;
//                     emailAddress = result.emailAddress;
//                     accessToken = result.accessToken;
//                     kennelName = result.kennelName;
//                     deviceId = result.deviceId;
//                     isPreview = result.isPreview;
//                 }


//                 Guid kennelIdGuid = Guid.Parse(kennelId);
//                 Guid userIdGuid = Guid.Parse(deviceId);

//                 recordCount = await SendKennelInvites(log, userIdGuid, userName, accessToken, kennelIdGuid, kennelName, isPreview);

//             }

//             catch (System.Exception ex)
//             {
//                 return new BadRequestObjectResult($"Error processing email request: {ex.ToString()}, {ex.Message}");
//             }

//             String verb = isPreview.ToLower() == "yes" ? "Will send" : "Successfully sent";
//             String verb2 = isPreview.ToLower() == "yes" ? "prepare for sending" : "send";

//             return recordCount < 0 ? new OkObjectResult($"Failed to {verb2} invite code emails.") :
//                 recordCount == 0 ? new OkObjectResult($"Successful attempt to {verb2} e-mails, but no recipients were selected to receive invite codes.") :
//                 recordCount == 1 ? new OkObjectResult($"{verb} 1 email.") :
//                                    new OkObjectResult($"{verb} {recordCount} email(s).");
//         }


//         public static async Task<int> SendKennelInvites(ILogger log, Guid deviceId, String sender, String accessToken, Guid kennelId, String kennelName, String isPreview)
//         {
//             String displayName = "";
//             String email = "";
//             String inviteCode = "";

//             int recordCount = -1;

//             //var from = new EmailAddress("email.service@harriercentral.com", "Harrier Central Service");
//             //var subject = $"Here's your Harrier Central Invite Code";
//             //var to = new EmailAddress(email, email);
//             //var plainTextContent = $"Hello. \n\nPlease use this six letter code '{inviteCode}' to re-connect your Harrier Central app to your account.\n\nIf you are not attempting to reset your Harrier Central account you are receiving this email because someone attempted to set up the Harrier Central app using your email address.\n\nThanks! \n\nThe Harrier Central support team.";
//             //var htmlContent = $"Hello. <br><br>Please use this six letter code <h1><strong>{inviteCode}</strong></h1> to re-connect your Harrier Central app to your account. Please note, this code is comprised only of letters and does not contain any numbers.<br><br>If you are not attempting to reset your Harrier Central account you are receiving this email because someone attempted to set up the Harrier Central app using your email address.<br><br>Thanks! <br><br>The Harrier Central support team.";
//             //var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);


//             List<EmailAddress> receipients = new List<EmailAddress>();
//             List<String> subjects = new List<string>();
//             List<Dictionary<String, String>> substitutions = new List<Dictionary<string, string>>();


//             string connectionStr = Environment.GetEnvironmentVariable("HcDbConnectionString")
//     ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");



//             using (SqlConnection conn = new SqlConnection(connectionStr))
//             {
//                 conn.Open();

//                 var query = $"EXEC HC3.rptApi_emailKennelInviteCodes @deviceId = '{deviceId.ToString()}', @accessToken = '{accessToken}',@kennelId = '{kennelId.ToString()}'";
//                 using (SqlCommand cmd = new SqlCommand(query, conn))
//                 {
//                     // Execute the command and log the # rows affected.
//                     using (SqlDataReader rows = await cmd.ExecuteReaderAsync())
//                     {



//                         if (rows.HasRows)
//                         {
//                             while (rows.Read())
//                             {
//                                 displayName = rows.GetValue(0).ToString();
//                                 email = rows.GetValue(1).ToString();
//                                 inviteCode = rows.GetValue(2).ToString();

//                                 receipients.Add(new EmailAddress(email, displayName));
//                                 subjects.Add("Join " + kennelName + " on Harrier Central");
//                                 substitutions.Add(new Dictionary<string, string>() { { "{receipient_name}", displayName }, { "{invite_code}", inviteCode } });

//                                 log.LogInformation($"name = {displayName}");
//                                 log.LogInformation($"email = {email}");
//                             }
//                         }
//                     }
//                 }
//             }

//             if ((receipients.Count > 0) && (isPreview.ToLower() != "yes"))
//             {
//                 String plainTextContent =
// $@"Hello {{receipient_name}}, \n\n{kennelName} is now 
// using Harrier Central to manage our Kennel's activities. It would be great if you 
// would download the app for iOS or Android and 
// connect to the account we have created 
// for you. Harrier Central has many 
// features that are helpful both to individual Hashers 
// and also to this Kennel's mismanagement 
// and it's 100% free for you to use! 
// You can learn more about Harrier Central at https://www.harriercentral.com/ .
// \n\nAfter downloading Harrier Central 
// you can use this six letter code 
// '{{invite_code}}' to connect to the free Harrier Central 
// account we've created for you. Please note, this code is 
// comprised only of letters and does not contain any numbers.
// \n\n
// If you do not wish to use Harrier Central, that's not a problem as we can 
// still track your runs and hash cash for {kennelName}. We hope you will 
// see that it is an easy way to RSVP for our trails, 
// track your run counts and find trails and Hash events around the world. 
// \n\nThanks!
// \n\n{sender}\n{kennelName}";


//                 String htmlContent =
//                 @$"Hello {{receipient_name}}, <br><br>{kennelName} is now using Harrier Central to manage 
// our Kennel's activities. It would be great if you would download the app for <a href=""https://apps.apple.com/app/harrier-central/id1445513595"">iOS</a> or <a href=""https://play.google.com/store/apps/details?id=com.harriercentral.app"">Android</a> 
// and connect to the account we have created for you. Harrier Central has many features that 
// are helpful both to individual Hashers and also to this Kennel's mismanagement and it's 
// 100% free for you to use! You can learn more about Harrier Central 
// at https://www.harriercentral.com/ . 
// <br><br>After downloading Harrier Central you can use this six letter 
// code <h1><strong>{{invite_code}}</strong></h1> to connect to the free 
// Harrier Central account we've created for you. 
// Please note, this code is comprised only of letters and does not 
// contain any numbers.
// <br><br>
// If you do not wish to use Harrier Central, that's not a problem as we can 
// still track your runs and hash cash for {kennelName}. We hope you will 
// see that it is an easy way to RSVP for our trails, 
// track your run counts and find trails and Hash events around the world. 
// <br><br>
// Thanks! 
// <br><br>{sender}<br>{kennelName}";

//                 SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient(Environment.GetEnvironmentVariable("SENDGRID_API_KEY"));

//                 EmailAddress from = new EmailAddress("email.service@harriercentral.com", $"{sender} (via Harrier Central Service)");

//                 SendGridMessage msg = MailHelper.CreateMultipleEmailsToMultipleRecipients(from, receipients, subjects, plainTextContent, htmlContent, substitutions);

//                 SendGrid.Response response = await mailClient.SendEmailAsync(msg);

//                 if (response.StatusCode == System.Net.HttpStatusCode.Accepted)
//                 {
//                     recordCount = receipients.Count;
//                 }
//             }
//             else if ((receipients.Count > 0) && (isPreview.ToLower() == "yes"))
//             {
//                 recordCount = receipients.Count;
//             }
//             else
//             {
//                 recordCount = 0;
//             }

//             return (recordCount);
//         }
//     }
// }


