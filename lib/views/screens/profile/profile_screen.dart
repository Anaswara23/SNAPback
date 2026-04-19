import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../models/user_profile.dart';
import '../../../viewmodels/session_view_model.dart';
import '../../../viewmodels/theme_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/snapback_scaffold.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionViewModel>();
    final theme = context.watch<ThemeViewModel>();
    final profile = session.profile;
    final cs = Theme.of(context).colorScheme;

    return SnapbackScaffold(
      title: 'Profile',
      actions: [
        IconButton(
          tooltip: 'Edit profile',
          icon: const Icon(Icons.edit_rounded),
          onPressed: () => context.push(AppRoutes.profileEdit),
        ),
        IconButton(
          tooltip: 'Settings',
          icon: const Icon(Icons.settings_rounded),
          onPressed: () => _openSettings(context, session),
        ),
        SizedBox(width: context.rGap(4)),
      ],
      child: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _ProfileHero(profile: profile, email: session.email),
          SizedBox(height: context.rGap(14)),
          _HouseholdCard(profile: profile),
          SizedBox(height: context.rGap(12)),
          _SectionCard(
            title: 'Account',
            rows: [
              _ProfileRow(
                icon: Icons.person_outline_rounded,
                label: 'Display name',
                value: profile.displayName.isEmpty
                    ? 'Not set'
                    : profile.displayName,
              ),
              if ((session.email ?? '').isNotEmpty)
                _ProfileRow(
                  icon: Icons.alternate_email_rounded,
                  label: 'Email',
                  value: session.email!,
                ),
              _ProfileRow(
                icon: Icons.translate_rounded,
                label: 'Language',
                value: AppConstants.languageLabels[profile.language] ??
                    profile.language,
              ),
            ],
          ),
          SizedBox(height: context.rGap(12)),
          _PreferencesCard(prefs: profile.culturalPrefs),
          SizedBox(height: context.rGap(12)),
          _AppearanceCard(theme: theme),
          SizedBox(height: context.rGap(20)),
          Center(
            child: Text(
              'SNAPback • v0.1',
              style: TextStyle(
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
          SizedBox(height: context.rGap(20)),
        ],
      ),
    );
  }

  Future<void> _openSettings(
    BuildContext context,
    SessionViewModel session,
  ) async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'Settings',
                  style: Theme.of(sheetCtx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(height: 4),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('Privacy policy'),
                subtitle: const Text('How we handle your data'),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy policy coming soon.'),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: AppTheme.lossRed,
                ),
                title: const Text(
                  'Sign out',
                  style: TextStyle(
                    color: AppTheme.lossRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () async {
                  Navigator.of(sheetCtx).pop();
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Sign out?'),
                      content: const Text(
                        'You\'ll need to sign in again to access your '
                        'household rewards.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.lossRed,
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Sign out'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await session.signOut();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero ────────────────────────────────────────────────────────────────────

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.profile, required this.email});

  final UserProfile profile;
  final String? email;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final initial = (profile.displayName.isEmpty
            ? (email?.isNotEmpty == true ? email![0] : 'S')
            : profile.displayName[0])
        .toUpperCase();

    return Container(
      padding: context.rPad(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0E2B1A), const Color(0xFF0A1F22)]
              : [const Color(0xFFE6F9EE), const Color(0xFFDFF4FA)],
        ),
        borderRadius: BorderRadius.circular(context.rGap(20)),
        border: Border.all(
          color: isDark
              ? AppTheme.neonGreen.withValues(alpha: 0.18)
              : AppTheme.deepGreen.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: context.rGap(64),
            height: context.rGap(64),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  isDark ? AppTheme.neonGreen : AppTheme.deepGreen,
                  AppTheme.neonBlue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isDark ? AppTheme.neonGreen : AppTheme.deepGreen)
                      .withValues(alpha: 0.35),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: context.rGap(26),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(width: context.rGap(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName.isEmpty
                      ? 'SNAPback Member'
                      : profile.displayName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                SizedBox(height: context.rGap(2)),
                if ((email ?? '').isNotEmpty)
                  Text(
                    email!,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withValues(alpha: 0.62),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: context.rGap(6)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.neonGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${profile.familySize} in household',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppTheme.neonGreen
                          : AppTheme.deepGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Household card (case ID + SNAP) ─────────────────────────────────────────

class _HouseholdCard extends StatelessWidget {
  const _HouseholdCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.home_work_rounded, color: accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'Household',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'One family or household = one SNAP case. This case ID ties your '
            'eligibility, benefits, and SNAPback rewards together.',
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: cs.onSurface.withValues(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 14),
          // Case ID pill with copy.
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: profile.householdCaseId.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: profile.householdCaseId),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Case ID copied'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accent.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.qr_code_2_rounded, color: accent, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Case ID',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.6,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          profile.householdCaseId.isEmpty
                              ? 'Generating…'
                              : profile.householdCaseId,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.people_alt_rounded,
                  label: 'Household size',
                  value: '${profile.familySize} people',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.payments_rounded,
                  label: 'Monthly SNAP',
                  value: '\$${profile.snapAmount.toStringAsFixed(0)}',
                  accent: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic section card ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.rows});

  final String title;
  final List<_ProfileRow> rows;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          ...rows.map((row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: row,
              )),
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.55),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Preferences card ────────────────────────────────────────────────────────

class _PreferencesCard extends StatelessWidget {
  const _PreferencesCard({required this.prefs});

  final Set<String> prefs;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Food preferences',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          if (prefs.isEmpty)
            Text(
              'No preferences set yet.',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: prefs
                  .map(
                    (p) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        p,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }
}

// ── Appearance card ─────────────────────────────────────────────────────────

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.theme});

  final ThemeViewModel theme;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {theme.themeMode},
            onSelectionChanged: (values) =>
                theme.setThemeMode(values.first),
          ),
        ],
      ),
    );
  }
}
