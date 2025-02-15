import 'package:eoffice/Screens/notification_screen.dart';
import 'package:eoffice/main.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class FirebaseApi {
  final _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotification() async {
    await _firebaseMessaging.requestPermission();
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');
    initPushNotification();
    sendFcmTokenToServer(fcmToken!);
  }

  Future<void> sendFcmTokenToServer(String fcmToken) async {
    final url = Uri.parse(
        'https://eofficess.com/api/store-fcm-token?fcm_token=$fcmToken');

    try {
      final response = await http.post(url);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('FCM Token successfully sent to server.');
      } else {
        print(
            'Failed to send FCM Token to server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending FCM Token to server: $e');
    }
  }
}

void handleMessage(RemoteMessage message) {
  print('Message data: ${message.data}');
  print('Message notification: ${message.notification}');

  if (message.notification != null) {
    navigatorKey.currentState?.pushNamed(
      NotificationScreen.route,
      arguments: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      },
    );
  }
}

Future<void> initPushNotification() async {
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.instance.getInitialMessage().then((message) {
    if (message != null) {
      handleMessage(message);
    }
  });

  FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      showForegroundNotification(message);
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  handleMessage(message);
}

void showForegroundNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(
    message.notification.hashCode,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
    payload: message.data.toString(),
  );
}
