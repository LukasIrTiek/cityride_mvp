import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../services/payment_service.dart';
import '../services/invoice_service.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({super.key});

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> rides = [];
  Map<String, dynamic>? passengerData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    setState(() => isLoading = true);
    await Future.wait([
      loadPassengerData(),
      loadPaymentHistory(),
    ]);
    setState(() => isLoading = false);
  }

  Future<void> loadPassengerData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('passengers')
          .select()
          .eq('id', user.id)
          .single();
      
      setState(() {
        passengerData = data;
      });
    } catch (e) {
      debugPrint('Error loading passenger data: $e');
    }
  }

  Future<void> loadPaymentHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('rides')
          .select()
          .eq('passenger_id', user.id) // Using passenger_id is more reliable than name
          .order('created_at', ascending: false);

      setState(() {
        rides = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      // Fallback to name if passenger_id doesn't exist yet in the schema
      try {
        final response = await supabase
            .from('rides')
            .select()
            .eq('passenger_name', passengerData?['full_name'] ?? '')
            .order('created_at', ascending: false);
        setState(() {
          rides = List<Map<String, dynamic>>.from(response);
        });
      } catch (e2) {
        debugPrint('Error loading payments: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardLast4 = passengerData?['card_last4'];
    final cardBrand = passengerData?['card_brand'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mokėjimai ir Sąskaitos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Payment Method Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mokėjimo būdas',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        cardBrand == 'visa' ? Icons.credit_card : Icons.credit_card, 
                        color: Colors.white, 
                        size: 30
                      ),
                      const SizedBox(width: 15),
                      Text(
                        cardLast4 != null 
                            ? '**** **** **** $cardLast4'
                            : 'Pridėkite kortelę',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () async {
                          final success = await PaymentService.setupPaymentMethod(context);
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Kortelė sėkmingai pridėta')),
                            );
                            loadPassengerData(); // Refresh card info
                          }
                        },
                        child: Text(
                          cardLast4 != null ? 'KEISTI' : 'PRIDĖTI', 
                          style: const TextStyle(color: Colors.red)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Sąskaitos faktūros',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : rides.isEmpty
                    ? const Center(child: Text('Nėra atliktų kelionių'))
                    : ListView.builder(
                        itemCount: rides.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final ride = rides[index];
                          final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(ride['created_at']));
                          final isPaid = ride['payment_status'] == 'paid';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(15),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isPaid ? Colors.green.shade50 : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.description,
                                  color: isPaid ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                'Kelionė $date',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                '${ride['pickup_address'].split(',')[0]}...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '€${((ride['price'] ?? 0) as num).toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 5),
                                  GestureDetector(
                                    onTap: () async {
                                      if (ride['driver_id'] == null) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Vairuotojas dar nebuvo priskirtas')),
                                        );
                                        return;
                                      }
                                      
                                      // Fetch additional info for invoice
                                      final passengerData = await supabase.from('passengers').select().eq('id', supabase.auth.currentUser!.id).single();
                                      final driverData = await supabase.from('drivers').select().eq('id', ride['driver_id']).single();
                                      
                                      await InvoiceService.generateRideInvoice(
                                        ride: ride,
                                        driver: driverData,
                                        passenger: passengerData,
                                      );
                                    },
                                    child: const Text(
                                      'PDF',
                                      style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
