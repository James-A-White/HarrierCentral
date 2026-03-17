using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Data.SqlClient;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using System.Data;
using System.Diagnostics;

//{"queryType":"getEvents","publicKennelId":"B6BAFD0D-5D2E-41CD-8495-811D551F01D0","accessToken":"asdfasdfasfasdfasdfasdf","publicKennelIds":"6EDC3585-C1F8-4800-B189-23A4036830C9"}

namespace HcWebApi.Endpoints
{

    public class InternalApi
    {
        private readonly ILogger<InternalApi> log;

        public InternalApi(ILogger<InternalApi> logger)
        {
            log = logger;
        }

        [Function("InternalApi")]
        public async Task<IActionResult> Run([HttpTrigger(AuthorizationLevel.Anonymous, "post")] HttpRequest req)
        {

            string connectionString = Environment.GetEnvironmentVariable("HcDbConnectionString")
                ?? throw new InvalidOperationException("HcDbConnectionString is not set in the environment.");


            // Parse the request body
            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            dynamic data = JsonConvert.DeserializeObject(requestBody)
     ?? throw new InvalidOperationException("Failed to deserialize the request body.");


            // Validate required parameters
            if (data.publicKennelId == null || data.accessToken == null)
            {
                log.LogInformation("Missing required parameters: publicKennelId or accessToken.");
                return new BadRequestObjectResult("Missing required parameters: publicKennelId or accessToken.");
            }

            // Validate required parameters
            if (data.queryType == null)
            {
                log.LogInformation("Missing query type.");
                return new BadRequestObjectResult("Missing query type.");

            }

            log.LogInformation($"App API Called: QueryType = {data.queryType}, UserID = {data.publicKennelId}");

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

                    String procedureName = $"[HC5].[hcportal_{data.queryType}]";

                    using (SqlCommand cmd = new SqlCommand(procedureName, conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        // Parse the request body into a JObject
                        JObject jsonData = JObject.Parse(requestBody);

                        // Iterate over each property and add it as a parameter to the SQL command
                        foreach (var property in jsonData.Properties())
                        {
                            if (property.Name == "queryType")
                            {
                                continue;
                            }

                            // Construct the parameter name (e.g., "@publicKennelId")
                            string parameterName = "@" + property.Name;

                            // Use DBNull.Value if the JSON value is null; otherwise, convert to a .NET object
                            object? parameterValue = ((property.Value == null) || (property.Value.Type == JTokenType.Null))
                                                    ? DBNull.Value
                                                    : property.Value.ToObject<object>();

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

