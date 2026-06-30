import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../auth_gate.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'help_page.dart';
import 'about_page.dart';
import 'delete_account_page.dart';
import 'refund_policy_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? profileData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;
      final userId = user.id;

      // Krauname kliento duomenis iš 'passengers' lentelės
      final data = await supabase
          .from('passengers')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          profileData = data;
          loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> _updatePhone() async {
    final TextEditingController phoneController = TextEditingController(text: profileData?['phone']);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Atnaujinti telefoną'),
        content: TextField(
          controller: phoneController, 
          decoration: const InputDecoration(labelText: 'Telefono numeris'),
          keyboardType: TextInputType.phone,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Atšaukti')),
          ElevatedButton(
            onPressed: () async {
              try {
                await supabase.from('passengers').update({
                  'phone': phoneController.text.trim(),
                }).eq('id', supabase.auth.currentUser!.id);
                if (mounted) Navigator.pop(context);
                loadProfile();
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Klaida: $e')));
              }
            },
            child: const Text('Išsaugoti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.light ? Colors.grey.shade50 : null,
      appBar: AppBar(
        title: const Text('Profilis', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.black12,
                    backgroundImage: (profileData?['profile_photo'] != null)
                        ? NetworkImage(profileData!['profile_photo']) 
                        : null,
                    child: (profileData?['profile_photo'] == null)
                        ? const Icon(Icons.person, color: Colors.white, size: 60) 
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profileData?['full_name'] ?? 'Keleivis',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Paskyra'),
                  _buildProfileItem(Icons.person_outline, profileData?['full_name'] ?? 'Vardas Pavardė', null),
                  _buildProfileItem(Icons.email_outlined, profileData?['email'] ?? 'El. paštas', null),
                  _buildProfileItem(
                    Icons.phone_outlined, 
                    profileData?['phone'] ?? 'Pridėti telefoną', 
                    _updatePhone
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Nustatymai'),
                  _buildProfileItem(Icons.settings_outlined, 'Programėlės tema', () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Pasirinkite temą'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              title: const Text('Šviesi'),
                              onTap: () { themeNotifier.value = ThemeMode.light; Navigator.pop(context); },
                            ),
                            ListTile(
                              title: const Text('Tamsi'),
                              onTap: () { themeNotifier.value = ThemeMode.dark; Navigator.pop(context); },
                            ),
                            ListTile(
                              title: const Text('Sistemos numatyta'),
                              onTap: () { themeNotifier.value = ThemeMode.system; Navigator.pop(context); },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 24),
                  _buildSectionTitle('Informacija'),
                  _buildProfileItem(Icons.privacy_tip_outlined, 'Privatumo politika', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()));
                  }),
                  _buildProfileItem(Icons.description_outlined, 'Naudojimosi taisyklės', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServicePage()));
                  }),
                  _buildProfileItem(Icons.assignment_return_outlined, 'Pinigų grąžinimo politika', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundPolicyPage()));
                  }),
                  _buildProfileItem(Icons.help_outline, 'Pagalba', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpPage()));
                  }),
                  _buildProfileItem(Icons.info_outline, 'Apie CityRide', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()));
                  }),
                  _buildProfileItem(Icons.delete_forever_outlined, 'Ištrinti paskyrą', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountPage()));
                  }),

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () async {
                        await supabase.auth.signOut();
                        if (!mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthGate()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade50,
                        foregroundColor: Colors.red,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Atsijungti', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
      ),
    );
  }

  Widget _buildProfileItem(IconData icon, String title, VoidCallback? onTap) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).brightness == Brightness.light ? Colors.black87 : Colors.white70),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
