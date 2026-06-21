import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Standard scaffold for top-level tabs (Home/Chat/...). Draws the
/// app bar and the bottom-nav shell. Inputs go through GoRouter so
/// the `destinations` map aligns with route paths.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.currentIndex,
    this.onTabSelected,
    this.bottomNavigationBarOverride,
    this.resizeToAvoidBottomInset,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int? currentIndex;
  final ValueChanged<int>? onTabSelected;
  final Widget? bottomNavigationBarOverride;
  final bool? resizeToAvoidBottomInset;

  static const _tabs = <_TabSpec>[
    _TabSpec(label: 'Home', icon: Icons.home_outlined, selected: Icons.home),
    _TabSpec(
        label: 'Chat', icon: Icons.chat_bubble_outline, selected: Icons.chat_bubble),
    _TabSpec(
        label: 'Attendance',
        icon: Icons.flag_outlined,
        selected: Icons.flag),
    _TabSpec(
        label: 'Timesheet', icon: Icons.timer_outlined, selected: Icons.timer),
    _TabSpec(
        label: 'Tickets', icon: Icons.task_alt_outlined, selected: Icons.task_alt),
  ];

  @override
  Widget build(BuildContext context) {
    Widget bottom = bottomNavigationBarOverride ??
        BottomNavigationBar(
          currentIndex: currentIndex ?? 0,
          onTap: onTabSelected,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: false,
          items: [
            for (final t in _tabs)
              BottomNavigationBarItem(
                icon: Icon(t.icon),
                label: t.label,
                activeIcon: Icon(t.selected),
              ),
          ],
        );
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: bottom,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.label,
    required this.icon,
    required this.selected,
  });
  final String label;
  final IconData icon;
  final IconData selected;
}

/// Avatar circle with initials fallback. Used wherever a user is
/// referenced in chat/tickets/attendance.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.userId,
    required this.displayName,
    this.email,
    this.size = 40,
  });

  final String userId;
  final String displayName;
  final String? email;
  final double size;

  String get _initials {
    final cleaned = displayName.trim();
    if (cleaned.isEmpty) {
      if (email != null && email!.isNotEmpty) {
        return email![0].toUpperCase();
      }
      return userId.isEmpty ? '?' : userId[0].toUpperCase();
    }
    final parts = cleaned.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Stable color per user so the same person looks the same across screens.
    final seed = userId.hashCode;
    final color = Color.lerp(
      scheme.primary,
      scheme.tertiary,
      (seed.abs() % 100) / 100,
    )!;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.38,
        ),
      ),
    );
  }
}

/// Tiny helper that returns the current signed-in user's id (or empty).
String currentUserId() => Supabase.instance.client.auth.currentUser?.id ?? '';
