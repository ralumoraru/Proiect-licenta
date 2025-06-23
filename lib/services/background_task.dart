import 'dart:convert';
import 'package:flight_ticket_checker/main.dart';
import 'package:flight_ticket_checker/models/BestFlights.dart';
import 'package:flight_ticket_checker/models/Flight.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_pair_builder.dart';
import 'package:flight_ticket_checker/views/flight_search/flight_search_page.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

Future<void> checkAndSendMatchingPrice({
  required int searchHistoryId,
  required String departureId,
  required String destinationId,
  required String formattedDepartureDate,
  String? formattedReturnDate,
  required int isReturnFlight,
  required String expectedDepartureDate,
  required String expectedArrivalDepartureDate,
  String? expectedReturnDate,
  String? expectedArrivalReturnDate,
  String? currency,
}) async
{
  print("Is return flight: $isReturnFlight");
  final now = DateTime.now();
  final depDate = DateTime.tryParse(formattedDepartureDate);
  if (depDate == null) {
    print("Data plecării nu e validă: $formattedDepartureDate. Oprire task.");
    await cancelTask(searchHistoryId);
    return;
  }

  if (depDate.isBefore(now)) {
    print("Data plecării $depDate a trecut deja. Oprire task pentru searchHistoryId $searchHistoryId.");
    await cancelTask(searchHistoryId);
    return;
  }

  if (currency == null) {
    final prefs = await SharedPreferences.getInstance();
    currency = prefs.getString('currency') ?? 'RON';
  }

  FlightSearchService flightSearchService = FlightSearchService();
  List<BestFlight> itineraries = await flightSearchService.searchFlights(
    from: departureId,
    to: destinationId,
    departureDate: formattedDepartureDate,
    returnDate: formattedReturnDate,
    type: isReturnFlight,
    currency: currency,
  );

  FlightPairBuilder pairBuilder = FlightPairBuilder(itineraries);
  List<Map<String, dynamic>> flightPairs = pairBuilder.buildFlightPairs();

  final expectedDepTime = DateTime.parse(expectedDepartureDate);
  print('expectedArrivalDepartureDate = $expectedArrivalDepartureDate');
  final expectedArrDepTime = DateTime.parse(expectedArrivalDepartureDate);
  final DateTime? expectedRetTime = (expectedReturnDate != null && expectedReturnDate.isNotEmpty)
      ? DateTime.parse(expectedReturnDate)
      : null;

  final DateTime? expectedArrRetTime = (expectedArrivalReturnDate != null && expectedArrivalReturnDate.isNotEmpty)
      ? DateTime.parse(expectedArrivalReturnDate)
      : null;

  for (var pair in flightPairs) {
    final outbound = pair['outboundFlight'] as BestFlight;
    final returnSet = pair['returnFlight'] as List<Flight>?;

    final depTime = DateTime.parse(outbound.flights.first.departureAirport.time);
    final arrDepTime = DateTime.parse(outbound.flights.last.arrivalAirport.time);

    final isDepartureMatch = depTime.isAtSameMomentAs(expectedDepTime);
    final isArrivalDepMatch = arrDepTime.isAtSameMomentAs(expectedArrDepTime);

    bool isReturnMatch = true;

    if (expectedRetTime != null && expectedArrRetTime != null && returnSet != null && returnSet.isNotEmpty) {
      final retDepTime = DateTime.parse(returnSet.first.departureAirport.time);
      final arrRetTime = DateTime.parse(returnSet.last.arrivalAirport.time);

      isReturnMatch = retDepTime.isAtSameMomentAs(expectedRetTime) &&
          arrRetTime.isAtSameMomentAs(expectedArrRetTime);
    }


    if (isDepartureMatch && isArrivalDepMatch && isReturnMatch) {
      print('SUCCESS: S-a găsit o potrivire de zbor!');

      final originalPrice = returnSet != null && returnSet.isNotEmpty
          ? returnSet.first.price
          : outbound.flights.first.price;

      final price = originalPrice - 10;
      print('INFO: Preț original: $originalPrice, Preț modificat (-10): $price');


      final lastKnownPrice = await fetchLastKnownPriceFromBackend(searchHistoryId.toString());

      if (lastKnownPrice != null) {
        if (price < lastKnownPrice) {
          print('INFO: Preț redus! $price (anterior $lastKnownPrice). Se trimite notificare.');
          await showNotification('Preț redus!', 'Zborul tău urmărit costă acum $price $currency (a scăzut de la $lastKnownPrice $currency)');
        } else if (price > lastKnownPrice) {
          print('INFO: Preț crescut! $price (anterior $lastKnownPrice). Se trimite notificare.');
          await showNotification('Preț crescut', 'Zborul tău urmărit costă acum $price $currency (a crescut de la $lastKnownPrice $currency)');
        } else {
          print('INFO: Prețul ($price) nu este mai mic decât ultimul preț cunoscut ($lastKnownPrice).');
        }
      } else {
        print('INFO: Primul preț găsit: $price. Nu există istoric pentru a compara.');
      }


      await sendPricesToBackend(
        searchHistoryId: searchHistoryId,
        price: price,
      );
      break;
    }
  }
}

