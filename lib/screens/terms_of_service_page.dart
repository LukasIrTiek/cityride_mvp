import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Naudojimosi taisyklės'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CITYRIDE NAUDOJIMOSI TAISYKLĖS',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Paskutinį kartą atnaujinta: 2026-06-25'),
            const SizedBox(height: 24),
            _buildSection('1. Bendrosios nuostatos', 
              'Šios naudojimosi taisyklės reglamentuoja naudojimąsi CityRide keleivių ir vairuotojų programėlėmis.\n\n'
              'Naudodamiesi CityRide programėle patvirtinate, kad susipažinote su šiomis taisyklėmis ir sutinkate jų laikytis.'
            ),
            _buildSection('2. Paslaugos aprašymas', 
              'CityRide yra platforma, jungianti keleivius ir vairuotojus, suteikianti galimybę užsisakyti keleivių vežimo paslaugas.\n\n'
              'CityRide organizuoja užsakymų perdavimą tarp keleivių ir vairuotojų bei administruoja platformos veikimą.'
            ),
            _buildSection('3. Registracija', 
              'Norint naudotis CityRide būtina:\n\n'
              '• sukurti paskyrą;\n'
              '• pateikti teisingus duomenis;\n'
              '• naudoti tik savo telefono numerį;\n'
              '• saugoti prisijungimo duomenis.\n\n'
              'Vartotojas atsako už visą veiklą savo paskyroje.'
            ),
            _buildSection('4. Kelionių užsakymas', 
              'Keleivis gali:\n\n'
              '• pasirinkti paėmimo vietą;\n'
              '• pasirinkti kelionės tikslą;\n'
              '• matyti preliminarią kainą;\n'
              '• pateikti užsakymą;\n'
              '• stebėti vairuotojo atvykimą realiu laiku.\n\n'
              'Galutinė kaina gali skirtis, jeigu pasikeičia maršrutas arba kelionės sąlygos.'
            ),
            _buildSection('5. Mokėjimai', 
              'Mokėjimai gali būti atliekami:\n\n'
              '• banko kortele;\n'
              '• grynaisiais (jeigu ši funkcija palaikoma).\n\n'
              'Vartotojas atsako už teisingų mokėjimo duomenų pateikimą.'
            ),
            _buildSection('6. Atšaukimas', 
              'Keleivis gali atšaukti kelionę.\n\n'
              'Tam tikrais atvejais gali būti taikomas atšaukimo mokestis, jei tai numatyta programėlėje.'
            ),
            _buildSection('7. Vartotojo pareigos', 
              'Naudodamasis CityRide vartotojas privalo:\n\n'
              '• pateikti teisingą informaciją;\n'
              '• gerbti vairuotojus ir kitus keleivius;\n'
              '• laikytis Lietuvos Respublikos įstatymų;\n'
              '• nenaudoti programėlės neteisėtiems tikslams.\n\n'
              'Draudžiama:\n\n'
              '• naudoti svetimą paskyrą;\n'
              '• pateikti melagingą informaciją;\n'
              '• trikdyti programėlės veikimą;\n'
              '• piktnaudžiauti užsakymų sistema.'
            ),
            _buildSection('8. Vairuotojų pareigos', 
              'Vairuotojai privalo:\n\n'
              '• turėti teisę teikti keleivių vežimo paslaugas;\n'
              '• laikytis kelių eismo taisyklių;\n'
              '• užtikrinti keleivių saugumą;\n'
              '• teikti tikslią informaciją.'
            ),
            _buildSection('9. Atsakomybės ribojimas', 
              'CityRide deda visas pastangas užtikrinti stabilų platformos veikimą, tačiau negarantuoja, kad paslauga visada veiks be trikdžių.\n\n'
              'CityRide neatsako už:\n\n'
              '• interneto ryšio sutrikimus;\n'
              '• trečiųjų šalių paslaugų veikimą;\n'
              '• force majeure aplinkybes.'
            ),
            _buildSection('10. Paskyros sustabdymas', 
              'CityRide gali laikinai arba visam laikui apriboti paskyrą, jei:\n\n'
              '• pažeidžiamos šios taisyklės;\n'
              '• naudojama neteisėta veikla;\n'
              '• piktnaudžiaujama sistema;\n'
              '• kyla grėsmė kitų vartotojų saugumui.'
            ),
            _buildSection('11. Intelektinė nuosavybė', 
              'Visi CityRide logotipai, dizainas, programinė įranga ir turinys priklauso CityRide.\n\n'
              'Be raštiško sutikimo draudžiama kopijuoti ar platinti programėlės turinį.'
            ),
            _buildSection('12. Taisyklių keitimas', 
              'CityRide gali bet kada atnaujinti šias naudojimosi taisykles.\n\n'
              'Atnaujinta versija bus paskelbta programėlėje.'
            ),
            _buildSection('13. Taikoma teisė', 
              'Šioms taisyklėms taikomi Lietuvos Respublikos įstatymai.\n\n'
              'Visi ginčai sprendžiami Lietuvos Respublikos teisės aktų nustatyta tvarka.'
            ),
            _buildSection('14. Kontaktai', 
              'CityRide\n'
              'Įmonės kodas: 307727101\n'
              'Adresas:\n'
              'Laisvės al. 85E-5, LT-44297 Kaunas\n'
              'Telefonas:\n'
              '+370 648 42016\n'
              'El. paštas:\n'
              'cityride.apps@gmail.com'
            ),
            const SizedBox(height: 16),
            const Text(
              'Baigiamosios nuostatos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Naudodamiesi CityRide programėle patvirtinate, kad perskaitėte, supratote ir sutinkate laikytis šių naudojimosi taisyklių.',
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
