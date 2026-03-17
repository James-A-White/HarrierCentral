using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Diagnostics;

//{"queryType":"getEvents","publicKennelId":"B6BAFD0D-5D2E-41CD-8495-811D551F01D0","accessToken":"asdfasdfasfasdfasdfasdf","publicKennelIds":"6EDC3585-C1F8-4800-B189-23A4036830C9"}

namespace HcWebApi.Endpoints
{

    public class PublicApi
    {
        private readonly ILogger<PublicApi> log;

        public PublicApi(ILogger<PublicApi> logger)
        {
            log = logger;
        }

        [Function("PublicApi")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
        {

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");


            if (string.IsNullOrEmpty(req.Query["publicKennelId"]) || string.IsNullOrEmpty(req.Query["apiKey"]))
            {
                log.LogInformation("Missing required parameters: publicKennelId or apiKey.");
                return new BadRequestObjectResult("Missing required parameters: publicKennelId or accessToken.");
            }
            string publicKennelId = req.Query["publicKennelId"]!;
            string apiKey = req.Query["apiKey"]!;


            if (string.IsNullOrEmpty(req.Query["queryType"]))
            {
                log.LogInformation("Missing queryType.");
                return new BadRequestObjectResult("Missing queryType.");
            }
            String queryType = req.Query["queryType"]!;

            log.LogInformation($"App API Called: QueryType = {queryType}, UserID = {publicKennelId}");

            // Initialize a list to hold the stored procedure results
            List<Dictionary<string, object>> results = new List<Dictionary<string, object>>();

            // Call the stored procedure and capture the results
            try
            {
                // Initialize a list to hold the result sets
                List<List<Dictionary<string, object>>> multipleResults = new List<List<Dictionary<string, object>>>();

                using (SqlConnection conn = new SqlConnection(connectionString))
                {
                    await conn.OpenAsync();

                    String procedureName = $"[HC5].[hcpublicapi_{queryType}]";

                    using (SqlCommand cmd = new SqlCommand(procedureName, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        // Iterate over each property and add it as a parameter to the SQL command
                        foreach (string key in req.Query.Keys)
                        {
                            if (key == "queryType")
                            {
                                continue;
                            }

                            // Construct the parameter name (e.g., "@publicKennelId")
                            string parameterName = "@" + key;

                            // Use DBNull.Value if the JSON value is null; otherwise, convert to a .NET object
                            object? parameterValue = req.Query[key].IsNullOrEmpty()
                                                    ? DBNull.Value
                                                    : req.Query[key].ToString();

                            if ((parameterName != null) && (parameterValue != null))
                            {
                                // Add the parameter to your SQL command
                                cmd.Parameters.AddWithValue(parameterName, parameterValue);
                                //log.LogInformation($"Param = {parameterName}, Value = {parameterValue}");
                            }
                        }

                        // Execute the stored procedure and retrieve multiple result sets
                        using (SqlDataReader reader = await cmd.ExecuteReaderAsync())
                        {
                            try
                            {
                                // Process each result set
                                do
                                {
                                    List<Dictionary<string, object>> resultSet = new List<Dictionary<string, object>>();

                                    while (await reader.ReadAsync())
                                    {
                                        var row = new Dictionary<string, object>();
                                        for (int i = 0; i < reader.FieldCount; i++)
                                        {
                                            string? name = reader.GetName(i);
                                            object? value = reader.IsDBNull(i) ? null : reader.GetValue(i);

                                            if ((name != null) && (value != null))
                                            {
                                                row[name] = value;
                                            }

                                        }
                                        resultSet.Add(row);
                                    }

                                    // Add the result set to the list of result sets
                                    multipleResults.Add(resultSet);

                                } while (await reader.NextResultAsync()); // Move to the next result set
                            }

                            catch (System.Exception ex)
                            {
                                Debug.Print(ex.ToString());
                            }
                        }
                    }
                }

                // handle any additoinal tasks after the SQL has been updated. 
                // ideally these should not take a long time to complete. If they
                // do, we should use a message queue to handle the long-running functions

                // switch ((string)data.queryType)
                // {
                //     case "addEditEvent":
                //         _ = UpdateGoogleCalendar(log);
                //         break;     
                // }

                // Return the multiple result sets as JSON
                return new OkObjectResult(multipleResults);

            }
            catch (Exception ex)
            {
                log.LogError($"Error executing stored procedure: {ex.Message}");
                return new BadRequestObjectResult($"Error executing stored procedure: {ex.Message}");
            }
        }



        static async Task UpdateGoogleCalendar(ILogger log)
        {
            // Call an Azure Logic App that will update Google calendars
            // NOTE: This triggers a function that will update any event with
            // Google calendar integration turned on when that event indicates
            // that the Google calendar might be out of date. It does not
            // only look at events from the Kennel currently being updated
            // The URL you want to call
            string gCalTriggerApi = Environment.GetEnvironmentVariable("GoogleCalendarTriggerApi") ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");

            //string requestUrl = "https://prod-19.northeurope.logic.azure.com:443/workflows/0108404b9b8f4b0b9ca2873491a3ad03/triggers/When_a_HTTP_request_is_received/paths/invoke?api-version=2016-10-01&sp=%2Ftriggers%2FWhen_a_HTTP_request_is_received%2Frun&sv=1.0&sig=I72oSYlBHUFE240337h2ysIDu3JQmhuKiabRdjC2ojg";

            try
            {
                using HttpClient client = new HttpClient();

                // Send the GET request
                HttpResponseMessage response = await client.GetAsync(gCalTriggerApi);

                // Throw an exception if the status code is not success
                response.EnsureSuccessStatusCode();

                // Read the response content as a string
                string responseBody = await response.Content.ReadAsStringAsync();

                // Print the response to console
                // Console.WriteLine("HTTP GET succeeded. Response:");
                // Console.WriteLine(responseBody);
            }
            catch (HttpRequestException ex)
            {
                log.LogError($"Error updating Google Calendar: {ex.Message}");
                // // Handle any HTTP-specific errors here
                // Console.WriteLine("Error occurred while calling Logic App:");
                // Console.WriteLine(ex.Message);
            }
            catch (Exception ex)
            {
                log.LogError($"Error updating Google Calendar: {ex.Message}");
                // Handle any other unforeseen errors
                // Console.WriteLine("An unexpected error occurred:");
                // Console.WriteLine(ex.Message);
            }

        }
    }
}

