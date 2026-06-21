import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../../../shared/models/attendance.dart';

class AttendanceRepository {
  AttendanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Verifies location services + permission. Throws a [Failure] with
  /// a user-facing message on each denial case so screens can show
  /// tailored guidance without having to re-implement the logic.
  Future<void> ensurePermission() async {
    final svc = await Geolocator.isLocationServiceEnabled();
    if (!svc) {
      throw Failure('Turn on Location services to check in.');
    }
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied) {
      throw Failure('Location permission was denied.');
    }
    if (perm == LocationPermission.deniedForever) {
      throw Failure(
          'Location permission is permanently denied. Open Settings to allow.');
    }
  }

  Future<Position> currentPosition() {
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  Future<Attendance> checkIn() async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Failure('Not signed in');
    await ensurePermission();
    final pos = await currentPosition();
    final res = await _client.from('attendance').insert({
      'user_id': me,
      'checkin_time': DateTime.now().toUtc().toIso8601String(),
      'checkin_lat': pos.latitude,
      'checkin_lng': pos.longitude,
    }).select().single();
    return Attendance.fromMap(Map<String, dynamic>.from(res));
  }

  /// Closes the user's most recent open row (the one with a non-null
  /// check-in time and a null check-out time).
  Future<Attendance> checkOut() async {
    final me = _client.auth.currentUser?.id;
    if (me == null) throw Failure('Not signed in');
    await ensurePermission();
    final pos = await currentPosition();

    final open = await _client
        .from('attendance')
        .select('*')
        .eq('user_id', me)
        .isFilter('checkout_time', null)
        .order('created_at', ascending: false)
        .limit(1);
    final list = (open as List).cast<Map<String, dynamic>>();
    if (list.isEmpty) {
      throw Failure('No open check-in to close.');
    }
    final id = list.first['id'] as String;
    final res = await _client
        .from('attendance')
        .update({
          'checkout_time': DateTime.now().toUtc().toIso8601String(),
          'latitude': pos.latitude,
          'longitude': pos.longitude,
        })
        .eq('id', id)
        .select()
        .single();
    return Attendance.fromMap(Map<String, dynamic>.from(res));
  }

  Stream<List<Attendance>> watchRecent({int limit = 50}) {
    final controller = StreamController<List<Attendance>>();
    RealtimeChannel? ch;

    Future<void> refresh() async {
      try {
        final me = _client.auth.currentUser?.id;
        if (me == null) {
          controller.add(const <Attendance>[]);
          return;
        }
        final res = await _client
            .from('attendance')
            .select('*')
            .eq('user_id', me)
            .order('created_at', ascending: false)
            .limit(limit);
        final list = (res as List)
            .cast<Map<String, dynamic>>()
            .map(Attendance.fromMap)
            .toList();
        if (!controller.isClosed) controller.add(list);
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(Failure('Reload failed: $e'));
        }
      }
    }

    controller.onListen = () async {
      await refresh();
      ch = _client
          .channel('att-${_client.auth.currentUser?.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'attendance',
            callback: (_) => refresh(),
          )
          .subscribe();
    };
    controller.onCancel = () async {
      final c = ch;
      if (c != null) await _client.removeChannel(c);
    };
    return controller.stream;
  }
}