Future<void> showNotification(String title, String body) async {
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'flight_channel',
        'Flight Alerts',
        channelDescription: 'Notificări când se schimbă prețul la zboruri',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
      ),
    ),
  );
}

// Funcție auxiliară pentru anularea task-ului
Future<void> cancelTask(int searchHistoryId) async {
  final prefs = await SharedPreferences.getInstance();
  final taskName = prefs.getString('lastTaskName_$searchHistoryId');

  if (taskName != null) {
    await Workmanager().cancelByUniqueName(taskName);
    print('Canceled task: $taskName');
  } else {
    print('No task name found for searchHistoryId $searchHistoryId');
  }
}


Future<int?> fetchLastKnownPriceFromBackend(String searchHistoryId) async {
  final url = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/search-history/last-price/$searchHistoryId');

  final response = await http.get(url, headers: {
    'Accept': 'application/json',
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final dynamic price = data['price'];
    if (price == null) {
      print("Eroare: 'price' este null în răspunsul de la backend pentru searchHistoryId $searchHistoryId");
      return null;
    } else if (price is int) {
      return price;
    } else if (price is String || price is double) {
      try {
        final parsedDouble = double.parse(price.toString());
        return parsedDouble.round(); // sau .floor() dacă vrei întotdeauna în jos
      } catch (e) {
        print("Eroare la conversia 'price' în double: $price");
        return null;
      }
    }
    else {
      print("Eroare: tip necunoscut pentru 'price': ${price.runtimeType}");
      return null;
    }
  } else if (response.statusCode == 404) {
    final prefs = await SharedPreferences.getInstance();
    final taskName = prefs.getString('taskName_$searchHistoryId');
    if (taskName != null) {
      Workmanager().cancelByUniqueName('checkAndSendMatchingPriceTask');
      print("Task-ul $taskName a fost oprit deoarece searchHistoryId $searchHistoryId nu mai există.");
    }
    return null;
  } else {
    print("Eroare la obținerea ultimului preț: ${response.statusCode}");
    return null;
  }
}

Future<void> sendPricesToBackend({
  required int searchHistoryId,
  required int price,
}) async
{
  final url = Uri.parse('https://viable-flamingo-advanced.ngrok-free.app/api/search-history/prices');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    body: jsonEncode({
      'search_history_id': searchHistoryId,
      'prices': [
        {
          'price': price,
        }
      ],
    }),
  );

  if (response.statusCode == 200 || response.statusCode == 201) {
    print("Price saved successfully for search history ID $searchHistoryId");
  } else if (response.statusCode == 422) {
    print("Search history ID invalid. Oprirea task-ului...");

    final prefs = await SharedPreferences.getInstance();
    final taskName = prefs.getString('taskName_$searchHistoryId');
    if (taskName != null) {
      await Workmanager().cancelByUniqueName(taskName);
      print("Task-ul $taskName a fost oprit deoarece ID-ul $searchHistoryId este invalid.");
    }
  } else {
    print("Failed to save price: ${response.statusCode} - ${response.body}");
  }
}

Future<String> generateUniqueTaskName(int searchHistoryId) async {
  final prefs = await SharedPreferences.getInstance();
  final keyCounter = 'taskCounter_$searchHistoryId';
  int currentCounter = prefs.getInt(keyCounter) ?? 0;

  currentCounter++;
  await prefs.setInt(keyCounter, currentCounter);

  final taskName = 'checkAndSendMatchingPriceTask_${searchHistoryId}_$currentCounter';
  await prefs.setString('taskName_${searchHistoryId}_$currentCounter', taskName);

  return taskName;
}



