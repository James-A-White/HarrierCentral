
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;

using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;

using OfficeOpenXml;
using System.Text;

// http://localhost:7071/api/SendKennelRunStatsReport?deviceId=2D290956-B6BB-4BD9-8F57-0973F0C6BEF0&accessToken=085BCF1D6FB0285F75E4E38AA0D3E820E257EC07FE078D2D0AE95144E1FA0FCA&kennelId=5029DE3A-D231-47AA-BE72-ECE9BCCD55D1&kennelName=FILTHHASH&userName=Opee&emailAddress=james@defenceinnovation.eu&digitsAfterDecimal=2&currencySymbol=€^

namespace HcWebApi.Endpoints
{
    public class SendKennelRunStatsReport
    {
        private readonly ILogger<SendKennelRunStatsReport> log;

        //private TableClient _tableClient;

        public SendKennelRunStatsReport(ILogger<SendKennelRunStatsReport> logger)
        {
            log = logger;
        }

        [Function("SendKennelRunStatsReport")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {

            log.LogInformation("SendKennelRunStatsReport triggered by HTTP Request");

            try
            {
                string deviceId = "";
                string kennelId = "";
                string emailAddress = "";
                string accessToken = "";
                string kennelName = "";
                string userName = "";
                string digitsAfterDecimal = "";
                string currencySymbol = "";

                if (req.QueryString.HasValue)
                {
                    deviceId = req.Query.TryGetValue("deviceId", out var dId) ? dId.ToString() : "";
                    kennelId = req.Query.TryGetValue("kennelId", out var kId) ? kId.ToString() : "";
                    emailAddress = req.Query.TryGetValue("emailAddress", out var email) ? email.ToString() : "";
                    accessToken = req.Query.TryGetValue("accessToken", out var token) ? token.ToString() : "";
                    kennelName = req.Query.TryGetValue("kennelName", out var kName) ? kName.ToString() : "";
                    userName = req.Query.TryGetValue("userName", out var uName) ? uName.ToString() : "";
                    digitsAfterDecimal = req.Query.TryGetValue("digitsAfterDecimal", out var digits) ? digits.ToString() : "2";
                    currencySymbol = req.Query.TryGetValue("currencySymbol", out var symbol) ? symbol.ToString() : "$^";

                }
                else
                {
                    string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
                    if (requestBody == null || requestBody.Trim().Length == 0)
                    {
                        return new BadRequestObjectResult("Request body is empty or null.");
                    }

                    //dynamic result = JsonConvert.DeserializeObject(requestBody);
                    dynamic? result = JsonConvert.DeserializeObject<JObject>(requestBody);

                    if (result == null)
                    {
                        return new BadRequestObjectResult("Invalid JSON in request body.");
                    }

                    userName = result.userName;
                    kennelId = result.kennelId;
                    emailAddress = result.emailAddress;
                    accessToken = result.accessToken;
                    kennelName = result.kennelName;
                    deviceId = result.deviceId;
                    digitsAfterDecimal = result.digitsAfterDecimal;
                    currencySymbol = result.currencySymbol;
                }

                Guid kennelIdGuid = Guid.Parse(kennelId);
                Guid deviceIdGuid = Guid.Parse(deviceId);

                ExcelPackage.LicenseContext = LicenseContext.NonCommercial;

                using (var wb = new ExcelPackage())
                {
                    await GetRptKennelRunStats(wb, log, deviceIdGuid, accessToken, kennelIdGuid, kennelName, digitsAfterDecimal, currencySymbol);

                    await Utilities.SendEmailAsync(
                        "https://prod-46.northeurope.logic.azure.com:443/workflows/ea2b7fd09a8d407fa58ab04b64638217/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=aqjP-q4tvhj-S9aemqQKFGP5ZQYBWOBFTL_KSUvcVl8",
                        "james@defenceinnovation.eu",
                        emailAddress,
                        $"Here's the run stats report for {kennelName}",
                        $"Hello {userName},<br><br>Attached, you will find the run stats report for {kennelName}.<br><br>Best regards,<br>Harrier Central Service",
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

        public static async Task GetRptKennelRunStats(ExcelPackage wb, ILogger log, Guid deviceIdGuid, String accessToken, Guid kennelId, String kennelName, String digitsAfterDecimal, String currencySymbol)
        {


            string connectionStr = Environment.GetEnvironmentVariable("HcDbConnectionString")
    ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");


            using SqlConnection conn = new(connectionStr);
            conn.Open();

            var queryTotals = $"EXEC HC5.hcapp_rptKennelRunStats @deviceId = '{deviceIdGuid}', @accessToken = '{accessToken}',@kennelId = '{kennelId}'";

            using SqlCommand cmdTotals = new(queryTotals, conn);
            // Execute the command and log the # rows affected.
            using SqlDataReader rowsTotals = await cmdTotals.ExecuteReaderAsync();

            if (rowsTotals.HasRows)
            {
                int worksheetIndex = 0;

                bool isFirstRow = true;
                ExcelWorksheet? firstSheet = null;
                int firstSheetRowCounter = 3;

                while (rowsTotals.Read())
                {
                    if (isFirstRow)
                    {
                        wb.Workbook.Worksheets.Add("Run Stats");
                        firstSheet = wb.Workbook.Worksheets[worksheetIndex];
                        worksheetIndex++;

                        firstSheet.Cells[1, 5].Value = "Kennel run stats report for: " + kennelName;
                        firstSheet.Row(1).Style.WrapText = false;
                        firstSheet.Row(1).Style.Font.Bold = true;
                        firstSheet.Row(1).Style.Font.Size = 22;
                        firstSheet.Cells[1, 5].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                        firstSheet.Row(firstSheetRowCounter).Style.WrapText = true;
                        firstSheet.Row(firstSheetRowCounter).Style.Font.Bold = true;
                        firstSheet.Row(firstSheetRowCounter).Style.Font.Size = 12;
                        firstSheet.Column(1).Width = 50;
                        firstSheet.Column(2).Width = 15;
                        firstSheet.Column(3).Width = 15;
                        firstSheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                        firstSheet.Column(3).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                        firstSheet.Column(4).Width = 30;

                        firstSheet.Column(2).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                        List<String> columns = Enumerable.Range(0, rowsTotals.FieldCount).Select(rowsTotals.GetName).ToList();

                        for (int col = 0; col < rowsTotals.FieldCount; col++)
                        {
                            if (col > 3)
                            {
                                firstSheet.Column(col + 1).Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;
                                firstSheet.Column(col + 1).Width = 8;
                                firstSheet.Cells[firstSheetRowCounter, col + 1].Style.TextRotation = 90;
                            }
                            else
                            {
                                firstSheet.Cells[firstSheetRowCounter, col + 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Center;

                            }
                            firstSheet.Cells[firstSheetRowCounter, col + 1].Value = columns[col].Replace('_', ' ');
                        }
                        firstSheetRowCounter++;
                    }


                    if (firstSheet != null)
                    {
                        for (int col = 0; col < rowsTotals.FieldCount; col++)
                        {
                            String s = "";

                            var val = rowsTotals.GetValue(col);

                            if (val is DateTime)
                            {
                                if (((DateTime)val) > new DateTime(2099, 1, 1))
                                {
                                    if (firstSheetRowCounter == 4)
                                    {
                                        firstSheet.Cells[firstSheetRowCounter, col + 1].Value = "Total runs =>";
                                    }
                                    else if (firstSheetRowCounter == 5)
                                    {
                                        firstSheet.Cells[firstSheetRowCounter, col + 1].Value = "Total haring =>";
                                    }
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Right;
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Bold = true;
                                    firstSheet.Cells[firstSheetRowCounter, 1].Value = "";
                                    continue;
                                }
                                if (firstSheetRowCounter > 5)
                                {
                                    s = String.Format("{0:ddd, dd MMM yyyy, hh:mm tt}", val);
                                }
                            }

                            int paymentType = 0;
                            bool isPaymentCell = false;

                            if ((val is int) && (Math.Abs(((int)val)) >= 100000000))
                            {
                                isPaymentCell = true;
                                int valInt = ((int)val);
                                bool isHare = valInt < 0 ? true : false;
                                valInt = Math.Abs(valInt) - 100000000;
                                paymentType = valInt % 10;
                                valInt /= 10;

                                decimal n = ((decimal)valInt) / 1000;

                                if (isHare)
                                {
                                    n = Math.Abs(n);
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Yellow);
                                }

                                if (n >= 9999)
                                {
                                    s = "?";
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Red);
                                    isPaymentCell = false;
                                }
                                else
                                {

                                    if ((firstSheetRowCounter <= 5) || (col == 1))
                                    {
                                        s = String.Format("{0:#####0}", n);
                                    }
                                    else
                                    {
                                        s = Utilities.formatCurrency((decimal)n, digitsAfterDecimal, currencySymbol);
                                    }
                                }
                            }
                            else if ((val is int) || (val is short))
                            {
                                int intVal;

                                if (val is short)
                                    intVal = (short)val; // unbox as short, then implicitly convert to int
                                else
                                    intVal = (int)val;   // unbox as int

                                if ((col != 1) || (intVal > 0))
                                {
                                    s = String.Format("{0:#####0}", intVal);
                                }
                            }

                            if (val is string strVal)
                            {
                                s = strVal;
                            }


                            //paymentTypeUnknown = EnumPaymentType<int>(0);
                            //paymentNotPaid = EnumPaymentType<int>(1);
                            //paymentFreeRun = EnumPaymentType<int>(2);
                            //paymentCash = EnumPaymentType<int>(3);
                            //paymentBankTransfer = EnumPaymentType<int>(4);
                            //paymentCashOtherAmount = EnumPaymentType<int>(5);
                            //paymentHashCredit = EnumPaymentType<int>(6);
                            //paymentBankTransferOtherAmount = EnumPaymentType<int>(7);

                            switch (paymentType)
                            {
                                case 0:
                                    if (isPaymentCell)
                                    {
                                        s = "?";
                                        firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Red);
                                        firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Bold = true;
                                    }
                                    break;
                                case 1:
                                    s = "✗";
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Red);
                                    break;
                                case 2:
                                    s = "Free";
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Green);
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Bold = true;
                                    break;
                                case 3:
                                case 5:
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Green);
                                    break;
                                case 4:
                                case 7:
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Blue);
                                    break;
                                case 6:
                                    firstSheet.Cells[firstSheetRowCounter, col + 1].Style.Font.Color.SetColor(System.Drawing.Color.Purple);
                                    break;
                            }

                            firstSheet.Cells[firstSheetRowCounter, col + 1].Value = s.Trim();
                        }

                        firstSheetRowCounter++;
                    }

                    isFirstRow = false;
                }

                firstSheetRowCounter += 3;

                if (firstSheet == null)
                {
                    throw new Exception("No data found for the report.");
                }

                firstSheet.Cells[firstSheetRowCounter, 2].Value = "Key";
                firstSheet.Cells[firstSheetRowCounter++, 2].Style.Font.Bold = true;

                firstSheet.Cells[firstSheetRowCounter, 2].Value = Utilities.formatCurrency(5, digitsAfterDecimal, currencySymbol);
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Green);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Green text = Hasher paid in cash";

