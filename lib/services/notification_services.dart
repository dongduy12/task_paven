import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '/models/task.dart';
import '/ui/pages/notification_screen.dart';
import 'package:flutter/services.dart';

class NotifyHelper {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  String selectedNotificationPayload = '';

  final BehaviorSubject<String> selectNotificationSubject =
      BehaviorSubject<String>();

  initializeNotification() async {
    tz.initializeTimeZones();
    _configureSelectNotificationSubject();
    await _configureLocalTimeZone();
    // await requestIOSPermissions(flutterLocalNotificationsPlugin);
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: false,
      requestBadgePermission: false,
      requestAlertPermission: false
    );

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(
      iOS: initializationSettingsIOS,
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse? payload) async {
        if (payload != null) {
          debugPrint('notification payload: $payload');
        }
        selectNotificationSubject.add(payload.toString());
      },
    );
  }

  displayNotification({required String title, required String body}) async {
    print('doing test');
    var androidPlatformChannelSpecifics = const AndroidNotificationDetails(
        'your channel id', 'your channel name',
        channelDescription: 'your channel description',
        importance: Importance.max,
        priority: Priority.high);
    var iOSPlatformChannelSpecifics = const DarwinNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: 'Default_Sound',
    );
  }

  cancelNotification(Task task) async {
    await flutterLocalNotificationsPlugin.cancel(task.id!);
    await flutterLocalNotificationsPlugin.cancel(_endNotificationId(task.id!));
    print('Notification is canceled');
  }

  cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print('Notification is canceled');
  }

  Future<void> scheduleTaskNotifications(Task task) async {
    if (task.id == null || task.date == null || task.startTime == null) {
      return;
    }

    final remindMinutes = task.remind ?? 0;
    final repeat = task.repeat ?? 'None';
    final parsedDate = DateFormat.yMd().parse(task.date!);
    final startDateTime = _combineDateAndTime(parsedDate, task.startTime!);
    final endDateTime =
        task.endTime != null ? _combineDateAndTime(parsedDate, task.endTime!) : null;

    await _scheduleNotification(
      id: task.id!,
      title: task.title ?? 'Nhiệm vụ',
      body: task.note ?? 'Đã đến lúc thực hiện nhiệm vụ của bạn.',
      scheduledDate: startDateTime,
      remindMinutes: remindMinutes,
      repeat: repeat,
    );

    if (endDateTime != null && endDateTime.isAfter(startDateTime)) {
      await _scheduleNotification(
        id: _endNotificationId(task.id!),
        title: 'Sắp hết thời gian: ${task.title ?? 'Nhiệm vụ'}',
        body: task.note ?? 'Kiểm tra tiến độ để kết thúc đúng hạn.',
        scheduledDate: endDateTime,
        remindMinutes: remindMinutes,
        repeat: repeat,
      );
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required int remindMinutes,
    required String repeat,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      _nextInstance(
          scheduledDate.hour, scheduledDate.minute, remindMinutes, repeat, scheduledDate),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'your channel id',
          'your channel name',
          channelDescription: 'your channel description',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: '$title|$body|${DateFormat.Hm().format(scheduledDate)}|',
    );
  }

  tz.TZDateTime _nextInstance(int hour, int minutes, int remind, String repeat,
      DateTime scheduledDate) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);

    final tz.TZDateTime targetDateTime = tz.TZDateTime(
      tz.local,
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
      hour,
      minutes,
    );

    var adjustedDate = afterRemind(remind, targetDateTime);

    if (adjustedDate.isBefore(now)) {
      if (repeat == 'Daily') {
        adjustedDate = adjustedDate.add(const Duration(days: 1));
      } else if (repeat == 'Weekly') {
        adjustedDate = adjustedDate.add(const Duration(days: 7));
      } else if (repeat == 'Monthly') {
        adjustedDate = tz.TZDateTime(tz.local, adjustedDate.year,
            adjustedDate.month + 1, adjustedDate.day, adjustedDate.hour,
            adjustedDate.minute);
      }
    }

    print('Next scheduledDate = $adjustedDate');
    return adjustedDate;
  }

  DateTime _combineDateAndTime(DateTime date, String rawTime) {
    try {
      final parsedTime = DateFormat.jm().parse(rawTime);
      return DateTime(
        date.year,
        date.month,
        date.day,
        parsedTime.hour,
        parsedTime.minute,
      );
    } catch (_) {
      return DateTime(date.year, date.month, date.day, 9, 0);
    }
  }

  int _endNotificationId(int taskId) => taskId * 1000 + 1;

  tz.TZDateTime afterRemind(int remind, tz.TZDateTime scheduledDate) {
    if (remind == 5) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 5));
    }
    if (remind == 10) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 10));
    }
    if (remind == 15) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 15));
    }
    if (remind == 20) {
      scheduledDate = scheduledDate.subtract(const Duration(minutes: 20));
    }
    return scheduledDate;
  }

  void requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  Future<void> _configureLocalTimeZone() async {
    tz.initializeTimeZones();
    const channel = MethodChannel('task_paven/timezone');
    final String timeZoneName =
        await channel.invokeMethod<String>('getLocalTimezone') ?? 'Etc/UTC';
    tz.setLocalLocation(tz.getLocation(timeZoneName));
  }

/*   Future selectNotification(String? payload) async {
    if (payload != null) {
      //selectedNotificationPayload = "The best";
      selectNotificationSubject.add(payload);
      print('notification payload: $payload');
    } else {
      print("Notification Done");
    }
    Get.to(() => SecondScreen(selectedNotificationPayload));
  } */

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      debugPrint('My payload is $payload');
      await Get.to(() => const NotificationScreen(payload: ''));
    });
  }
}
