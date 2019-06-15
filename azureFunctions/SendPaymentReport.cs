// using System;
// using System.Collections.Generic;
// using System.Configuration;
// using System.Data.SqlClient;
// using System.IO;
// using System.Linq;
// using System.Net.Http;
// using System.Reflection;
// using System.Text;
// using System.Text.RegularExpressions;
// using System.Threading.Tasks;
// using Microsoft.Azure.WebJobs;
// using Microsoft.WindowsAzure.Storage;
// using Microsoft.WindowsAzure.Storage.Blob;
// using Newtonsoft.Json;
// using Microsoft.Extensions.Logging;
// using OfficeOpenXml;

// using Microsoft.AspNetCore.Mvc;
// using Microsoft.Azure.WebJobs.Extensions.Http;
// using Microsoft.AspNetCore.Http;
// using SendGrid.Helpers.Mail;

// namespace HcAzureFunctions
// {
//     public static class SendPaymentReport
//     {
//         [FunctionName("SendPaymentReport")]
//         public static async Task<IActionResult> Run(
//             [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)]
//             HttpRequest req,
//             ILogger log)
//         {
//             log.LogInformation("C# HTTP trigger function processed a request.");

//             try
//             {
//                 string content = string.Empty;

//                 string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

//                 dynamic result = JsonConvert.DeserializeObject(requestBody);

//                 string userName = result.userName;
//                 string eventId = result.eventId;
//                 string emailAddress = result.emailAddress;
//                 string accessToken = result.accessToken;
//                 string eventName = result.eventName;
//                 string userId = result.userId;

//                 Guid eventIdGuid = Guid.Parse(eventId);
//                 Guid userIdGuid = Guid.Parse(userId);

//                 using (var wb = new ExcelPackage())
//                 {
//                     await GetPaymentReport(wb, log, userIdGuid, accessToken, eventIdGuid);

//                     SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient("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");

//                     // Send a Single Email using the Mail Helper
//                     var from = new EmailAddress("gd@jamesawhite.com", "Harrier Central Service");
//                     var subject = $"Here's your Harrier Central Payment Report for {eventName}";
//                     var to = new EmailAddress(emailAddress, userName);
//                     var plainTextContent = $"Hello. Attached, you will find your Payment Report for {eventName}.";
//                     var htmlContent = $"<strong>Hello. Attached, you will find your Payment Report for {eventName}</strong>";
//                     var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

//                     msg.AddAttachment("paymentReport.xlsx", System.Convert.ToBase64String(wb.GetAsByteArray()), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

//                     var response = await mailClient.SendEmailAsync(msg);
//                 }
//             }

//             catch (System.Exception ex)
//             {
//                 return new BadRequestObjectResult($"Error processing email request: {ex.ToString()}, {ex.Message}");
//             }

//             return new OkObjectResult("Success");
//         }


//         public static async Task GetPaymentReport(ExcelPackage wb, ILogger log, Guid userId, String accessToken, Guid eventId)
//         {


//             wb.Workbook.Worksheets.Add("Payment Report");
//             var ws = wb.Workbook.Worksheets[0];

//             var str = ConfigurationManager.ConnectionStrings["HarrierCentralDb"]?.ConnectionString;
//             if (String.IsNullOrWhiteSpace(str))
//             {
//                 str = "Server=tcp:harriercentral.database.windows.net,1433;Initial Catalog=HarrierCentralWebDb;Persist Security Info=False;User ID=harrieradmin;Password=Op33AndTuna;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
//             }

//             using (SqlConnection conn = new SqlConnection(str))
//             {
//                 conn.Open();

//                 var query = $"EXEC HC2.getPaymentReport @userId = '{userId.ToString()}', @accessToken = '{accessToken}',@kennelId = '00000000-0000-0000-0000-000000000000',@eventId = '{eventId.ToString()}', @showAllTransactions = 0, @paidTo = '00000000-0000-0000-0000-000000000000',@paidBy = '00000000-0000-0000-0000-000000000000',@includeAggregates = 0";

