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

// namespace HcAzureFunctions
// {
//     public static class FacebookPolling
//     {
//         static MobileMessagingClient mmClient;

//         [FunctionName("FacebookPolling")]
//         public async static Task Run([TimerTrigger("*/5 * * * *")]TimerInfo myTimer, ILogger log, ExecutionContext context)
//         {

//             if (mmClient == null)
//             {
//                 String appDirectory = context.FunctionAppDirectory;
//                 mmClient = new MobileMessagingClient(appDirectory);
//             }

//             log.LogInformation($"C# Timer trigger function executed at: {DateTime.Now}");
//             await CheckFacebook(log, mmClient);
//             //await PublishUpdatedWebPages(log);
//         }

//         public static async Task<Uri> PublishUpdatedWebPages(ILogger log)
//         {
//             //var match = new Regex(
//             //  $@"^data\:(?<type>image\/(jpg|gif|png));base64,(?<data>[A-Z0-9\+\/\=]+)$",
//             //  RegexOptions.Compiled | RegexOptions.ExplicitCapture | RegexOptions.IgnoreCase)
//             //  .Match(photoBase64String);
//             //string contentType = match.Groups["type"].Value;
//             //string extension = contentType.Split('/')[1];

//             //tring fileName = $"RunLists/xxx-{DateTime.Now.ToString("yyyymmddhhMMss")}.html";
//             string fileName = $"RunLists/test.html";


//             CloudStorageAccount storageAccount = CloudStorageAccount.Parse("DefaultEndpointsProtocol=https;AccountName=harriercentral;AccountKey=n44turMqFQieLr+ZD7ZdCkCDDzTjvQohUKuetitoCSGK98BkD+GdNPESWLB4WHTZduAMGOBHNDEunkyGJXRz1A==;EndpointSuffix=core.windows.net");
//             CloudBlobClient client = storageAccount.CreateCloudBlobClient();
//             CloudBlobContainer container = client.GetContainerReference("$web");

//             await container.CreateIfNotExistsAsync(
//               BlobContainerPublicAccessType.Blob,
//               new BlobRequestOptions(),
//               new OperationContext());

//             CloudBlockBlob blob = container.GetBlockBlobReference(fileName);
//             blob.Properties.ContentType = "text/html";

//             var assembly = Assembly.GetExecutingAssembly();

//             var resourceName = "HcAzureFunctions.HTML.PageTemplate.html";
//             string pageTemplate = String.Empty;
//             using (Stream stream = assembly.GetManifestResourceStream(resourceName))
//             using (StreamReader reader = new StreamReader(stream))
//             {
//                 pageTemplate = reader.ReadToEnd();
//             }

//             resourceName = "HcAzureFunctions.HTML.AccordionTemplate.html";
//             string accordianTemplate = String.Empty;
//             using (Stream stream = assembly.GetManifestResourceStream(resourceName))
//             using (StreamReader reader = new StreamReader(stream))
//             {
//                 accordianTemplate = reader.ReadToEnd();
//             }

//             resourceName = "HcAzureFunctions.HTML.AccordionCardTemplate.html";
//             string runCard = String.Empty;
//             using (Stream stream = assembly.GetManifestResourceStream(resourceName))
//             using (StreamReader reader = new StreamReader(stream))
//             {
//                 runCard = reader.ReadToEnd();
//             }

//             StringBuilder sb = new StringBuilder();

//             string str = ConfigurationManager.ConnectionStrings["HarrierCentralDb"]?.ConnectionString;
//             if (String.IsNullOrWhiteSpace(str))
//             {
//                 str = "Server=tcp:harriercentral.database.windows.net,1433;Initial Catalog=HarrierCentralWebDb;Persist Security Info=False;User ID=harrieradmin;Password=Op33AndTuna;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
//             }

//             int counter = 101;
//             bool firstPass = true;

//             List<RunDataForWebPage> allRunData = new List<RunDataForWebPage>();

//             using (SqlConnection conn = new SqlConnection(str))
//             {
//                 conn.Open();
//                 var text2 = "select id,EventName,EventDescription,EventStartDatetime,EventImage from HC.Event where KennelId = '6F901167-4BD3-45AF-9DA0-6AF5A1128F42' order by EventStartDatetime desc";

//                 using (SqlCommand cmd = new SqlCommand(text2, conn))
//                 {
//                     // Execute the command and log the # rows affected.
//                     var rows = await cmd.ExecuteReaderAsync();

