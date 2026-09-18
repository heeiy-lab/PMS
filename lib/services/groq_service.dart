import 'dart:convert';

import 'package:http/http.dart' as http;

class GroqService {
  // 🔑 MASUKKAN API KEY GROQ KAMU DI SINI
  static const String _apiKey = '';
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String> fetchEducationTips(String topic) async {
    if (_apiKey.isEmpty || _apiKey.contains('PASTE_API_KEY')) {
      throw Exception('API Key Groq belum diisi di groq_service.dart');
    }

    final prompt =
        '''
Bertindaklah sebagai seorang dokter spesialis kandungan dan ahli kesehatan wanita yang ramah.
Berikan informasi edukasi, tips praktis, dan penjelasan singkat berbahasa Indonesia mengenai topik: "$topic".
Format jawaban dengan rapi menggunakan poin-poin penting (bullet points) agar mudah dibaca oleh wanita yang sedang mengalami PMS. Buat isinya menenangkan dan solutif.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'openai/gpt-oss-120b',
          'messages': [
            {
              'role': 'system',
              'content': 'Anda adalah edukator kesehatan wanita yang ramah. Berikan informasi umum, bukan diagnosis medis.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content'];

        if (content != null && content.toString().trim().isNotEmpty) {
          return content.toString().trim();
        } else {
          throw Exception('Respons AI kosong.');
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['error']?['message'] ?? response.body;
        throw Exception(
          'Gagal menghubungi AI (Error ${response.statusCode}): $errorMessage',
        );
      }
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
