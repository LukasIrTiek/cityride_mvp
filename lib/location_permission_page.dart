import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'passenger_map_page.dart';

class LocationPermissionPage
    extends StatefulWidget {

  const LocationPermissionPage({
    super.key,
  });

  @override
  State<LocationPermissionPage>
  createState() =>
      _LocationPermissionPageState();
}

class _LocationPermissionPageState
    extends State<LocationPermissionPage> {

  bool loading = false;

  Future<void> allowLocation() async {

    setState(() {
      loading = true;
    });

    bool serviceEnabled =
    await Geolocator
        .isLocationServiceEnabled();

    if (!serviceEnabled) {

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Įjunkite GPS',
          ),
        ),
      );

      return;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission ==
        LocationPermission.denied) {

      permission =
      await Geolocator
          .requestPermission();
    }

    if (permission ==
        LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Reikia vietos leidimo',
          ),
        ),
      );

      return;
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
        const PassengerRideScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.white,

      body: SafeArea(

        child: Padding(
          padding:
          const EdgeInsets.all(24),

          child: Column(

            mainAxisAlignment:
            MainAxisAlignment.center,

            children: [

              const Spacer(),

              /// ICON
              Container(
                width: 140,
                height: 140,

                decoration: BoxDecoration(
                  color: Colors.black,

                  borderRadius:
                  BorderRadius.circular(
                    40,
                  ),
                ),

                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 70,
                ),
              ),

              const SizedBox(height: 40),

              /// TITLE
              const Text(
                'Leisti vietos prieigą',

                style: TextStyle(
                  fontSize: 32,
                  fontWeight:
                  FontWeight.bold,
                ),

                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              /// DESCRIPTION
              const Text(
                'CityRide naudoja jūsų vietą, kad galėtų rasti vairuotojus netoliese ir parodyti maršrutą.',

                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  height: 1.5,
                ),

                textAlign: TextAlign.center,
              ),

              const Spacer(),

              /// BUTTON
              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(

                  onPressed:
                  loading
                      ? null
                      : allowLocation,

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
                        20,
                      ),
                    ),
                  ),

                  child: loading
                      ? const SizedBox(
                    width: 24,
                    height: 24,

                    child:
                    CircularProgressIndicator(
                      color:
                      Colors.white,
                    ),
                  )
                      : const Text(
                    'Leisti vietą',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}