//                     while (rows.Read())
//                     {
//                         RunDataForWebPage newRunData = new RunDataForWebPage();

//                         newRunData.EventId = Guid.Parse(rows.GetValue(0).ToString());
//                         newRunData.EventName = rows.GetValue(1).ToString().Trim();
//                         newRunData.EventDescription = rows.GetValue(2).ToString().Trim();
//                         newRunData.EventStartDate = DateTime.Parse(rows.GetValue(3).ToString().Trim());
//                         newRunData.EventImage = rows.GetValue(4).ToString().Trim();

//                         allRunData.Add(newRunData);
//                     }

//                     conn.Close();
//                 }
//             }

//             List<RunDataForWebPage> futureRuns = allRunData.Where(s => s.EventStartDate >= DateTime.Now.Date).OrderBy(s => s.EventStartDate).ToList();
//             List<RunDataForWebPage> pastRuns = allRunData.Where(s => s.EventStartDate < DateTime.Now.Date).OrderByDescending(s => s.EventStartDate).ToList();

//             StringBuilder accordions = new StringBuilder();

//             for (int i = 0; i <= 1; i++)
//             {
//                 int pastRunCount = 0;

//                 foreach (RunDataForWebPage rd in i==0 ? futureRuns : pastRuns )
//                 {

//                     if (pastRunCount > 12) break;

//                     // {0} heading
//                     // {1} description
//                     // {2} show
//                     // {3} sequence
//                     // {4} "collapsed "
//                     // {5} expanded
//                     // {6} run image URL
//                     // {7} hc-run-list-bg-future or hc-run-list-bg-past based on the date of the run

//                     string card = String.Format(runCard,
//                                                 rd.EventName.Replace("\r\n", "<p>").Replace("\n", "<p>") // 0
//                                                 , rd.EventDescription.Replace("\r\n", "<p>").Replace("\n", "<p>") //1
//                                                 , firstPass ? " show" : "" // 2 - show details flag
//                                                 , counter.ToString().Substring(1) // 3 sequence number on cards
//                                                 , firstPass ? "" : "collapsed " // 4 collapsed flag
//                                                 , firstPass ? "true" : "false" // 5 expanded
//                                                 , String.IsNullOrWhiteSpace(rd.EventImage) ? "" : $"<img src=\"{rd.EventImage}\" alt=\"Event Image\" style=\"width:100%;\">" // 6 event image
//                                                 , i == 0 ? "hc-run-list-bg-future" : "hc-run-list-bg-past"
//                                                 , rd.EventStartDate.ToString("MMM")
//                                                 , rd.EventStartDate.ToString("%d")
//                                                 , rd.EventStartDate.ToString("h:mm tt")
//                                                 );


//                     sb.Append(card);

//                     if (i == 1) pastRunCount++;

//                     firstPass = false;
//                     counter++;
//                 }

//                 accordions.Append(accordianTemplate.Replace("<!--Card-->", sb.ToString()).Replace("{0}", i==0 ? "future":"past").Replace("{1}",i==0 ? "Future Runs" : "Past Runs"));

//                 sb.Clear();
//             }

//             string fullPage = pageTemplate.Replace("<!--Accordions-->", accordions.ToString());

//             using (Stream stream = GenerateStreamFromString(fullPage))
//             {
//                 await blob.UploadFromStreamAsync(stream).ConfigureAwait(false);
//             }

//             log.LogInformation($"HTML page written at:: {DateTime.Now}");

//             return blob.Uri;
//         }

//         public static Stream GenerateStreamFromString(string s)
//         {
//             var stream = new MemoryStream();
//             var writer = new StreamWriter(stream);
//             writer.Write(s);
//             writer.Flush();
//             stream.Position = 0;
//             return stream;
//         }

//         public static async Task CheckFacebook(ILogger log, MobileMessagingClient mmClient)
//         {
//             bool updateWebFiles = false;

//             Regex latLonRegex = new Regex(@"(^[-+]?(?:[1-8]?\d(?:\.\d+)?|90(?:\.0+)?)),\s*([-+]?(?:180(?:\.0+)?|(?:(?:1[0-7]\d)|(?:[1-9]?\d))(?:\.\d+)?))$", RegexOptions.IgnoreCase);

