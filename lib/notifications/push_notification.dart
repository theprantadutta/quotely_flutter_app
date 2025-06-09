import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:quotely_flutter_app/screens/quote_of_the_day_screen.dart';
import 'package:quotely_flutter_app/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../firebase_options.dart';
import '../navigation/app_navigation.dart';

class PushNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin
      _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  // request notification permission
  static Future init() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // On background notification tapped
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? message) {
      if (message == null) return; // Exit early if message is null

      debugPrint('Message: ${message.toMap().toString()}');
      debugPrint('Data: ${message.data.toString()}');

      if (message.notification != null) {
        debugPrint("Background Notification Tapped");

        // final noticeId = message.data['noticeId'];

        AppNavigation.rootNavigatorKey.currentContext?.push(
          // noticeId != null
          //     ? '${QuoteOfTheDayScreen.kRouteName}'
          //     : QuoteOfTheDayScreen.kRouteName,
          QuoteOfTheDayScreen.kRouteName,
        );
      }
    });

    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    getFCMToken();

    // Listen to background notifications
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);

    // to handle foreground notifications
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      String payloadData = jsonEncode(message.data);
      debugPrint("Got a message in foreground");
      if (message.notification != null) {
        PushNotifications.showSimpleNotification(
          title: message.notification!.title!,
          body: message.notification!.body!,
          payload: payloadData,
        );
      }
    });

    // for handling in terminated state
    final RemoteMessage? message =
        await FirebaseMessaging.instance.getInitialMessage();

    if (message != null) {
      debugPrint("Launched from terminated state");
      Future.delayed(
        const Duration(seconds: 1),
        () {
          // AppNavigation.rootNavigatorKey.currentState!.pushNamed(
          //   NoticeScreen.name,
          //   arguments: message,
          // );
        },
      );
    }

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // await _firebaseMessaging.subscribeToAllTopic();

    const String allTopicKey = 'subscribedToAllTopic';

    // Get SharedPreferences instance
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // Check if already subscribed
    final bool isAlreadySubscribed = prefs.getBool(allTopicKey) ?? false;

    if (!isAlreadySubscribed) {
      // Subscribe to the topic
      await NotificationService().subscribeToAllTopic();

      // Mark as subscribed in SharedPreferences
      await prefs.setBool(allTopicKey, true);

      debugPrint('Subscribed to all topic and updated preferences.');
    } else {
      debugPrint('Already subscribed to all topic.');
    }
  }

  // get the fcm device token
  static Future getFCMToken({int maxRetires = 3}) async {
    try {
      // get the device fcm token
      String? token = await _firebaseMessaging.getToken();

      if (kDebugMode) {
        debugPrint("Firebae FCM Token: $token");
      }

      return token;
    } catch (e) {
      debugPrint("failed to get device token");
      if (maxRetires > 0) {
        debugPrint("try after 10 sec");
        await Future.delayed(const Duration(seconds: 10));
        return getFCMToken(maxRetires: maxRetires - 1);
      } else {
        return null;
      }
    }
  }

  // initalize local notifications
  static Future localNotiInit() async {
    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            // onDidReceiveLocalNotification: (id, title, body, payload) {},
            );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
      onDidReceiveBackgroundNotificationResponse: onNotificationTap,
    );
  }

  // on tap local notification in foreground
  static void onNotificationTap(NotificationResponse notificationResponse) {
    // AppNavigation.rootNavigatorKey.currentState!.pushNamed(
    //   NoticeScreen.name,
    //   arguments: notificationResponse,
    // );
  }

  // function to lisen to background changes
  static Future _firebaseBackgroundMessage(RemoteMessage? message) async {
    if (message?.notification != null) {
      debugPrint("Some notification Received");
    }
  }

  // show a simple notification
  static Future showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'com.pranta.quotely',
      'Quotely',
      channelDescription: 'Quotely Application',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );
    // Generate a unique notification ID
    int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }
}
