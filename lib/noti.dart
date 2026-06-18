import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:invoice_ai/nav.dart';

class NotificationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'Used for important app notifications',
        importance: Importance.high,
      );

  static bool _isListening = false;
  static bool _isLocalNotificationsReady = false;
  static bool _isForegroundListenerReady = false;
  static bool _isTapHandlerReady = false;
  static StreamSubscription<String>? _tokenRefreshSubscription;
  static StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;
  static StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

  static Future<void> initialize() async {
    if (!_isSupportedPlatform) return;

    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final isAllowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!isAllowed) return;

      await _initializeLocalNotifications();
      _listenForForegroundMessages();
      await _setupNotificationTapHandlers();

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;

      await _saveToken(token);
    } catch (e, stackTrace) {
      debugPrint('NotificationService.initialize failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void listenForTokenRefresh() {
    if (!_isSupportedPlatform ||
        _isListening ||
        _tokenRefreshSubscription != null) {
      return;
    }

    try {
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh
          .listen(
            (token) async {
              if (token.trim().isEmpty) return;

              try {
                await _saveToken(token);
              } catch (e, stackTrace) {
                debugPrint('NotificationService token refresh save failed: $e');
                debugPrintStack(stackTrace: stackTrace);
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              debugPrint(
                'NotificationService token refresh listener failed: $error',
              );
              debugPrintStack(stackTrace: stackTrace);
            },
          );
      _isListening = true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService.listenForTokenRefresh failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _initializeLocalNotifications() async {
    if (!_isSupportedPlatform || _isLocalNotificationsReady) return;

    try {
      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('notification_icon'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (response) {
          final data = _decodePayload(response.payload);
          debugPrint('Local notification tapped with payload: $data');
          _handleNotificationData(data ?? const <String, dynamic>{});
        },
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_androidChannel);

      _isLocalNotificationsReady = true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService local notification init failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static void _listenForForegroundMessages() {
    if (!_isSupportedPlatform ||
        _isForegroundListenerReady ||
        _foregroundMessageSubscription != null) {
      return;
    }

    try {
      _foregroundMessageSubscription = FirebaseMessaging.onMessage.listen(
        _showForegroundNotification,
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('NotificationService foreground listener failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );
      _isForegroundListenerReady = true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService foreground setup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (!_isSupportedPlatform || !_isLocalNotificationsReady) return;

    try {
      final title =
          message.notification?.title ??
          _stringFromData(message.data['title']) ??
          'إشعار جديد';
      final body =
          message.notification?.body ??
          _stringFromData(message.data['body']) ??
          '';
      final payload = jsonEncode(message.data);

      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',
          channelDescription: 'Used for important app notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          presentBanner: true,
          presentList: true,
        ),
      );

      await _localNotifications.show(
        id: _notificationIdFor(message),
        title: title,
        body: body,
        notificationDetails: notificationDetails,
        payload: payload,
      );
    } catch (e, stackTrace) {
      debugPrint('NotificationService foreground notification failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _setupNotificationTapHandlers() async {
    if (!_isSupportedPlatform ||
        _isTapHandlerReady ||
        _messageOpenedSubscription != null) {
      return;
    }

    try {
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint(
          'Notification opened app from terminated state: ${initialMessage.data}',
        );
        _handleNotificationData(
          Map<String, dynamic>.from(initialMessage.data),
          allowNavigation: false,
        );
      }

      _messageOpenedSubscription = FirebaseMessaging.onMessageOpenedApp.listen(
        (message) {
          debugPrint(
            'Notification opened app from background: ${message.data}',
          );
          _handleNotificationData(Map<String, dynamic>.from(message.data));
        },
        onError: (Object error, StackTrace stackTrace) {
          debugPrint('NotificationService tap listener failed: $error');
          debugPrintStack(stackTrace: stackTrace);
        },
      );

      _isTapHandlerReady = true;
    } catch (e, stackTrace) {
      debugPrint('NotificationService tap setup failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Map<String, dynamic>? _decodePayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return null;

      return decoded.map((key, value) => MapEntry(key.toString(), value));
    } catch (e) {
      debugPrint('NotificationService invalid notification payload: $e');
      return null;
    }
  }

  static void _handleNotificationData(
    Map<String, dynamic> data, {
    bool allowNavigation = true,
  }) {
    if (data.isEmpty) {
      debugPrint('Notification tap had no payload data.');
      return;
    }

    debugPrint('Notification tap data: $data');
    if (!allowNavigation) return;

    _navigateFromNotificationData(data);
  }

  static void _navigateFromNotificationData(Map<String, dynamic> data) {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('Notification navigation skipped: no signed-in user.');
        return;
      }

      final screen = _stringFromData(data['screen']);
      if (screen != 'receive') {
        debugPrint('Notification navigation skipped for screen: $screen');
        return;
      }

      final navigator = navigatorKey.currentState;
      if (navigator == null) {
        debugPrint('Notification navigation skipped: navigator unavailable.');
        return;
      }

      navigator.pushReplacementNamed(AppRoutes.receipts);
    } catch (e, stackTrace) {
      debugPrint('NotificationService navigation failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static Future<void> _saveToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userSnapshot.data();
      if (userData == null) return;

      final organizationId = _organizationIdFrom(userData['organization_id']);
      if (organizationId == null) return;

      final tokenDoc = FirebaseFirestore.instance
          .collection('fcm_tokens')
          .doc(_safeTokenDocId(token));
      final tokenSnapshot = await tokenDoc.get();

      final data = <String, Object?>{
        'token': token,
        'uid': user.uid,
        'organization_id': organizationId,
        'platform': _platformName,
        'is_active': true,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (!tokenSnapshot.exists) {
        data['created_at'] = FieldValue.serverTimestamp();
      }

      await tokenDoc.set(data, SetOptions(merge: true));
    } catch (e, stackTrace) {
      debugPrint('NotificationService._saveToken failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static String? _organizationIdFrom(Object? value) {
    if (value is! String) return null;

    final organizationId = value.trim();
    return organizationId.isEmpty ? null : organizationId;
  }

  static String? _stringFromData(Object? value) {
    if (value == null) return null;

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _notificationIdFor(RemoteMessage message) {
    final messageId = message.messageId;
    if (messageId != null && messageId.isNotEmpty) {
      return messageId.hashCode & 0x7fffffff;
    }

    return DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff);
  }

  static bool get _isSupportedPlatform {
    if (kIsWeb) return false;

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static String get _platformName {
    if (kIsWeb) return 'unknown';

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
  }

  static String _safeTokenDocId(String token) {
    return base64UrlEncode(utf8.encode(token)).replaceAll('=', '');
  }
}