//             var str = ConfigurationManager.ConnectionStrings["HarrierCentralDb"]?.ConnectionString;
//             if (String.IsNullOrWhiteSpace(str))
//             {
//                 str = "Server=tcp:harriercentral.database.windows.net,1433;Initial Catalog=HarrierCentralWebDb;Persist Security Info=False;User ID=harrieradmin;Password=Op33AndTuna;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;";
//             }

//             using (SqlConnection conn = new SqlConnection(str))
//             {
//                 conn.Open();
//                 var text = "SELECT id,KennelName,KennelFacebookId,KennelFacebookToken,KennelShortName,Latitude,Longitude,KennelFacebookImportDaysInPast,KennelFacebookImportDaysInFuture FROM HC.Kennel WHERE KennelFacebookToken IS NOT NULL;";

//                 using (SqlCommand cmd = new SqlCommand(text, conn))
//                 {
//                     // Execute the command and log the # rows affected.
//                     var rows = await cmd.ExecuteReaderAsync();

//                     while (rows.Read())
//                     {
//                         var KennelId = rows.GetValue(0);
//                         string KennelName = rows.GetValue(1).ToString().Trim();
//                         string KennelFacebookId = rows.GetValue(2).ToString().Trim();
//                         string KennelFacebookToken = rows.GetValue(3).ToString().Trim();
//                         string KennelShortName = rows.GetValue(4).ToString().Trim();
//                         string KennelLatitude = rows.GetValue(5).ToString().Trim();
//                         string KennelLongitude = rows.GetValue(6).ToString().Trim();

//                         int daysInFuture = 9999;
//                         int daysInPast = 60;

//                         try
//                         {
//                              daysInPast = int.Parse(rows.GetValue(7).ToString().Trim());
//                              daysInFuture = int.Parse(rows.GetValue(8).ToString().Trim());
//                         }

//                         catch(System.Exception)
//                         {
//                             // if the number won't parse (which would be very unusual, just eat the exception
//                         }

//                         string regexPattern = String.Format(@"({0})(#|:|-|\s)*(?<number>\d+)", KennelShortName);
//                         log.LogInformation("*****" + regexPattern);
//                         Regex regex = new Regex(regexPattern, RegexOptions.IgnoreCase);

//                         string shortNamePattern = String.Format(@"(^|[^a-zA-Z0-9]){0}([^a-zA-Z0-9]|$)", KennelShortName);
//                         log.LogInformation("*****" + shortNamePattern);
//                         Regex regexShortName = new Regex(shortNamePattern, RegexOptions.IgnoreCase);



//                         //log.LogInformation($"KennelId = {KennelId.ToString()}, KennelName = {KennelName}, KennelFacebookId = {KennelFacebookId}, KennelFacebookToken = {KennelFacebookToken}");

//                         using (var client = new HttpClient())
//                         {
//                             try
//                             {
//                                 client.BaseAddress = new Uri("https://graph.facebook.com/v3.0/");

//                                 var request = String.Format("{0}?fields=events.limit(1000).since({1}).until({2}).fields(cover,name,place,description,start_time,type,category,id)&access_token={3}", KennelFacebookId, DateTime.Now.AddDays(-(daysInPast + 2)).ToString("MM/dd/yy"), DateTime.Now.AddDays(daysInFuture + 2).ToString("MM/dd/yy"), KennelFacebookToken);
//                                 HttpResponseMessage response = client.GetAsync(request).Result;

//                                 response.EnsureSuccessStatusCode();

//                                 string result = response.Content.ReadAsStringAsync().Result;

//                                 // log.LogInformation(result);

//                                 var jsonRes = JsonConvert.DeserializeObject<FbGroup>(result);


//                                 for (int i = 0; i < jsonRes.Events.Data.Count(); i++)
//                                 {
//                                     try
//                                     {
//                                         string Name = jsonRes.Events.Data[i].Name?.Replace("'", "''") ?? "<no event name>";

//                                         try
//                                         {
//                                             string Description = jsonRes.Events.Data[i].Description?.Replace("'", "''") ?? "";
//                                             string Id = jsonRes.Events.Data[i].Id;


//                                             string StartTime = jsonRes.Events.Data[i].StartTime.Substring(0, 22) + ":" + jsonRes.Events.Data[i].StartTime.Substring(22, 2);
//                                             log.LogInformation("Time = " + StartTime);

//                                             long OffsetX = jsonRes.Events.Data[i].Cover?.OffsetX ?? -1;
//                                             long OffsetY = jsonRes.Events.Data[i].Cover?.OffsetY ?? -1;
//                                             string Source = jsonRes.Events.Data[i].Cover?.Source ?? "";

