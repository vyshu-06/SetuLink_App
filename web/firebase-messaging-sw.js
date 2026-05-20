importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyDywqDmqmNhotb3ikQW3KgzKd4rxrA3aCQ",
  appId: "1:60751051995:web:f43d66486004ff780060fe",
  messagingSenderId: "60751051995",
  projectId: "setulink-app-fb",
  authDomain: "setulink-app-fb.firebaseapp.com",
  storageBucket: "setulink-app-fb.firebasestorage.app",
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log("Received background message: ", payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/icons/Icon-192.png",
  };

  return self.registration.showNotification(
    notificationTitle,
    notificationOptions
  );
});
