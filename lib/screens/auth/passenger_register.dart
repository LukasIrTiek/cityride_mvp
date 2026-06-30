import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PassengerRegister extends StatefulWidget {
  const PassengerRegister({super.key});

  @override
  State<PassengerRegister> createState() =>
      _PassengerRegister();
}

class _PassengerRegister
    extends State<PassengerRegister> {

  final supabase =
      Supabase.instance.client;

  final fullNameController =
  TextEditingController();

  final phoneController =
  TextEditingController();

  final emailController =
  TextEditingController();

  final passwordController =
  TextEditingController();

  bool loading = false;

  Future<void> register() async {

    if (fullNameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        emailController.text.isEmpty ||
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

      final authResponse =
      await supabase.auth.signUp(

        email:
        emailController.text.trim(),

        password:
        passwordController.text.trim(),
      );

      final user =
          authResponse.user;

      if (user == null) return;

      await supabase
          .from('passengers')
          .insert({

        'id':
        user.id,

        'full_name':
        fullNameController.text,

        'phone':
        phoneController.text,

        'email':
        emailController.text,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(
          content: Text(
            'Registracija sėkminga',
          ),
        ),
      );

      Navigator.pop(context);

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

                'Susikurk paskyrą ir\nužsisakyk kelionę',

                textAlign:
                TextAlign.center,

                style: TextStyle(

                  fontSize: 16,

                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              /// FULL NAME
              TextField(

                controller:
                fullNameController,

                decoration:
                inputStyle(

                  'Vardas Pavardė',

                  Icons.person,
                ),
              ),

              const SizedBox(height: 18),

              /// PHONE
              TextField(

                controller:
                phoneController,

                keyboardType:
                TextInputType.phone,

                decoration:
                inputStyle(

                  'Telefono numeris',

                  Icons.phone,
                ),
              ),

              const SizedBox(height: 18),

              /// EMAIL
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

              /// PASSWORD
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

              /// BUTTON
              SizedBox(

                width: double.infinity,
                height: 60,

                child: ElevatedButton(

                  onPressed:
                  loading
                      ? null
                      : register,

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

                    'Registruotis',

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [

                  const Text(
                    'Jau turite paskyrą?',
                  ),

                  TextButton(

                    onPressed: () {

                      Navigator.pop(
                        context,
                      );
                    },

                    child: const Text(

                      'Prisijungti',

                      style: TextStyle(
                        color: Colors.red,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}