import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  // Daftar topik edukasi lengkap dengan ikon, gradasi warna, dan warna background
  final List<Map<String, dynamic>> _topics = [
    {
      'title': 'Olahraga saat PMS',
      'icon': Icons.fitness_center_rounded,
      'gradient': [const Color(0xFFFF8A9E), const Color(0xFFFE5F75)],
      'lightColor': const Color(0xFFFFF0F3),
    },
    {
      'title': 'Nutrisi & Makanan Pereda Kram',
      'icon': Icons.restaurant_rounded,
      'gradient': [const Color(0xFF6FCF97), const Color(0xFF27AE60)],
      'lightColor': const Color(0xFFE8F8F0),
    },
    {
      'title': 'Menjaga Mental Health & Mood Swings',
      'icon': Icons.psychology_rounded,
      'gradient': [const Color(0xFFFFB74D), const Color(0xFFF57C00)],
      'lightColor': const Color(0xFFFFF8E1),
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
            '---\n*Catatan Teknis:* `$e`';
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
    // Ambil data topik aktif untuk style header
    final activeTopicData = _topics.firstWhere(
      (t) => t['title'] == _selectedTopic,
      orElse: () => _topics.first,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'AI Wellness & Edukasi',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 16,
                  color: AppColors.primaryPink,
                ),
                SizedBox(width: 6),
                Text(
                  'Rekomendasi Harian Untukmu',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Horizontal Cards Selector
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _topics.length,
              itemBuilder: (context, index) {
                final item = _topics[index];
                final topicTitle = item['title'] as String;
                final gradientColors = item['gradient'] as List<Color>;
                final iconData = item['icon'] as IconData;
                final isSelected = topicTitle == _selectedTopic;

                return GestureDetector(
                  onTap: () {
                    if (!_isLoading && !isSelected) {
                      _fetchTips(topicTitle);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 145,
                    margin: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: gradientColors[0].withValues(
                            alpha: isSelected ? 0.4 : 0.15,
                          ),
                          blurRadius: isSelected ? 16 : 8,
                          offset: Offset(0, isSelected ? 6 : 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(iconData, color: Colors.white, size: 24),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 18,
                              ),
                          ],
                        ),
                        Text(
                          topicTitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Container Output Respon AI
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.softPink.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge Topik Aktif
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activeTopicData['lightColor'] as Color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedTopic,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: (activeTopicData['gradient'] as List<Color>)[1],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Area Teks AI (Markdown / Loading)
                  Expanded(
                    child: _isLoading
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: AppColors.primaryPink,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Menyiapkan rekomendasi AI...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: MarkdownBody(
                              data: _educationContent,
                              styleSheet: MarkdownStyleSheet(
                                p: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark,
                                  height: 1.6,
                                ),
                                h1: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                h2: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPink,
                                ),
                                h3: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPink,
                                ),
                                strong: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                listBullet: const TextStyle(
                                  color: AppColors.primaryPink,
                                  fontWeight: FontWeight.bold,
                                ),
                                tableBorder: TableBorder.all(
                                  color: Colors.grey.shade300,
                                  width: 1,
                                ),
                                tableHead: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryPink,
                                ),
                                tablePadding: const EdgeInsets.all(8),
                                blockquoteDecoration: BoxDecoration(
                                  color: AppColors.softPink.withValues(
                                    alpha: 0.2,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
