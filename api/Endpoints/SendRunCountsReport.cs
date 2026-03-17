using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;

using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

using OfficeOpenXml;

// http://localhost:7071/api/SendRunCountsReport?deviceId=723BB72E-3737-4B53-A3A9-D5B812AD930C&accessToken1=0EF40BCDD8BB668C5B387B2055BBF51DE920AE189D6F06CA7E91277BB61C67A0&accessToken2=FC2A32F976E65E0C5F50DE3FF89596A801C0E79C03019759FDC43B485AA73CDE&kennelId=D1D51D20-5C09-458A-AD0F-D22A8B5BA019&kennelName=Test&userName=Opee&emailAddress=james@defenceinnovation.eu
// http://localhost:7071/api/SendRunCountsReport?deviceId=723BB72E-3737-4B53-A3A9-D5B812AD930C&accessToken1=0EF40BCDD8BB668C5B387B2055BBF51DE920AE189D6F06CA7E91277BB61C67A0&accessToken2=FC2A32F976E65E0C5F50DE3FF89596A801C0E79C03019759FDC43B485AA73CDE&kennelId=00000000-0000-0000-0000-000000000000&kennelName=Test&userName=Opee&emailAddress=james@defenceinnovation.eu


namespace HcWebApi.Endpoints
{
    public class SendRunCountsReport
    {
        private readonly ILogger<SendRunCountsReport> log;

        //private TableClient _tableClient;

        // Helper: safely get a trimmed string ("" if null/DB null)
        static string SafeStr(object? value)
            => value is null || value is DBNull ? "" : (value.ToString()?.Trim() ?? "");

        // Helper: safely parse int (0 if null/invalid)
        static int SafeInt(object? value)
        {
            var str = SafeStr(value);
            return int.TryParse(str, out var result) ? result : 0;
        }

        public SendRunCountsReport(ILogger<SendRunCountsReport> logger)
        {
            log = logger;
        }

