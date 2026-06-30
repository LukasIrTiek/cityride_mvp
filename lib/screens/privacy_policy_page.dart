import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privatumo politika'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CITYRIDE PRIVATUMO POLITIKA',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Paskutinį kartą atnaujinta: 2026-06-25'),
            const SizedBox(height: 24),
            _buildSection('1. Bendrosios nuostatos', 
              'Sveiki atvykę į CityRide.\n\n'
              'Šioje Privatumo politikoje paaiškinama, kokius asmens duomenis renkame, kaip juos naudojame, saugome ir kokias teises turite naudodamiesi CityRide keleivių ir vairuotojų programėlėmis.\n\n'
              'Naudodamiesi CityRide programėle Jūs patvirtinate, kad susipažinote su šia Privatumo politika.'
            ),
            _buildSection('2. Duomenų valdytojas', 
              'CityRide\n'
              'Įmonės kodas: 307727101\n'
              'Vadovas: Lukas Petkevičius\n'
              'Adresas:\n'
              'Laisvės al. 85E-5, LT-44297 Kaunas, Lietuva\n'
              'Telefonas:\n'
              '+370 648 42016\n'
              'El. paštas:\n'
              'cityride.apps@gmail.com'
            ),
            _buildSection('3. Kokius duomenis renkame', 
              'Naudojantis CityRide gali būti renkami šie duomenys:\n\n'
              '• Vardas ir pavardė;\n'
              '• Telefono numeris;\n'
              '• El. pašto adresas;\n'
              '• Profilio nuotrauka (jei ją įkeliate);\n'
              '• GPS vietos duomenys;\n'
              '• Paėmimo vieta;\n'
              '• Kelionės tikslas;\n'
              '• Kelionių istorija;\n'
              '• Mokėjimų informacija;\n'
              '• Sąskaitų informacija;\n'
              '• Įrenginio modelis;\n'
              '• Operacinės sistemos versija;\n'
              '• IP adresas;\n'
              '• Firebase identifikatoriai;\n'
              '• Push Notification (FCM) identifikatoriai;\n'
              '• Programėlės naudojimo statistika.'
            ),
            _buildSection('4. Kam naudojami Jūsų duomenys', 
              'Jūsų duomenys naudojami:\n\n'
              '• Registracijai;\n'
              '• Prisijungimui;\n'
              '• Paskyros administravimui;\n'
              '• Artimiausio vairuotojo paieškai;\n'
              '• Maršruto sudarymui;\n'
              '• Kelionės vykdymui;\n'
              '• Kainos apskaičiavimui;\n'
              '• Mokėjimų apdorojimui;\n'
              '• Sąskaitų išrašymui;\n'
              '• Pranešimų siuntimui;\n'
              '• Susisiekimui tarp keleivio ir vairuotojo;\n'
              '• Sukčiavimo prevencijai;\n'
              '• Paslaugų kokybės gerinimui;\n'
              '• Klientų aptarnavimui;\n'
              '• Teisinių prievolių vykdymui.'
            ),
            _buildSection('5. Vietos duomenys', 
              'CityRide naudoja Jūsų buvimo vietą tam, kad:\n\n'
              '• Surastų artimiausią vairuotoją;\n'
              '• Apskaičiuotų preliminarų atvykimo laiką (ETA);\n'
              '• Nubraižytų maršrutą;\n'
              '• Vykdytų aktyvią kelionę;\n'
              '• Užbaigtų kelionę;\n'
              '• Pagerintų navigacijos tikslumą.\n\n'
              'Vietos duomenys nėra naudojami reklamos ar rinkodaros tikslais.'
            ),
            _buildSection('6. Mokėjimai', 
              'Jeigu naudojate mokėjimą banko kortele:\n\n'
              '• CityRide nesaugo pilnų banko kortelių numerių;\n'
              '• Mokėjimus tvarko sertifikuoti mokėjimų paslaugų teikėjai;\n'
              '• Mokėjimo duomenys perduodami tik saugiais ryšiais.'
            ),
            _buildSection('7. Kam perduodami duomenys', 
              'Jūsų duomenys gali būti perduodami tik:\n\n'
              '• Priskirtam vairuotojui;\n'
              '• Keleiviui;\n'
              '• Mokėjimų paslaugų teikėjams;\n'
              '• Google Maps paslaugoms;\n'
              '• Firebase paslaugoms;\n'
              '• Teisėsaugos institucijoms, kai to reikalauja Lietuvos Respublikos teisės aktai.\n\n'
              'CityRide neparduoda ir nenuomoja Jūsų asmens duomenų trečiosioms šalims.'
            ),
            _buildSection('8. Duomenų saugojimas', 
              'Asmens duomenys saugomi tiek laiko, kiek būtina:\n\n'
              '• Kelionių vykdymui;\n'
              '• Mokėjimų administravimui;\n'
              '• Sąskaitų išrašymui;\n'
              '• Teisinių prievolių vykdymui;\n'
              '• Ginčų nagrinėjimui;\n'
              '• Sukčiavimo prevencijai.'
            ),
            _buildSection('9. Duomenų saugumas', 
              'CityRide naudoja:\n\n'
              '• Firebase Authentication;\n'
              '• SSL/TLS šifravimą;\n'
              '• Saugias duomenų bazes;\n'
              '• Prieigos kontrolę;\n'
              '• Autentifikaciją;\n'
              '• Reguliarius saugumo atnaujinimus.\n\n'
              'Dedame visas pagrįstas pastangas apsaugoti Jūsų informaciją nuo neteisėtos prieigos, praradimo ar pakeitimo.'
            ),
            _buildSection('10. Jūsų teisės', 
              'Pagal BDAR (GDPR) Jūs turite teisę:\n\n'
              '• Gauti informaciją apie tvarkomus duomenis;\n'
              '• Ištaisyti neteisingus duomenis;\n'
              '• Prašyti ištrinti savo duomenis;\n'
              '• Apriboti duomenų tvarkymą;\n'
              '• Gauti savo duomenų kopiją;\n'
              '• Atšaukti sutikimą dėl duomenų tvarkymo;\n'
              '• Pateikti skundą Valstybinei duomenų apsaugos inspekcijai.'
            ),
            _buildSection('11. Paskyros ištrynimas', 
              'Programėlėje galite pasirinkti funkciją „Ištrinti paskyrą“.\n\n'
              'Ištrynus paskyrą:\n\n'
              '• pašalinama Firebase Authentication paskyra;\n'
              '• pašalinami vartotojo duomenys iš Firestore;\n'
              '• ištrinami vietiniai programėlės duomenys;\n'
              '• vartotojas automatiškai atjungiamas.\n\n'
              'Tam tikri apskaitos ar teisės aktuose numatyti duomenys gali būti saugomi tiek, kiek to reikalauja Lietuvos Respublikos teisės aktai.'
            ),
            _buildSection('12. Nepilnamečiai', 
              'CityRide paslaugos nėra skirtos jaunesniems nei 18 metų asmenims, nebent jie naudojasi paslauga teisėto atstovo vardu ar su jo sutikimu.'
            ),
            _buildSection('13. Privatumo politikos pakeitimai', 
              'CityRide gali bet kuriuo metu atnaujinti šią Privatumo politiką.\n\n'
              'Naujausia versija visada bus prieinama programėlėje ir (jeigu naudojama) oficialioje svetainėje.'
            ),
            _buildSection('14. Kontaktai', 
              'Jeigu turite klausimų dėl šios Privatumo politikos arba Jūsų asmens duomenų tvarkymo, susisiekite su mumis.\n\n'
              'CityRide\n'
              'Įmonės kodas: 307727101\n'
              'Adresas:\n'
              'Laisvės al. 85E-5, LT-44297 Kaunas, Lietuva\n'
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
              'Naudodamiesi CityRide programėle patvirtinate, kad susipažinote su šia Privatumo politika ir sutinkate su joje nurodytomis sąlygomis.',
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
