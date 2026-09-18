import 'package:collection/collection.dart';

import '../models/day_status.dart';
import '../models/user_settings.dart';
import '../models/period_log.dart';

class MenstrualCalculatorService {
  // 1. Menghitung rata-rata panjang siklus
  int calculateAverageCycle(List<PeriodLog> logs, UserSettings settings) {
    if (logs.isEmpty) return settings.defaultCycleLength;

    List<PeriodLog> sortedLogs = List.from(logs)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    List<int> validCycleLengths = [];

    for (int i = 0; i < sortedLogs.length - 1; i++) {
      int diffInDays = sortedLogs[i + 1].normalizedStartDate
          .difference(sortedLogs[i].normalizedStartDate)
          .inDays;

      if (diffInDays >= 15 && diffInDays <= 50) {
        validCycleLengths.add(diffInDays);
      }
    }

    if (validCycleLengths.length < 2) {
      return settings.defaultCycleLength;
    }

    int totalDays = validCycleLengths.reduce((a, b) => a + b);
    return (totalDays / validCycleLengths.length).round();
  }

  // 2. Memprediksi tanggal haid berikutnya
  DateTime predictNextPeriod(List<PeriodLog> logs, UserSettings settings) {
    if (logs.isEmpty) return DateTime.now();

    PeriodLog lastLog = logs.reduce(
      (a, b) => a.startDate.isAfter(b.startDate) ? a : b,
    );
    int avgCycle = calculateAverageCycle(logs, settings);

    return lastLog.normalizedStartDate.add(Duration(days: avgCycle));
  }

  // 3. Menghitung masa ovulasi & masa subur
  Map<String, DateTime> predictOvulationAndFertility(
    DateTime nextPredictedPeriod,
  ) {
    DateTime ovulationDate = nextPredictedPeriod.subtract(
      const Duration(days: 14),
    );
    DateTime fertileWindowStart = ovulationDate.subtract(
      const Duration(days: 5),
    );
    DateTime fertileWindowEnd = ovulationDate.add(const Duration(days: 1));

    return {
      'ovulation': ovulationDate,
      'fertileStart': fertileWindowStart,
      'fertileEnd': fertileWindowEnd,
    };
  }

  // 4. Menentukan status hari untuk kalender / home screen
  DayStatus getDayStatus(
    DateTime date,
    List<PeriodLog> logs,
    UserSettings settings,
  ) {
    if (logs.isEmpty) return DayStatus.none;

    DateTime targetDate = DateTime(date.year, date.month, date.day);

    List<PeriodLog> sortedLogs = List.from(logs)
      ..sort((a, b) => b.startDate.compareTo(a.startDate));

    PeriodLog? activeLog = sortedLogs.firstWhereOrNull(
      (log) =>
          log.normalizedStartDate.isBefore(targetDate) ||
          log.normalizedStartDate.isAtSameMomentAs(targetDate),
    );

    if (activeLog == null) return DayStatus.none;

    int periodDuration = (activeLog.endDate != null)
        ? activeLog.normalizedEndDate!
                  .difference(activeLog.normalizedStartDate)
                  .inDays +
              1
        : settings.defaultPeriodLength;

    DateTime periodEndDate = activeLog.normalizedStartDate.add(
      Duration(days: periodDuration - 1),
    );

    if ((targetDate.isAfter(activeLog.normalizedStartDate) ||
            targetDate.isAtSameMomentAs(activeLog.normalizedStartDate)) &&
        (targetDate.isBefore(periodEndDate) ||
            targetDate.isAtSameMomentAs(periodEndDate))) {
      return DayStatus.period;
    }

    int avgCycle = calculateAverageCycle(logs, settings);
    DateTime thisCycleNextPeriod = activeLog.normalizedStartDate.add(
      Duration(days: avgCycle),
    );

    Map<String, DateTime> fertilityData = predictOvulationAndFertility(
      thisCycleNextPeriod,
    );
    DateTime ovulation = fertilityData['ovulation']!;
    DateTime fertileStart = fertilityData['fertileStart']!;
    DateTime fertileEnd = fertilityData['fertileEnd']!;

    if (targetDate.isAtSameMomentAs(ovulation)) {
      return DayStatus.ovulation;
    }

    if ((targetDate.isAfter(fertileStart) ||
            targetDate.isAtSameMomentAs(fertileStart)) &&
        (targetDate.isBefore(fertileEnd) ||
            targetDate.isAtSameMomentAs(fertileEnd))) {
      return DayStatus.fertile;
    }

    if (targetDate.isAfter(fertileEnd) &&
        targetDate.isBefore(thisCycleNextPeriod)) {
      return DayStatus.luteal;
    }

    if (targetDate.isAfter(periodEndDate) &&
        targetDate.isBefore(fertileStart)) {
      return DayStatus.follicular;
    }

    return DayStatus.none;
  }
}
