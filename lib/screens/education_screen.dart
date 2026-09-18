import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Import Markdown untuk UI rapi

import '../theme/app_colors.dart';
import '../services/groq_service.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  final GroqService _groqService = GroqService();

  bool _isLoading = false;
  String _educationContent = '';
  String _selectedTopic = 'Olahraga saat PMS';

  // Daftar topik edukasi lengkap dengan warna card-nya
  final List<Map<String, dynamic>> _topics = [
    {
      'title': 'Olahraga saat PMS',
      'color': const Color(0xFFE57373), // Merah muda / Coral
    },
    {
      'title': 'Nutrisi & Makanan Pereda Kram',
      'color': const Color(0xFF81C784), // Hijau pastel
    },
    {
      'title': 'Menjaga Mental Health & Mood Swings',
      'color': const Color(0xFFFFB74D), // Orange pastel
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchTips(_selectedTopic);
  }

  Future<void> _fetchTips(String topic) async {
    setState(() {
      _isLoading = true;
      _selectedTopic = topic;
      _educationContent = '';
    });

    try {
      final result = await _groqService.fetchEducationTips(topic);

      if (!mounted) return;
      setState(() {
        _educationContent = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _educationContent =
            'Layanan AI saat ini tidak tersedia. Berikut tips cadangan untukmu:\n\n'
            '${_buildFallbackContent(topic)}\n\n'
            '--- \nCatatan Teknis: $e';
        _isLoading = false;
      });
    }
  }

  String _buildFallbackContent(String topic) {
    switch (topic) {
      case 'Olahraga saat PMS':
        return '• Pilih olahraga ringan seperti jalan cepat atau yoga 15-30 menit.\n• Hindari latihan berat saat rasa nyeri sedang tinggi.\n• Konsumsi air yang cukup dan istirahat.';
      case 'Nutrisi & Makanan Pereda Kram':
        return '• Konsumsi makanan kaya magnesium seperti bayam dan alpukat.\n• Tambahkan sumber kalium seperti pisang dan yogurt.\n• Hindari kafein berlebihan dan makanan terlalu asin.';
      case 'Menjaga Mental Health & Mood Swings':
        return '• Coba teknik relaksasi seperti pernapasan dalam.\n• Prioritaskan tidur yang konsisten minimal 7 jam.\n• Batasi stres berlebih dan lakukan aktivitas yang rileks.';
      default:
        return '• Jaga pola tidur dan makan yang teratur.\n• Kelola stres dengan baik.';
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Judul Seksi Kartu Harian ala Referensi UI
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'My daily insights - Today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ),

          // Barisan Card Horizontal (Bisa di-scroll ke samping & support Double Click)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final item = _topics[index];
                final topicTitle = item['title'] as String;
                final cardColor = item['color'] as Color;
                final isSelected = topicTitle == _selectedTopic;

                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      // FITUR DOUBLE CLICK UNTUK MEMBACA ARTIKEL
                      onDoubleTap: () {
                        if (!_isLoading) {
                          _fetchTips(topicTitle);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Memuat artikel: $topicTitle'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      onTap: () {
                        // Tap biasa juga bisa mengganti topik
                        if (!_isLoading) {
                          _fetchTips(topicTitle);
                        }
                      },
                      child: Container(
                        width: 140,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: cardColor.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? Colors.white
                                : Colors.transparent,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cardColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              topicTitle,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Card Output Respon AI dengan Markdown
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.1),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryPink,
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      // Menggunakan MarkdownBody agar format AI tampil rapi
                      child: MarkdownBody(
                        data: _educationContent,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDark,
                            height: 1.6,
                          ),
                          h3: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryPink,
                          ),
                          strong: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
