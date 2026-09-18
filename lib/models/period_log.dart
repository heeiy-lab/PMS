class PeriodLog {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final int? cycleLength;

  PeriodLog({
    required this.id,
    required this.startDate,
    this.endDate,
    this.cycleLength,
  });

  DateTime get normalizedStartDate =>
      DateTime(startDate.year, startDate.month, startDate.day);
  DateTime? get normalizedEndDate => endDate != null
      ? DateTime(endDate!.year, endDate!.month, endDate!.day)
      : null;
}