//                 using (SqlCommand cmd = new SqlCommand(query, conn))
//                 {
//                     // Execute the command and log the # rows affected.
//                     var rows = await cmd.ExecuteReaderAsync();

//                     if (rows.HasRows)
//                     {
//                         ws.Cells[2, 1].Value = "Paid by";
//                         ws.Cells[2, 2].Value = "Amount Paid";
//                         ws.Cells[2, 3].Value = "Payment Type";
//                         ws.Cells[2, 4].Value = "Paid to";
//                         ws.Cells[2, 5].Value = "Payment reference";
//                         ws.Cells[2, 6].Value = "Amount due";
//                         ws.Cells[2, 7].Value = "Payment date";
//                         ws.Cells[2, 8].Value = "Credit remaining";
//                         ws.Cells[2, 9].Value = "Notes";

//                         int rowCounter = 3;

//                         while (rows.Read())
//                         {
//                             int paymentTypeInt = int.Parse(rows.GetValue(8).ToString());

//                             if (paymentTypeInt < 100)
//                             {

//                                 string currencySymbol = rows.GetValue(14).ToString().Trim();
//                                 int digitsAfterDecimal = int.Parse(rows.GetValue(15).ToString());
//                                 String currencyFormat = "0";
//                                 if (digitsAfterDecimal > 0)
//                                 {
//                                     currencyFormat = currencyFormat + "." + "00000000".Substring(0, digitsAfterDecimal);
//                                 }

//                                 currencyFormat = currencySymbol.Replace("^", currencyFormat);


//                                 string paidBy = rows.GetValue(3).ToString().Trim();
//                                 string paidTo = rows.GetValue(4).ToString().Trim();
//                                 string cancelledBy = rows.GetValue(5).ToString().Trim();
//                                 string amountPaid = double.Parse(rows.GetValue(6).ToString().Trim()).ToString(currencyFormat);
//                                 string amountDue = double.Parse(rows.GetValue(7).ToString().Trim()).ToString(currencyFormat);

//                                 string paymentDate = rows.GetValue(9).ToString().Trim();
//                                 string cancelledDate = rows.GetValue(10).ToString().Trim();
//                                 string paymentReference = rows.GetValue(11).ToString().Trim();
//                                 string notes = rows.GetValue(12).ToString().Trim();
//                                 string creditRemaining = double.Parse(rows.GetValue(13).ToString().Trim()).ToString(currencyFormat);

//                                 String paymentType = "Unknown";

//                                 switch (paymentTypeInt)
//                                 {
//                                     case 0:
//                                         paymentType = "Unknown";
//                                         break;
//                                     case 1:
//                                         paymentType = "Not paid";
//                                         break;
//                                     case 2:
//                                         paymentType = "Free";
//                                         break;
//                                     case 3:
//                                         paymentType = "Cash";
//                                         break;
//                                     case 4:
//                                         paymentType = "Bank transfer";
//                                         break;
//                                     case 5:
//                                         paymentType = "Cash (other amount)";
//                                         break;
//                                     case 6:
//                                         paymentType = "Hash credit";
//                                         break;
//                                     case 7:
//                                         paymentType = "Bank Transfer (other amount)";
//                                         break;

//                                 }

//                                 ws.Cells[rowCounter, 1].Value = paidBy;
//                                 ws.Cells[rowCounter, 2].Value = amountPaid;
//                                 ws.Cells[rowCounter, 3].Value = paymentType;
//                                 ws.Cells[rowCounter, 4].Value = paidTo;
//                                 ws.Cells[rowCounter, 5].Value = paymentReference;
//                                 ws.Cells[rowCounter, 6].Value = amountDue;
//                                 ws.Cells[rowCounter, 7].Value = paymentDate;
//                                 ws.Cells[rowCounter, 8].Value = creditRemaining;
//                                 ws.Cells[rowCounter, 9].Value = notes;

//                                 rowCounter++;

//                             }

//                         }
//                     }

//                 }
//             }
//         }
//     }
// }


