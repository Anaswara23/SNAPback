import 'package:intl/intl.dart';

/// Utilities for the monthly cashback cycle. Reset happens at midnight on
/// the 1st of each month (local time).
class MonthUtils {
  MonthUtils._();

  /// Days remaining (inclusive of today) until the cashback cap resets.
  /// Always returns at least 1 (the day-of reset still shows "1 day left").
  static int daysUntilReset({DateTime? now}) {
    final today = now ?? DateTime.now();
    final firstOfNext = DateTime(today.year, today.month + 1, 1);
    final diff = firstOfNext.difference(
      DateTime(today.year, today.month, today.day),
    );
    final days = diff.inDays;
    return days < 1 ? 1 : days;
  }

  /// Friendly label for a [DateTime] in `MMMM yyyy`, e.g. `April 2026`.
  static String monthLabel(DateTime month) =>
      DateFormat('MMMM yyyy').format(month);

  /// `MMM d` short label, e.g. `Apr 18`.
  static String shortDate(DateTime date) =>
      DateFormat('MMM d').format(date);

  /// First instant of the month containing [date] (00:00 local).
  static DateTime startOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// First instant of the next month after [date] (00:00 local).
  static DateTime startOfNextMonth(DateTime date) =>
      DateTime(date.year, date.month + 1, 1);

  /// True if [a] and [b] fall in the same calendar month/year.
  static bool sameMonth(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month;
}
