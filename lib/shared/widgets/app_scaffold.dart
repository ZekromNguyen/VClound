import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Standard scaffold for top-level tabs (Home/Chat/...). Draws the
/// app bar and the bottom-nav shell. The shell auto-detects which tab is
/// active from GoRouterState, so screens only have to set [title] and
/// [body]; the bottom bar is hidden on non-tab routes (login, signup, ...).
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBarOverride,
    this.resizeToAvoidBottomInset,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBarOverride;
  final bool? resizeToAvoidBottomInset;

  static const _tabs = <_TabSpec>[
    _TabSpec(label: 'Home', path: '/home', icon: Icons.home_outlined, selected: Icons.home),
    _TabSpec(label: 'Chat', path: '/chat', icon: Icons.chat_bubble_outline, selected: Icons.chat_bubble),
    _TabSpec(label: 'Attendance', path: '/attendance', icon: Icons.flag_outlined, selected: Icons.flag),
    _TabSpec(label: 'Timesheet', path: '/timesheet', icon: Icons.timer_outlined, selected: Icons.timer),
    _TabSpec(label: 'Tickets', path: '/tickets', icon: Icons.task_alt_outlined, selected: Icons.task_alt),
  ];

  @override
  Widget build(BuildContext context) {
    // Map the current GoRouter location to one of the tab paths so the
    // shell can highlight the right tab and route user taps to the right
    // path. Any path prefixed by a tab path (e.g. `/chat/abc` → Chat) still
    // belongs to that tab; paths like `/login`, `/signup` map to no tab
    // and we hide the bar entirely.
    final loc = GoRouterState.of(context).matchedLocation;
    final activeIndex = () {
      for (var i = 0; i < _tabs.length; i++) {
        final p = _tabs[i].path;
        if (loc == p || loc.startsWith('$p/')) return i;
      }
      return null;
    }();

    final Widget bottom = bottomNavigationBarOverride ?? (activeIndex == null
        ? const SizedBox.shrink()
        : BottomNavigationBar(
            currentIndex: activeIndex,
            onTap: (i) {
              // go() replaces the route stack with the tab's root, which
              // matches the existing tab-by-context.go wiring used elsewhere.
              context.go(_tabs[i].path);
            },
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
          ));

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
    required this.path,
    required this.icon,
    required this.selected,
  });
  final String label;
  final String path;
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
