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



// // http://localhost:7071/api/SendKennelRunStatsReport?userId=0CDBB109-215E-4B5F-A405-F6C9FBCB18EC&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&kennelId=5029DE3A-D231-47AA-BE72-ECE9BCCD55D1&kennelName=FILTHHASH&userName=Opee&emailAddress=james@defenceinnovation.eu&digitsAfterDecimal=2&currencySymbol=€^

// namespace HcAzureFunctions
// {
//     public static class SendKennelRunStatsReport
//     {
//         [FunctionName("SendKennelRunStatsReport")]
//         public static async Task<IActionResult> Run(
//             [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)]
//             HttpRequest req,
//             ILogger log)
//         {
//             log.LogInformation("SendKennelRunStatsReport triggered by HTTP Request");

//             try
//             {
//                 string userId = "";
//                 string kennelId = "";
//                 string emailAddress = "";
//                 string accessToken = "";
//                 string kennelName = "";
//                 string userName = "";
//                 string digitsAfterDecimal = "";
//                 string currencySymbol = "";

//                 if (req.QueryString.HasValue)
//                 {
//                     userId = req.Query["userId"];
//                     kennelId = req.Query["kennelId"];
//                     emailAddress = req.Query["emailAddress"];
//                     accessToken = req.Query["accessToken"];
//                     kennelName = req.Query["kennelName"];
//                     userName = req.Query["userName"];
//                     digitsAfterDecimal = req.Query["digitsAfterDecimal"];
//                     currencySymbol = req.Query["currencySymbol"];
//                 }
//                 else
//                 {
//                     string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
//                     dynamic result = JsonConvert.DeserializeObject(requestBody);

//                     userName = result.userName;
//                     kennelId = result.kennelId;
//                     emailAddress = result.emailAddress;
//                     accessToken = result.accessToken;
//                     kennelName = result.kennelName;
//                     userId = result.userId;
//                     digitsAfterDecimal = result.digitsAfterDecimal;
//                     currencySymbol = result.currencySymbol;
//                 }

//                 Guid kennelIdGuid = Guid.Parse(kennelId);
//                 Guid userIdGuid = Guid.Parse(userId);

//                 using (var wb = new ExcelPackage())
//                 {
//                     await GetRptKennelRunStats(wb, log, userIdGuid, accessToken, kennelIdGuid, kennelName, digitsAfterDecimal, currencySymbol);

//                     SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient("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");

//                     // Send a Single Email using the Mail Helper
//                     var from = new EmailAddress("gd@jamesawhite.com", "Harrier Central Service");
//                     var subject = $"Here's the run stats report for {kennelName}";
//                     var to = new EmailAddress(emailAddress, userName);
//                     var plainTextContent = $"Hello. Attached, you will find the run stats report for {kennelName}.";
//                     var htmlContent = $"<strong>Hello. Attached, you will find the run stats report for {kennelName}</strong>";
//                     var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

//                     msg.AddAttachment("kennelRunStats.xlsx", System.Convert.ToBase64String(wb.GetAsByteArray()), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

//                     var response = await mailClient.SendEmailAsync(msg);
//                 }
//             }

//             catch (System.Exception ex)
//             {
//                 return new BadRequestObjectResult($"Error processing email request: {ex.ToString()}, {ex.Message}");
//             }

//             return new OkObjectResult("Success");
//         }

//         public static String formatCurrency(decimal amount, String digitsAfterDecimal, String currencySymbol)
//         {

//             String formatDecimals = "{0:#####0.00}";
//             switch (digitsAfterDecimal)
//             {
//                 case "0":
//                     formatDecimals = "{0:#####0}";
//                     break;
//                 case "1":
//                     formatDecimals = "{0:#####0.0}";
//                     break;
//                 case "2":
//                     formatDecimals = "{0:#####0.00}";
//                     break;
//                 case "3":
//                     formatDecimals = "{0:#####0.000}";
//                     break;
//                 case "4":
//                     formatDecimals = "{0:#####0.0000}";
//                     break;
//                 default:
//                     formatDecimals = "{0:#####0.00}";
//                     break;
//             }

//             return currencySymbol.Replace("^", String.Format(formatDecimals, amount));
//         }


