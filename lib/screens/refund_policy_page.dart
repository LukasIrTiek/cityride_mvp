import 'package:flutter/material.dart';

class RefundPolicyPage extends StatelessWidget {
  const RefundPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pinigų grąžinimo politika'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PINIGŲ GRĄŽINIMO POLITIKA',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Paskutinį kartą atnaujinta: 2026-06-25'),
            const SizedBox(height: 24),
            _buildSection('1. Bendros nuostatos', 
              'CityRide siekia užtikrinti sąžiningą ir skaidrų atsiskaitymą už visas keliones. Jei manote, kad mokėjimas buvo atliktas neteisingai, galite kreiptis dėl jo peržiūros.'
            ),
            _buildSection('2. Kada gali būti grąžinami pinigai?', 
              'Pinigai gali būti grąžinti šiais atvejais:\n\n'
              '• Mokėjimas buvo nuskaitytas du kartus.\n'
              '• Kelionė neįvyko, tačiau mokėjimas buvo nuskaičiuotas.\n'
              '• Dėl techninės klaidos buvo apskaičiuota neteisinga kelionės kaina.\n'
              '• Mokėjimas įvyko dėl sistemos klaidos.'
            ),
            _buildSection('3. Kada pinigai negrąžinami?', 
              'Pinigai paprastai nėra grąžinami, jeigu:\n\n'
              '• Kelionė buvo sėkmingai įvykdyta.\n'
              '• Keleivis pats atšaukė kelionę po nemokamo atšaukimo laikotarpio.\n'
              '• Keleivis nepasirodė sutartoje paėmimo vietoje.\n'
              '• Ginčas kilo dėl eismo sąlygų, maršruto ar kitų nuo CityRide nepriklausančių aplinkybių.'
            ),
            _buildSection('4. Kaip pateikti prašymą?', 
              'Norėdami pateikti pinigų grąžinimo prašymą, susisiekite su mumis:\n\n'
              'El. paštas: cityride.apps@gmail.com\n\n'
              'Prašyme nurodykite:\n'
              '• kelionės datą;\n'
              '• užsakymo informaciją;\n'
              '• problemos aprašymą.'
            ),
            _buildSection('5. Prašymų nagrinėjimas', 
              'Visi prašymai peržiūrimi individualiai. Atsakymą siekiame pateikti kuo greičiau.\n\n'
              'Jeigu grąžinimas patvirtinamas, pinigai grąžinami tuo pačiu mokėjimo būdu, kuriuo buvo atliktas mokėjimas.'
            ),
            _buildSection('6. Kontaktai', 
              'CityRide\n'
              'Įmonės kodas: 307727101\n'
              'Adresas:\n'
              'Laisvės al. 85E-5, LT-44297 Kaunas, Lietuva\n'
              'Telefonas:\n'
              '+370 648 42016\n'
              'El. paštas:\n'
              'cityride.apps@gmail.com'
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
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
