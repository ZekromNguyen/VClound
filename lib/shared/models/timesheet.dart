/// Whitelisted values for the `timesheet_category` postgres enum.
enum TimesheetCategory { erp, crm, meeting, support, other }

extension TimesheetCategoryDb on TimesheetCategory {
  String get dbValue => switch (this) {
        TimesheetCategory.erp => 'ERP',
        TimesheetCategory.crm => 'CRM',
        TimesheetCategory.meeting => 'Meeting',
        TimesheetCategory.support => 'Support',
        TimesheetCategory.other => 'Other',
      };

  String get label => switch (this) {
        TimesheetCategory.erp => 'ERP',
        TimesheetCategory.crm => 'CRM',
        TimesheetCategory.meeting => 'Meeting',
        TimesheetCategory.support => 'Support',
        TimesheetCategory.other => 'Other',
      };

  static TimesheetCategory fromDb(String v) {
    return TimesheetCategory.values.firstWhere(
      (c) => c.dbValue == v,
      orElse: () => TimesheetCategory.other,
    );
  }
}

/// Whitelisted values for the `timesheet_duration` postgres enum.
enum TimesheetDuration { fifteen, thirty, sixty, oneTwenty }

extension TimesheetDurationDb on TimesheetDuration {
  String get dbValue => switch (this) {
        TimesheetDuration.fifteen => '15m',
        TimesheetDuration.thirty => '30m',
        TimesheetDuration.sixty => '1h',
        TimesheetDuration.oneTwenty => '2h',
      };

  Duration get duration => switch (this) {
        TimesheetDuration.fifteen => const Duration(minutes: 15),
        TimesheetDuration.thirty => const Duration(minutes: 30),
        TimesheetDuration.sixty => const Duration(hours: 1),
        TimesheetDuration.oneTwenty => const Duration(hours: 2),
      };

  String get label => dbValue;

  static TimesheetDuration fromDb(String v) {
    return TimesheetDuration.values.firstWhere(
      (d) => d.dbValue == v,
      orElse: () => TimesheetDuration.thirty,
    );
  }
}

/// Row from `public.timesheets`.
class TimesheetEntry {
  const TimesheetEntry({
    required this.id,
    required this.userId,
    required this.taskName,
    required this.category,
    required this.duration,
    required this.workedDate,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String taskName;
  final TimesheetCategory category;
  final TimesheetDuration duration;
  final DateTime workedDate;
  final DateTime createdAt;

  factory TimesheetEntry.fromMap(Map<String, dynamic> map) => TimesheetEntry(
        id: map['id'] as String,
        userId: map['user_id'] as String,
        taskName: map['task_name'] as String,
        category: TimesheetCategoryDb.fromDb(map['category'] as String),
        duration: TimesheetDurationDb.fromDb(map['duration'] as String),
        workedDate: DateTime.parse(map['worked_date'] as String),
        createdAt: DateTime.parse(map['created_at'] as String),
      );
}
