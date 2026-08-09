importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.22.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBeYl4IKFpNr1wHiKXajPK0J4IV9lpvykI",
  authDomain: "tubitak-akran-zorbaligi.firebaseapp.com",
  projectId: "tubitak-akran-zorbaligi",
  storageBucket: "tubitak-akran-zorbaligi.firebasestorage.app",
  messagingSenderId: "610579116609",
  appId: "1:610579116609:web:c8ef1afb8e7256d4844cc0"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  // Do not log notification payloads: they can contain child-related data.
});
