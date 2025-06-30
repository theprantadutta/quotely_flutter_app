import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../navigation/app_navigation.dart';

class PushNotifications {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const String _channelId = 'quotely_notification_channel';
  static const String _initialSubscriptionKey = 'initial-subscription';

  // Main initialization
  static Future<void> init() async {
    try {
      // 1. Setup notification channel (Android)
      await _createNotificationChannel();

      // 2. Request permissions
      await _requestNotificationPermissions();

      // 3. Initialize local notifications
      await _initializeLocalNotifications();

      // 4. Setup FCM token and listeners
      await _setupFcmServices();

      // 5. Handle initial message (app launched from terminated state)
      await _handleInitialMessage();

      // 6. Subscribe to topics (once)
      await _subscribeToTopics();
    } catch (e) {
      debugPrint('PushNotifications initialization failed: $e');
    }
  }

  // Notification Channel Setup (Android)
  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      'Quotely Notifications',
      description: 'Notifications for new releases and updates.',
      importance: Importance.max,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Permission Handling
  static Future<void> _requestNotificationPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: true,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Local Notifications Initialization
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  // FCM Services Setup
  static Future<void> _setupFcmServices() async {
    // Get and log FCM token
    await getFCMToken();

    // Setup message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessage);
  }

  // Handle initial message (app launched from terminated state)
  static Future<void> _handleInitialMessage() async {
    final RemoteMessage? message = await _firebaseMessaging.getInitialMessage();
    if (message != null) {
      debugPrint("Launched from terminated state");
      _handleNotificationTap(message.data);
    }
  }

  // Topic Subscription
  static Future<void> _subscribeToTopics() async {
    final preferences = await SharedPreferences.getInstance();
    final isAlreadySubscribed =
        preferences.getBool(_initialSubscriptionKey) ?? false;

    if (!isAlreadySubscribed) {
      await _firebaseMessaging.subscribeToTopic('all');
      await preferences.setBool(_initialSubscriptionKey, true);
      debugPrint('Subscribed to "all" topic');
    }
  }

  // FCM Token Handling
  static Future<String?> getFCMToken({int maxRetries = 3}) async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (kDebugMode && token != null) {
        debugPrint("Firebase FCM Token: $token");
      }
      return token;
    } catch (e) {
      debugPrint("Failed to get FCM token: $e");
      if (maxRetries > 0) {
        await Future.delayed(const Duration(seconds: 10));
        return getFCMToken(maxRetries: maxRetries - 1);
      }
      return null;
    }
  }

  // Notification Display
  static Future<void> showSimpleNotification({
    required String title,
    required String body,
    required String payload,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      _channelId,
      'Quotely Notifications',
      channelDescription: 'Notifications for new releases and updates.',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Message Handlers
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint("Foreground message received");
    if (message.notification != null) {
      await showSimpleNotification(
        title: message.notification!.title!,
        body: message.notification!.body!,
        payload: jsonEncode(message.data),
      );
    }
  }

  static void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint("Background notification tapped");
    _handleNotificationTap(message.data);
  }

  static Future<void> _firebaseBackgroundMessage(RemoteMessage? message) async {
    if (message?.notification != null) {
      debugPrint("Background notification received");
    }
  }

  // Notification Tap Handler
  static void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationTap(data);
      } catch (e) {
        debugPrint("Error parsing notification payload: $e");
      }
    }
  }

  static void _handleNotificationTap(Map<String, dynamic> data) {
    // Get the current context from your navigation key
    final context = AppNavigation.rootNavigatorKey.currentContext;
    if (context == null) {
      debugPrint('No context available for navigation');
      return;
    }

    // Check if routeName exists and is a non-empty string
    final routeName = data['routeName']?.toString();
    if (routeName == null || routeName.isEmpty) {
      debugPrint('No valid routeName found in notification data: $data');
      return;
    }

    try {
      // Use GoRouter to navigate to the specified route
      debugPrint('Navigating to route: $routeName');
      GoRouter.of(context).push(routeName);
    } catch (e) {
      debugPrint('Failed to navigate to route $routeName: $e');
      debugPrint('Full notification data: $data');
    }
  }
}
