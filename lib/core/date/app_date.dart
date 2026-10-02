/// Date helpers shared by every date-aware surface (calendar strip, full
/// calendar, event cards, participation receipt).
///
class AppDate {
  const AppDate._();

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// Midnight on the same calendar day, with the time component dropped.
  static DateTime dayOf(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Whole days from [from] to [to]; negative when [to] is in the past.
  static int daysBetween(DateTime from, DateTime to) =>
      dayOf(to).difference(dayOf(from)).inDays;

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Three-letter weekday name for the date's real weekday, not a
  /// month-relative offset.
  static String weekday(DateTime date) => _weekdayNames[date.weekday - 1];

  static String monthName(int month) => _monthNames[month - 1];

  /// `"September 2026"` — the full-calendar header.
  static String monthYear(DateTime date) =>
      '${monthName(date.month)} ${date.year}';

  /// `"Sep 6"` — the compact label used on cards and receipts.
  static String shortLabel(DateTime date) =>
      '${monthName(date.month).substring(0, 3)} ${date.day}';

  /// Heading for the schedule list: `"Today"` / `"Tomorrow"` / `"Sep 6"`.
  static String scheduleHeading(DateTime date, {DateTime? now}) {
    final today = dayOf(now ?? DateTime.now());
    final offset = daysBetween(today, date);
    if (offset == 0) return 'Today';
    if (offset == 1) return 'Tomorrow';
    if (offset == -1) return 'Yesterday';
    return shortLabel(date);
  }

  /// First day of the given month, at midnight.
  static DateTime firstOfMonth(DateTime date) =>
      DateTime(date.year, date.month, 1);

  /// Days in the month, leap-year aware (so February is never assumed to be 28).
  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// Clamps a day number to the month's real length, so navigating to a
  /// shorter month can never produce an invalid date.
  static DateTime clampToMonth(DateTime date, int year, int month) {
    final length = daysInMonth(year, month);
    return DateTime(year, month, date.day <= length ? date.day : length);
  }

  /// The seven weekday labels for the calendar's fixed Mon–Sun header.
  static List<String> get weekdayNames => _weekdayNames;
}
