import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoiceService {
  static String _removeAccents(String text) {
    var str = text;
    var map = {
      'ą': 'a', 'Ą': 'A',
      'č': 'c', 'Č': 'C',
      'ę': 'e', 'Ę': 'E',
      'ė': 'e', 'Ė': 'E',
      'į': 'i', 'Į': 'I',
      'š': 's', 'Š': 'S',
      'ų': 'u', 'Ų': 'U',
      'ū': 'u', 'Ū': 'U',
      'ž': 'z', 'Ž': 'Z',
    };
    map.forEach((key, value) {
      str = str.replaceAll(key, value);
    });
    return str;
  }

  static Future<void> generateRideInvoice({
    required Map<String, dynamic> ride,
    required Map<String, dynamic> driver,
    required Map<String, dynamic> passenger,
  }) async {
    final pdf = pw.Document();
    final date = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(ride['created_at']).toLocal());
    
    final isCancelled = ride['status'] == 'cancelled';
    final cancellationFee = double.tryParse(ride['cancellation_fee']?.toString() ?? '0') ?? 0.0;
    final price = isCancelled ? cancellationFee : (double.tryParse(ride['price'].toString()) ?? 0.0);
    
    final driverName = _removeAccents(driver['full_name'] ?? 'Vairuotojas');
    final carInfo = _removeAccents(driver['car_model'] ?? '-');
    final plate = _removeAccents(driver['plate_number'] ?? '-');
    final ivNo = _removeAccents(driver['iv_number'] ?? '-');
    final passengerName = _removeAccents(passenger['full_name'] ?? 'Keleivis');
    final pickup = _removeAccents(ride['pickup_address'] ?? '-');
    final destination = _removeAccents(ride['destination_address'] ?? '-');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(isCancelled ? 'ATSAUKIMO KVITAS' : 'KELIONES KVITAS', 
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                      pw.Text('ID: ${ride['id']}'),
                      pw.Text('Data: $date'),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('CityRide Platform', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('MB cityride'),
                      pw.Text('Im. kodas: 307727101'),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.SizedBox(height: 10),
              
              pw.Text('PASLAUGOS TEIKEJAS (VAIRUOTOJAS):', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(driverName),
              pw.Text('Indiv. veiklos Nr.: $ivNo'),
              pw.Text('Automobilis: $carInfo ($plate)'),
              
              pw.SizedBox(height: 20),
              pw.Text('PIRKEJAS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text(passengerName),
              
              pw.SizedBox(height: 20),
              pw.Text('MARSRUTAS:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              pw.Text('Is: $pickup'),
              pw.Text('I: $destination'),
              
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(isCancelled ? 'Atsaukimo mokestis:' : 'Is viso apmoketa:'),
                      pw.Text('EUR ${price.toStringAsFixed(2)}', 
                        style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 50),
              pw.Text('Aciu, kad naudojates CityRide!', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
              pw.Text('Dokumentas sugeneruotas automatiskai.', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save(), name: 'Kvitas_${ride['id']}.pdf');
  }
}
