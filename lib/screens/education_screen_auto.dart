import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../theme/app_colors.dart';

class EducationScreenAuto extends StatefulWidget {
  const EducationScreenAuto({super.key});

  @override
  State<EducationScreenAuto> createState() => _EducationScreenAutoState();
}

class _EducationScreenAutoState extends State<EducationScreenAuto> {
  static const String groqApiKey = String.fromEnvironment(
    'GROQ_API_KEY',
    defaultValue: '',
  );

  bool _isLoading = false;
  String _educationContent = '';
  String _selectedTopic = 'Olahraga saat PMS';

  final List<String> _topics = [
    'Olahraga saat PMS',
    'Nutrisi & Makanan Pereda Kram',
    'Menjaga Mental Health & Mood Swings',
  ];

  @override
  void initState() {
    super.initState();
    _fetchGroqTips(_selectedTopic);
  }

  String _buildFallbackContent(String topic) {
    switch (topic) {
      case 'Olahraga saat PMS':
        return '''• Pilih olahraga ringan seperti jalan cepat, yoga, atau stretching 15270 menit, 35 kali seminggu.
• Hindari latihan berat saat rasa nyeri atau lelah sedang tinggi.
• Prioritaskan pemanasan dan pendampingan napas agar tubuh tetap rileks.
• Konsumsi air yang cukup dan istirahat bila tubuh merasa cepat lelah.
''';
      case 'Nutrisi & Makanan Pereda Kram':
        return '''
• Konsumsi makanan kaya magnesium seperti kacang, biji-bijian, bayam, dan alpukat.
• Tambahkan sumber kalium seperti pisang, kentang, dan yogurt untuk membantu keseimbangan cairan.
• Hindari kafein berlebihan, makanan terlalu asin, dan gula cepat naik saat gejala mulai muncul.
• Makan dalam porsi kecil tapi sering agar perut tidak kembung dan tetap nyaman.
''';
      case 'Menjaga Mental Health & Mood Swings':
        return '''
• Coba teknik relaksasi seperti pernapasan dalam, meditasi singkat, atau yoga ringan.
• Berikan waktu istirahat yang cukup dan prioritaskan tidur yang konsisten.
• Bicarakan perubahan mood dengan orang terdekat agar tidak merasa sendirian.
• Batasi stres berlebih dan tetap lakukan aktivitas yang membuat rileks.
''';
      default:
        return '''
• Jaga pola tidur dan makan yang teratur.
• Minum air yang cukup dan hindari stres berlebihan.
• Dengarkan tubuh Anda dan pilih aktivitas yang membuat nyaman.
''';
    }
  }

  Future<void> _fetchGroqTips(String topic) async {
    setState(() {
      _isLoading = true;
      _selectedTopic = topic;
      _educationContent = '';
    });

    final prompt =
        '''
Bertindaklah sebagai seorang dokter spesialis kandungan dan ahli kesehatan wanita yang ramah.
Berikan informasi edukasi, tips praktis, dan penjelasan singkat berbahasa Indonesia mengenai topik: "$topic".
Format jawaban dengan rapi menggunakan poin-poin penting (bullet points) agar mudah dibaca oleh wanita yang sedang mengalami PMS. Buat isinya menenangkan dan solutif.
''';

    String? resultText;
    String lastError = '';

    if (groqApiKey.isEmpty) {
      lastError = 'GROQ_API_KEY belum dikonfigurasi. Jalankan aplikasi dengan --dart-define.';
    } else {
      try {
        final selectedModel = await _getAvailableModel();

        final response = await http.post(
          Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
          headers: {
            'Authorization': 'Bearer $groqApiKey',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': selectedModel,
            'messages': [
              {
                'role': 'system',
                'content':
                    'Anda adalah edukator kesehatan wanita yang ramah. '
                    'Berikan informasi umum, bukan diagnosis medis.',
              },
              {'role': 'user', 'content': prompt},
            ],
            'temperature': 0.7,
            'max_tokens': 500,
          }),
        );

        final responseBody = _decodeResponse(response.body);
        if (response.statusCode >= 200 && response.statusCode < 300) {
          final choices = responseBody['choices'];
          final firstChoice = choices is List && choices.isNotEmpty ? choices.first : null;
          final message = firstChoice is Map ? firstChoice['message'] : null;
          final content = message is Map ? message['content'] : null;
          if (content is String && content.trim().isNotEmpty) {
            resultText = content.trim();
          } else {
            lastError = 'Respons Groq tidak berisi konten.';
          }
        } else {
          final error = responseBody['error'];
          final message = error is Map ? error['message'] : null;
          lastError = message is String
              ? 'HTTP ${response.statusCode}: $message'
              : 'HTTP ${response.statusCode}: ${response.body}';
        }
      } catch (e) {
        lastError = e.toString();
      }
    }

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (resultText != null) {
        _educationContent = resultText;
      } else {
        _educationContent =
            'Konten edukasi cadangan digunakan karena layanan AI saat ini tidak tersedia.\n\n${_buildFallbackContent(topic)}\n\nCatatan teknis: ${_formatGroqError(lastError)}';
      }
    });
  }

  Future<String> _getAvailableModel() async {
    // Preferred models in order
    final preferred = [
      'llama-3.3-70b-versatile',
      'llama-3.1-8b-instant',
      'llama-3.1-8b',
      'gemma2-9b-it',
    ];

    try {
      final resp = await http.get(
        Uri.parse('https://api.groq.com/openai/v1/models'),
        headers: {'Authorization': 'Bearer $groqApiKey'},
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final map = _decodeResponse(resp.body);
        final data = map['data'] ?? map['models'] ?? map['model'] ?? map['result'];
        final available = <String>{};
        if (data is List) {
          for (final item in data) {
            if (item is Map) {
              final id = item['id'] ?? item['name'] ?? item['model'];
              if (id is String) available.add(id);
            } else if (item is String) {
              available.add(item);
            }
          }
        }

        for (final p in preferred) {
          if (available.contains(p)) return p;
        }
      }
    } catch (_) {
      // ignore and fallback
    }

    // fallback default
    return 'llama-3.1-8b-instant';
  }

  String _formatGroqError(String error) {
    final normalizedError = error.toLowerCase();
    if (normalizedError.contains('401') ||
        normalizedError.contains('invalid api key') ||
        normalizedError.contains('unauthorized')) {
      return 'API key Groq ditolak. Detail: $error';
    }
    if (normalizedError.contains('429') ||
        normalizedError.contains('rate limit')) {
      return 'Batas penggunaan Groq tercapai. Detail: $error';
    }
    return 'Groq gagal dihubungi. Detail: $error';
  }

  Map<String, dynamic> _decodeResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'raw': body};
    } on FormatException {
      return <String, dynamic>{'raw': body};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Wellness & Edukasi PMS',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // Pilihan Kategori Topik
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final topic = _topics[index];
                final isSelected = topic == _selectedTopic;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(topic),
                    selected: isSelected,
                    selectedColor: AppColors.primaryPink,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textDark,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      if (selected && !_isLoading) {
                        _fetchGroqTips(topic);
                      }
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Card Output Respon Gemini AI
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Text(
                        _educationContent,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
