using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Net.Http;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.WindowsAzure.Storage;
using Microsoft.WindowsAzure.Storage.Blob;
using Newtonsoft.Json;
using Microsoft.Extensions.Logging;
using OfficeOpenXml;

using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using SendGrid.Helpers.Mail;



// http://localhost:7071/api/SendRunCountsReport?userId=0CDBB109-215E-4B5F-A405-F6C9FBCB18EC&accessToken1=0EF40BCDD8BB668C5B387B2055BBF51DE920AE189D6F06CA7E91277BB61C67A0&accessToken2=FC2A32F976E65E0C5F50DE3FF89596A801C0E79C03019759FDC43B485AA73CDE&kennelId=00000000-0000-0000-0000-000000000000&kennelName=Test&userName=Opee&emailAddress=james@defenceinnovation.eu

namespace HcAzureFunctions
{
    public static class SendRunCountsReport
    {
        [FunctionName("SendRunCountsReport")]
        public static async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post", Route = null)]
            HttpRequest req,
            ILogger log)
        {
            log.LogInformation("SendRunCountsReport triggered by HTTP Request");

            try
            {
                string userId = "";
                string kennelId = "";
                string emailAddress = "";
                string accessToken_getMyRuns = "";
                string accessToken_getMyKennelRunTotals = "";
                string kennelName = "";
                string userName = "";

                if (req.QueryString.HasValue)
                {
                    userId = req.Query["userId"];
                    kennelId = req.Query["kennelId"];
                    emailAddress = req.Query["emailAddress"];
                    accessToken_getMyRuns = req.Query["accessToken1"];
                    accessToken_getMyKennelRunTotals = req.Query["accessToken2"];
                    kennelName = req.Query["kennelName"];
                    userName = req.Query["userName"];
                }
                else
                {
                    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                    dynamic result = JsonConvert.DeserializeObject(requestBody);

                    userName = result.userName;
                    kennelId = result.kennelId;
                    emailAddress = result.emailAddress;
                    accessToken_getMyRuns = result.accessToken1;
                    accessToken_getMyKennelRunTotals = result.accessToken2;
                    kennelName = result.kennelName;
                    userId = result.userId;
                }

                Guid kennelIdGuid = Guid.Parse(kennelId);
                Guid userIdGuid = Guid.Parse(userId);

                using (var wb = new ExcelPackage())
                {
                    await GetMyKennelRunTotals(wb, log, userIdGuid, accessToken_getMyKennelRunTotals, accessToken_getMyRuns, kennelIdGuid, userName);

                    SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient("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");

                    // Send a Single Email using the Mail Helper
                    var from = new EmailAddress("gd@jamesawhite.com", "Harrier Central Service");
                    var subject = $"Here's your Harrier Central Run Count Report for {kennelName}";
                    var to = new EmailAddress(emailAddress, userName);
                    var plainTextContent = $"Hello. Attached, you will find your Payment Report for {kennelName}.";
                    var htmlContent = $"<strong>Hello. Attached, you will find your Run Count Report for {kennelName}</strong>";
                    var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

                    msg.AddAttachment("runCountReport.xlsx", System.Convert.ToBase64String(wb.GetAsByteArray()), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

                    var response = await mailClient.SendEmailAsync(msg);
                }
            }

            catch (System.Exception ex)
            {
                return new BadRequestObjectResult($"Error processing email request: {ex.ToString()}, {ex.Message}");
            }

            return new OkObjectResult("Success");
        }


        public static async Task GetMyKennelRunTotals(ExcelPackage wb, ILogger log, Guid userId, String accessToken_getMyKennelRunTotals, String accessToken_getMyRuns, Guid kennelId, String userName)
        {
            var str = ConfigurationManager.ConnectionStrings["HarrierCentralDb"]?.ConnectionString;
            if (String.IsNullOrWhiteSpace(str))
            {
                str = "Server=tcp:harriercentral.database.windows.net,1433;Initial Catalog=HarrierCentralWebDb;Persist Security Info=False;User ID=harrieradmin;Password=Op33AndTuna;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
            }

            using (SqlConnection conn = new SqlConnection(str))
            {
                conn.Open();

                var queryTotals = $"EXEC HC2.getMyKennelRunTotals @userId = '{userId.ToString()}', @accessToken = '{accessToken_getMyKennelRunTotals}',@kennelId = '{kennelId.ToString()}'";

                using (SqlCommand cmdTotals = new SqlCommand(queryTotals, conn))
                {
                    // Execute the command and log the # rows affected.
                    var rowsTotals = await cmdTotals.ExecuteReaderAsync();

                    if (rowsTotals.HasRows)
                    {
                        int worksheetIndex = 0;

                        bool isFirstRow = true;
                        ExcelWorksheet firstSheet = null;
                        int firstSheetRowCounter = 4;

                        while (rowsTotals.Read())
                        {
                            string kennelIdStr = rowsTotals.GetValue(0).ToString().Trim();
                            string kennelLogo = rowsTotals.GetValue(1).ToString().Trim();
                            string kennelName = rowsTotals.GetValue(2).ToString().Trim();
                            string totalTotalRunsThisKennel = rowsTotals.GetValue(3).ToString().Trim();
                            string totalTotalPackRunsThisKennel = rowsTotals.GetValue(4).ToString().Trim();
                            string totalTotalHaringThisKennel = rowsTotals.GetValue(5).ToString().Trim();
                            string following = rowsTotals.GetValue(6).ToString().Trim();
                            string kennelShortName = rowsTotals.GetValue(7).ToString().Trim();

 //                           KennelId as kennelId
	//,KennelLogo as kennelLogo
	//,KennelName as kennelName
	//,TotalRunsThisKennel as totalRunsThisKennel
	//,TotalPackRunsThisKennel as totalPackRunsThisKennel
	//,TotalHaringThisKennel as totalHaringThisKennel
	//,[Following] as [following]
	//,KennelShortName as kennelShortName

                            //0: kennelId
                            //1: kennelLogo
                            //2: kennelName
                            //3: totalRunsThisKennel
                            //4: totalPackRunsThisKennel
                            //5: totalHaringThisKennel
                            //6: following
                            //7: kennelShortName

                            if (isFirstRow && kennelId == Guid.Empty)
                            {
                                isFirstRow = false;
                                if (kennelIdStr == "00000000-0000-0000-0000-000000000000")
                                {
                                    wb.Workbook.Worksheets.Add("Overall Totals");
                                    firstSheet = wb.Workbook.Worksheets[worksheetIndex];
                                    worksheetIndex++;

                                    firstSheet.Cells[1, 3].Value = "Run report for: " + userName;
                                    firstSheet.Row(1).Style.WrapText = false;
                                    firstSheet.Row(1).Style.Font.Bold = true;
                                    firstSheet.Row(1).Style.Font.Size = 22;
                                    firstSheet.Cells[1, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                                    firstSheet.Cells[3, 1].Value = "Kennel name";
                                    firstSheet.Column(1).Width = 30;
                                    firstSheet.Cells[3, 2].Value = "Total runs";
                                    firstSheet.Column(2).Width = 10;
                                    firstSheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                    firstSheet.Cells[3, 3].Value = "Ran as pack";
                                    firstSheet.Column(3).Width = 10;
                                    firstSheet.Column(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                    firstSheet.Cells[3, 4].Value = "Hared";
                                    firstSheet.Column(4).Width = 10;
                                    firstSheet.Column(4).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                    firstSheet.Cells[3, 5].Value = "Following Kennel";
                                    firstSheet.Column(5).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                    firstSheet.Column(5).Width = 15;

                                    firstSheet.Row(3).Style.WrapText = true;
                                    firstSheet.Row(3).Style.Font.Bold = true;
                                    firstSheet.Row(3).Style.Font.Size = 15;
                                    firstSheet.Row(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                }     
                                continue;
                            } else
                            {
                                if ((kennelId == Guid.Empty) || (kennelId.ToString().ToLower() == kennelIdStr.ToLower()))
                                {
                                    if (firstSheet != null)
                                    {
                                        firstSheet.Cells[firstSheetRowCounter, 1].Value = kennelName;
                                        firstSheet.Cells[firstSheetRowCounter, 2].Value = totalTotalRunsThisKennel;
                                        firstSheet.Cells[firstSheetRowCounter, 3].Value = totalTotalPackRunsThisKennel;
                                        firstSheet.Cells[firstSheetRowCounter, 4].Value = totalTotalHaringThisKennel;
                                        firstSheet.Cells[firstSheetRowCounter, 5].Value = following == "1" ? "Yes" : "";
                                        firstSheetRowCounter++;
                                    }
                                }
                            }

                            if ((kennelId == Guid.Empty) || (kennelId.ToString().ToLower() == kennelIdStr.ToLower()))
                            {

                                var queryOneKennel = $"EXEC HC2.getRuns @userId = '{userId.ToString()}', @accessToken = '{accessToken_getMyRuns}',@kennelId = '{kennelIdStr}',@following = -1,@filterByUser = 1,@includeHidden=0,@includeFuture=0";

                                using (SqlCommand cmdOneKennel = new SqlCommand(queryOneKennel, conn))
                                {
                                    // Execute the command and log the # rows affected.
                                    var rowOneKennel = await cmdOneKennel.ExecuteReaderAsync();

                                    if (rowOneKennel.HasRows)
                                    {
                                        bool needsWorksheet = true;
                                        ExcelWorksheet ws = null;
                                        int rowCounter = 4;

                                        while (rowOneKennel.Read())
                                        {
                                            //   0 e.id as eventId
                                            //  1 ,e.eventStartDatetime as eventStartDatetime
                                            //  2,e.eventEndDatetime as eventEndDatetime
                                            //  3,e.eventName as eventName
                                            //  4,e.EventNumber as eventNumber
                                            //5  ,e.LocationOneLineDesc as locationOneLineDesc
                                            // 6,e.userEventCounterIncrement as userEventCounterIncrement
                                            //7,e.EventFacebookId as eventFacebookId
                                            //8,e.IsVisible as isVisible
                                            //9,e.IsCountedRun as isCountedRun
                                            //10,e.AbsoluteEventNumber as absoluteEventNumber
                                            //11,hem.isHare as isHare
                                            //12,hem.totalRunsThisKennel as totalRunsThisKennel
                                            //13,hem.totalRunsAllKennels as totalRunsAllKennels
                                            //14,hem.TotalHaringThisKennel as totalHaringThisKennel
                                            //15,hem.userStartEvent as userStartEvent
                                            //16,coalesce(hem.RsvpState, 0) as rsvpState
                                            //17,coalesce(hem.AttendenceState, 0) as attendenceState
                                            //18,e.CanEditRunAttendence* hkm.CanEditRunAttendence* k.CanEditRunAttendence as canEditRunAttendence

                                            string eventId = rowOneKennel.GetValue(0).ToString().Trim();
                                            string eventStartDateTime = rowOneKennel.GetValue(1).ToString().Trim();
                                            string eventName = rowOneKennel.GetValue(3).ToString().Trim();
                                            string eventNumber = kennelShortName + " Run #" + rowOneKennel.GetValue(4).ToString().Trim();
                                            string location = rowOneKennel.GetValue(5).ToString().Trim();
                                            string isHare = rowOneKennel.GetValue(11).ToString().Trim();
                                            string totalRunsThisKennel = rowOneKennel.GetValue(12).ToString().Trim();
                                            string totalRunsAllKennels = rowOneKennel.GetValue(13).ToString().Trim();
                                            string totalHaringThisKennel = rowOneKennel.GetValue(14).ToString().Trim();
                                            int attendenceState = int.Parse(rowOneKennel.GetValue(17).ToString().Trim());

                                            // don't create a new worksheet until we know that we have completed
                                            // runs we want to log in that worksheet
                                            if (attendenceState >= 20)
                                            {
                                                if (needsWorksheet)
                                                {
                                                    needsWorksheet = false;
                                                    wb.Workbook.Worksheets.Add(kennelName);

                                                    ws = wb.Workbook.Worksheets[worksheetIndex];
                                                    worksheetIndex++;

                                                    ws.Cells[1, 4].Value = $"Run report for {userName} for {kennelName}";
                                                    ws.Row(1).Style.WrapText = false;
                                                    ws.Row(1).Style.Font.Bold = true;
                                                    ws.Row(1).Style.Font.Size = 22;
                                                    ws.Cells[1, 4].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                                                    ws.Cells[3, 1].Value = "Your run count";
                                                    ws.Column(1).Width = 10;
                                                    ws.Column(1).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                                    ws.Cells[3, 2].Value = "Run date";
                                                    ws.Column(2).Width = 20;
                                                    ws.Cells[3, 3].Value = "Run name";
                                                    ws.Column(3).Width = 50;
                                                    ws.Cells[3, 4].Value = "Run number";
                                                    ws.Column(4).Width = 20;
                                                    ws.Cells[3, 5].Value = "Was hare";
                                                    ws.Column(5).Width = 10;
                                                    ws.Column(5).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                                    ws.Cells[3, 6].Value = "Times hared";
                                                    ws.Column(6).Width = 10;
                                                    ws.Column(6).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                                    ws.Cells[3, 7].Value = "Location";
                                                    ws.Column(7).Width = 50;
                                                    ws.Cells[3, 8].Value = "Your run count\r\n(all Kennels)";
                                                    ws.Column(8).Width = 20;
                                                    ws.Column(8).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                                                    ws.Row(3).Style.WrapText = true;
                                                    ws.Row(3).Style.Font.Bold = true;
                                                    ws.Row(3).Style.Font.Size = 15;
                                                }

                                                ws.Cells[rowCounter, 1].Value = totalRunsThisKennel;
                                                ws.Cells[rowCounter, 2].Value = eventStartDateTime;
                                                ws.Cells[rowCounter, 3].Value = eventName;
                                                ws.Cells[rowCounter, 4].Value = eventNumber;
                                                ws.Cells[rowCounter, 5].Value = isHare == "1" ? "Yes" : "";
                                                ws.Cells[rowCounter, 6].Value = isHare == "1" ? totalHaringThisKennel : "";
                                                ws.Cells[rowCounter, 7].Value = location;
                                                ws.Cells[rowCounter, 8].Value = totalRunsAllKennels;
                                                rowCounter++;
                                            }

                                            //0: eventId
                                            //1: eventStartDateTime
                                            //2: eventEndDateTime
                                            //3: eventName
                                            //4: eventNumber
                                            //5: locationOneLineDesc
                                            //6: userEventCounterIncrement
                                            //7: isHare
                                            //8: totalRunsThisKennel
                                            //9: totalRunsAllKennels
                                            //10: totalHaringThisKennel
                                            //11: userStartEvent(dateTime)
                                            //12: rsvpState
                                            //13: attendenceState
                                            //14: canEditRunAttendence







                                        }
                                    }
                                }
                            }





                                        //int paymentTypeInt = int.Parse(rows.GetValue(8).ToString());

                                        //if (paymentTypeInt < 100)
                                        //{

                                        //    string currencySymbol = rows.GetValue(14).ToString().Trim();
                                        //    int digitsAfterDecimal = int.Parse(rows.GetValue(15).ToString());
                                        //    String currencyFormat = "0";
                                        //    if (digitsAfterDecimal > 0)
                                        //    {
                                        //        currencyFormat = currencyFormat + "." + "00000000".Substring(0, digitsAfterDecimal);
                                        //    }

                                        //    currencyFormat = currencySymbol.Replace("^", currencyFormat);


                                        //    string paidBy = rows.GetValue(3).ToString().Trim();
                                        //    string paidTo = rows.GetValue(4).ToString().Trim();
                                        //    string cancelledBy = rows.GetValue(5).ToString().Trim();
                                        //    string amountPaid = double.Parse(rows.GetValue(6).ToString().Trim()).ToString(currencyFormat);
                                        //    string amountDue = double.Parse(rows.GetValue(7).ToString().Trim()).ToString(currencyFormat);

                                        //    string paymentDate = rows.GetValue(9).ToString().Trim();
                                        //    string cancelledDate = rows.GetValue(10).ToString().Trim();
                                        //    string paymentReference = rows.GetValue(11).ToString().Trim();
                                        //    string notes = rows.GetValue(12).ToString().Trim();
                                        //    string creditRemaining = double.Parse(rows.GetValue(13).ToString().Trim()).ToString(currencyFormat);

                                        //    String paymentType = "Unknown";

                                        //    switch (paymentTypeInt)
                                        //    {
                                        //        case 0:
                                        //            paymentType = "Unknown";
                                        //            break;
                                        //        case 1:
                                        //            paymentType = "Not paid";
                                        //            break;
                                        //        case 2:
                                        //            paymentType = "Free";
                                        //            break;
                                        //        case 3:
                                        //            paymentType = "Cash";
                                        //            break;
                                        //        case 4:
                                        //            paymentType = "Bank transfer";
                                        //            break;
                                        //        case 5:
                                        //            paymentType = "Cash (other amount)";
                                        //            break;
                                        //        case 6:
                                        //            paymentType = "Hash credit";
                                        //            break;
                                        //        case 7:
                                        //            paymentType = "Bank Transfer (other amount)";
                                        //            break;

                                        //    }

                                        //    ws.Cells[rowCounter, 1].Value = paidBy;
                                        //    ws.Cells[rowCounter, 2].Value = amountPaid;
                                        //    ws.Cells[rowCounter, 3].Value = paymentType;
                                        //    ws.Cells[rowCounter, 4].Value = paidTo;
                                        //    ws.Cells[rowCounter, 5].Value = paymentReference;
                                        //    ws.Cells[rowCounter, 6].Value = amountDue;
                                        //    ws.Cells[rowCounter, 7].Value = paymentDate;
                                        //    ws.Cells[rowCounter, 8].Value = creditRemaining;
                                        //    ws.Cells[rowCounter, 9].Value = notes;

                                        //    rowCounter++;


                                    }
                    }

                }
            }
        }
    }
}


