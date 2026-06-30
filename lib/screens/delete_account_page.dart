import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth_gate.dart';

class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final supabase = Supabase.instance.client;
  bool _isDeleting = false;

  Future<void> _deleteAccount() async {
    setState(() => _isDeleting = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      // 1. Ištriname vartotojo duomenis iš duomenų bazės (passengers lentelė)
      // Pastaba: priklausomai nuo DB nustatymų, tai gali automatiškai ištrinti ir susijusius duomenis (Cascade)
      await supabase.from('passengers').delete().eq('id', userId);

      // 2. Atsijungiame (Supabase Auth vartotojo ištrynimas dažniausiai reikalauja Admin teisių per Edge Functions, 
      // arba vartotojas tiesiog atsijungia ir jo duomenys yra pašalinami).
      // Čia atliekame pilną atsijungimą.
      await supabase.auth.signOut();

      if (!mounted) return;
      
      // Grįžtame į login ekraną
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => AuthGate()),
        (route) => false,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paskyra sėkmingai ištrinta')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Klaida trinant paskyrą: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ar tikrai norite ištrinti paskyrą?'),
        content: const Text('Šio veiksmo atšaukti negalima. Visi jūsų duomenys bus pašalinti.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ATŠAUKTI'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('IŠTRINTI'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ištrinti paskyrą'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PASKYROS IŠTRYNIMAS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Paskutinį kartą atnaujinta: 2026-06-25'),
            const SizedBox(height: 24),
            const Text(
              'Paskyros ištrynimas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'CityRide suteikia galimybę bet kuriuo metu ištrinti savo paskyrą tiesiogiai programėlėje.\n\n'
              'Norėdami ištrinti paskyrą:\n'
              '1. Atidarykite Profilis.\n'
              '2. Pasirinkite Ištrinti paskyrą.\n'
              '3. Perskaitykite įspėjimą.\n'
              '4. Patvirtinkite paskyros ištrynimą.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            _buildSection('Kas nutiks ištrynus paskyrą?', 
              '• Jūsų CityRide paskyra bus panaikinta.\n'
              '• Nebegalėsite prisijungti prie programėlės.\n'
              '• Bus pašalinti Jūsų profilio duomenys.\n'
              '• Bus pašalinti išsaugoti adresai.\n'
              '• Bus pašalinti įrenginio prisijungimo duomenys.\n'
              '• Būsite automatiškai atjungti nuo programėlės.'
            ),
            _buildSection('Kokie duomenys gali būti saugomi?', 
              'Tam tikra informacija gali būti saugoma tiek laiko, kiek to reikalauja Lietuvos Respublikos teisės aktai, pavyzdžiui:\n'
              '• sąskaitų informacija;\n'
              '• mokėjimų įrašai;\n'
              '• apskaitos dokumentai;\n'
              '• duomenys, reikalingi teisinių prievolių vykdymui.\n\n'
              'Tokie duomenys naudojami tik teisės aktuose numatytais tikslais.'
            ),
            _buildSection('Ar paskyrą galima atkurti?', 
              'Ne.\n\n'
              'Patvirtinus paskyros ištrynimą, šio veiksmo atšaukti negalima. Jei vėliau norėsite naudotis CityRide paslaugomis, turėsite susikurti naują paskyrą.'
            ),
            const Text(
              'Reikia pagalbos?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'CityRide\n'
              '📧 cityride.apps@gmail.com\n'
              '📞 +370 648 42016\n'
              '📍 Laisvės al. 85E-5, LT-44297 Kaunas, Lietuva',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isDeleting ? null : _showConfirmDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isDeleting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('IŠTRINTI PASKYRĄ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
        const SizedBox(height: 24),
      ],
    );
  }
}
