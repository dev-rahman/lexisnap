import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../localization/locale_keys.dart';
import '../../utils/study_day.dart';
import '../streak/streak_service.dart';

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
  static const _testNotificationId = 1002;
  static const _channelId = 'study_reminders';

  final _plugin = FlutterLocalNotificationsPlugin();

  final isEnabled = false.obs;
  final time = Rx<TimeOfDay>(defaultTime);

  Worker? _studyWorker;

  bool get _isSupported => Platform.isAndroid || Platform.isIOS;

  Future<StudyReminderService> init() async {
    final prefs = await SharedPreferences.getInstance();
    isEnabled.value = prefs.getBool(_enabledKey) ?? false;
    time.value = TimeOfDay(
      hour: prefs.getInt(_hourKey) ?? defaultTime.hour,
      minute: prefs.getInt(_minuteKey) ?? defaultTime.minute,
    );

    if (!_isSupported) return this;

    // Initialize the plugin FIRST, before the timezone step, so a
    // notification can always be posted even if the timezone (needed only
    // for scheduling) can't be resolved. Previously a timezone failure
    // returned early and left the plugin uninitialized, which silently broke
    // notifications entirely.
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

    tz_data.initializeTimeZones();
    try {
      final localZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localZone.identifier));
    } catch (_) {
      // Unknown/unavailable zone: scheduling would fire at the wrong local
      // hour, so keep the reminder off. The plugin is up, so the test
      // notification still works and can show that.
      isEnabled.value = false;
      return this;
    }

    // Re-arm on launch: an OS update or reboot can drop pending alarms.
    if (isEnabled.value) await _schedule(time.value);
    _watchStudy();
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
    return await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        false;
  }

  Future<void> _schedule(TimeOfDay at) async {
    await _plugin.zonedSchedule(
      id: _notificationId,
      title: LocaleKeys.reminderNotificationTitle.tr,
      body: LocaleKeys.reminderNotificationBody.tr,
      scheduledDate: _nextOccurrenceOf(at),
      notificationDetails: _details(),
      // alarmClock mode uses AlarmManager.setAlarmClock, the highest-priority
      // alarm: it fires at the exact minute, wakes the device from Doze, and
      // aggressive OEM battery managers (ColorOS, MIUI) honour it instead of
      // batching it like ordinary exact alarms. The trade-off is a small
      // "alarm set" indicator in the status bar, which is worth it for a
      // reminder that actually arrives on time.
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  NotificationDetails _details() => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      LocaleKeys.reminderChannelName.tr,
      channelDescription: LocaleKeys.reminderChannelDescription.tr,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
    iOS: const DarwinNotificationDetails(),
  );

  /// Diagnostic for "my reminder never fired". Posts a notification right now
  /// through the exact same channel the reminder uses, and reports whether
  /// the system allows notifications and whether a reminder is actually
  /// scheduled. If the notification appears, the pipeline works and the
  /// problem is delivery of the scheduled alarm (usually the OEM killing the
  /// app); if it doesn't, notifications are blocked or permission is off.
  Future<String> sendTestNotification() async {
    if (!_isSupported) return 'Not supported on this platform.';

    try {
      final granted = await _requestPermission();

      bool? systemAllowed;
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        systemAllowed = await android?.areNotificationsEnabled();
      }

      await _plugin.show(
        id: _testNotificationId,
        title: LocaleKeys.reminderNotificationTitle.tr,
        body: LocaleKeys.reminderTestBody.tr,
        notificationDetails: _details(),
      );

      final pending = await _plugin.pendingNotificationRequests();
      final reminderScheduled = pending.any((p) => p.id == _notificationId);

      return 'permission granted=$granted, system allowed=$systemAllowed, '
          'reminder scheduled=$reminderScheduled, pending=${pending.length}';
    } catch (e) {
      // Surface the failure instead of the button doing nothing.
      return 'error: $e';
    }
  }

  /// When the reminder should next fire: the next [at] that is still ahead
  /// *and* falls in a study day the user hasn't already studied in.
  ///
  /// The notification repeats daily from whatever date it is first
  /// scheduled for, so skipping today is a matter of starting tomorrow. It
  /// used to start on the next [at] unconditionally, which meant studying
  /// at 8am still earned a "time to study" at 7:30pm - a nudge for
  /// something already done, and the fastest way to teach someone to
  /// swipe every notification away unread.
  tz.TZDateTime _nextOccurrenceOf(TimeOfDay at) {
    final now = tz.TZDateTime.now(tz.local);
    // Built from calendar components rather than by adding a 24-hour
    // Duration, which would land an hour off across a daylight-saving
    // change.
    tz.TZDateTime onDay(int dayOffset) => tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + dayOffset,
      at.hour,
      at.minute,
    );

    var offset = onDay(0).isAfter(now) ? 0 : 1;
    final lastStudied = Get.find<StreakService>().streak.value.lastStudiedAt;
    if (lastStudied != null &&
        studyDaysBetween(lastStudied, onDay(offset)) == 0) {
      offset++;
    }
    return onDay(offset);
  }

  /// Re-arms the reminder the first time the user studies in a study day,
  /// so today's occurrence is dropped as soon as there's nothing to remind
  /// them of. Reviews are recorded per card; only the first one in a day
  /// changes anything, so the rest are ignored.
  void _watchStudy() {
    final streak = Get.find<StreakService>().streak;
    DateTime? armedFor = streak.value.lastStudiedAt == null
        ? null
        : studyDayStart(streak.value.lastStudiedAt!);

    _studyWorker?.dispose();
    _studyWorker = ever<StudyStreak>(streak, (s) {
      final studied = s.lastStudiedAt;
      if (studied == null || !isEnabled.value) return;

      final day = studyDayStart(studied);
      if (armedFor != null && day.isAtSameMomentAs(armedFor!)) return;
      armedFor = day;
      _schedule(time.value);
    });
  }

  @override
  void onClose() {
    _studyWorker?.dispose();
    super.onClose();
  }
}
