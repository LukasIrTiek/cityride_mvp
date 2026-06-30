import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'chat_page.dart';
import '../constants.dart';

class RideStatusPage extends StatefulWidget {
  final String rideId;

  const RideStatusPage({
    super.key,
    required this.rideId,
  });

  @override
  State<RideStatusPage> createState() =>
      _RideStatusPageState();
}

class _RideStatusPageState
    extends State<RideStatusPage> {

  final supabase = Supabase.instance.client;

  final PolylinePoints polylinePoints =
  PolylinePoints();

  Map<String, dynamic>? ride;

  Timer? timer;

  GoogleMapController? mapController;

  Set<Marker> markers = {};

  Set<Polyline> polylines = {};

  bool firstCameraMove = true;

  BitmapDescriptor? carIcon;

  LatLng driverPosition = const LatLng(
    54.8985,
    23.9036,
  );

  String etaText = '';

  String driverName = '';
  String carModel = '';
  String plateNumber = '';
  String driverPhone = '';
  String driverPhoto = '';
  double driverRating = 4.9;

  bool isProcessingPayment = false;

  int _searchingSeconds = 0;
  Timer? _timeoutTimer;
  Timer? _repingTimer; // Naujas laikmatis pakartotinei paieškai
  DateTime? _searchStartTime; // Laikas, kada pradėta paieška šiame įrenginyje

  @override
  void initState() {
    super.initState();
    _searchStartTime = DateTime.now();
    loadCarIcon();
    fetchRide();
    listenToRide();
    WakelockPlus.enable(); // Neleidžiame ekranui užgesti

    // 1. Pagrindinis timeout (3 min)
    _timeoutTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (ride != null && ride!['status'] == 'searching') {
        final elapsed = DateTime.now().difference(_searchStartTime!).inSeconds;
        if (elapsed >= 180) {
          _handleRideTimeout();
        }
      }
    });

    // 2. Re-ping logika: jei vairuotojas ignoruoja užsakymą 40 sekundžių, ieškome kito
    _repingTimer = Timer.periodic(const Duration(seconds: 40), (t) async {
      if (ride != null && ride!['status'] == 'searching') {
        debugPrint('RE-PINGING: Searching for next driver...');
        try {
          await supabase.functions.invoke('send-ride-notification', body: {
            'ride_id': widget.rideId,
            'title': '🚕 Naujas užsakymas',
            'message': '${ride!['pickup_address']} → ${ride!['destination_address']}',
            'lat': ride!['pickup_lat'],
            'lng': ride!['pickup_lng'],
            'is_retry': true,
          });
        } catch (e) {
          debugPrint('Reping error: $e');
        }
      }
    });
    
    // PAŠALINTA: Periodinis polling'as (timer), nes naudojame listenToRide() stream'ą
  }

  Future<void> loadCarIcon() async {

    carIcon = await BitmapDescriptor.asset(
      const ImageConfiguration(
        size: Size(24, 24),
      ),
      'lib/assets/car_small.png',
    );

    setState(() {});
  }

  Future<void> fetchRide() async {

    final response = await supabase
        .from('rides')
        .select()
        .eq('id', widget.rideId)
        .single();

    ride = response;

    if (ride!['driver_id'] != null) {

      final driverData =
      await supabase
          .from('drivers')
          .select()
          .eq(
        'id',
        ride!['driver_id'],
      )
          .single();

      driverName =
          driverData['full_name']
              ?? '';

      carModel =
          driverData['car_model']
              ?? '';

      plateNumber =
          driverData['plate_number']
              ?? '';

      driverPhone =
          driverData['phone']
              ?? '';

      driverPhoto =
          driverData['profile_photo']
              ?? '';
      
      if (driverData['rating'] != null) {
        driverRating = (driverData['rating'] as num).toDouble();
      }
    }

    if (ride!['eta_to_pickup'] != null &&
        ride!['eta_to_pickup']
            .toString()
            .isNotEmpty) {

      etaText =
          ride!['eta_to_pickup']
              .toString();

    } else {

      etaText = '';
    }

    updateDriverMarker();

    await updatePolyline();

    if (!mounted) return;

    setState(() {});
  }

  void updateDriverMarker() {
    if (ride!['driver_lat'] != null &&
        ride!['driver_lng'] != null) {
      driverPosition = LatLng(
        (ride!['driver_lat'] as num).toDouble(),
        (ride!['driver_lng'] as num).toDouble(),
      );

      markers.removeWhere((marker) => marker.markerId.value == 'driver');
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPosition,
          icon: carIcon ?? BitmapDescriptor.defaultMarker,
          anchor: const Offset(0.5, 0.5),
          flat: true,
        ),
      );

      // Add pickup and destination markers
      if (ride!['pickup_lat'] != null && ride!['pickup_lng'] != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng((ride!['pickup_lat'] as num).toDouble(), (ride!['pickup_lng'] as num).toDouble()),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      if (ride!['destination_lat'] != null && ride!['destination_lng'] != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng((ride!['destination_lat'] as num).toDouble(), (ride!['destination_lng'] as num).toDouble()),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }

      if (firstCameraMove) {
        _updateBounds();
        firstCameraMove = false;
      }
    }
  }

  void _updateBounds() {
    if (mapController == null || ride == null || markers.isEmpty) return;

    LatLngBounds bounds;
    List<LatLng> points = markers.map((m) => m.position).toList();
    
    // Add polyline points to bounds if they exist
    if (polylines.isNotEmpty) {
      for (var poly in polylines) {
        points.addAll(poly.points);
      }
    }

    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
  }

  Future<void> updatePolyline() async {

    if (ride == null) return;

    polylines.clear();

    final status = ride!['status'];

    double endLat;
    double endLng;

    if (status == 'accepted' ||
        status == 'arrived') {

      endLat =
          (ride!['pickup_lat'] as num)
              .toDouble();

      endLng =
          (ride!['pickup_lng'] as num)
              .toDouble();

    }

    else if (status == 'in_progress') {

      endLat =
          (ride!['destination_lat']
          as num)
              .toDouble();

      endLng =
          (ride!['destination_lng']
          as num)
              .toDouble();

    } else {
      return;
    }

    PolylineResult result =
    await polylinePoints.getRouteBetweenCoordinates(

      request: PolylineRequest(

        origin: PointLatLng(
          driverPosition.latitude,
          driverPosition.longitude,
        ),

        destination: PointLatLng(
          endLat,
          endLng,
        ),

        mode: TravelMode.driving,
      ),

      googleApiKey: googleApiKey,
    );

    if (result.points.isNotEmpty) {

      List<LatLng> polylineCoordinates =
      result.points.map((point) {

        return LatLng(
          point.latitude,
          point.longitude,
        );

      }).toList();

      polylines.add(

        Polyline(

          polylineId:
          const PolylineId('route'),

          color:
          status == 'in_progress'
              ? Colors.green
              : Colors.black,

          width: 7,

          points: polylineCoordinates,

          startCap: Cap.roundCap,
          endCap: Cap.roundCap,

          jointType:
          JointType.round,
        ),
      );

      if (!mounted) return;

      setState(() {});
    }
  }

  void listenToRide() {
    supabase
        .from('rides')
        .stream(primaryKey: ['id'])
        .eq('id', widget.rideId)
        .listen((data) async {
      if (data.isNotEmpty) {
        final newRide = data.first;
        
        // Atnaujiname tik jei statusas pasikeitė arba tai pirmas krovimas
        if (ride == null || ride!['status'] != newRide['status'] || ride!['driver_id'] != newRide['driver_id']) {
          ride = newRide;
          await fetchRide(); // Užkrauname pilną info (vairuotojo vardą, nuotrauką) tik kai pasikeičia esminė info
        } else {
          ride = newRide;
          etaText = ride!['eta_to_pickup'] ?? '';
          updateDriverMarker();
          if (mounted) setState(() {});
        }

        // Automatinis mokėjimas, kai kelionė baigta
        if (ride!['status'] == 'completed' && ride!['payment_status'] != 'paid') {
          processAutomaticPayment();
        }
      }
    });
  }

  Future<void> processAutomaticPayment() async {
    if (isProcessingPayment) return;
    
    setState(() {
      isProcessingPayment = true;
    });

    try {
      await supabase.functions.invoke('stripe-auto-charge', body: {
        'ride_id': widget.rideId,
      });
      // Būsena bus atnaujinta per listenToRide() arba fetchRide()
    } catch (e) {
      debugPrint('Automatinio mokėjimo klaida: $e');
      setState(() {
        isProcessingPayment = false;
      });
    }
  }

  Future<void> _handleRideTimeout() async {
    _timeoutTimer?.cancel();
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Vairuotojų nerasta'),
        content: const Text('Apgailestaujame, bet šiuo metu nėra laisvų vairuotojų. Rezervuotos lėšos bus grąžintos į jūsų kortelę.'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
            child: const Text('GERAI'),
          ),
        ],
      ),
    );

    try {
      await supabase.functions.invoke('release-payment', body: {'ride_id': widget.rideId});
    } catch (e) {
      debugPrint('Timeout release error: $e');
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    _timeoutTimer?.cancel();
    _repingTimer?.cancel();
    WakelockPlus.disable(); // Leidžiame ekranui vėl užgesti baigus kelionę
    super.dispose();
  }

  String getStatusText() {
    if (ride == null) return 'Kraunama...';
    final status = ride!['status'];
    final paymentStatus = ride!['payment_status'];

    if (status == 'cancelled' && paymentStatus == 'paid_cancellation') {
      return 'Jūs nepasirodėte';
    }

    switch (status) {
      case 'searching': return 'Ieškome vairuotojo';
      case 'reserved': return 'Vairuotojas baigia kitą kelionę';
      case 'accepted': return 'Vairuotojas vyksta pas jus';
      case 'arrived': return 'Vairuotojas atvyko';
      case 'in_progress': return 'Kelionė prasidėjo';
      case 'completed': return 'Kelionė baigta';
      case 'cancelled': return 'Kelionė atšaukta';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = ride?['status'];
    final paymentStatus = ride?['payment_status'];
    final isCompleted = status == 'completed';
    final isNoShow = status == 'cancelled' && paymentStatus == 'paid_cancellation';

    return Scaffold(

      backgroundColor: Colors.white,

      appBar: AppBar(

        elevation: 0,

        backgroundColor: Colors.white,

        foregroundColor: Colors.black,

        centerTitle: true,

        title: const Text(

          'Kelionės būsena',

          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
      ),

      body: ride == null

          ? const Center(
        child:
        CircularProgressIndicator(),
      )

          : Stack(

        children: [

          GoogleMap(

            initialCameraPosition:
            CameraPosition(
              target: driverPosition,
              zoom: 15,
            ),

            markers: markers,

            polylines: polylines,

            myLocationEnabled: true,
            myLocationButtonEnabled: true,

            compassEnabled: false,

            zoomControlsEnabled: false,

            trafficEnabled: false,

            buildingsEnabled: true,

            onMapCreated: (controller) {
              mapController = controller;
            },
          ),

          Align(

            alignment:
            Alignment.bottomCenter,

            child: SafeArea(

              child: Container(

                margin:
                const EdgeInsets.all(12),

                padding:
                const EdgeInsets.all(14),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                  BorderRadius.circular(26),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: 0.08),

                      blurRadius: 20,

                      offset:
                      const Offset(0, -4),
                    ),
                  ],
                ),

                child: Column(

                  mainAxisSize:
                  MainAxisSize.min,

                  children: [

                    Container(

                      width: 36,
                      height: 4,

                      decoration: BoxDecoration(

                        color:
                        Colors.grey.shade300,

                        borderRadius:
                        BorderRadius.circular(
                          20,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        if (!isCompleted)
                          Expanded(
                            flex: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Column(
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      status == 'arrived'
                                          ? '0 min.'
                                          : (etaText.isNotEmpty
                                              ? etaText
                                                  .replaceAll('mins', 'min.')
                                                  .replaceAll('min', 'min.')
                                                  .replaceAll('hours', 'val.')
                                                  .replaceAll('hour', 'val.')
                                              : 'Laukiama...'),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    status == 'in_progress'
                                        ? 'Atvyksite už'
                                        : (status == 'reserved'
                                            ? 'Bus laisvas už'
                                            : (status == 'arrived' ? 'Vairuotojas laukia' : 'Vairuotojas atvyks')),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (!isCompleted) const SizedBox(width: 10),
                        Expanded(
                          flex: 5,
                          child: Text(
                            getStatusText(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (status == 'reserved')
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Vairuotojas baigia ankstesnę kelionę ir netrukus atvyks pas jus.',
                                  style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (isNoShow)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.red.shade100)),
                          child: Column(
                            children: [
                              const Text('JŪS NEPASIRODĖTE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 8),
                              const Text(
                                'Vairuotojas jūsų laukė daugiau nei 3 minutes. Pagal taisykles jums pritaikytas minimalus 3.00€ mokestis.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Likusios rezervuotos lėšos bus automatiškai grąžintos į jūsų kortelę.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
                              ),
                            ],
                          ),
                        ),
                      ),

                    if (!isCompleted && !isNoShow &&
                        driverName.isNotEmpty) ...[

                      const SizedBox(height: 12),

                      Container(

                        width:
                        double.infinity,

                        padding:
                        const EdgeInsets.all(12),

                        decoration: BoxDecoration(

                          color:
                          Colors.grey.shade100,

                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),
                        ),

                        child: Column(

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 46,
                                  height: 46,

                                  decoration:
                                  BoxDecoration(

                                    color: Colors.black,

                                    borderRadius:
                                    BorderRadius.circular(
                                      16,
                                    ),
                                  ),

                                  child: ClipRRect(

                                    borderRadius:
                                    BorderRadius.circular(
                                      16,
                                    ),

                                    child:
                                    driverPhoto.isNotEmpty

                                        ? Image.network(

                                      driverPhoto,

                                      fit: BoxFit.cover,

                                      errorBuilder:
                                          (_, __, ___) {

                                        return const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 22,
                                        );
                                      },
                                    )

                                        : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  width: 10,
                                ),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                    children: [

                                      Text(

                                        driverName,

                                        maxLines: 1,

                                        overflow:
                                        TextOverflow
                                            .ellipsis,

                                        style:
                                        const TextStyle(

                                          fontSize: 15,

                                          fontWeight:
                                          FontWeight
                                              .bold,
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 2,
                                      ),

                                      Row(
                                        children: [
                                          const Icon(Icons.star, size: 12, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            driverRating.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            carModel,
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow
                                                .ellipsis,
                                            style:
                                            const TextStyle(
                                              fontSize: 12,
                                              color:
                                              Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),

                                      Text(

                                        plateNumber,

                                        style:
                                        const TextStyle(

                                          fontSize: 12,

                                          fontWeight:
                                          FontWeight
                                              .w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            Row(

                              children: [

                                Expanded(

                                  child: SizedBox(

                                    height: 42,

                                    child:
                                    ElevatedButton.icon(

                                      onPressed: () async {
                                        if (driverPhone.isNotEmpty) {
                                          final Uri url = Uri(
                                            scheme: 'tel',
                                            path: driverPhone.replaceAll(RegExp(r'[^0-9+]'), ''),
                                          );
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        }
                                      },

                                      style:
                                      ElevatedButton
                                          .styleFrom(

                                        elevation: 0,

                                        backgroundColor:
                                        Colors.black,

                                        foregroundColor:
                                        Colors.white,

                                        shape:
                                        RoundedRectangleBorder(

                                          borderRadius:
                                          BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),

                                      icon: const Icon(
                                        Icons.call,
                                        size: 16,
                                      ),

                                      label:
                                      const Text(
                                        'Skambinti',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 10),

                                Expanded(

                                  child: SizedBox(

                                    height: 42,

                                    child:
                                    ElevatedButton.icon(

                                      onPressed: () {
                                        if (driverName.isNotEmpty) {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ChatPage(
                                                rideId: widget.rideId,
                                                otherName: driverName,
                                              ),
                                            ),
                                          );
                                        }
                                      },

                                      style:
                                      ElevatedButton
                                          .styleFrom(

                                        elevation: 0,

                                        backgroundColor:
                                        Colors.green,

                                        foregroundColor:
                                        Colors.white,

                                        shape:
                                        RoundedRectangleBorder(

                                          borderRadius:
                                          BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),

                                      icon: const Icon(
                                        Icons.chat_bubble,
                                        size: 16,
                                      ),

                                      label:
                                      const Text(
                                        'Žinutė',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            GestureDetector(
                              onTap: () async {
                                final status = ride?['status'];
                                final acceptedAtStr = ride?['accepted_at'];
                                bool shouldChargeFee = false;

                                if (acceptedAtStr != null && (status == 'accepted' || status == 'arrived' || status == 'in_progress')) {
                                  final acceptedAt = DateTime.parse(acceptedAtStr).toLocal();
                                  final diff = DateTime.now().difference(acceptedAt);
                                  if (diff.inMinutes >= 3) {
                                    shouldChargeFee = true;
                                  }
                                }

                                if (shouldChargeFee) {
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Atšaukimo mokestis'),
                                      content: const Text('Kadangi vairuotojas jau vyksta pas jus daugiau nei 3 minutes, bus pritaikytas 3.00€ atšaukimo mokestis.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('NEATŠAUKTI')),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true), 
                                          child: const Text('ATŠAUKTI IR SUMOKĖTI', style: TextStyle(color: Colors.red))
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm != true) return;

                                  // Charge fee
                                  try {
                                    await supabase.functions.invoke('charge-cancellation-fee', body: {
                                      'ride_id': widget.rideId,
                                      'passenger_id': supabase.auth.currentUser!.id,
                                      'amount': 300,
                                    });
                                  } catch (e) {
                                    debugPrint('Error charging fee: $e');
                                  }
                                } else {
                                  // Nemokamas atšaukimas - paleidžiame rezervuotus pinigus
                                  try {
                                    await supabase.functions.invoke('release-payment', body: {
                                      'ride_id': widget.rideId,
                                    });
                                  } catch (e) {
                                    debugPrint('Error releasing payment: $e');
                                    await supabase.from('rides').update({'status': 'cancelled'}).eq('id', widget.rideId);
                                  }
                                }

                                if (context.mounted) {
                                  Navigator.pop(context);
                                }
                              },
                              child: Column(

                                children: [

                                  const Text(

                                    'Atšaukti kelionę',

                                    style: TextStyle(

                                      color: Colors.red,

                                      fontWeight:
                                      FontWeight.w600,

                                      fontSize: 13,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(

                                    'Jeigu neatšaukėte per 2 minutes,\ntaikomas 3€ mokestis',

                                    textAlign:
                                    TextAlign.center,

                                    style: TextStyle(

                                      color: Colors.grey.shade600,

                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if ((isCompleted || isNoShow) &&
                        ride!['price'] != null) ...[

                      const SizedBox(height: 12),

                      Container(

                        width:
                        double.infinity,

                        padding:
                        const EdgeInsets.all(14),

                        decoration: BoxDecoration(

                          color: isNoShow ? Colors.red.shade50 : Colors.green.shade50,

                          borderRadius:
                          BorderRadius.circular(
                            18,
                          ),
                        ),

                        child: Column(

                          children: [

                            Text(
                              isNoShow ? 'Atšaukimo mokestis' : 'Kelionės kaina',

                              style: const TextStyle(

                                fontSize: 13,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            const SizedBox(
                              height: 6,
                            ),

                            Text(
                              isNoShow ? '€3.00' : '€${(double.tryParse(ride!['price']?.toString() ?? '0') ?? 0).toStringAsFixed(2)}',
                              style:
                              const TextStyle(

                                fontSize: 26,

                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),

                            if (ride!['payment_status'] == 'paid' || ride!['payment_status'] == 'paid_cancellation') ...[
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Apmokėta automatiškai', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      SizedBox(

                        width:
                        double.infinity,

                        height: 46,

                        child: ElevatedButton(

                          onPressed: () {

                            Navigator.popUntil(
                              context,
                                  (route) =>
                              route.isFirst,
                            );
                          },

                          style:
                          ElevatedButton.styleFrom(

                            elevation: 0,

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

                            'Grįžti į pradžią',

                            style: TextStyle(

                              fontSize: 13,

                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}