import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final supabase = Supabase.instance.client;

  List rides = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('rides')
          .select()
          .eq('passenger_id', user.id)
          .order('created_at', ascending: false);

      for (var ride in response) {
        if (ride['driver_id'] != null) {
          try {
            final driver = await supabase
                .from('drivers')
                .select()
                .eq('id', ride['driver_id'])
                .single();

            ride['driver_name'] = driver['full_name'];
            ride['car_model'] = driver['car_model'];
            ride['plate_number'] = driver['plate_number'];
            ride['driver_phone'] = driver['phone'];
            ride['driver_photo'] = driver['profile_photo'];
          } catch (_) {}
        }
      }

      setState(() {
        rides = response;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  String formatDate(String? date) {
    if (date == null) return '';

    try {
      // Užtikriname, kad laikas būtų traktuojamas kaip UTC, jei nėra nurodyta kitaip
      String dateStr = date;
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
        dateStr = '${dateStr.replaceFirst(' ', 'T')}Z';
      }
      final dt = DateTime.parse(dateStr).toLocal();

      return
        '${dt.day.toString().padLeft(2, '0')}.'
            '${dt.month.toString().padLeft(2, '0')}.'
            '${dt.year} '
            '${dt.hour.toString().padLeft(2, '0')}:'
            '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }

  Color statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  String statusText(String status) {
    switch (status) {
      case 'completed':
        return 'Baigta';

      case 'cancelled':
        return 'Atšaukta';

      case 'accepted':
        return 'Priimta';

      case 'in_progress':
        return 'Vyksta';

      default:
        return status;
    }
  }

  String shortenAddress(String? address) {
    if (address == null) return '';
    return address.split(',').first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelionių istorija'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rides.isEmpty
              ? const Center(child: Text('Kelionių nėra'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: rides.length,
                  itemBuilder: (context, index) {
                    final ride = rides[index];
                    final price = (ride['price'] ?? 0) as num;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${shortenAddress(ride['pickup_address'])} → ${shortenAddress(ride['destination_address'])}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: statusColor(ride['status'] ?? '').withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                                  child: Text(
                                    statusText(ride['status'] ?? ''),
                                    style: TextStyle(color: statusColor(ride['status'] ?? ''), fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(formatDate(ride['created_at']), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 12),
                                const SizedBox(width: 8),
                                Expanded(child: Text(ride['pickup_address'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.more_vert, size: 10, color: Colors.grey),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 12),
                                const SizedBox(width: 8),
                                Expanded(child: Text(ride['destination_address'] ?? '', style: const TextStyle(color: Colors.black54, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('€${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                if (ride['driver_name'] != null)
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          final phone = ride['driver_phone'];
                                          if (phone != null && phone.toString().isNotEmpty) {
                                            final Uri url = Uri(
                                              scheme: 'tel',
                                              path: phone.toString().replaceAll(RegExp(r'[^0-9+]'), ''),
                                            );
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        icon: const Icon(Icons.phone_outlined, color: Colors.green),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        onPressed: () async {
                                          final phone = ride['driver_phone'];
                                          if (phone != null && phone.toString().isNotEmpty) {
                                            final Uri url = Uri(
                                              scheme: 'sms',
                                              path: phone.toString().replaceAll(RegExp(r'[^0-9+]'), ''),
                                            );
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          }
                                        },
                                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(ride['driver_name'], style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                                          if (ride['plate_number'] != null)
                                            Text(ride['plate_number'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                        ],
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}