        [Function("SendRunCountsReport")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {

            log.LogInformation("SendRunCountsReport triggered by HTTP Request");

            try
            {
                string deviceId = "";
                string kennelId = "";
                string emailAddress = "";
                string accessToken_getMyRuns = "";
                string accessToken_getMyKennelRunTotals = "";
                string kennelName = "";
                string userName = "";

                if (req.QueryString.HasValue)
                {
                    deviceId = req.Query.TryGetValue("deviceId", out var dId) ? dId.ToString() : "";
                    kennelId = req.Query.TryGetValue("kennelId", out var kId) ? kId.ToString() : "";
                    emailAddress = req.Query.TryGetValue("emailAddress", out var email) ? email.ToString() : "";
                    accessToken_getMyRuns = req.Query.TryGetValue("accessToken1", out var at1) ? at1.ToString() : "";
                    accessToken_getMyKennelRunTotals = req.Query.TryGetValue("accessToken2", out var at2) ? at2.ToString() : "";
                    kennelName = req.Query.TryGetValue("kennelName", out var kName) ? kName.ToString() : "";
                    userName = req.Query.TryGetValue("userName", out var uName) ? uName.ToString() : "";

                }
                else
                {
                    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();

                    dynamic? result = JsonConvert.DeserializeObject<JObject>(requestBody);

                    if (result == null)
                    {
                        return new BadRequestObjectResult("Invalid JSON in request body.");
                    }

                    userName = result.userName;
                    kennelId = result.kennelId;
                    emailAddress = result.emailAddress;
                    accessToken_getMyRuns = result.accessToken1;
                    accessToken_getMyKennelRunTotals = result.accessToken2;
                    kennelName = result.kennelName;
                    deviceId = result.deviceId;
                }

                Guid kennelIdGuid = Guid.Parse(kennelId);
                Guid deviceIdGuid = Guid.Parse(deviceId);

                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                using (var wb = new ExcelPackage())
                {

                    await GetMyKennelRunTotals(wb, log, deviceIdGuid, accessToken_getMyKennelRunTotals, accessToken_getMyRuns, kennelIdGuid, userName);

                    SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient(Environment.GetEnvironmentVariable("SENDGRID_API_KEY"));


                    await Utilities.SendEmailAsync(
                            "https://prod-46.northeurope.logic.azure.com:443/workflows/ea2b7fd09a8d407fa58ab04b64638217/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aqjP-q4tvhj-S9aemqQKFGP5ZQYBWOBFTL_KSUvcVl8",
                            "james@defenceinnovation.eu",
                            emailAddress,
                            $"Here's your Harrier Central Run Count Report for {kennelName}",
                            $"<strong>Hello. Attached, you will find your Run Count Report for {kennelName}</strong>",
                            Convert.ToBase64String(wb.GetAsByteArray())
                        );


                    // // Send a Single Email using the Mail Helper
                    // var from = new EmailAddress("email.service@harriercentral.com", "Harrier Central Service");
                    // var subject = $"Here's your Harrier Central Run Count Report for {kennelName}";
                    // var to = new EmailAddress(emailAddress, userName);
                    // var plainTextContent = $"Hello. Attached, you will find your Payment Report for {kennelName}.";
                    // var htmlContent = $"<strong>Hello. Attached, you will find your Run Count Report for {kennelName}</strong>";
                    // var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

                    // msg.AddAttachment("runCountReport.xlsx", System.Convert.ToBase64String(wb.GetAsByteArray()), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");

                    // var response = await mailClient.SendEmailAsync(msg);
                }
            }

            catch (System.Exception ex)
            {
                return new BadRequestObjectResult($"Error processing email request: {ex.ToString()}, {ex.Message}");
            }

            return new OkObjectResult("Success");
        }


        public static async Task GetMyKennelRunTotals(ExcelPackage wb, ILogger log, Guid deviceId, String accessToken_getMyKennelRunTotals, String accessToken_getMyRuns, Guid kennelId, String userName)
        {
            String connectionStr = "";
            if (String.IsNullOrWhiteSpace(connectionStr))
            {
                connectionStr = "Server=tcp:harriercentral.database.windows.net,1433;Initial Catalog=HarrierCentralWebDb;Persist Security Info=False;User ID=harrieradmin;Password=Op33AndTuna;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
            }

            using (SqlConnection conn = new SqlConnection(connectionStr))
            {
                conn.Open();

                var queryTotals = $"EXEC HC5.hcapp_getMyKennelRunTotals @deviceId = '{deviceId.ToString()}', @accessToken = '{accessToken_getMyKennelRunTotals}',@kennelId = '{kennelId.ToString()}'";

                using (SqlCommand cmdTotals = new SqlCommand(queryTotals, conn))
                {
                    // Execute the command and log the # rows affected.
                    using (SqlDataReader rowsTotals = await cmdTotals.ExecuteReaderAsync())
                    {

                        if (rowsTotals.HasRows)
                        {
                            int worksheetIndex = 0;

                            bool isFirstRow = true;
                            ExcelWorksheet? firstSheet = null;
                            int firstSheetRowCounter = 4;

                            while (rowsTotals.Read())
                            {
                                // Usage
                                string kennelIdStr = SafeStr(rowsTotals.GetValue(0));
                                string kennelLogo = SafeStr(rowsTotals.GetValue(1));
                                string kennelName = SafeStr(rowsTotals.GetValue(2));
                                string totalTotalRunsThisKennel = SafeStr(rowsTotals.GetValue(3));
                                string totalTotalPackRunsThisKennel = SafeStr(rowsTotals.GetValue(4));
                                string totalTotalHaringThisKennel = SafeStr(rowsTotals.GetValue(5));
                                string following = SafeStr(rowsTotals.GetValue(6));
                                string kennelShortName = SafeStr(rowsTotals.GetValue(7));



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


                                    firstSheet.Cells[firstSheetRowCounter, 1].Value = kennelName;
                                    firstSheet.Cells[firstSheetRowCounter, 2].Value = int.Parse(totalTotalRunsThisKennel);
                                    firstSheet.Cells[firstSheetRowCounter, 3].Value = int.Parse(totalTotalPackRunsThisKennel);
                                    firstSheet.Cells[firstSheetRowCounter, 4].Value = int.Parse(totalTotalHaringThisKennel);
                                    firstSheet.Cells[firstSheetRowCounter, 5].Value = following == "1" ? "Yes" : "No";
                                    firstSheetRowCounter++;

                                    continue;
                                }
                                else
                                {
                                    if ((kennelId == Guid.Empty) || (kennelId.ToString().ToLower() == kennelIdStr.ToLower()))
                                    {
                                        if (firstSheet != null)
                                        {
                                            firstSheet.Cells[firstSheetRowCounter, 1].Value = kennelName;
                                            firstSheet.Cells[firstSheetRowCounter, 2].Value = int.Parse(totalTotalRunsThisKennel);
                                            firstSheet.Cells[firstSheetRowCounter, 3].Value = int.Parse(totalTotalPackRunsThisKennel);
                                            firstSheet.Cells[firstSheetRowCounter, 4].Value = int.Parse(totalTotalHaringThisKennel);
                                            firstSheet.Cells[firstSheetRowCounter, 5].Value = following == "1" ? "Yes" : "No";
                                            firstSheetRowCounter++;
                                        }
                                    }
                                }

                                if ((kennelId == Guid.Empty) || (kennelId.ToString().ToLower() == kennelIdStr.ToLower()))
                                {
                                    using (SqlConnection conn2 = new SqlConnection(connectionStr))
                                    {
                                        conn2.Open();

                                        var queryOneKennel = $"EXEC HC5.hcapp_getRuns @deviceId = '{deviceId.ToString()}', @accessToken = '{accessToken_getMyRuns}',@kennelId = '{kennelIdStr}'";

                                        using (SqlCommand cmdOneKennel = new SqlCommand(queryOneKennel, conn2))
                                        {
                                            // Execute the command and log the # rows affected.
                                            using (SqlDataReader rowOneKennel = await cmdOneKennel.ExecuteReaderAsync())
                                            {

                                                if (rowOneKennel.HasRows)
                                                {
                                                    bool needsWorksheet = true;
                                                    ExcelWorksheet? ws = null;
                                                    int rowCounter = 4;

                                                    while (rowOneKennel.Read())
                                                    {
                                                        //0 e.id as eventId
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

                                                        string eventId = SafeStr(rowOneKennel.GetValue(0));
                                                        string eventStartDateTime = SafeStr(rowOneKennel.GetValue(1));
                                                        string eventName = SafeStr(rowOneKennel.GetValue(3));
                                                        string eventNumber = kennelShortName + " Run #" + SafeStr(rowOneKennel.GetValue(4));
                                                        string location = SafeStr(rowOneKennel.GetValue(5));
                                                        string isHare = SafeStr(rowOneKennel.GetValue(11));
                                                        string totalRunsThisKennel = SafeStr(rowOneKennel.GetValue(12));
                                                        string totalRunsAllKennels = SafeStr(rowOneKennel.GetValue(13));
                                                        string totalHaringThisKennel = SafeStr(rowOneKennel.GetValue(14));
                                                        int attendenceState = SafeInt(rowOneKennel.GetValue(17));

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

                                                            if (ws != null)
                                                            {

                                                                ws.Cells[rowCounter, 1].Value = int.Parse(totalRunsThisKennel);
                                                                ws.Cells[rowCounter, 2].Value = eventStartDateTime;
                                                                ws.Cells[rowCounter, 3].Value = eventName;
                                                                ws.Cells[rowCounter, 4].Value = eventNumber;
                                                                ws.Cells[rowCounter, 5].Value = isHare == "1" ? "Yes" : "";
                                                                if (isHare == "1")
                                                                {
                                                                    ws.Cells[rowCounter, 6].Value = int.Parse(totalHaringThisKennel);
                                                                }
                                                                ws.Cells[rowCounter, 7].Value = location;
                                                                ws.Cells[rowCounter, 8].Value = int.Parse(totalRunsAllKennels);
                                                                rowCounter++;
                                                            }
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
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}


