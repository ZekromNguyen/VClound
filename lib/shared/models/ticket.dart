/// Whitelisted values for the `ticket_status` enum.
enum TicketStatus { todo, doing, done }

extension TicketStatusDb on TicketStatus {
  String get dbValue => switch (this) {
        TicketStatus.todo => 'Todo',
        TicketStatus.doing => 'Doing',
        TicketStatus.done => 'Done',
      };

  String get label => dbValue;

  bool get isOpen => this != TicketStatus.done;

  static TicketStatus fromDb(String v) {
    return TicketStatus.values.firstWhere(
      (s) => s.dbValue == v,
      orElse: () => TicketStatus.todo,
    );
  }
}

/// Row from `public.tickets`.
class Ticket {
  const Ticket({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.createdBy,
    required this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String? description;
  final TicketStatus status;
  final String createdBy;
  final String assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Ticket copyWith({TicketStatus? status}) => Ticket(
        id: id,
        title: title,
        description: description,
        status: status ?? this.status,
        createdBy: createdBy,
        assignedTo: assignedTo,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory Ticket.fromMap(Map<String, dynamic> map) => Ticket(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        status: TicketStatusDb.fromDb(map['status'] as String),
        createdBy: map['created_by'] as String,
        assignedTo: map['assigned_to'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );
}
