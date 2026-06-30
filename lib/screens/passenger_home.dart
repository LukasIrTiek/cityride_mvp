import 'dart:async';
import 'dart:convert';
import 'package:cityride_mvp/screens/profile_page.dart';
import 'package:geolocator/geolocator.dart';
import 'history_page.dart';
import 'payments_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants.dart';
import '../services/payment_service.dart';
import 'ride_status_page.dart';

class PassengerHome extends StatefulWidget {

  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() =>
      _PassengerHomeState();
}

class _PassengerHomeState
    extends State<PassengerHome> {

  final supabase =
      Supabase.instance.client;

  final pickupController =
  TextEditingController();

  final destinationController =
  TextEditingController();

  String estimatedEta = '';

  double estimatedPrice = 0;
  String estimatedDistance = '';

  double? pickupLat;
  double? pickupLng;

  double? destinationLat;
  double? destinationLng;

  GoogleMapController?
  mapController;

  Set<Marker> markers = {};

  BitmapDescriptor?
  carIcon;

  Timer?
  driverRefreshTimer;

  List<String> recentLocations = [];

  @override
  void initState() {

    super.initState();

    _checkActiveRide();

    loadCarIcon();

    loadDrivers();

    loadRecentLocations();

    driverRefreshTimer =
        Timer.periodic(

          const Duration(
            seconds: 3,
          ),

              (_) async {

            await loadDrivers();
          },
        );
  }

  Future<void> _checkActiveRide() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('rides')
          .select('id, status')
          .eq('passenger_id', user.id)
          .neq('status', 'completed')
          .neq('status', 'cancelled')
          .maybeSingle();

      if (response != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RideStatusPage(rideId: response['id']),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error checking active ride: $e');
    }
  }

  Future<void> requestLocationPermission() async {

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {

      permission =
      await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.deniedForever) {
      return;
    }

    final position =
    await Geolocator
        .getCurrentPosition();

    mapController?.animateCamera(

      CameraUpdate.newLatLng(

        LatLng(

          position.latitude,
          position.longitude,
        ),
      ),
    );
  }

  Future<void> loadCarIcon() async {

    carIcon =
    await BitmapDescriptor.asset(

      const ImageConfiguration(

        size: Size(48, 48),
      ),

      'lib/assets/car.png',
    );

    setState(() {});
  }

  Future<void> loadDrivers() async {
    final drivers =
    await supabase
        .from('drivers')
        .select()
        .eq('online', true);

    final Set<Marker>
    loadedMarkers = {};

    for (final driver in drivers) {
      final lat = driver['lat'];
      final lng = driver['lng'];

      if (lat == null || lng == null) {
        continue;
      }

      loadedMarkers.add(
        Marker(
          markerId: MarkerId(driver['id'].toString()),
          position: LatLng(lat, lng),
          icon: carIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      markers = loadedMarkers;
    });
  }

  Future<void> _useCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=${position.latitude},${position.longitude}&key=$googleApiKey';
      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (data['results'].isNotEmpty) {
        final address = data['results'][0]['formatted_address'];
        pickupController.text = address;
        pickupLat = position.latitude;
        pickupLng = position.longitude;
        _updateMarkersAndBounds();
        await calculateRealEta();
      }
    } catch (e) {
      debugPrint('Klaida nustatant vietą: $e');
    }
  }

  Future<void> loadRecentLocations() async {
    try {
      final response = await supabase
          .from('rides')
          .select('destination_address')
          .eq('passenger_id', supabase.auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(5);

      if (!mounted) return;
      setState(() {
        recentLocations = (response as List)
            .map((e) => e['destination_address'].toString())
            .toSet()
            .toList();
      });
    } catch (_) {}
  }

  void _updateMarkersAndBounds() {
    markers.removeWhere((m) => m.markerId.value == 'pickup' || m.markerId.value == 'destination');

    if (pickupLat != null && pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(pickupLat!, pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    if (destinationLat != null && destinationLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(destinationLat!, destinationLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (pickupLat != null && destinationLat != null) {
      double minLat = pickupLat! < destinationLat! ? pickupLat! : destinationLat!;
      double maxLat = pickupLat! > destinationLat! ? pickupLat! : destinationLat!;
      double minLng = pickupLng! < destinationLng! ? pickupLng! : destinationLng!;
      double maxLng = pickupLng! > destinationLng! ? pickupLng! : destinationLng!;

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
      mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } else if (pickupLat != null) {
      mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pickupLat!, pickupLng!), 15));
    }
  }

  Widget _buildQuickAction(IconData icon, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.black87, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<List<String>> searchPlaces(
      String query,
      ) async {

    if (query.isEmpty) {
      return [];
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        '?input=$query'
        '&key=$googleApiKey';

    final response =
    await http.get(
      Uri.parse(url),
    );

    final data =
    jsonDecode(response.body);

    final predictions =
    data['predictions'] as List;

    return predictions
        .map(
          (e) => e['description']
          .toString(),
    )
        .toList();
  }

  Future<void> getPickupCoordinates(
      String address,
      ) async {

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=$googleApiKey';

    final response =
    await http.get(
      Uri.parse(url),
    );

    final data =
    jsonDecode(response.body);

    if (data['results']
        .isEmpty) {
      return;
    }

    final location =
    data['results'][0]
    ['geometry']['location'];

    pickupLat =
    location['lat'];

    pickupLng =
    location['lng'];
  }

  Future<void> getDestinationCoordinates(
      String address,
      ) async {

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(address)}'
        '&key=$googleApiKey';

    final response =
    await http.get(
      Uri.parse(url),
    );

    final data =
    jsonDecode(response.body);

    if (data['results']
        .isEmpty) {
      return;
    }

    final location =
    data['results'][0]
    ['geometry']['location'];

    destinationLat =
    location['lat'];

    destinationLng =
    location['lng'];
  }


  Future<void> calculateRealEta() async {

    if (pickupLat == null ||
        pickupLng == null) {

      estimatedEta =
      'Nepavyko rasti lokacijos';

      setState(() {});

      return;
    }

    final drivers =
    await supabase
        .from('drivers')
        .select()
        .eq('online', true);

    final validDrivers =
    drivers.where((driver) {

      return driver['lat'] != null &&
          driver['lng'] != null;
    }).toList();

    if (validDrivers.isEmpty) {

      estimatedEta =
      'Nėra laisvų vairuotojų';

      setState(() {});

      return;
    }

    final driver =
        validDrivers.first;

    final driverLat =
    driver['lat'];

    final driverLng =
    driver['lng'];

    final url =
        'https://maps.googleapis.com/maps/api/distancematrix/json'
        '?origins=$driverLat,$driverLng'
        '&destinations=$pickupLat,$pickupLng'
        '&key=$googleApiKey';

    final response =
    await http.get(
      Uri.parse(url),
    );

    final data =
    jsonDecode(response.body);

    if (data['rows'] == null ||
        data['rows'].isEmpty ||
        data['rows'][0]['elements'] == null ||
        data['rows'][0]['elements'].isEmpty ||
        data['rows'][0]['elements'][0]['status'] != 'OK') {

      estimatedEta =
      'Nepavyko apskaičiuoti ETA';

      setState(() {});

      return;
    }

    final duration =
    data['rows'][0]
    ['elements'][0]
    ['duration']['text'];

    estimatedEta =
        duration;

    setState(() {});
  }

  Future<void> calculatePrice() async {
    if (pickupLat == null ||
        pickupLng == null ||
        destinationLat == null ||
        destinationLng == null) {
      return;
    }

    double distanceKm =
        Geolocator.distanceBetween(
          pickupLat!,
          pickupLng!,
          destinationLat!,
          destinationLng!,
        ) /
            1000;

    // Nauji įkainiai:
    // Minimali kelionė – 3,00 €
    // Įsėdimas – 0,70 €
    // 1 km – 0,55 €
    // 1 min. – 0,15 €
    
    double baseFare = 0.70;
    double perKm = 0.55;
    double perMin = 0.15;
    double minimumFare = 3.00;
    
    // Preliminarus laikas (2 min už 1 km)
    double durationMinutes = distanceKm * 2;

    double price =
        baseFare + (distanceKm * perKm) + (durationMinutes * perMin);

    if (price < minimumFare) {
      price = minimumFare;
    }

    setState(() {
      estimatedPrice = price;
      estimatedDistance =
      '${distanceKm.toStringAsFixed(1)} km';
    });
  }

  Future<void> requestRide() async {

    if (pickupController.text.isEmpty || destinationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Įveskite adresus')));
      return;
    }

    if (pickupLat == null || pickupLng == null || destinationLat == null || destinationLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nepavyko nustatyti adresų koordinačių. Pasirinkite adresą iš sąrašo.')));
      return;
    }

    final onlineDrivers = await supabase.from('drivers').select().eq('online', true);

    final validDrivers =
    onlineDrivers.where((driver) {

      return driver['lat'] != null &&
          driver['lng'] != null;
    }).toList();

    if (validDrivers.isEmpty) {

      ScaffoldMessenger
          .of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            'Nėra laisvų vairuotojų',
          ),
        ),
      );

      return;
    }

    final passengerData =
    await supabase
        .from('passengers')
        .select()
        .eq(
      'id',
      supabase.auth.currentUser!.id,
    )
        .single();

    // Patikriname, ar vartotojas turi pridėtą kortelę
    if (passengerData['card_last4'] == null) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pridėkite kortelę'),
          content: const Text('Norėdami užsisakyti kelionę, pirmiausia pridėkite mokėjimo kortelę.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ATŠAUKTI'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentsPage()),
                );
              },
              child: const Text('PRIDĖTI'),
            ),
          ],
        ),
      );
      return;
    }


    // Patikriname apmokėjimą (Hold funds) prieš užsakant
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.black)),
    );

    final authResult = await PaymentService.preAuthorizePayment(
      amount: estimatedPrice,
      customerEmail: supabase.auth.currentUser!.email!,
    );

    if (context.mounted) Navigator.pop(context); // Nuimame loading

    if (!authResult['success']) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mokėjimo klaida'),
            content: Text(authResult['error'] ?? 'Nepavyko autorizuoti mokėjimo. Patikrinkite kortelės balansą.'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('GERAI'))],
          ),
        );
      }
      return;
    }

    final response = await supabase.from('rides').insert({
      'pickup_address': pickupController.text,
      'destination_address': destinationController.text,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'destination_lat': destinationLat,
      'destination_lng': destinationLng,
      'passenger_id': supabase.auth.currentUser!.id,
      'passenger_name': passengerData['full_name'],
      'passenger_phone': passengerData['phone'],
      'price': estimatedPrice,
      'status': 'searching',
      'rejected_by': [],
      'stripe_payment_intent_id': authResult['paymentIntentId'],
    }).select().single();

    final rideId = response['id'];

    try {
      debugPrint('SENDING PUSH TO CLOSEST DRIVER FOR RIDE: $rideId');

      final notifyResponse = await supabase.functions.invoke(
        'send-ride-notification',
        body: {
          'ride_id': rideId,
          'title': '🚕 Naujas užsakymas',
          'message': '${pickupController.text} → ${destinationController.text}',
          'lat': pickupLat,
          'lng': pickupLng,
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
      );
      
      if (notifyResponse.status != 200 || notifyResponse.data?['error'] != null) {
        debugPrint('FCM ERROR FROM EDGE FUNCTION: ${notifyResponse.data}');
      }

      debugPrint('EDGE FUNCTION CALLED SUCCESSFULLY');
    } catch (e) {
      debugPrint('FCM NOTIFICATION ERROR: $e');
    }

    if (!mounted) return;

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) =>
            RideStatusPage(

              rideId:
              rideId,
            ),
      ),
    );
  }

  @override
  void dispose() {

    driverRefreshTimer
        ?.cancel();

    pickupController.dispose();

    destinationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool hasDrivers = markers.any((m) => m.markerId.value != 'pickup' && m.markerId.value != 'destination');

    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryPage()));
          }
          if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentsPage()));
          }
          if (index == 3) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }
        },
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Pagrindinis'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Istorija'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Mokėjimai'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profilis'),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(target: LatLng(54.8985, 23.9036), zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            onMapCreated: (controller) async {
              mapController = controller;
              await requestLocationPermission();
            },
          ),

          // Current Location Button
          Positioned(
            right: 16,
            bottom: 350,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: () async {
                final position = await Geolocator.getCurrentPosition();
                mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 16));
              },
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (estimatedEta.isNotEmpty && estimatedPrice == 0)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.green, size: 18),
                                const SizedBox(width: 8),
                                Text(estimatedEta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                              ],
                            ),
                          ),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  TypeAheadField<String>(
                                    controller: pickupController,
                                    suggestionsCallback: (search) async => await searchPlaces(search),
                                    emptyBuilder: (context) => ListTile(
                                      leading: const Icon(Icons.my_location, color: Colors.blue),
                                      title: const Text('Kviesti pagal buvimo vietą', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                      onTap: () {
                                        _useCurrentLocation();
                                      },
                                    ),
                                    loadingBuilder: (context) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2))),
                                    builder: (context, controller, focusNode) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.circle, color: Colors.green, size: 14),
                                          hintText: 'Iš kur paimti?',
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      );
                                    },
                                    itemBuilder: (context, suggestion) => ListTile(
                                      leading: const Icon(Icons.location_on_outlined, color: Colors.grey, size: 18),
                                      title: Text(suggestion, style: const TextStyle(fontSize: 13)),
                                      dense: true,
                                    ),
                                    onSelected: (suggestion) async {
                                      pickupController.text = suggestion;
                                      await getPickupCoordinates(suggestion);
                                      _updateMarkersAndBounds();
                                      await calculateRealEta();
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  TypeAheadField<String>(
                                    controller: destinationController,
                                    suggestionsCallback: (search) async => await searchPlaces(search),
                                    emptyBuilder: (context) => const Padding(padding: EdgeInsets.all(16.0), child: Text('Adresų nerasta')),
                                    loadingBuilder: (context) => const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(strokeWidth: 2))),
                                    builder: (context, controller, focusNode) {
                                      return TextField(
                                        controller: controller,
                                        focusNode: focusNode,
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.location_on, color: Colors.red, size: 14),
                                          hintText: 'Kur važiuosite?',
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      );
                                    },
                                    itemBuilder: (context, suggestion) => ListTile(
                                      leading: const Icon(Icons.history, color: Colors.grey, size: 18),
                                      title: Text(suggestion, style: const TextStyle(fontSize: 13)),
                                      dense: true,
                                    ),
                                    onSelected: (suggestion) async {
                                      destinationController.text = suggestion;
                                      await getDestinationCoordinates(suggestion);
                                      _updateMarkersAndBounds();
                                      await calculatePrice();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (estimatedPrice == 0) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildQuickAction(Icons.home_outlined, 'Namai', onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funkcija bus pridėta artimiausiu metu')));
                              }),
                              _buildQuickAction(Icons.work_outline, 'Darbas', onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funkcija bus pridėta artimiausiu metu')));
                              }),
                              _buildQuickAction(Icons.star_outline, 'Mėgstamos', onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Funkcija bus pridėta artimiausiu metu')));
                              }),
                            ],
                          ),
                        ],

                        if (estimatedPrice > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Kaina: €${estimatedPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                    Text(estimatedDistance, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                                if (estimatedEta.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Atvyks per', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                      Text(estimatedEta, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: (hasDrivers || estimatedPrice > 0) ? requestRide : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            child: Text(
                              hasDrivers ? 'Kviesti CityRide' : 'Nėra laisvų vairuotojų',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}