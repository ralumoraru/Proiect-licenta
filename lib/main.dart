import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'views/auth/login_page.dart';
import 'views/auth/signup_page.dart';
import 'views/home/navigation_bar.dart';
import 'services/background_task.dart';
import 'package:flight_ticket_checker/services/currency_provider.dart'; // <-- Import nou
import 'package:provider/provider.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  try {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
  } catch (e) {
    print('Error initializing Workmanager: $e');
  }

  runApp(const MyAppWrapper());
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('Task started: $task');

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);

    if (inputData == null) {
      print('Input data is null');
      return Future.value(false);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final currency = prefs.getString('currency') ?? 'RON';

      await checkAndSendMatchingPrice(
        searchHistoryId: inputData['searchHistoryId'],
        departureId: inputData['departureId'],
        destinationId: inputData['destinationId'],
        formattedDepartureDate: inputData['formattedDepartureDate'],
        formattedReturnDate: inputData['formattedReturnDate'] ?? "",
        isReturnFlight: inputData['isReturnFlight'] ?? false,
        expectedDepartureDate: inputData['expectedDepartureDate'],
        expectedArrivalDepartureDate: inputData['expectedArrivalDepartureDate'],
        expectedReturnDate: inputData['expectedReturnDate'] ?? "",
        expectedArrivalReturnDate: inputData['expectedArrivalReturnDate'] ?? "",
        currency: currency,
      );
    } catch (e, stack) {
      print("Eroare în worker: $e");
      print(stack);
      return Future.value(false);
    }

    print('Task completed: $task');
    return Future.value(true);
  });
}

class MyAppWrapper extends StatefulWidget {
  const MyAppWrapper({Key? key}) : super(key: key);

  @override
  State<MyAppWrapper> createState() => _MyAppWrapperState();
}

class _MyAppWrapperState extends State<MyAppWrapper> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications().then((_) async {
      await _requestNotificationPermission();
    });
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _requestNotificationPermission() async {
    if (await Permission.notification.isDenied) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        print('Notification permission denied');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CurrencyProvider()),
      ],
      child: const MyApp(),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flight Ticket Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/sign-up': (context) => const SignUpPage(),
        '/home': (context) => AppNavigationBar(),
      },
    );
  }
}