//                                             string PlaceName = jsonRes.Events.Data[i].Place?.Name?.Replace("'", "''") ?? "";
//                                             string City = jsonRes.Events.Data[i].Place?.Location?.City?.Replace("'", "''") ?? "";
//                                             string Country = jsonRes.Events.Data[i].Place?.Location?.Country?.Replace("'", "''") ?? "";

//                                             string Street = jsonRes.Events.Data[i].Place?.Location?.Street?.Replace("'", "''") ?? "";
//                                             string Zip = jsonRes.Events.Data[i].Place?.Location?.Zip?.Replace("'", "''") ?? "";

//                                             double Latitude = jsonRes.Events.Data[i].Place?.Location?.Latitude ?? -1;
//                                             double Longitude = jsonRes.Events.Data[i].Place?.Location?.Longitude ?? -1;

//                                             // TODO: ReGeocode only when a record has been updated


//                                             var match = regex.Match(Name);
//                                             int absoluteEventNumber = -1;

//                                             if (match.Success)
//                                             {
//                                                 Group t = match.Groups["number"];
//                                                 int.TryParse(t.Value, out absoluteEventNumber);
//                                                 log.LogInformation(absoluteEventNumber.ToString());
//                                             }

//                                             var shortNameMatch = regexShortName.Match(Name);

//                                             // assume it is not a numbered run
//                                             int isCountedRun = -1;

//                                             // // did we match with the KennelShortName in the event name? If so, make it a counted Hash event
//                                             // if (shortNameMatch.Success)
//                                             // {
//                                             //     isCountedRun = 1;
//                                             // } 


//                                             var updateText = $"EXEC HC.nonApi_updateEventFromFacebook @KennelId='{KennelId}', @EventDescription='{Description}', @EventName='{Name}', @StartTime='{StartTime}', @FacebookEventId='{Id}', @EventImage='{Source}', @PlaceName='{PlaceName}', @City='{City}', @Country='{Country}', @Latitude={Latitude.ToString()}, @Longitude={Longitude.ToString()}, @Street='{Street}', @Zip='{Zip}', @OffsetX={OffsetX}, @OffsetY={OffsetY}, @AbsoluteEventNumber={absoluteEventNumber}, @isCountedRun={isCountedRun}";

//                                             log.LogInformation(Name);

//                                             using (SqlConnection conn2 = new SqlConnection(str))
//                                             {

//                                                 using (SqlCommand updateCmd = new SqlCommand(updateText, conn2))
//                                                 {
//                                                     conn2.Open();

//                                                     try
//                                                     {
//                                                         // Execute the command and log the # rows affected.
//                                                         var updateRows = updateCmd.ExecuteReader();
//                                                         // log.LogInformation(updateText);

//                                                         while (updateRows.Read())
//                                                         {
//                                                             log.LogInformation(updateRows.GetValue(0).ToString());

//                                                             //*******************
//                                                             // NOTE: This two stage approach to geocoding is done to prevent geocoding running every time we do a Faceook Query
//                                                             // By doing geocoding in a second stage, we only invoke the geocode service when new records are added and records are updated

//                                                             if (updateRows.GetValue(0).ToString() != "Rows updated = 0")
//                                                             {

//                                                                 updateWebFiles = true;

//                                                                 await mmClient.SendNotification("Run updated", updateRows.GetValue(0).ToString(), log);

//                                                                 // Check to see if Geocoding is requird

//                                                                 if ((Latitude == -1) || (Longitude == -1))
//                                                                 {
//                                                                     log.LogInformation("########### LatLong detected");
//                                                                     bool reverse = false;

//                                                                     if (latLonRegex.IsMatch(PlaceName))
//                                                                     {
//                                                                         Match latLonMatch = latLonRegex.Match(PlaceName);
//                                                                         double lat = -1;
//                                                                         double lon = -1;

//                                                                         reverse = double.TryParse(latLonMatch.Groups[1].Value, out lat);
//                                                                         if (reverse)
//                                                                         {
//                                                                             reverse = double.TryParse(latLonMatch.Groups[2].Value, out lon);
//                                                                             if(reverse)
//                                                                             {
//                                                                                 Latitude = lat;
//                                                                                 Longitude = lon;
//                                                                                 PlaceName = $"{lat},{lon}";
//                                                                             }
//                                                                         }
//                                                                     }


