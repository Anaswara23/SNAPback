import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../viewmodels/profile_view_model.dart';
import '../../../viewmodels/session_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/neon_backdrop.dart';
import '../../shared/widgets/snapback_header.dart';

class ProfileEditScreen extends StatelessWidget {
  const ProfileEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProfileViewModel>(
      create: (context) =>
          ProfileViewModel(session: context.read<SessionViewModel>()),
      child: const _ProfileEditView(),
    );
  }
}

class _ProfileEditView extends StatefulWidget {
  const _ProfileEditView();

  @override
  State<_ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<_ProfileEditView> {
  final _nameController = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProfileViewModel>();
    final profile = vm.profile;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;

    if (!_seeded) {
      _nameController.text = profile.displayName;
      _seeded = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const SnapbackHeader(title: 'Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/main'),
        ),
      ),
      body: NeonBackdrop(
        child: Padding(
          padding: context.rPad(horizontal: 16, vertical: 8),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: context.rGap(12)),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Display name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      onChanged: vm.setDisplayName,
                    ),
                    SizedBox(height: context.rGap(12)),
                    DropdownButtonFormField<String>(
                      initialValue: profile.language,
                      items: AppConstants.supportedLanguages
                          .map(
                            (lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(
                                AppConstants.languageLabels[lang] ?? lang,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) vm.setLanguage(value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Language',
                        prefixIcon: Icon(Icons.translate_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rGap(12)),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home_work_rounded, color: accent, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Household & SNAP',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One household = one SNAP case. Update household size '
                      'and your monthly SNAP allotment.',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    SizedBox(height: context.rGap(12)),
                    if (profile.householdCaseId.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded,
                                color: accent, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                profile.householdCaseId,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: cs.onSurface.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: context.rGap(14)),
                    Text(
                      'Monthly SNAP amount: \$${profile.snapAmount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: context.rGap(13),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Slider(
                      min: AppConstants.minSnapAmount,
                      max: AppConstants.maxSnapAmount,
                      divisions: 39,
                      value: profile.snapAmount,
                      onChanged: vm.setSnapAmount,
                    ),
                    DropdownButtonFormField<int>(
                      initialValue: profile.familySize,
                      items: List.generate(10, (i) => i + 1)
                          .map(
                            (size) => DropdownMenuItem(
                              value: size,
                              child: Text('$size people'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) vm.setFamilySize(value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Household size',
                        helperText: 'Everyone who lives and eats with you',
                        prefixIcon: Icon(Icons.people_alt_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rGap(12)),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Food preferences',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    SizedBox(height: context.rGap(10)),
                    Wrap(
                      spacing: context.rGap(8),
                      runSpacing: context.rGap(8),
                      children: AppConstants.culturalPreferences.map((pref) {
                        final selected = profile.culturalPrefs.contains(pref);
                        return FilterChip(
                          selected: selected,
                          selectedColor: cs.primary.withValues(alpha: 0.16),
                          checkmarkColor: cs.primary,
                          labelStyle: TextStyle(
                            fontSize: context.rGap(12),
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          label: Text(
                            pref,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            softWrap: false,
                          ),
                          onSelected: (value) =>
                              vm.togglePreference(pref, value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: context.rGap(20)),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: vm.isSaving
                      ? null
                      : () async {
                          await vm.save();
                          if (!context.mounted) return;
                          if (vm.statusMessage == 'Saved.') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile saved.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/main');
                            }
                          } else if (vm.statusMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(vm.statusMessage!)),
                            );
                          }
                        },
                  icon: vm.isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(vm.isSaving ? 'Saving…' : 'Save changes'),
                ),
              ),
              SizedBox(height: context.rGap(20)),
            ],
          ),
        ),
      ),
    );
  }
}
