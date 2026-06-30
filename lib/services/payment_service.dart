import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static final supabase = Supabase.instance.client;

  static Future<void> initStripe() async {
    // Nustatome Stripe raktą iš aplinkos kintamųjų
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? "";
    try {
      await Stripe.instance.applySettings();
    } catch (e) {
      debugPrint('Stripe init error: $e');
    }
  }

  static Future<bool> setupPaymentMethod(BuildContext context) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        _showError(context, 'Naudotojas nerastas');
        return false;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 1. Call Edge Function to create SetupIntent
      debugPrint('Calling stripe-setup-intent for ${user.email}...');
      final response = await supabase.functions.invoke(
        'stripe-setup-intent',
        body: {
          'customer_email': user.email,
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${response.status}');
      debugPrint('Response data: ${response.data}');

      if (context.mounted) Navigator.pop(context); // Hide loading

      if (response.status != 200) {
        _showError(context, 'Nepavyko sukurti SetupIntent: ${response.data}');
        return false;
      }

      final data = response.data;
      final setupIntentClientSecret = data['setupIntent'];
      // Stripe.publishableKey = data['publishableKey']; // Already set in init

      // 2. Initialize Payment Sheet for Setup
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: setupIntentClientSecret,
          merchantDisplayName: 'CityRide',
          style: ThemeMode.light,
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            name: CollectionMode.always,
            email: CollectionMode.always,
          ),
        ),
      );

      // 3. Present Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // Show loading again for saving
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // 4. NAUJA: Iškviečiame funkciją, kuri suras ką tik pridėtą kortelę ir įrašys jos galą (last4) į DB
      await supabase.functions.invoke('save-payment-method', body: {
        'customer_email': user.email,
      });

      if (context.mounted) Navigator.pop(context); // Hide loading
      
      return true;
    } catch (e) {
      if (context.mounted && Navigator.canPop(context)) Navigator.pop(context); // Hide loading if still there

      if (e is StripeException) {
        debugPrint('Stripe Error: ${e.error.localizedMessage}');
        _showError(context, 'Stripe klaida: ${e.error.localizedMessage}');
      } else {
        debugPrint('Setup Error: $e');
        _showError(context, 'Klaida: $e');
      }
      return false;
    }
  }

  static Future<Map<String, dynamic>> preAuthorizePayment({
    required double amount,
    required String customerEmail,
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'stripe-pre-auth',
        body: {
          'amount': amount,
          'customer_email': customerEmail,
        },
      );

      if (response.status == 200) {
        return {'success': true, 'paymentIntentId': response.data['paymentIntentId']};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Nepavyko autorizuoti kortelės'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  static void _showError(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  static Future<bool> makePayment({
    required BuildContext context,
    required double amount,
    required String rideId,
  }) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      // 1. Call Edge Function to create PaymentIntent
      final response = await supabase.functions.invoke(
        'stripe-payment',
        body: {
          'amount': amount,
          'currency': 'eur',
          'customer_email': user.email,
          'ride_id': rideId,
        },
      );

      if (response.status != 200) {
        throw Exception('Failed to create PaymentIntent');
      }

      final data = response.data;
      final paymentIntentClientSecret = data['paymentIntent'];
      Stripe.publishableKey = data['publishableKey'];

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: 'CityRide',
          style: ThemeMode.light,
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Update ride status in DB
      await supabase.from('rides').update({
        'payment_status': 'paid',
        'payment_method': 'stripe',
      }).eq('id', rideId);

      return true;
    } catch (e) {
      if (e is StripeException) {
        debugPrint('Stripe Error: ${e.error.localizedMessage}');
      } else {
        debugPrint('Payment Error: $e');
      }
      return false;
    }
  }
}