//                                                                     log.LogInformation("########### Geocoding Required");

//                                                                     GeocodeResult geo = await AzureGeocode(PlaceName, KennelLatitude, KennelLongitude,reverse);

//                                                                     if (geo != null)
//                                                                     {
//                                                                         City = geo?.City?.Replace("'", "''") ?? "";
//                                                                         Country = geo?.Country?.Replace("'", "''") ?? "";
//                                                                         Street = geo?.Street?.Replace("'", "''") ?? "";
//                                                                         Zip = geo?.Zip?.Replace("'", "''") ?? "";
//                                                                         if (!reverse)
//                                                                         {
//                                                                             Latitude = geo?.Latitude ?? -1;
//                                                                             Longitude = geo?.Longitude ?? -1;
//                                                                         }

//                                                                         log.LogInformation($"City={City}, Street={Street}, Lat={Latitude}, Lon={Longitude}, Post={Zip}");
//                                                                     }

//                                                                     string updateText2 = $"EXEC HC.nonApi_updateEventFromFacebook @KennelId='{KennelId}', @FacebookEventId='{Id}', @City='{City}', @Country='{Country}', @Latitude={Latitude.ToString()}, @Longitude={Longitude.ToString()}, @Street='{Street}', @Zip='{Zip}', @ForceUpdate = 1";

//                                                                     using (SqlConnection conn4 = new SqlConnection(str))
//                                                                     {

//                                                                         using (SqlCommand updateCmd2 = new SqlCommand(updateText2, conn4))
//                                                                         {
//                                                                             conn4.Open();

//                                                                             try
//                                                                             {
//                                                                                 // Execute the command and log the # rows affected.
//                                                                                 var updateRows2 = updateCmd2.ExecuteReader();
//                                                                                 // log.LogInformation(updateText);

//                                                                                 while (updateRows2.Read())
//                                                                                 {
//                                                                                     log.LogInformation(updateText2);
//                                                                                     log.LogInformation(updateRows2.GetValue(0).ToString() + " Geocode Successful");
//                                                                                 }
//                                                                             }

//                                                                             catch (System.Exception ex)
//                                                                             {
//                                                                                 log.LogInformation("----- Geocode Pass Failure --- " + ex.Message);
//                                                                                 log.LogInformation("----- " + Name + " --- " + ex.Message);
//                                                                                 log.LogInformation("----- " + ex.GetType().Name);
//                                                                                 log.LogInformation("----- " + updateText);
//                                                                             }
//                                                                         }
//                                                                     }
//                                                                 }
//                                                             }
//                                                         }
//                                                     }

//                                                     catch (System.Exception ex)
//                                                     {

//                                                         log.LogInformation("----- " + Name + " --- " + ex.Message);
//                                                         log.LogInformation("----- " + ex.GetType().Name);
//                                                         log.LogInformation("----- " + updateText);
//                                                     }

//                                                 }
//                                             }
//                                         }

//                                         catch (System.NullReferenceException ex)
//                                         {
//                                             log.LogInformation("--------- " + Name + " --- " + ex.Message);
//                                             log.LogInformation("--------- " + ex.GetType().Name);
//                                         }

//                                         catch (System.Exception ex)
//                                         {
//                                             log.LogInformation("----- " + Name + " --- " + ex.Message);
//                                             log.LogInformation("----- " + ex.GetType().Name);
//                                         }
//                                     }

//                                     catch (System.NullReferenceException ex)
//                                     {
//                                         log.LogInformation("--------- Error Parsing Event Name");
//                                         log.LogInformation("--------- " + ex.GetType().Name);
//                                     }

//                                     catch (System.Exception ex)
//                                     {
//                                         log.LogInformation("----- Error Parsing Event Name");
//                                         log.LogInformation("----- " + ex.GetType().Name);
//                                     }
//                                 }


//                                 using (SqlConnection conn3 = new SqlConnection(str))
//                                 {
//                                     string renumberCommand = $"EXEC HC.nonApi_updateRunNumbers @KennelId='{KennelId}'";

//                                     using (SqlCommand updateCmd = new SqlCommand(renumberCommand, conn3))
//                                     {
//                                         conn3.Open();

//                                         try
//                                         {
//                                             // Execute the command and log the # rows affected.
//                                             var updateRows = updateCmd.ExecuteReader();
//                                             // log.LogInformation(updateText);

