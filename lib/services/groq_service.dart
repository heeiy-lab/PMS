import 'dart:convert';

import 'package:http/http.dart' as http;

class GroqService {
  // Sekarang panggil server backend lokal, bukan api.groq.com langsung
  static const String _backendUrl = 'http://localhost:3000/api/chat';

  Future<String> fetchEducationTips(String topic) async {
    try {
      final response = await http.post(
        Uri.parse(_backendUrl),
        headers: {
          'Content-Type': 'application/json',
          // Perhatikan: Tidak ada lagi Header 'Authorization' / API Key di sini!
        },
        body: jsonEncode({'topic': topic}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? 'Respons AI kosong.';
      } else {
        throw Exception('Gagal terhubung ke backend proxy.');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}
