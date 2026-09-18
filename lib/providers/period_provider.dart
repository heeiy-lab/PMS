import 'package:flutter/foundation.dart';

import '../models/day_status.dart';
import '../models/period_log.dart';
import '../models/user_settings.dart';
import '../services/menstrual_services_calculator.dart';

class PeriodProvider extends ChangeNotifier {
  final MenstrualCalculatorService _calculator = MenstrualCalculatorService();

  // Pengaturan default user
  UserSettings _settings = UserSettings(
    defaultCycleLength: 28,
    defaultPeriodLength: 5,
  );
  UserSettings get settings => _settings;

  // Riwayat Log Haid (Contoh data awal / dummy, nanti bisa dihubungkan ke Firebase/Local DB)
  final List<PeriodLog> _logs = [
    PeriodLog(
      id: '1',
      startDate: DateTime.now().subtract(const Duration(days: 45)),
      endDate: DateTime.now().subtract(const Duration(days: 40)),
    ),
    PeriodLog(
      id: '2',
      startDate: DateTime.now().subtract(const Duration(days: 16)),
      endDate: DateTime.now().subtract(const Duration(days: 11)),
    ),
  ];

  List<PeriodLog> get logs => _logs;

  // --- GETTER UNTUK UI ---

  // 1. Mendapatkan rata-rata panjang siklus
  int get averageCycleLength {
    return _calculator.calculateAverageCycle(_logs, _settings);
  }

  // 2. Mendapatkan prediksi tanggal haid berikutnya
  DateTime get nextPeriodDate {
    return _calculator.predictNextPeriod(_logs, _settings);
  }

  // 3. Menghitung hari ke-X siklus saat ini (untuk lingkaran besar di Home Screen)
  int get currentCycleDay {
    if (_logs.isEmpty) return 1;

    // Cari log haid terakhir
    PeriodLog lastLog = _logs.reduce(
      (a, b) => a.startDate.isAfter(b.startDate) ? a : b,
    );

    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final startDate = DateTime(
      lastLog.startDate.year,
      lastLog.startDate.month,
      lastLog.startDate.day,
    );

    int difference = today.difference(startDate).inDays + 1;
    return difference > 0 ? difference : 1;
  }

  // 4. Hitung sisa hari menuju haid berikutnya
  int get daysUntilNextPeriod {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final nextPeriod = DateTime(
      nextPeriodDate.year,
      nextPeriodDate.month,
      nextPeriodDate.day,
    );

    int diff = nextPeriod.difference(today).inDays;
    return diff >= 0 ? diff : 0;
  }

  // 5. Mendapatkan status tanggal tertentu (untuk kalender)
  DayStatus getDayStatus(DateTime date) {
    return _calculator.getDayStatus(date, _logs, _settings);
  }

  // --- AKSI / FUNGSI PERUBAHAN DATA ---

  // Menambahkan log haid baru (misal user klik tombol catat haid hari ini)
  void addPeriodLog(DateTime startDate, DateTime? endDate) {
    final newLog = PeriodLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startDate: startDate,
      endDate: endDate,
    );
    _logs.add(newLog);
    notifyListeners(); // Memperbarui UI secara otomatis
  }

  // Mengubah settingan durasi siklus
  void updateSettings(int newCycleLength, int newPeriodLength) {
    _settings = UserSettings(
      defaultCycleLength: newCycleLength,
      defaultPeriodLength: newPeriodLength,
    );
    notifyListeners();
  }
}
