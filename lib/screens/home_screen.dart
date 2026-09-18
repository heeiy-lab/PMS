import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _visibleMonthYear = DateTime.now();
  Set<DateTime> _periodDays = {};

  // Controller untuk mengontrol pergerakan scroll baris tanggal horizontal
  late final ScrollController _scrollController;

  final int _periodDuration = 5; // Durasi haid (hari)
  final int _cycleLength = 28; // Total panjang siklus (hari)
  final DateTime _startDateEpoch = DateTime(2020, 1, 1);

  @override
  void initState() {
    super.initState();
    // Inisialisasi posisi awal scroll berdasarkan hari ini
    final int initialIndex = DateTime.now().difference(_startDateEpoch).inDays;
    double initialOffset = (initialIndex - 3) * 66.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _loadPeriodDays();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // Fungsi untuk menggeser barisan tanggal horizontal secara otomatis ke tanggal tertentu
  void _scrollToSelectedDay(DateTime selectedDate) {
    final int targetIndex = selectedDate.difference(_startDateEpoch).inDays;
    final double targetOffset = (targetIndex - 3) * 66.0;

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadPeriodDays() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? savedDays = prefs.getStringList('period_days');

    if (savedDays != null) {
      setState(() {
        _periodDays = savedDays.map((day) => DateTime.parse(day)).toSet();
      });
    }
  }

  Future<void> _savePeriodDays() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> daysToSave = _periodDays
        .map((day) => day.toIso8601String())
        .toList();
    prefs.setStringList('period_days', daysToSave);
  }

  // Toggle Haid: Jika tanggal sudah jadi masa haid, batalkan (undo). Jika belum, tandai 5 hari ke depan sebagai haid.
  void _togglePeriodOnSelectedDay() {
    final normalized = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );

    setState(() {
      bool isAlreadyPeriod = _periodDays.any((d) => _isSameDay(d, normalized));

      if (isAlreadyPeriod) {
        _periodDays.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Catatan haid dibatalkan (Undo).'),
            duration: Duration(milliseconds: 1500),
          ),
        );
      } else {
        _periodDays.clear();
        for (int i = 0; i < _periodDuration; i++) {
          final d = _selectedDay.add(Duration(days: i));
          _periodDays.add(DateTime(d.year, d.month, d.day));
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Masa haid dicatat mulai ${DateFormat('d MMM yyyy').format(_selectedDay)}',
            ),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    });
    _savePeriodDays();
  }

  // Mendapatkan daftar tanggal prediksi haid berikutnya (siklus mendatang) & sebelumnya berdasarkan data tercatat
  Set<DateTime> _getPredictedPeriodDays() {
    Set<DateTime> predicted = {};
    if (_periodDays.isEmpty) return predicted;

    List<DateTime> sortedDays = _periodDays.toList()
      ..sort((a, b) => a.compareTo(b));
    DateTime latestStart = sortedDays.first;

    // Proyeksi ke depan (3 siklus berikutnya)
    for (int c = 1; c <= 3; c++) {
      DateTime nextCycleStart = latestStart.add(
        Duration(days: _cycleLength * c),
      );
      for (int i = 0; i < _periodDuration; i++) {
        DateTime d = nextCycleStart.add(Duration(days: i));
        predicted.add(DateTime(d.year, d.month, d.day));
      }
    }

    // Proyeksi ke belakang (3 siklus sebelumnya)
    for (int c = 1; c <= 3; c++) {
      DateTime prevCycleStart = latestStart.subtract(
        Duration(days: _cycleLength * c),
      );
      for (int i = 0; i < _periodDuration; i++) {
        DateTime d = prevCycleStart.add(Duration(days: i));
        predicted.add(DateTime(d.year, d.month, d.day));
      }
    }

    return predicted;
  }

  Map<String, dynamic> _getCycleStatus() {
    if (_periodDays.isEmpty) {
      return {
        'headline': 'Belum Ada Data',
        'subtext': 'Ketuk tanggal di atas, lalu ketuk tombol di bawah.',
      };
    }

    List<DateTime> sortedDays = _periodDays.toList()
      ..sort((a, b) => a.compareTo(b));
    DateTime latestPeriodStart = sortedDays.first;

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final dayInCycle = today.difference(latestPeriodStart).inDays + 1;

    if (dayInCycle >= 1 && dayInCycle <= _periodDuration) {
      return {
        'headline': 'Hari ke-$dayInCycle Haid',
        'subtext': 'Periode menstruasi sedang berlangsung.',
      };
    } else if (dayInCycle > _periodDuration && dayInCycle <= _cycleLength) {
      int daysLeft = _cycleLength - dayInCycle;
      DateTime nextPeriodDate = latestPeriodStart.add(
        Duration(days: _cycleLength),
      );
      return {
        'headline': 'Haid dalam\n$daysLeft hari',
        'subtext':
            'Estimasi berikutnya: ${DateFormat('d MMM yyyy').format(nextPeriodDate)}',
      };
    } else {
      int overdue = dayInCycle - _cycleLength;
      return {
        'headline': 'Siklus Lewat $overdue Hari',
        'subtext': 'Estimasi haid berikutnya disesuaikan.',
      };
    }
  }

  void _showMonthYearPicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visibleMonthYear,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      helpText: 'PILIH TANGGAL / BULAN TUJUAN',
    );

    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _visibleMonthYear = picked;
      });

      // Otomatis geser barisan tanggal horizontal ke tanggal pilihan user
      _scrollToSelectedDay(picked);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Berhasil memuat tanggal: ${DateFormat('d MMM yyyy').format(picked)}',
          ),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getCycleStatus();
    final int totalDaysSpan = 4000;

    final normalizedSelected = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final bool isSelectedDayPeriod = _periodDays.any(
      (d) => _isSameDay(d, normalizedSelected),
    );
    final Set<DateTime> predictedDays = _getPredictedPeriodDays();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: InkWell(
          onTap: _showMonthYearPicker,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(_visibleMonthYear),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, color: AppColors.textDark),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Baris Tanggal Horizontal Bebas Scroll
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: totalDaysSpan,
              controller: _scrollController, // Menggunakan controller dinamis
              itemBuilder: (context, index) {
                final date = _startDateEpoch.add(Duration(days: index));
                final isSelected = _isSameDay(date, _selectedDay);

                final normalized = DateTime(date.year, date.month, date.day);
                final isPeriodDay = _periodDays.any(
                  (d) => _isSameDay(d, normalized),
                );
                final isPredictedDay = predictedDays.any(
                  (d) => _isSameDay(d, normalized),
                );

                Color containerColor = Colors.white;
                Border? borderStyle;

                if (isSelected) {
                  containerColor = AppColors.primaryPink;
                } else if (isPeriodDay) {
                  containerColor = AppColors.primaryPink.withValues(alpha: 0.8);
                } else if (isPredictedDay) {
                  containerColor = AppColors.softPink.withValues(alpha: 0.5);
                  borderStyle = Border.all(
                    color: AppColors.primaryPink.withValues(alpha: 0.6),
                    width: 1.2,
                  );
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = date;
                      _visibleMonthYear = date;
                    });
                    _scrollToSelectedDay(date);
                  },
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: containerColor,
                      borderRadius: BorderRadius.circular(16),
                      border: borderStyle,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 15,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat('MMM').format(date),
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const Spacer(),

          // Kartu Lingkaran Tengah Utama
          Center(
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('EEEE, d MMMM yyyy').format(_selectedDay),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    status['headline'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      status['subtext'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _togglePeriodOnSelectedDay,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelectedDayPeriod
                          ? Colors.grey.shade400
                          : AppColors.primaryPink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isSelectedDayPeriod
                          ? 'Batalkan Haid (Undo)'
                          : 'Tandai Haid (Day 1)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}