//         public static async Task GetRptKennelRunStats(ExcelPackage wb, ILogger log, Guid userId, String accessToken, Guid kennelId, String kennelName, String digitsAfterDecimal, String currencySymbol)
//         {
//             var str = ConfigurationManager.ConnectionStrings["HarrierCentralDb"]?.ConnectionString;
//             if (String.IsNullOrWhiteSpace(str))
//             {
//                 str = "Server=tcp:harriercentral.database.windows.net,1433;Initial Catalog=HarrierCentralWebDb;Persist Security Info=False;User ID=harrieradmin;Password=Op33AndTuna;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
//             }

//             using (SqlConnection conn = new SqlConnection(str))
//             {
//                 conn.Open();

//                 var queryTotals = $"EXEC HC3.rptKennelRunStats @userId = '{userId.ToString()}', @accessToken = '{accessToken}',@kennelId = '{kennelId.ToString()}'";

//                 using (SqlCommand cmdTotals = new SqlCommand(queryTotals, conn))
//                 {
//                     // Execute the command and log the # rows affected.
//                     var rowsTotals = await cmdTotals.ExecuteReaderAsync();

//                     if (rowsTotals.HasRows)
//                     {
//                         int worksheetIndex = 0;

//                         bool isFirstRow = true;
//                         ExcelWorksheet firstSheet = null;
//                         int firstSheetRowCounter = 3;

//                         while (rowsTotals.Read())
//                         {    
//                             if (isFirstRow)
//                             {
//                                 wb.Workbook.Worksheets.Add("Run Stats");
//                                 firstSheet = wb.Workbook.Worksheets[worksheetIndex];
//                                 worksheetIndex++;

//                                 firstSheet.Cells[1, 5].Value = "Kennel run stats report for: " + kennelName;
//                                 firstSheet.Row(1).Style.WrapText = false;
//                                 firstSheet.Row(1).Style.Font.Bold = true;
//                                 firstSheet.Row(1).Style.Font.Size = 22;
//                                 firstSheet.Cells[1, 5].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

//                                 firstSheet.Row(firstSheetRowCounter).Style.WrapText = true;
//                                 firstSheet.Row(firstSheetRowCounter).Style.Font.Bold = true;
//                                 firstSheet.Row(firstSheetRowCounter).Style.Font.Size = 12;
//                                 firstSheet.Column(1).Width = 50;
//                                 firstSheet.Column(2).Width = 15;
//                                 firstSheet.Column(3).Width = 15;
//                                 firstSheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
//                                 firstSheet.Column(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
//                                 firstSheet.Column(4).Width = 30;

//                                 firstSheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

//                                 List<String> columns = Enumerable.Range(0, rowsTotals.FieldCount).Select(rowsTotals.GetName).ToList();
                                
//                                 for (int col = 0; col < rowsTotals.FieldCount; col++)
//                                 {
//                                     if (col > 3)
//                                     {
//                                         firstSheet.Column(col+1).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
//                                         firstSheet.Column(col+1).Width = 8;
//                                         firstSheet.Cells[firstSheetRowCounter, col + 1].Style.TextRotation = 90;
//                                     } else
//                                     {
//                                         firstSheet.Cells[firstSheetRowCounter, col + 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                        
//                                     }
//                                     firstSheet.Cells[firstSheetRowCounter, col + 1].Value = columns[col].Replace('_',' ');
//                                 }
//                                 firstSheetRowCounter++;
//                             }


//                             if (firstSheet != null)
//                             {
//                                 for (int col = 0; col < rowsTotals.FieldCount; col++)
//                                 {
//                                     String s = "";
                            
//                                     var val = rowsTotals.GetValue(col);

//                                     if (val is DateTime)
//                                     {
//                                         if (((DateTime)val) > new DateTime(2099,1,1))
//                                         {
//                                             if (firstSheetRowCounter == 4)
//                                             {
//                                                 firstSheet.Cells[firstSheetRowCounter, col + 1].Value = "Total runs =>";        
//                                             } else if (firstSheetRowCounter == 5)
//                                             {
//                                                 firstSheet.Cells[firstSheetRowCounter, col + 1].Value = "Total haring =>";
//                                             }
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Right;
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Bold = true;
//                                             firstSheet.Cells[firstSheetRowCounter, 1].Value = "";
//                                             continue;
//                                         }
//                                         if (firstSheetRowCounter > 5)
//                                         {
//                                             s = String.Format("{0:ddd, dd MMM yyyy, hh:mm tt}",val);
//                                         }
//                                     }

