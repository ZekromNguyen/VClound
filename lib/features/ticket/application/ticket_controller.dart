import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/ticket.dart';
import '../data/ticket_repository.dart';

final ticketRepositoryProvider = Provider<TicketRepository>(
  (_) => TicketRepository(),
);

final ticketsProvider = StreamProvider.autoDispose<List<Ticket>>(
  (ref) => ref.read(ticketRepositoryProvider).watchAssigned(),
);

/// Lightweight notifier that holds an *override* list used for
/// optimistic status updates. When non-null, the rest of the app
/// reads it in place of [ticketsProvider]; when null, the source
/// stream is used.
class TicketOverride extends Notifier<List<Ticket>?> {
  @override
  List<Ticket>? build() => null;

  void set(List<Ticket>? next) => state = next;
}

final ticketOverrideProvider =
    NotifierProvider<TicketOverride, List<Ticket>?>(TicketOverride.new);

final effectiveTicketsProvider = Provider<List<Ticket>>((ref) {
  final override = ref.watch(ticketOverrideProvider);
  if (override != null) return override;
  return ref.watch(ticketsProvider).value ?? const <Ticket>[];
});

class TicketActions {
  TicketActions(this._repo, this._ref);
  final TicketRepository _repo;
  final Ref _ref;

  Future<Ticket> create({
    required String title,
    required String? description,
  }) async {
    final t = await _repo.create(title: title, description: description);
    _ref.invalidate(ticketsProvider);
    return t;
  }

  /// Optimistic status update. We patch the override, fire the API,
  /// and roll the override back to null on success/failure — letting
  /// the source stream re-emit authoritative data on the next tick.
  Future<void> updateStatus(String id, TicketStatus status) async {
    final cur = _ref.read(ticketsProvider).value ?? const <Ticket>[];
    final patched = [
      for (final t in cur) t.id == id ? t.copyWith(status: status) : t,
    ];
    _ref.read(ticketOverrideProvider.notifier).set(patched);
    try {
      await _repo.updateStatus(id, status);
    } catch (_) {
      _ref.read(ticketOverrideProvider.notifier).set(null);
      _ref.invalidate(ticketsProvider);
      rethrow;
    }
    _ref.read(ticketOverrideProvider.notifier).set(null);
    _ref.invalidate(ticketsProvider);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _ref.invalidate(ticketsProvider);
  }
}

final ticketActionsProvider = Provider(
  (ref) => TicketActions(ref.read(ticketRepositoryProvider), ref),
);

final openTicketsCountProvider = Provider<int>((ref) {
  final list = ref.watch(effectiveTicketsProvider);
  return list.where((t) => t.status.isOpen).length;
});
