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

  Set<String> _periodDays = {};
  Set<String> _pausedDays = {};

  late final ScrollController _scrollController;

  final int _defaultPeriodSpan = 5;
  int _cycleLength = 28;
  final DateTime _startDateEpoch = DateTime(2020, 1, 1);

  @override
  void initState() {
    super.initState();
    final int initialIndex = DateTime.now().difference(_startDateEpoch).inDays;
    double initialOffset = (initialIndex - 3) * 66.0;
    _scrollController = ScrollController(initialScrollOffset: initialOffset);

    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _cleanDate(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  String _formatKey(DateTime d) {
    return DateFormat('yyyy-MM-dd').format(d);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

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

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _periodDays = (prefs.getStringList('period_days') ?? []).toSet();
      _pausedDays = (prefs.getStringList('paused_days') ?? []).toSet();
      _cycleLength = prefs.getInt('cycle_length') ?? 28;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('period_days', _periodDays.toList());
    await prefs.setStringList('paused_days', _pausedDays.toList());
    await prefs.setInt('cycle_length', _cycleLength);
  }

  Future<void> _resetAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('period_days');
    await prefs.remove('paused_days');
    await prefs.remove('cycle_length');
    setState(() {
      _periodDays.clear();
      _pausedDays.clear();
      _cycleLength = 28;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Semua data berhasil di-reset!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showCycleLengthSettings() {
    int tempLength = _cycleLength;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Atur Rata-rata Siklus Haid',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pilih jarak hari dari hari pertama haid ke haid berikutnya:',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '$tempLength Hari',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryPink,
                    ),
                  ),
                  Slider(
                    value: tempLength.toDouble(),
                    min: 21,
                    max: 35,
                    divisions: 14,
                    label: '$tempLength Hari',
                    activeColor: AppColors.primaryPink,
                    onChanged: (val) {
                      setModalState(() {
                        tempLength = val.toInt();
                      });
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        '21 Hari (Pendek)',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '28 Hari (Normal)',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                      Text(
                        '35 Hari (Panjang)',
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _cycleLength = tempLength;
                        });
                        _saveData();
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startPeriod() {
    final cleanSelected = _cleanDate(_selectedDay);
    setState(() {
      for (int i = 0; i < _defaultPeriodSpan; i++) {
        final dateKey = _formatKey(cleanSelected.add(Duration(days: i)));
        _periodDays.add(dateKey);
        _pausedDays.remove(dateKey);
      }
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Rentang haid dicatat mulai ${DateFormat('d MMM').format(_selectedDay)}',
        ),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _markAsPaused() {
    final key = _formatKey(_selectedDay);
    setState(() {
      _periodDays.remove(key);
      _pausedDays.add(key);
    });
    _saveData();
  }

  void _resumePeriod() {
    final key = _formatKey(_selectedDay);
    setState(() {
      _pausedDays.remove(key);
      _periodDays.add(key);
    });
    _saveData();
  }

  void _clearDayRecord() {
    final key = _formatKey(_selectedDay);
    setState(() {
      _periodDays.remove(key);
      _pausedDays.remove(key);
    });
    _saveData();
  }

  DateTime? _getLatestPeriodStart() {
    if (_periodDays.isEmpty) return null;

    final cleanSelected = _cleanDate(_selectedDay);

    List<DateTime> sorted =
        _periodDays
            .map((e) => _cleanDate(DateTime.parse(e)))
            .where((d) => !d.isAfter(cleanSelected))
            .toList()
          ..sort((a, b) => a.compareTo(b));

    if (sorted.isEmpty) {
      sorted = _periodDays.map((e) => _cleanDate(DateTime.parse(e))).toList()
        ..sort((a, b) => a.compareTo(b));
    }

    List<DateTime> blockStarts = [];
    for (var d in sorted) {
      DateTime prev = d.subtract(const Duration(days: 1));
      String prevKey = _formatKey(prev);
      if (!_periodDays.contains(prevKey) && !_pausedDays.contains(prevKey)) {
        blockStarts.add(d);
      }
    }

    return blockStarts.isNotEmpty ? blockStarts.last : sorted.first;
  }

  DateTime? _getNextPredictedPeriodDate({int? customCycle}) {
    final latestStart = _getLatestPeriodStart();
    if (latestStart == null) return null;

    return latestStart.add(Duration(days: customCycle ?? _cycleLength));
  }

  Set<String> _getPredictedPeriodDays() {
    Set<String> predicted = {};
    final latestStart = _getLatestPeriodStart();
    if (latestStart == null) return predicted;

    for (int cycle = 1; cycle <= 6; cycle++) {
      DateTime nextCycleStart = latestStart.add(
        Duration(days: _cycleLength * cycle),
      );
      for (int day = 0; day < _defaultPeriodSpan; day++) {
        DateTime d = nextCycleStart.add(Duration(days: day));
        predicted.add(_formatKey(d));
      }
    }

    return predicted;
  }

  bool _isIrregularFlow(DateTime currentDay) {
    DateTime searchStart = _cleanDate(currentDay);
    for (int i = 0; i < 10; i++) {
      DateTime prev = searchStart.subtract(Duration(days: i));
      String key = _formatKey(prev);
      if (_periodDays.contains(key) || _pausedDays.contains(key)) {
        searchStart = prev;
      } else {
        break;
      }
    }

    DateTime searchEnd = _cleanDate(currentDay);
    for (int i = 0; i < 10; i++) {
      DateTime next = searchEnd.add(Duration(days: i));
      String key = _formatKey(next);
      if (_periodDays.contains(key) || _pausedDays.contains(key)) {
        searchEnd = next;
      } else {
        break;
      }
    }

    bool hasPauseInside = false;
    DateTime temp = searchStart;
    while (!temp.isAfter(searchEnd)) {
      if (_pausedDays.contains(_formatKey(temp))) {
        hasPauseInside = true;
        break;
      }
      temp = temp.add(const Duration(days: 1));
    }

    return hasPauseInside;
  }

  Map<String, dynamic> _getCycleStatus() {
    final key = _formatKey(_selectedDay);
    final bool isPeriod = _periodDays.contains(key);
    final bool isPaused = _pausedDays.contains(key);
    final Set<String> predictedDays = _getPredictedPeriodDays();
    final DateTime? nextPeriodDate = _getNextPredictedPeriodDate();

    if (_periodDays.isEmpty && _pausedDays.isEmpty) {
      return {
        'headline': 'Belum Ada Data',
        'subtext': 'Pilih tanggal awal haidmu di bawah.',
        'nextDate': null,
      };
    }

    if (isPaused) {
      bool irregular = _isIrregularFlow(_selectedDay);
      return {
        'headline': 'Tidak Haid (Hari Jeda)',
        'subtext': irregular
            ? 'Pola Haid Tidak Lancar: Terjadi jeda di tengah siklus.'
            : 'Pendarahan haid berhenti sementara.',
        'nextDate': nextPeriodDate,
      };
    }

    if (isPeriod) {
      DateTime blockStart = _cleanDate(_selectedDay);
      while (_periodDays.contains(
            _formatKey(blockStart.subtract(const Duration(days: 1))),
          ) ||
          _pausedDays.contains(
            _formatKey(blockStart.subtract(const Duration(days: 1))),
          )) {
        blockStart = blockStart.subtract(const Duration(days: 1));
      }

      final int dayIndex =
          _cleanDate(_selectedDay).difference(blockStart).inDays + 1;
      bool irregular = _isIrregularFlow(_selectedDay);

      return {
        'headline': 'Hari ke-$dayIndex Haid',
        'subtext': irregular
            ? 'Pola Haid Tidak Lancar (Ada jeda pendarahan).'
            : 'Siklus pendarahan haid lancar.',
        'nextDate': nextPeriodDate,
      };
    }

    if (predictedDays.contains(key)) {
      return {
        'headline': 'Prediksi Haid',
        'subtext': 'Diperkirakan haid akan mulai sekitar tanggal ini.',
        'nextDate': nextPeriodDate,
      };
    }

    final latestStart = _getLatestPeriodStart();
    if (latestStart == null) {
      return {
        'headline': 'Fase Siklus',
        'subtext': 'Belum ada data riwayat.',
        'nextDate': null,
      };
    }

    final cleanSelected = _cleanDate(_selectedDay);
    final int dayInCycle = cleanSelected.difference(latestStart).inDays + 1;

    if (dayInCycle < 1) {
      return {
        'headline': 'Sebelum Catatan',
        'subtext': 'Tanggal ini berada sebelum riwayat haid tercatat.',
        'nextDate': nextPeriodDate,
      };
    } else if (dayInCycle <= 5) {
      return {
        'headline': 'Hari ke-$dayInCycle Siklus',
        'subtext': 'Perkiraan masa pendarahan haid.',
        'nextDate': nextPeriodDate,
      };
    } else if (dayInCycle <= 14) {
      return {
        'headline': 'Fase Folikuler',
        'subtext': 'Hormon estrogen mulai meningkat.',
        'nextDate': nextPeriodDate,
      };
    } else if (dayInCycle <= 17) {
      return {
        'headline': 'Masa Subur',
        'subtext': 'Peluang kehamilan paling tinggi (Fase Ovulasi).',
        'nextDate': nextPeriodDate,
      };
    } else if (dayInCycle <= _cycleLength) {
      int left = _cycleLength - dayInCycle + 1;
      return {
        'headline': 'Fase Luteal',
        'subtext': 'Haid berikutnya dalam $left hari lagi.',
        'nextDate': nextPeriodDate,
      };
    } else {
      int overdue = dayInCycle - _cycleLength;
      return {
        'headline': 'Lewat $overdue Hari',
        'subtext': 'Siklus mengalami keterlambatan dari perkiraan.',
        'nextDate': nextPeriodDate,
      };
    }
  }

  void _showMonthYearPicker() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _visibleMonthYear,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
    );

    if (picked != null) {
      setState(() {
        _selectedDay = picked;
        _visibleMonthYear = picked;
      });
      _scrollToSelectedDay(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _getCycleStatus();
    final currentKey = _formatKey(_selectedDay);

    final bool isPeriod = _periodDays.contains(currentKey);
    final bool isPaused = _pausedDays.contains(currentKey);
    final Set<String> predictedDays = _getPredictedPeriodDays();
    final DateTime? nextDate = status['nextDate'] as DateTime?;

    final DateTime? shortCycleDate = _getNextPredictedPeriodDate(
      customCycle: 21,
    );
    final DateTime? longCycleDate = _getNextPredictedPeriodDate(
      customCycle: 35,
    );

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
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.primaryPink),
            tooltip: 'Pengaturan Siklus',
            onPressed: _showCycleLengthSettings,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            tooltip: 'Reset Data',
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Data?'),
                  content: const Text(
                    'Semua catatan haid yang tersimpan akan dihapus.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _resetAllData();
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Baris Tanggal Horizontal
          SizedBox(
            height: 75,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4000,
              controller: _scrollController,
              itemBuilder: (context, index) {
                final date = _startDateEpoch.add(Duration(days: index));
                final key = _formatKey(date);
                final isSelected = _isSameDay(date, _selectedDay);

                final bool dateIsPeriod = _periodDays.contains(key);
                final bool dateIsPaused = _pausedDays.contains(key);
                final bool dateIsPredicted = predictedDays.contains(key);

                Color containerColor = Colors.white;
                Border? borderStyle;

                if (isSelected) {
                  containerColor = AppColors.primaryPink;
                } else if (dateIsPeriod) {
                  containerColor = AppColors.primaryPink.withValues(alpha: 0.8);
                } else if (dateIsPaused) {
                  containerColor = Colors.orange.shade200;
                  borderStyle = Border.all(color: Colors.orange, width: 1.2);
                } else if (dateIsPredicted) {
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

          // 1. Lingkaran Utama (Hanya Fokus 3 Info Utama & Tombol)
          Center(
            child: Container(
              width: 275,
              height: 275,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.12),
                    blurRadius: 32,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.softPink.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Tanggal
                    Text(
                      DateFormat('EEEE, d MMM yyyy').format(_selectedDay),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textLight,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Judul Status Utama
                    Text(
                      status['headline'],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        height: 1.15,
                      ),
                    ),

                    // Badge Prediksi Kapsul
                    if (nextDate != null) ...[
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _showCycleLengthSettings,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.softPink.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                size: 12,
                                color: AppColors.primaryPink,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Prediksi: ${DateFormat('d MMM').format(nextDate)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryPink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Tombol Aksi
                    if (!isPeriod && !isPaused) ...[
                      ElevatedButton(
                        onPressed: _startPeriod,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          elevation: 2,
                          shadowColor: AppColors.primaryPink.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'Mulai Haid Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (isPeriod) ...[
                      OutlinedButton(
                        onPressed: _markAsPaused,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Tidak Haid Hari Ini (Jeda)',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearDayRecord,
                        child: const Text(
                          'Hapus Catatan',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ),
                    ] else if (isPaused) ...[
                      ElevatedButton(
                        onPressed: _resumePeriod,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryPink,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Haid Kembali Hari Ini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearDayRecord,
                        child: const Text(
                          'Hapus Catatan',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Kartu Detail Informasi (Dipindah ke Luar Lingkaran)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Teks Penjelasan Status
                  Row(
                    children: [
                      Icon(
                        status['subtext'].contains('Tidak Lancar')
                            ? Icons.warning_amber_rounded
                            : Icons.info_outline_rounded,
                        size: 16,
                        color: status['subtext'].contains('Tidak Lancar')
                            ? Colors.redAccent
                            : AppColors.primaryPink,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          status['subtext'],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                status['subtext'].contains('Tidak Lancar')
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: status['subtext'].contains('Tidak Lancar')
                                ? Colors.redAccent
                                : AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Rentang Perkiraan (Pendek - Panjang)
                  if (shortCycleDate != null && longCycleDate != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(height: 1, thickness: 0.5),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rentang Normal ($_cycleLength hr)',
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '${DateFormat('d MMM').format(shortCycleDate)} – ${DateFormat('d MMM').format(longCycleDate)}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ],
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
