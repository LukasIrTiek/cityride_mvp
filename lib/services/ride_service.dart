import 'package:supabase_flutter/supabase_flutter.dart';

class RideService {

  final supabase = Supabase.instance.client;

  Future createRide({

    required String pickup,

    required String destination,

    String? eta,

  }) async {

    await supabase
        .from('rides')
        .insert({

      'pickup_address':
      pickup,

      'destination_address':
      destination,

      'eta_to_pickup':
      eta,

      'status':
      'searching',
    });
  }
}