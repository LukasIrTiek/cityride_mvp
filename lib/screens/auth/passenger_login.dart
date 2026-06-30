import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/passenger_home.dart';
import '../passenger_home.dart';
import 'passenger_register.dart';

class PassengerLogin extends StatefulWidget {
  const PassengerLogin({super.key});

  @override
  State<PassengerLogin> createState() =>
      _PassengerLoginPageState();
}

class _PassengerLoginPageState
    extends State<PassengerLogin> {

  final supabase =
      Supabase.instance.client;

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  bool loading = false;

  Future<void> login() async {

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Užpildykite visus laukus',
          ),
        ),
      );

      return;
    }

    try {

      setState(() {
        loading = true;
      });

      await supabase.auth
          .signInWithPassword(

        email:
        emailController.text.trim(),

        password:
        passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Prisijungta',
          ),
        ),
      );

      /// HOME PAGE
      Navigator.pushAndRemoveUntil(

        context,

        MaterialPageRoute(

          builder: (_) =>
          const PassengerHome(),
        ),

            (route) => false,
      );

    } catch (e) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        SnackBar(
          content: Text(
            e.toString(),
          ),
        ),
      );
    }

    setState(() {
      loading = false;
    });
  }

  InputDecoration inputStyle(
      String hint,
      IconData icon,
      ) {

    return InputDecoration(

      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: Colors.red,
      ),

      filled: true,

      fillColor: Colors.white,

      contentPadding:
      const EdgeInsets.symmetric(
        vertical: 18,
      ),

      border:
      OutlineInputBorder(

        borderRadius:
        BorderRadius.circular(18),

        borderSide:
        BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
      const Color(0xffF7F7F7),

      body: SafeArea(

        child: SingleChildScrollView(

          padding:
          const EdgeInsets.all(24),

          child: Column(

            children: [

              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.asset(
                  'lib/assets/logo.png',
                  width: 110,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_taxi,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(

                'CityRide',

                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              const Text(

                'Prisijunkite prie savo paskyros',

                textAlign:
                TextAlign.center,

                style: TextStyle(

                  fontSize: 16,

                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              TextField(

                controller:
                emailController,

                keyboardType:
                TextInputType.emailAddress,

                decoration:
                inputStyle(

                  'El. paštas',

                  Icons.email,
                ),
              ),

              const SizedBox(height: 18),

              TextField(

                controller:
                passwordController,

                obscureText: true,

                decoration:
                inputStyle(

                  'Slaptažodis',

                  Icons.lock,
                ),
              ),

              const SizedBox(height: 34),

              Row(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  const Text(
                    'Neturi paskyros?',
                  ),

                  TextButton(

                    onPressed: () {

                      Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) =>
                          const PassengerRegister(),
                        ),
                      );
                    },

                    child: const Text(

                      'Registruokis',

                      style: TextStyle(
                        color: Colors.red,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              SizedBox(

                width: double.infinity,
                height: 60,

                child: ElevatedButton(

                  onPressed:
                  loading
                      ? null
                      : login,

                  style:
                  ElevatedButton.styleFrom(

                    backgroundColor:
                    Colors.red,

                    foregroundColor:
                    Colors.white,

                    elevation: 0,

                    shape:
                    RoundedRectangleBorder(

                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),
                    ),
                  ),

                  child:

                  loading

                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )

                      : const Text(

                    'Prisijungti',

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),


            ],
          ),
        ),
      ),
    );
  }
}