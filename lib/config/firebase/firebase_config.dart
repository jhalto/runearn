import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfig {
  FirebaseConfig._();

  static String get googleWebClientId => dotenv.get('CLIENT_ID');
}