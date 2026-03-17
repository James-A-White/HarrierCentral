using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;

using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

using OfficeOpenXml;

// http://localhost:7071/api/SendPaymentReport?deviceId=723BB72E-3737-4B53-A3A9-D5B812AD930C&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&eventId=AE3974C4-2641-49E2-B1BA-1B7F24B88D09&eventName=test&userName=Opee&emailAddress=james@defenceinnovation.eu

namespace HcWebApi.Endpoints
{
    public class SendPaymentReport
    {
        private readonly ILogger<SendPaymentReport> log;

        //private TableClient _tableClient;

        public SendPaymentReport(ILogger<SendPaymentReport> logger)
        {
            log = logger;
        }

        [Function("SendPaymentReport")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {

            log.LogInformation("SendPaymentReport triggered by HTTP Request");
            try
            {
                string content = string.Empty;

                string accessToken = "";
                string deviceId = "";
                string emailAddress = "";
                string eventId = "";
                string eventName = "";
                string userName = "";

                if (req.QueryString.HasValue)
                {
                    accessToken = req.Query.TryGetValue("accessToken", out var token) ? token.ToString() : "";
                    deviceId = req.Query.TryGetValue("deviceId", out var dId) ? dId.ToString() : "";
                    emailAddress = req.Query.TryGetValue("emailAddress", out var email) ? email.ToString() : "";
                    eventId = req.Query.TryGetValue("eventId", out var eid) ? eid.ToString() : "";
                    eventName = req.Query.TryGetValue("eventName", out var eName) ? eName.ToString() : "";
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
                    eventId = result.eventId;
                    emailAddress = result.emailAddress;
                    accessToken = result.accessToken;
                    eventName = result.eventName;
                    deviceId = result.deviceId;
                }

                Guid eventIdGuid = Guid.Parse(eventId);
                Guid deviceIdGuid = Guid.Parse(deviceId);

                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                using (var wb = new ExcelPackage())
                {
                    await GetPaymentReport(wb, log, deviceIdGuid, accessToken, eventIdGuid);

                    // SendGrid.SendGridClient mailClient = new SendGrid.SendGridClient(Environment.GetEnvironmentVariable("SENDGRID_API_KEY"));

                    // // Send a Single Email using the Mail Helper
                    // var from = new EmailAddress("email.service@harriercentral.com", "Harrier Central Service");
                    // var subject = $"Here's your Harrier Central Payment Report for {eventName}";
                    // var to = new EmailAddress(emailAddress, userName);
                    // var plainTextContent = $"Hello. Attached, you will find your Payment Report for {eventName}.";
                    // var htmlContent = $"<strong>Hello. Attached, you will find your Payment Report for {eventName}</strong>";
                    // var msg = MailHelper.CreateSingleEmail(from, to, subject, plainTextContent, htmlContent);

                    // msg.AddAttachment("paymentReport.xlsx", System.Convert.ToBase64String(wb.GetAsByteArray()), "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");


                    await Utilities.SendEmailAsync(
                            "https://prod-46.northeurope.logic.azure.com:443/workflows/ea2b7fd09a8d407fa58ab04b64638217/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aqjP-q4tvhj-S9aemqQKFGP5ZQYBWOBFTL_KSUvcVl8",
                            "james@defenceinnovation.eu",
                            emailAddress,
                            $"Here's your Harrier Central Payment Report for {eventName}",
                            $"<strong>Hello. Attached, you will find your Payment Report for {eventName}</strong>",
                            Convert.ToBase64String(wb.GetAsByteArray())
                        );

                }
            }

            catch (System.Exception ex)
            {
                return new BadRequestObjectResult($"Error processing email request: {ex.ToString()}, {ex.Message}");
            }

            return new OkObjectResult("Success");
        }


        public static async Task GetPaymentReport(ExcelPackage wb, ILogger log, Guid deviceId, String accessToken, Guid eventId)
        {
            wb.Workbook.Worksheets.Add("Payment Report");
            var ws = wb.Workbook.Worksheets[0];

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
    ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");



            using (SqlConnection conn = new SqlConnection(connectionString))
            {
                conn.Open();

                var query = $"EXEC HC5.hcapp_getPaymentReport @deviceId = '{deviceId.ToString()}', @accessToken = '{accessToken}',@eventId = '{eventId.ToString()}'";

                using (SqlCommand cmd = new SqlCommand(query, conn))
                {
                    // Execute the command and log the # rows affected.
                    using (SqlDataReader rows = await cmd.ExecuteReaderAsync())
                    {

                        if (rows.HasRows)
                        {
                            ws.Cells[2, 1].Value = "Paid by";
                            ws.Cells[2, 2].Value = "Amount Paid";
                            ws.Cells[2, 3].Value = "Payment Type";
                            ws.Cells[2, 4].Value = "Paid to";
                            ws.Cells[2, 5].Value = "Payment reference";
                            ws.Cells[2, 6].Value = "Amount due";
                            ws.Cells[2, 7].Value = "Payment date";
                            ws.Cells[2, 8].Value = "Credit remaining";
                            ws.Cells[2, 9].Value = "Notes";

                            int rowCounter = 3;

                            while (rows.Read())
                            {
                                int paymentTypeInt = int.TryParse(rows.IsDBNull(8) ? "" : rows.GetValue(8)?.ToString()?.Trim(), out var pt) ? pt : 0;

                                if (paymentTypeInt < 100)
                                {

                                    string currencySymbol = rows.IsDBNull(14) ? "" : rows.GetValue(14)?.ToString()?.Trim() ?? "";

                                    int digitsAfterDecimal = int.TryParse(
                                        rows.IsDBNull(15) ? "" : rows.GetValue(15)?.ToString()?.Trim(),
                                        out var d) ? d : 0;


                                    String currencyFormat = "0";
                                    if (digitsAfterDecimal > 0)
                                    {
                                        currencyFormat = currencyFormat + "." + "00000000".Substring(0, digitsAfterDecimal);
                                    }

                                    currencyFormat = currencySymbol.Replace("^", currencyFormat);


                                    string paidBy = rows.IsDBNull(3) ? "" : rows.GetValue(3)?.ToString()?.Trim() ?? "";
                                    string paidTo = rows.IsDBNull(4) ? "" : rows.GetValue(4)?.ToString()?.Trim() ?? "";
                                    string cancelledBy = rows.IsDBNull(5) ? "" : rows.GetValue(5)?.ToString()?.Trim() ?? "";

                                    string amountPaid = double.TryParse(rows.IsDBNull(6) ? "" : rows.GetValue(6)?.ToString()?.Trim(), out var ap)
                                                                ? ap.ToString(currencyFormat) : 0.0.ToString(currencyFormat);

                                    string amountDue = double.TryParse(rows.IsDBNull(7) ? "" : rows.GetValue(7)?.ToString()?.Trim(), out var ad)
                                                                ? ad.ToString(currencyFormat) : 0.0.ToString(currencyFormat);

                                    string paymentDate = rows.IsDBNull(9) ? "" : rows.GetValue(9)?.ToString()?.Trim() ?? "";
                                    string cancelledDate = rows.IsDBNull(10) ? "" : rows.GetValue(10)?.ToString()?.Trim() ?? "";
                                    string paymentReference = rows.IsDBNull(11) ? "" : rows.GetValue(11)?.ToString()?.Trim() ?? "";
                                    string notes = rows.IsDBNull(12) ? "" : rows.GetValue(12)?.ToString()?.Trim() ?? "";

                                    string creditRemaining = double.TryParse(rows.IsDBNull(13) ? "" : rows.GetValue(13)?.ToString()?.Trim(), out var cr)
                                                                ? cr.ToString(currencyFormat) : 0.0.ToString(currencyFormat);

                                    String paymentType = "Unknown";

                                    switch (paymentTypeInt)
                                    {
                                        case 0:
                                            paymentType = "Unknown";
                                            break;
                                        case 1:
                                            paymentType = "Not paid";
                                            break;
                                        case 2:
                                            paymentType = "Free";
                                            break;
                                        case 3:
                                            paymentType = "Cash";
                                            break;
                                        case 4:
                                            paymentType = "Bank transfer";
                                            break;
                                        case 5:
                                            paymentType = "Cash (other amount)";
                                            break;
                                        case 6:
                                            paymentType = "Hash credit";
                                            break;
                                        case 7:
                                            paymentType = "Bank Transfer (other amount)";
                                            break;

                                    }

                                    ws.Cells[rowCounter, 1].Value = paidBy;
                                    ws.Cells[rowCounter, 2].Value = amountPaid;
                                    ws.Cells[rowCounter, 3].Value = paymentType;
                                    ws.Cells[rowCounter, 4].Value = paidTo;
                                    ws.Cells[rowCounter, 5].Value = paymentReference;
                                    ws.Cells[rowCounter, 6].Value = amountDue;
                                    ws.Cells[rowCounter, 7].Value = paymentDate;
                                    ws.Cells[rowCounter, 8].Value = creditRemaining;
                                    ws.Cells[rowCounter, 9].Value = notes;

                                    rowCounter++;

                                }

                            }
                        }
                    }

                }
            }
        }
    }
}