//                                             while (updateRows.Read())
//                                             {
//                                                 log.LogInformation(updateRows.GetValue(0).ToString());
//                                             }
//                                         }

//                                         catch (System.Exception ex)
//                                         {
//                                             log.LogInformation("----- " + ex.GetType().Name);
//                                             log.LogInformation("----- " + ex.Message);
//                                         }

//                                     }
//                                 }
//                             }

//                             catch (System.Net.Http.HttpRequestException ex)
//                             {
//                                 log.LogInformation("----- Error Querying Facebook");
//                                 log.LogInformation("----- " + ex.GetType().Name);
//                                 log.LogInformation("----- " + ex.Message);
//                             }

//                             catch (System.Exception ex)
//                             {
//                                 log.LogInformation("----- Error Querying Facebook");
//                                 log.LogInformation("----- " + ex.GetType().Name);
//                                 log.LogInformation("----- " + ex.Message);
//                             }
//                         }
//                     }
//                 }
//             }

//             if (updateWebFiles) await PublishUpdatedWebPages(log);
//         }


//         private static string createToken(string resourceUri, string keyName, string key)
//         {
//             TimeSpan sinceEpoch = DateTime.UtcNow - new DateTime(1970, 1, 1);
//             var week = 60 * 60 * 24 * 7;
//             var expiry = Convert.ToString((int)sinceEpoch.TotalSeconds + week);
//             string stringToSign = System.Web.HttpUtility.UrlEncode(resourceUri) + "\n" + expiry;
//             System.Security.Cryptography.HMACSHA256 hmac = new System.Security.Cryptography.HMACSHA256(Encoding.UTF8.GetBytes(key));
//             var signature = Convert.ToBase64String(hmac.ComputeHash(Encoding.UTF8.GetBytes(stringToSign)));
//             var sasToken = String.Format(System.Globalization.CultureInfo.InvariantCulture, "SharedAccessSignature sr={0}&sig={1}&se={2}&skn={3}", System.Web.HttpUtility.UrlEncode(resourceUri), System.Web.HttpUtility.UrlEncode(signature), expiry, keyName);
//             //var sasToken = String.Format(System.Globalization.CultureInfo.InvariantCulture, "SharedAccessSignature sr={0}&sig={1}&se={2}&skn={3}",resourceUri, signature, expiry, keyName);
//             return sasToken;
//         }


//         static async Task<GeocodeResult> AzureGeocode(string address, string lat, string lon, bool reverse)
//         {
//             GeocodeResult geo = new GeocodeResult();
//             string url;

//             if (reverse)
//             {
//                 url = $"https://atlas.microsoft.com/search/address/reverse/JSON?subscription-key=kTv-hbcehDKyCUljAaqcbE5IIycrVkcG30RkqHZqgkw&api-version=1.0&query={address}";
//             }
//             else
//             {
//                 url = $"https://atlas.microsoft.com/search/fuzzy/JSON?subscription-key=kTv-hbcehDKyCUljAaqcbE5IIycrVkcG30RkqHZqgkw&api-version=1.0&minFuzzyLevel={1}&maxFuzzyLevel={4}&query={System.Net.WebUtility.UrlEncode(address)}.&lat={lat}&lon={lon}";
//             }

//             // ... Use HttpClient.
//             using (System.Net.Http.HttpClient client = new HttpClient())
//             using (System.Net.Http.HttpResponseMessage response = await client.GetAsync(url))
//             using (HttpContent content = response.Content)
//             {
//                 // ... Read the string.
//                 string result = await content.ReadAsStringAsync();

//                 if (!reverse)
//                 {
//                     AzureFuzzyPlace places = Newtonsoft.Json.JsonConvert.DeserializeObject<AzureFuzzyPlace>(result);

//                     if (places != null)
//                     {
//                         if (places.results.Count() > 0)
//                         {
//                             geo.PlaceName = places.summary.query?.Replace("'", "''") ?? "";
//                             geo.City = places.results[0].address.municipality?.Replace("'", "''") ?? "";
//                             geo.Country = places.results[0].address.country?.Replace("'", "''") ?? "";
//                             geo.Street = (places.results[0].address.streetNumber?.Replace("'", "''") ?? "") + " " + (places.results[0].address.streetName?.Replace("'", "''") ?? "");
//                             geo.Zip = places.results[0].address.extendedPostalCode?.Replace("'", "''") ?? places.results[0].address.postalCode?.Replace("'", "''") ?? "";
//                             geo.Latitude = places.results[0].position.lat ?? -1.0;
//                             geo.Longitude = places.results[0].position.lon ?? -1.0;
//                         }
//                         else
//                         {
//                             geo = null;
//                         }
//                     }
//                 } else
//                 {
//                     AzureAddressPlace places = Newtonsoft.Json.JsonConvert.DeserializeObject<AzureAddressPlace>(result);

