importScripts('https://www.gstatic.com/firebasejs/10.9.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.9.0/firebase-messaging-compat.js');

const firebaseConfig = {
    apiKey: "AIzaSyA_z9Xbh3U55aQ1HJYn1WqfXkY5_aetpFE",
    authDomain: "harrier-central-mobile.firebaseapp.com",
    databaseURL: "https://harrier-central-mobile.firebaseio.com",
    projectId: "harrier-central-mobile",
    storageBucket: "harrier-central-mobile.firebasestorage.app",
    messagingSenderId: "699693953835",
    appId: "1:699693953835:web:43c78891078029d87a8b6e",
    measurementId: "G-2B04ZP86XF"
};

firebase.initializeApp(firebaseConfig);

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
