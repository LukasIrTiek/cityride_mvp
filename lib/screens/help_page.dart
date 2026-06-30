import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagalba'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CITYRIDE PAGALBA IR KONTAKTAI',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Paskutinį kartą atnaujinta: 2026-06-25'),
            const SizedBox(height: 24),
            const Text(
              'Sveiki atvykę į CityRide pagalbos centrą',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Jeigu kilo klausimų dėl CityRide programėlės, kelionių, mokėjimų ar paskyros, susisiekite su mumis. Mūsų tikslas – padėti kuo greičiau išspręsti Jūsų problemą.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            const Text(
              'Kontaktai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildContactItem(Icons.location_on_outlined, 'Adresas', 'Laisvės al. 85E-5, LT-44297 Kaunas, Lietuva'),
            _buildContactItem(Icons.phone_outlined, 'Telefonas', '+370 648 42016', onTap: () => _launchCaller('+37064842016')),
            _buildContactItem(Icons.email_outlined, 'El. paštas', 'cityride.apps@gmail.com', onTap: () => _launchEmail('cityride.apps@gmail.com')),
            const SizedBox(height: 32),
            const Text(
              'Dažniausiai užduodami klausimai (DUK)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildFAQItem('Kaip užsisakyti kelionę?', 'Įveskite paėmimo vietą ir kelionės tikslą, tada paspauskite „Kviesti CityRide“.'),
            _buildFAQItem('Kaip atšaukti kelionę?', 'Kelionę galite atšaukti programėlėje prieš jai prasidedant. Tam tikrais atvejais gali būti taikomas atšaukimo mokestis.'),
            _buildFAQItem('Kaip susisiekti su vairuotoju?', 'Kai vairuotojas priima užsakymą, galite naudoti Skambučio arba SMS mygtukus programėlėje.'),
            _buildFAQItem('Kaip gauti sąskaitą?', 'Visas sąskaitas rasite skiltyje „Sąskaitos“, kur jas galėsite peržiūrėti arba atsisiųsti.'),
            _buildFAQItem('Pamiršau daiktą automobilyje', 'Pirmiausia pabandykite susisiekti su vairuotoju naudodami Skambučio arba SMS mygtukus. Jei nepavyksta, susisiekite su CityRide pagalba.'),
            _buildFAQItem('Nepavyko atlikti mokėjimo', 'Patikrinkite mokėjimo kortelės duomenis arba kreipkitės į savo banką. Jei problema išlieka, parašykite mums.'),
            _buildFAQItem('Kaip pakeisti telefono numerį ar el. paštą?', 'Kontaktinius duomenis galite atnaujinti savo profilio nustatymuose.'),
            _buildFAQItem('Kaip ištrinti paskyrą?', 'Programėlėje pasirinkite „Ištrinti paskyrą“ ir patvirtinkite veiksmą.'),
            const SizedBox(height: 24),
            _buildSection('Pranešimas apie problemas', 'Jeigu pastebėjote programėlės klaidą arba neveikiančią funkciją, kuo tiksliau aprašykite problemą ir, jei galite, pridėkite ekrano nuotrauką.'),
            _buildSection('Atsakomybė', 'CityRide siekia užtikrinti patikimą paslaugų veikimą, tačiau dėl techninių ar nuo mūsų nepriklausančių priežasčių gali pasitaikyti laikinų sutrikimų.'),
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

  Widget _buildContactItem(IconData icon, String title, String value, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: Colors.black87),
      title: Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
      onTap: onTap,
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(answer, style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.4)),
        ],
      ),
    );
  }

  Future<void> _launchCaller(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  Future<void> _launchEmail(String email) async {
    final Uri url = Uri.parse('mailto:$email');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }
}
