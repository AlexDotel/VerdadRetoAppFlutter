import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'app_language.dart';

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  NotificationDetails get _details => NotificationDetails(
    android: AndroidNotificationDetails(
      'weekend_game_reminders',
      deviceLanguageCode() == 'es'
          ? 'Recordatorios para jugar'
          : 'Game reminders',
      channelDescription: deviceLanguageCode() == 'es'
          ? 'Invitaciones para volver a jugar Verdad o Reto'
          : 'Invitations to play Truth or Dare again',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    ),
  );

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // UTC remains a safe fallback until the next app launch.
    }
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/impostor_launcher'),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    return await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        true;
  }

  Future<bool> showTestNotification() async {
    final allowed = await requestPermission();
    if (!allowed) return false;
    await _plugin.show(
      id: 900,
      title: deviceLanguageCode() == 'es' ? 'Verdad o Reto' : 'Truth or Dare',
      body: deviceLanguageCode() == 'es'
          ? '¿Listos para jugar? Esta es una notificación de prueba.'
          : 'Ready to play? This is a test notification.',
      notificationDetails: _details,
    );
    return true;
  }

  Future<void> scheduleReminders() async {
    await initialize();
    await cancelReminders();
    const schedules = <(int, int, int)>[
      (101, DateTime.monday, 0),
      (102, DateTime.monday, 20),
      (103, DateTime.tuesday, 20),
      (104, DateTime.wednesday, 20),
      (105, DateTime.thursday, 20),
      (106, DateTime.friday, 20),
      (107, DateTime.saturday, 20),
      (108, DateTime.saturday, 22),
      (109, DateTime.sunday, 0),
      (110, DateTime.sunday, 20),
      (111, DateTime.sunday, 22),
    ];
    final bodies = deviceLanguageCode() == 'es'
        ? const [
            '¿Una verdad o un reto? Reúne al grupo y que empiece la partida.',
            'La noche está para buenas historias. ¿Jugamos?',
            'Tu próxima anécdota puede empezar con una tarjeta.',
          ]
        : const [
            'Truth or dare? Gather the group and let the game begin.',
            'Tonight is made for great stories. Shall we play?',
            'Your next great story could begin with a card.',
          ];
    for (var index = 0; index < schedules.length; index++) {
      final (id, weekday, hour) = schedules[index];
      await _plugin.zonedSchedule(
        id: id,
        title: deviceLanguageCode() == 'es' ? 'Verdad o Reto' : 'Truth or Dare',
        body: bodies[index % bodies.length],
        scheduledDate: _nextWeekdayTime(weekday, hour),
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  tz.TZDateTime _nextWeekdayTime(int weekday, int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    while (scheduled.weekday != weekday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelReminders() async {
    for (var id = 101; id <= 111; id++) {
      await _plugin.cancel(id: id);
    }
  }
}