//                     if (places != null)
//                     {
//                         if (places.addresses.Count() > 0)
//                         {
//                             geo.PlaceName = address;
//                             geo.City = places.addresses[0].address.municipality?.Replace("'", "''") ?? "";
//                             geo.Country = places.addresses[0].address.country?.Replace("'", "''") ?? "";
//                             geo.Street = (places.addresses[0].address.streetNumber?.Replace("'", "''") ?? "") + " " + (places.addresses[0].address.streetName?.Replace("'", "''") ?? "");
//                             geo.Zip = places.addresses[0].address.extendedPostalCode?.Replace("'", "''") ?? places.addresses[0].address.postalCode?.Replace("'", "''") ?? "";
//                         }
//                         else
//                         {
//                             geo = null;
//                         }
//                     }
//                 }
//             }

//             return geo;
//         }

//         public partial class FbGroup
//         {
//             [JsonProperty("events")]
//             public Events Events { get; set; }

//             [JsonProperty("id")]
//             public string Id { get; set; }
//         }

//         public partial class Events
//         {
//             [JsonProperty("data")]
//             public Datum[] Data { get; set; }

//             [JsonProperty("paging")]
//             public Paging Paging { get; set; }
//         }

//         public partial class Datum
//         {
//             [JsonProperty("cover", NullValueHandling = NullValueHandling.Ignore)]
//             public Cover Cover { get; set; }

//             [JsonProperty("name")]
//             public string Name { get; set; }

//             [JsonProperty("place", NullValueHandling = NullValueHandling.Ignore)]
//             public Place Place { get; set; }

//             [JsonProperty("description", NullValueHandling = NullValueHandling.Ignore)]
//             public string Description { get; set; }

//             [JsonProperty("start_time")]
//             public string StartTime { get; set; }

//             [JsonProperty("type")]
//             public string Type { get; set; }

//             [JsonProperty("id")]
//             public string Id { get; set; }
//         }

//         public partial class Cover
//         {
//             [JsonProperty("offset_x")]
//             public long OffsetX { get; set; }

//             [JsonProperty("offset_y")]
//             public long OffsetY { get; set; }

//             [JsonProperty("source")]
//             public string Source { get; set; }

//             [JsonProperty("id")]
//             public string Id { get; set; }
//         }

//         public partial class Place
//         {
//             [JsonProperty("name")]
//             public string Name { get; set; }

//             [JsonProperty("location", NullValueHandling = NullValueHandling.Ignore)]
//             public Location Location { get; set; }

//             [JsonProperty("id", NullValueHandling = NullValueHandling.Ignore)]
//             public string Id { get; set; }
//         }

//         public partial class Location
//         {
//             [JsonProperty("city", NullValueHandling = NullValueHandling.Ignore)]
//             public string City { get; set; }

//             [JsonProperty("country", NullValueHandling = NullValueHandling.Ignore)]
//             public string Country { get; set; }

//             [JsonProperty("latitude", NullValueHandling = NullValueHandling.Ignore)]
//             public double? Latitude { get; set; }

//             [JsonProperty("longitude", NullValueHandling = NullValueHandling.Ignore)]
//             public double? Longitude { get; set; }

//             [JsonProperty("street", NullValueHandling = NullValueHandling.Ignore)]
//             public string Street { get; set; }

//             [JsonProperty("zip", NullValueHandling = NullValueHandling.Ignore)]
//             public string Zip { get; set; }
//         }

//         public partial class Paging
//         {
//             [JsonProperty("cursors")]
//             public Cursors Cursors { get; set; }
//         }

//         public partial class Cursors
//         {
//             [JsonProperty("before")]
//             public string Before { get; set; }

//             [JsonProperty("after")]
//             public string After { get; set; }
//         }


//         public class GeocodeResult
//         {
//             public string PlaceName { get; set; }
//             public string City { get; set; }
//             public string Country { get; set; }

//             public string Street { get; set; }
//             public string Zip { get; set; }

