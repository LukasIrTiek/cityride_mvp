import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import 'screens/ride_status_page.dart';

class PassengerRideScreen extends StatefulWidget {
  const PassengerRideScreen({super.key});

  @override
  State<PassengerRideScreen> createState() =>
      _PassengerRideScreenState();
}

class _PassengerRideScreenState
    extends State<PassengerRideScreen> {

  final supabase = Supabase.instance.client;

  GoogleMapController? mapController;

  final pickupController =
  TextEditingController();

  final destinationController =
  TextEditingController();

  LatLng currentPosition = const LatLng(
    54.6872,
    25.2797,
  );

  bool loading = true;

  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  double estimatedPrice = 0;

  String estimatedDistance = '';
  String estimatedDuration = '';

  String nearestDriverEta = '';

  Timer? driverRefreshTimer;

  @override
  void initState() {
    super.initState();

    getCurrentLocation();

    startNearbyDriversUpdates();
  }

  Future<void> getCurrentLocation() async {

    try {

      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {

        setState(() {
          loading = false;
        });

        return;
      }

      permission =
      await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {

        permission =
        await Geolocator.requestPermission();

        if (permission ==
            LocationPermission.denied) {

          setState(() {
            loading = false;
          });

          return;
        }
      }

      if (permission ==
          LocationPermission.deniedForever) {

        setState(() {
          loading = false;
        });

        return;
      }

      final position =
      await Geolocator.getCurrentPosition(
        desiredAccuracy:
        LocationAccuracy.high,
      );

      currentPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      markers.add(
        Marker(
          markerId:
          const MarkerId('current'),

          position: currentPosition,

          icon:
          BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          ),

          infoWindow: const InfoWindow(
            title: 'Jūsų vieta',
          ),
        ),
      );

      setState(() {
        loading = false;
      });

    } catch (e) {

      setState(() {
        loading = false;
      });
    }
  }

  void startNearbyDriversUpdates() {

    fetchNearbyDrivers();

    driverRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
          (_) {
        fetchNearbyDrivers();
      },
    );
  }

  Future<void> fetchNearbyDrivers() async {

    try {

      final response = await supabase
          .from('drivers')
          .select()
          .eq('online', true);

      markers.removeWhere(
            (marker) =>
            marker.markerId.value
                .startsWith(
              'online_driver',
            ),
      );

      double closestDistance =
      999999;

      LatLng comparePoint =
          currentPosition;

      /// JEI YRA PICKUP
      /// SKAIČIUOJAM ETA IKI PICKUP
      if (pickupController
          .text
          .isNotEmpty) {

        final pickupCoords =
        await getCoordinatesFromAddress(
          pickupController.text,
        );

        if (pickupCoords != null) {

          comparePoint =
              pickupCoords;
        }
      }

      for (int i = 0;
      i < response.length;
      i++) {

        final driver = response[i];

        if (driver['lat'] == null ||
            driver['lng'] == null) {
          continue;
        }

        final driverLat =
        (driver['lat'] as num)
            .toDouble();

        final driverLng =
        (driver['lng'] as num)
            .toDouble();

        final distance =
        Geolocator.distanceBetween(

          comparePoint.latitude,
          comparePoint.longitude,

          driverLat,
          driverLng,
        );

        if (distance <
            closestDistance) {

          closestDistance =
              distance;

          final minutes =
          ((distance / 1000) * 3)
              .ceil();

          nearestDriverEta =
          '$minutes min';
        }

        markers.add(
          Marker(
            markerId:
            MarkerId(
              'online_driver_$i',
            ),

            position: LatLng(
              driverLat,
              driverLng,
            ),

            icon: await BitmapDescriptor.asset(
              const ImageConfiguration(
                size: Size(48, 48),
              ),
              'lib/assets/car.png',
            ),

            infoWindow:
            const InfoWindow(
              title:
              'CityRide Driver',
            ),
          ),
        );
      }

      /// JEI NĖRA DRIVER
      if (response.isEmpty) {

        nearestDriverEta =
        'Nėra vairuotojų';
      }

      setState(() {});
    } catch (e) {

      debugPrint(
        'Drivers fetch error: $e',
      );
    }
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
    await http.get(Uri.parse(url));

    final data = jsonDecode(response.body);

    final predictions =
    data['predictions'] as List;

    return predictions
        .map((e) =>
        e['description'].toString())
        .toList();
  }

  Future<LatLng?> getCoordinatesFromAddress(
      String address,
      ) async {

    final url =
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=$address'
        '&key=$googleApiKey';

    final response =
    await http.get(Uri.parse(url));

    final data = jsonDecode(response.body);

    if (data['results'].isEmpty) {
      return null;
    }

    final location =
    data['results'][0]
    ['geometry']['location'];

    return LatLng(
      location['lat'],
      location['lng'],
    );
  }

  Future<void> getRouteAndPrice() async {

    setState(() {
      estimatedPrice = 15.99;
      estimatedDistance = '10 km';
      estimatedDuration = '15 min';
    });

    final pickup =
    await getCoordinatesFromAddress(
      pickupController.text,
    );

    final destination =
    await getCoordinatesFromAddress(
      destinationController.text,
    );

    if (pickup == null ||
        destination == null) {
      return;
    }

    print('Pickup: ${pickupController.text}');
    print('Destination: ${destinationController.text}');
    print('Price: $estimatedPrice');

    markers.removeWhere(
          (marker) =>
      marker.markerId.value ==
          'pickup' ||
          marker.markerId.value ==
              'destination',
    );

    markers.add(
      Marker(
        markerId:
        const MarkerId('pickup'),

        position: pickup,

        infoWindow: const InfoWindow(
          title: 'Paėmimas',
        ),
      ),
    );

    markers.add(
      Marker(
        markerId:
        const MarkerId('destination'),

        position: destination,

        icon:
        BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),

        infoWindow: const InfoWindow(
          title: 'Tikslas',
        ),
      ),
    );

    PolylinePoints polylinePoints =
    PolylinePoints();

    PolylineResult result =
    await polylinePoints
        .getRouteBetweenCoordinates(

      request: PolylineRequest(

        origin: PointLatLng(
          pickup.latitude,
          pickup.longitude,
        ),

        destination: PointLatLng(
          destination.latitude,
          destination.longitude,
        ),

        mode: TravelMode.driving,
      ),

      googleApiKey:
      googleApiKey,
    );

    List<LatLng> polylineCoordinates =
    [];

    if (result.points.isNotEmpty) {

      for (var point
      in result.points) {

        polylineCoordinates.add(
          LatLng(
            point.latitude,
            point.longitude,
          ),
        );
      }
    }

    polylines.clear();

    polylines.add(
      Polyline(
        polylineId:
        const PolylineId('route'),

        points:
        polylineCoordinates,

        width: 5,

        color: Colors.black,
      ),
    );

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        pickup,
        13,
      ),
    );

    double distanceKm =
        Geolocator.distanceBetween(
          pickup.latitude,
          pickup.longitude,
          destination.latitude,
          destination.longitude,
        ) /
            1000;

    double durationMinutes =
        distanceKm * 2;

    // Nauji įkainiai:
    // Minimali kelionė – 3,00 €
    // Įsėdimas – 0,70 €
    // 1 km – 0,55 €
    // 1 min. – 0,15 €

    double baseFare = 0.70;
    double distanceFare =
        distanceKm * 0.55;
    double timeFare =
        durationMinutes * 0.15;
    double minimumFare = 3.00;

    estimatedPrice =
        baseFare +
            distanceFare +
            timeFare;
            
    if (estimatedPrice < minimumFare) {
      estimatedPrice = minimumFare;
    }

    estimatedDistance =
    '${distanceKm.toStringAsFixed(1)} km';

    estimatedDuration =
    '${durationMinutes.toStringAsFixed(0)} min';

    setState(() {});
  }

  Future<void> requestRide() async {
    final pickup = await getCoordinatesFromAddress(pickupController.text);
    final destination = await getCoordinatesFromAddress(destinationController.text);
    
    if (pickup == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepavyko nustatyti vietos koordinačių')),
      );
      return;
    }

    final user = supabase.auth.currentUser;
    if (user == null) return;

    // Gauname šviežius keleivio duomenis iš DB
    final passengerData = await supabase.from('passengers').select().eq('id', user.id).single();

    final response = await supabase
        .from('rides')
        .insert({
      'pickup_address': pickupController.text,
      'destination_address': destinationController.text,
      'pickup_lat': pickup.latitude,
      'pickup_lng': pickup.longitude,
      'destination_lat': destination.latitude,
      'destination_lng': destination.longitude,
      'status': 'searching',
      'price': estimatedPrice.toStringAsFixed(2),
      'passenger_id': user.id,
      'passenger_name': passengerData['full_name'] ?? 'Keleivis',
      'passenger_phone': passengerData['phone'] ?? '',
    })
        .select()
        .single();

    final rideId = response['id'];

    try {
      debugPrint('SENDING PUSH FOR RIDE: $rideId');
      await supabase.functions.invoke(
        'send-ride-notification',
        body: {
          'ride_id': rideId,
          'title': '🚕 Naujas užsakymas',
          'message': '${pickupController.text} → ${destinationController.text}',
          'lat': pickup.latitude,
          'lng': pickup.longitude,
        },
      );
    } catch (e) {
      debugPrint('FCM NOTIFICATION ERROR: $e');
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RideStatusPage(
          rideId: rideId,
        ),
      ),
    );
  }

  @override
  void dispose() {

    driverRefreshTimer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      body: loading

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : Stack(

        children: [

          /// MAP
          GoogleMap(

            initialCameraPosition:
            CameraPosition(
              target: currentPosition,
              zoom: 15,
            ),

            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            zoomControlsEnabled: false,

            markers: markers,

            polylines: polylines,

            onMapCreated: (controller) {
              mapController =
                  controller;
            },
          ),

          /// TOP SEARCH CARD
          Positioned(

            top: 55,
            left: 16,
            right: 16,

            child: Material(

              elevation: 10,

              borderRadius:
              BorderRadius.circular(22),

              child: Container(

                padding:
                const EdgeInsets.all(14),

                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(
                    22,
                  ),
                ),

                child: Column(

                  children: [

                    /// DRIVER ETA
                    if (pickupController
                        .text
                        .isNotEmpty)

                      Container(

                        width: double.infinity,

                        margin:
                        const EdgeInsets.only(
                          bottom: 12,
                        ),

                        padding:
                        const EdgeInsets.all(
                          12,
                        ),

                        decoration: BoxDecoration(
                          color:
                          Colors.green.shade50,

                          borderRadius:
                          BorderRadius.circular(
                            14,
                          ),
                        ),

                        child: Row(

                          children: [

                            const Text(
                              '🚕',
                              style: TextStyle(
                                fontSize: 22,
                              ),
                            ),

                            const SizedBox(
                              width: 10,
                            ),

                            Expanded(

                              child: Text(
                                nearestDriverEta
                                    .isEmpty
                                    ? 'Ieškoma vairuotojų...'
                                    : 'Vairuotojas atvyks už $nearestDriverEta',

                                style:
                                const TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    /// PICKUP
                    TypeAheadField<String>(

                      suggestionsCallback:
                          (search) async {

                        return await
                        searchPlaces(
                          search,
                        );
                      },

                      builder: (
                          context,
                          controller,
                          focusNode,
                          ) {

                        return TextField(

                          controller:
                          controller,

                          focusNode:
                          focusNode,

                          decoration:
                          InputDecoration(

                            hintText:
                            'Iš kur paimti?',

                            filled: true,

                            fillColor:
                            Colors.grey.shade100,

                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),

                            border:
                            OutlineInputBorder(

                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),

                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        );
                      },

                      itemBuilder:
                          (
                          context,
                          suggestion,
                          ) {

                        return ListTile(
                          title:
                          Text(suggestion),
                        );
                      },

                      onSelected:
                          (suggestion) {

                        pickupController
                            .text =
                            suggestion;

                        setState(() {});
                      },
                    ),

                    const SizedBox(
                      height: 10,
                    ),

                    /// DESTINATION
                    TypeAheadField<String>(

                      suggestionsCallback:
                          (search) async {

                        return await
                        searchPlaces(
                          search,
                        );
                      },

                      builder: (
                          context,
                          controller,
                          focusNode,
                          ) {

                        return TextField(

                          controller:
                          controller,

                          focusNode:
                          focusNode,

                          decoration:
                          InputDecoration(

                            hintText:
                            'Kur važiuosite?',

                            filled: true,

                            fillColor:
                            Colors.grey.shade100,

                            contentPadding:
                            const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),

                            border:
                            OutlineInputBorder(

                              borderRadius:
                              BorderRadius.circular(
                                16,
                              ),

                              borderSide:
                              BorderSide.none,
                            ),
                          ),
                        );
                      },

                      itemBuilder:
                          (
                          context,
                          suggestion,
                          ) {

                        return ListTile(
                          title:
                          Text(suggestion),
                        );
                      },

                      onSelected:
                          (suggestion) {

                        destinationController
                            .text =
                            suggestion;

                        getRouteAndPrice();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// BOTTOM PANEL
          Positioned(

            left: 0,
            right: 0,
            bottom: 0,

            child: Container(

              padding:
              const EdgeInsets.fromLTRB(
                20,
                16,
                20,
                26,
              ),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius:
                const BorderRadius.only(
                  topLeft:
                  Radius.circular(28),

                  topRight:
                  Radius.circular(28),
                ),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 12,
                  ),
                ],
              ),

              child: Column(

                mainAxisSize:
                MainAxisSize.min,

                children: [

                  if (estimatedPrice > 0)
                    ...[

                      Text(
                        '€${estimatedPrice.toStringAsFixed(2)}',

                        style:
                        const TextStyle(
                          fontSize: 28,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      const SizedBox(
                        height: 6,
                      ),

                      Text(
                        '$estimatedDistance • $estimatedDuration',

                        style:
                        const TextStyle(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),
                    ],

                  SizedBox(

                    width: double.infinity,
                    height: 54,

                    child: ElevatedButton(

                      onPressed:
                      estimatedPrice == 0
                          ? null
                          : requestRide,

                      style:
                      ElevatedButton.styleFrom(
                        backgroundColor:
                        Colors.black,

                        foregroundColor:
                        Colors.white,

                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),
                      ),

                      child: const Text(
                        'Kviesti CityRide',

                        style: TextStyle(
                          fontSize: 17,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
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