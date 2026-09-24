import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../localization/locale_keys.dart';

/// Schedules the one daily notification that asks the user to come back.
///
/// Spaced repetition only pays off if the session actually happens, and
/// remembering to open the app is the highest-effort part of the whole
/// loop - so it is the part worth automating. One reminder a day, at a
/// time the user picks, and nothing else.
class StudyReminderService extends GetxService {
  static const defaultTime = TimeOfDay(hour: 19, minute: 30);

  static const _enabledKey = 'study_reminder_enabled';
  static const _hourKey = 'study_reminder_hour';
  static const _minuteKey = 'study_reminder_minute';
  static const _notificationId = 1001;
  static const _channelId = 'study_reminders';

  final _plugin = FlutterLocalNotificationsPlugin();

  final isEnabled = false.obs;
  final time = Rx<TimeOfDay>(defaultTime);

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  Future<StudyReminderService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_enabledKey) ?? false;
    time.value = TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? defaultTime.hour,
      minute: prefs.getInt(_minuteKey) ?? defaultTime.minute,
    );

    if (!_isSupported) return this;

    tz_data.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (_) {
      // Unknown/unavailable zone: timezone defaults to UTC, which would
      // fire the reminder at the wrong local hour. Better to leave the
      // reminder unscheduled than to nag at 3am.
      isEnabled.value = false;
      return this;
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Asked for explicitly when the user turns the reminder on, so
          // the OS prompt arrives with context instead of at cold start.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    // Re-arm on launch: an OS update or reboot can drop pending alarms.
    if (isEnabled.value) await _schedule(time.value);
    return this;
  }

  /// Turns the daily reminder on at [at], prompting for notification
  /// permission if it hasn't been granted. Returns false when the user
  /// declines, leaving the reminder off.
  Future<bool> enable({TimeOfDay? at}) async {
    if (!_isSupported) return false;

    final granted = await _requestPermission();
    if (!granted) return false;

    final scheduledTime = at ?? time.value;
    await _schedule(scheduledTime);

    isEnabled.value = true;
    time.value = scheduledTime;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, true);
    await prefs.setInt(_hourKey, scheduledTime.hour);
    await prefs.setInt(_minuteKey, scheduledTime.minute);
    return true;
  }

  Future<void> disable() async {
    if (_isSupported) await _plugin.cancel(id: _notificationId);
    isEnabled.value = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, false);
  }

  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
  }

  Future<void> _schedule(TimeOfDay at) async {
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: LocaleKeys.reminderNotificationTitle.tr,
      body: LocaleKeys.reminderNotificationBody.tr,
      scheduledDate: _nextOccurrenceOf(at),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          LocaleKeys.reminderChannelName.tr,
          channelDescription: LocaleKeys.reminderChannelDescription.tr,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Inexact delivery avoids needing the SCHEDULE_EXACT_ALARM
      // permission; a study nudge a few minutes late is no worse.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  tz.TZDateTime _nextOccurrenceOf(TimeOfDay at) {
    final now = tz.TZDateTime.now(tz.local);
    final today = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      at.hour,
      at.minute,
    );
    return today.isAfter(now) ? today : today.add(const Duration(days: 1));
  }
}
