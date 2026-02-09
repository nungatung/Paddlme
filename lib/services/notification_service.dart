import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_service.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();
  
  // Stream controller for badge count
  final _badgeController = StreamController<int>.broadcast();
  Stream<int> get badgeStream => _badgeController.stream;

  Future<void> initialize() async {
    // Request permission (iOS)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    
    await _localNotifications.initialize(settings: initSettings);

    // Get FCM token and save to Firestore
    await _updateFcmToken();

    // Listen for token refresh
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background/terminated messages
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
    
    // Check for initial message (app opened from terminated state)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }
  }

  Future<void> _updateFcmToken() async {
    final token = await _fcm.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _authService.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'fcmToken': token});
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Show local notification when app is in foreground
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      await _showLocalNotification(
        title: notification.title ?? 'New Message',
        body: notification.body ?? '',
        payload: data['conversationId'],
      );
      
      // Update badge count
      _updateBadgeCount();
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'messages_channel',
      'Messages',
      channelDescription: 'New message notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(
      id: DateTime.now().millisecond,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    final data = message.data;
    if (data['type'] == 'message') {
      // Navigate to chat screen - you'll need to implement this
      // Use a navigator key or state management to handle navigation
      _navigateToChat(data);
    }
  }

  void _handleNotificationTap(String? payload) {
    if (payload != null) {
      _navigateToChat({'conversationId': payload});
    }
  }

  void _navigateToChat(Map<String, dynamic> data) {
    // TODO: Implement navigation to chat screen
    // You can use a GlobalKey<NavigatorState> or a state management solution
    // to navigate from here
    print('Should navigate to conversation: ${data['conversationId']}');
  }

  void _updateBadgeCount() {
    // Increment badge count - implement based on your state management
    // This should update the badge on your Messages tab
    _badgeController.add(1);
  }

  // Call this when user reads messages to clear badge
  void clearBadge() {
    _badgeController.add(0);
  }

  void dispose() {
    _badgeController.close();
  }
}

// Top-level function for background messages
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  print('Handling background message: ${message.messageId}');
}