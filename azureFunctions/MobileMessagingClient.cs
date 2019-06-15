// using System;
// using System.Collections.Generic;
// using System.Text;
// using FirebaseAdmin;
// using FirebaseAdmin.Messaging;
// using Google.Apis.Auth.OAuth2;
// using System.Threading.Tasks;
// using Microsoft.Extensions.Logging;

// namespace HcAzureFunctions
// {



// public class MobileMessagingClient
//     {
//         private readonly FirebaseMessaging messaging;

//         public MobileMessagingClient(String appDirectory)
//         {

//             //Directory.GetParent(executionContext.FunctionDirectory).FullName
//             String path = appDirectory + "/" + "harrier-central-mobile-52d5ffd539d4.json";

//             var app = FirebaseApp.Create(new AppOptions() { Credential = GoogleCredential.FromFile(path).CreateScoped("https://www.googleapis.com/auth/firebase.messaging") });
//             messaging = FirebaseMessaging.GetMessaging(app);
//         }

//         private Message CreateNotification(string title, string notificationBody)
//         {
//             return new Message()
//             {
//                 //Token = "dLhJRZGdQbI:APA91bEy_DblcHTyPyvBaUwe7q618MA91HWRAsYtIQ7BGplh47T8nOdmeWz4SF7JkSmtIdPgdP0r_UPvK",
//                 Topic = "test",
//                 Notification = new Notification()
//                 {
//                     Body = notificationBody,
//                     Title = title
                    
//                 }
//             };
//         }

//         public async Task SendNotification(string title, string body, ILogger log)
//         {
//             var result = await messaging.SendAsync(CreateNotification(title, body));
//             log.LogInformation($"Notification result = {result.ToString()}");
//             //do something with result
//         }
//     }
// }
