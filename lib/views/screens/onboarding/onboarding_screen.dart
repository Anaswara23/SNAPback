import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../viewmodels/onboarding_view_model.dart';
import '../../../viewmodels/session_view_model.dart';
import '../../shared/widgets/neon_backdrop.dart';
import '../../shared/widgets/snapback_header.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OnboardingViewModel>(
      create: (context) =>
          OnboardingViewModel(session: context.read<SessionViewModel>()),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _controller = PageController();
  final _nameController = TextEditingController();
  bool _seededName = false;

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OnboardingViewModel>();
    final profile = vm.profile;
    if (!_seededName) {
      _nameController.text = profile.displayName;
      _seededName = true;
    }

    return Scaffold(
      body: NeonBackdrop(
        child: SafeArea(
          child: Padding(
            padding: context.rPad(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                const SnapbackHeader(title: 'Set up your profile'),
                SizedBox(height: context.rGap(16)),
                LinearProgressIndicator(value: (vm.currentStep + 1) / 3),
                SizedBox(height: context.rGap(18)),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: vm.onPageChanged,
                    children: [
                      _StepNameLanguage(
                        nameController: _nameController,
                        onNameChanged: vm.setDisplayName,
                        language: profile.language,
                        onLanguageChanged: vm.setLanguage,
                      ),
                      _StepSnapFamily(
                        snapAmount: profile.snapAmount,
                        onSnapChanged: vm.setSnapAmount,
                        familySize: profile.familySize,
                        onFamilyChanged: vm.setFamilySize,
                        householdCaseId: profile.householdCaseId,
                      ),
                      _StepCulturalPrefs(
                        selected: profile.culturalPrefs,
                        onToggle: vm.togglePreference,
                      ),
                    ],
                  ),
                ),
                if (vm.errorMessage != null) ...[
                  SizedBox(height: context.rGap(8)),
                  Text(
                    vm.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                SizedBox(height: context.rGap(8)),
                FilledButton.icon(
                  onPressed: vm.isSubmitting
                      ? null
                      : () async {
                          final isComplete = await vm.advance();
                          if (!context.mounted) return;
                          if (isComplete) return; // router handles redirect
                          if (vm.currentStep != _controller.page?.round()) {
                            _controller.animateToPage(
                              vm.currentStep,
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        },
                  icon: Icon(
                    vm.currentStep == 2
                        ? Icons.check_circle
                        : Icons.arrow_forward,
                  ),
                  label: Text(vm.currentStep == 2 ? 'Complete' : 'Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepNameLanguage extends StatelessWidget {
  const _StepNameLanguage({
    required this.nameController,
    required this.onNameChanged,
    required this.language,
    required this.onLanguageChanged,
  });

  final TextEditingController nameController;
  final ValueChanged<String> onNameChanged;
  final String language;
  final ValueChanged<String> onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 1: Name + Language',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Display name'),
          onChanged: onNameChanged,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: language,
          items: AppConstants.supportedLanguages
              .map((lang) => DropdownMenuItem(
                    value: lang,
                    child: Text(AppConstants.languageLabels[lang] ?? lang),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onLanguageChanged(value);
          },
          decoration: const InputDecoration(labelText: 'Language'),
        ),
      ],
    );
  }
}

class _StepSnapFamily extends StatelessWidget {
  const _StepSnapFamily({
    required this.snapAmount,
    required this.onSnapChanged,
    required this.familySize,
    required this.onFamilyChanged,
    required this.householdCaseId,
  });

  final double snapAmount;
  final ValueChanged<double> onSnapChanged;
  final int familySize;
  final ValueChanged<int> onFamilyChanged;
  final String householdCaseId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Household & SNAP',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          // Household / case-ID explainer card.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.08),
              border: Border.all(
                color: accent.withValues(alpha: 0.25),
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.family_restroom_rounded,
                        color: accent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Your household case',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'SNAP is household-based — everyone who lives and eats '
                  'together is one case. We assign your household a unique '
                  'case ID that ties your benefits, eligibility, and '
                  'rewards together.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded, size: 18, color: accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          householdCaseId.isEmpty
                              ? 'Generating…'
                              : householdCaseId,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Text(
                        'one family = one case',
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurface.withValues(alpha: 0.55),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Monthly SNAP amount: \$${snapAmount.toStringAsFixed(0)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Slider(
            min: AppConstants.minSnapAmount,
            max: AppConstants.maxSnapAmount,
            divisions: 39,
            value: snapAmount,
            onChanged: onSnapChanged,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: familySize,
            items: List.generate(10, (i) => i + 1)
                .map(
                  (size) => DropdownMenuItem(
                    value: size,
                    child: Text('$size people'),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onFamilyChanged(value);
            },
            decoration: const InputDecoration(
              labelText: 'Household size',
              helperText: 'Everyone who lives and eats with you',
            ),
          ),
        ],
      ),
    );
  }
}

class _StepCulturalPrefs extends StatelessWidget {
  const _StepCulturalPrefs({required this.selected, required this.onToggle});

  final Set<String> selected;
  final void Function(String value, bool selected) onToggle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 3: Cultural food preferences',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 14),
        Text(
          'Select all that match your household food traditions',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.culturalPreferences.map((pref) {
            final isSelected = selected.contains(pref);
            return FilterChip(
              selected: isSelected,
              selectedColor: colorScheme.primary.withValues(alpha: 0.18),
              checkmarkColor: colorScheme.primary,
              side: BorderSide(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.25),
              ),
              labelStyle: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              label: Text(
                pref,
                maxLines: 1,
                overflow: TextOverflow.fade,
                softWrap: false,
              ),
              onSelected: (value) => onToggle(pref, value),
            );
          }).toList(),
        ),
      ],
    );
  }
}
