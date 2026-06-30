import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _version = '...';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apie CityRide'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APIE CITYRIDE',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Versija: $_version'),
            const SizedBox(height: 24),
            const Text(
              'Sveiki atvykę į CityRide',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'CityRide – tai moderni keleivių pavėžėjimo platforma, sukurta Lietuvoje, kurios tikslas – pasiūlyti saugų, patogų ir greitą būdą užsisakyti keliones.\n\n'
              'Mūsų tikslas – sujungti keleivius ir vairuotojus naudojant šiuolaikines technologijas, užtikrinant patikimą aptarnavimą bei skaidrią kainodarą.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mūsų misija',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suteikti patikimą, saugią ir patogią pavėžėjimo paslaugą kiekvienam keleiviui.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ką siūlo CityRide?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildListItem('Greitą vairuotojo paiešką.'),
            _buildListItem('Kelionės stebėjimą realiuoju laiku.'),
            _buildListItem('Aiškią išankstinę kainą.'),
            _buildListItem('Patogų atsiskaitymą.'),
            _buildListItem('Sąskaitų istoriją.'),
            _buildListItem('Saugų ryšį tarp keleivio ir vairuotojo.'),
            const SizedBox(height: 32),
            const Text(
              'Kontaktai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'CityRide\n'
              'Įmonės kodas: 307727101\n'
              'Adresas:\n'
              'Laisvės al. 85E-5, LT-44297 Kaunas, Lietuva\n'
              'Telefonas:\n'
              '+370 648 42016\n'
              'El. paštas:\n'
              'cityride.apps@gmail.com',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'Versija: $_version',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '© 2026 CityRide. Visos teisės saugomos.',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }
}