//                                     int paymentType = 0;
//                                     bool isPaymentCell = false;

//                                     if ((val is int) && (Math.Abs(((int)val)) >= 100000000))
//                                     {
//                                         isPaymentCell = true;
//                                         int valInt = ((int)val);
//                                         bool isHare = valInt < 0 ? true : false;
//                                         valInt = Math.Abs(valInt) - 100000000;
//                                         paymentType = valInt % 10;
//                                         valInt /= 10;

//                                         decimal n = ((decimal)valInt)/1000;

//                                         if (isHare)
//                                         {
//                                             n = Math.Abs(n);
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Yellow);
//                                         }

//                                         if (n >= 9999)
//                                         {
//                                             s = "✓";
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Red);
//                                             isPaymentCell = false;
//                                         }
//                                         else
//                                         {

//                                             if ((firstSheetRowCounter <= 5) || (col == 1))
//                                             {
//                                                 s = String.Format("{0:#####0}", n);
//                                             }
//                                             else
//                                             {
//                                                 s = formatCurrency((decimal)n, digitsAfterDecimal, currencySymbol);
//                                             }
//                                         }
//                                     } else if ((val is int) || (val is short))
//                                     {
//                                         if ((col != 1) || (((int)((short)val)) > 0))
//                                         {
//                                             s = String.Format("{0:#####0}", val);
//                                         }
//                                     }

//                                     if (val is String)
//                                     {
//                                         s = val.ToString();
//                                     }

//                                     //paymentTypeUnknown = EnumPaymentType<int>(0);
//                                     //paymentNotPaid = EnumPaymentType<int>(1);
//                                     //paymentFreeRun = EnumPaymentType<int>(2);
//                                     //paymentCash = EnumPaymentType<int>(3);
//                                     //paymentBankTransfer = EnumPaymentType<int>(4);
//                                     //paymentCashOtherAmount = EnumPaymentType<int>(5);
//                                     //paymentHashCredit = EnumPaymentType<int>(6);
//                                     //paymentBankTransferOtherAmount = EnumPaymentType<int>(7);

//                                     switch (paymentType)
//                                     {
//                                         case 0:
//                                             if (isPaymentCell)
//                                             {
//                                                 s = "?";
//                                                 firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Red);
//                                                 firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Bold = true;
//                                             }
//                                             break;
//                                         case 1:
//                                             s = "✗";
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Red);
//                                             break;
//                                         case 2:
//                                             s = "Free";
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Green);
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Bold = true;
//                                             break;
//                                         case 3:
//                                         case 5:
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Green);
//                                             break;
//                                         case 4:
//                                         case 7:
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Blue);
//                                             break;
//                                         case 6:
//                                             firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Purple);
//                                             break;
//                                     }

//                                     firstSheet.Cells[firstSheetRowCounter, col+1].Value = s.Trim();
//                                 }

//                                 firstSheetRowCounter++;
//                             }

//                             isFirstRow = false;
//                         }

//                         firstSheetRowCounter += 3;

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = "Key";
//                         firstSheet.Cells[firstSheetRowCounter++, 2].Style.Font.Bold = true;

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = formatCurrency(5, digitsAfterDecimal, currencySymbol);
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Green);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Green text = Hasher paid in cash";

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = formatCurrency(5, digitsAfterDecimal, currencySymbol);
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Blue);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Blue text = Hasher paid by bank transfer";

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = formatCurrency(5, digitsAfterDecimal, currencySymbol);
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Purple);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Purple text = Hasher paid by Hash credit";

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = "✗";
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Red);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Red X = Hasher didn't pay";

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = "✓";
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Red);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Red ✓ = Hasher was at the run, but there is no payment record. They probably didn't pay";

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = "Free";
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Green);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Green 'Free' = Hasher's run was free";

//                         firstSheet.Cells[firstSheetRowCounter, 2].Value = "";
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
//                         firstSheet.Cells[firstSheetRowCounter, 2].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Yellow);
//                         firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
//                         firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Yellow highlighted cell indicates Hasher hared this run";

//                     }
//                 }
//             }
//         }
//     }
// }


