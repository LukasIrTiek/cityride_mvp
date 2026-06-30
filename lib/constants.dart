import 'package:flutter_dotenv/flutter_dotenv.dart';

// Naudojame getterį, kad užtikrintume, jog dotenv jau užkrautas
String get googleApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