                firstSheet.Cells[firstSheetRowCounter, 2].Value = Utilities.formatCurrency(5, digitsAfterDecimal, currencySymbol);
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Blue);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Blue text = Hasher paid by bank transfer";

                firstSheet.Cells[firstSheetRowCounter, 2].Value = Utilities.formatCurrency(5, digitsAfterDecimal, currencySymbol);
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Purple);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Purple text = Hasher paid by Hash credit";

                firstSheet.Cells[firstSheetRowCounter, 2].Value = "✗";
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Red);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Red X = Hasher didn't pay";

                firstSheet.Cells[firstSheetRowCounter, 2].Value = "?";
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Red);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Red ? = Hasher was at the run, but there is no payment record. They probably didn't pay";

                firstSheet.Cells[firstSheetRowCounter, 2].Value = "Free";
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Font.Color.SetColor(System.Drawing.Color.Green);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Green 'Free' = Hasher's run was free";

                firstSheet.Cells[firstSheetRowCounter, 2].Value = "";
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Fill.PatternType = OfficeOpenXml.Style.ExcelFillStyle.Solid;
                firstSheet.Cells[firstSheetRowCounter, 2].Style.Fill.BackgroundColor.SetColor(System.Drawing.Color.Yellow);
                firstSheet.Cells[firstSheetRowCounter, 3].Style.HorizontalAlignment = OfficeOpenXml.Style.ExcelHorizontalAlignment.Left;
                firstSheet.Cells[firstSheetRowCounter++, 3].Value = "Yellow highlighted cell indicates Hasher hared this run";

            }
        }
    }
}


