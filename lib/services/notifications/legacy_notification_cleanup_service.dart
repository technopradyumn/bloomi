import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationCleanupService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> cancelPreviouslyScheduledNotifications() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: settings);
    await _plugin.cancelAll();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      for (final channelId in [
        'bloomi_reminders',
        'bloomi_milestones',
        'bloomi_channel_hydration_v2',
        'bloomi_channel_steps_v2',
        'bloomi_channel_heart_rate_v2',
        'bloomi_channel_sleep_v2',
        'bloomi_channel_calories_v2',
        'bloomi_channel_blood_oxygen_v2',
        'bloomi_channel_weight_v2',
        'bloomi_channel_blood_pressure_v2',
        'bloomi_channel_nutrition_v2',
        'bloomi_channel_milestones_v2',
        'bloomi_channel_daily_plan_v2',
      ]) {
        await android.deleteNotificationChannel(channelId: channelId);
      }
    }
  }
}