//             public double Latitude { get; set; }
//             public double Longitude { get; set; }
//         }


//         public class GeoBias
//         {
//             public double lat { get; set; }
//             public double lon { get; set; }
//         }

//         public class Summary
//         {
//             public string query { get; set; }
//             public string queryType { get; set; }
//             public int queryTime { get; set; }
//             public int numResults { get; set; }
//             public int offset { get; set; }
//             public int totalResults { get; set; }
//             public int fuzzyLevel { get; set; }
//             public GeoBias geoBias { get; set; }
//         }

//         public class Address
//         {
//             public string streetNumber { get; set; }
//             public string streetName { get; set; }
//             public string municipalitySubdivision { get; set; }
//             public string municipality { get; set; }
//             public string countrySecondarySubdivision { get; set; }
//             public string countryTertiarySubdivision { get; set; }
//             public string countrySubdivision { get; set; }
//             public string postalCode { get; set; }
//             public string extendedPostalCode { get; set; }
//             public string countryCode { get; set; }
//             public string country { get; set; }
//             public string countryCodeISO3 { get; set; }
//             public string freeformAddress { get; set; }
//             public string countrySubdivisionName { get; set; }
//         }

//         public class Position
//         {
//             public double? lat { get; set; }
//             public double? lon { get; set; }
//         }

//         public class TopLeftPoint
//         {
//             public double lat { get; set; }
//             public double lon { get; set; }
//         }

//         public class BtmRightPoint
//         {
//             public double lat { get; set; }
//             public double lon { get; set; }
//         }

//         public class Viewport
//         {
//             public TopLeftPoint topLeftPoint { get; set; }
//             public BtmRightPoint btmRightPoint { get; set; }
//         }

//         public class Position2
//         {
//             public double lat { get; set; }
//             public double lon { get; set; }
//         }

//         public class EntryPoint
//         {
//             public string type { get; set; }
//             public Position2 position { get; set; }
//         }

//         public class From
//         {
//             public double lat { get; set; }
//             public double lon { get; set; }
//         }

//         public class To
//         {
//             public double lat { get; set; }
//             public double lon { get; set; }
//         }

//         public class AddressRanges
//         {
//             public string rangeLeft { get; set; }
//             public string rangeRight { get; set; }
//             public From from { get; set; }
//             public To to { get; set; }
//         }

//         public class FuzzyResult
//         {
//             public string type { get; set; }
//             public string id { get; set; }
//             public double score { get; set; }
//             public double dist { get; set; }
//             public Address address { get; set; }
//             public Position position { get; set; }
//             public Viewport viewport { get; set; }
//             public List<EntryPoint> entryPoints { get; set; }
//             public AddressRanges addressRanges { get; set; }
//         }

//         public class AzureFuzzyPlace
//         {
//             public Summary summary { get; set; }
//             public List<FuzzyResult> results { get; set; }
//         }

//         public class RunDataForWebPage
//         {
//             public Guid EventId;
//             public string EventName;
//             public string EventDescription;
//             public DateTime EventStartDate;
//             public string EventImage;
//         }



//         ///// AzureAddressPlace
//         ///

//         public class AapSummary
//         {
//             public int queryTime { get; set; }
//             public int numResults { get; set; }
//         }

//         public class AapBoundingBox
//         {
//             public string northEast { get; set; }
//             public string southWest { get; set; }
//             public string entity { get; set; }
//         }

//         public class AapAddress2
//         {
//             public string buildingNumber { get; set; }
//             public string streetNumber { get; set; }
//             public List<object> routeNumbers { get; set; }
//             public string street { get; set; }
//             public string streetName { get; set; }
//             public string streetNameAndNumber { get; set; }
//             public string countryCode { get; set; }
//             public string countrySubdivision { get; set; }
//             public string municipality { get; set; }
//             public string postalCode { get; set; }
//             public string municipalitySubdivision { get; set; }
//             public string country { get; set; }
//             public string countryCodeISO3 { get; set; }
//             public string freeformAddress { get; set; }
//             public AapBoundingBox boundingBox { get; set; }
//             public string extendedPostalCode { get; set; }
//             public string localName { get; set; }
//         }

//         public class AapAddress
//         {
//             public AapAddress2 address { get; set; }
//             public string position { get; set; }
//         }

//         public class AzureAddressPlace
//         {
//             public AapSummary summary { get; set; }
//             public List<AapAddress> addresses { get; set; }
//         }




//     }
// }


