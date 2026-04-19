import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/month_utils.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../models/recipe_suggestion.dart';
import '../../../models/trip_result.dart';
import '../../../viewmodels/trip_result_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/item_health_bar.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/snapback_loader.dart';
import '../../shared/widgets/snapback_scaffold.dart';

class TripResultScreen extends StatelessWidget {
  const TripResultScreen({super.key, required this.tripId});

  final String tripId;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<TripResultViewModel>(
      create: (_) => TripResultViewModel(tripId: tripId),
      child: const _TripResultView(),
    );
  }
}

class _TripResultView extends StatelessWidget {
  const _TripResultView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TripResultViewModel>();
    final trip = vm.trip;

    return SnapbackScaffold(
      title: 'Trip Result',
      actions: [
        if (trip != null)
          IconButton(
            tooltip: 'Delete trip',
            icon: vm.isDeleting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            color: AppTheme.lossRed,
            onPressed: vm.isDeleting ? null : () => _confirmDelete(context, vm),
          ),
      ],
      child: vm.isLoading
          ? Center(
              child: SnapbackLoader(
                size: 84,
                label: vm.errorMessage == 'Processing receipt...'
                    ? 'Processing receipt...'
                    : 'Loading trip...',
              ),
            )
          : trip == null
              ? Center(
                  child: Padding(
                    padding: context.rPad(horizontal: 24),
                    child: Text(
                      vm.errorMessage ?? 'Trip result not available yet.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : _Body(vm: vm, trip: trip),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TripResultViewModel vm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: const Text(
          'This will permanently remove this trip from your history, '
          'including the receipt image. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.lossRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await vm.deleteTrip();
      messenger.showSnackBar(
        const SnackBar(content: Text('Trip deleted.')),
      );
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete trip: $e')),
      );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.vm, required this.trip});

  final TripResultViewModel vm;
  final TripResult trip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysLeft = MonthUtils.daysUntilReset();

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        ScoreRing(
          score: vm.score,
          label: 'Trip Health Score',
          sublabel: '${vm.tripAvgHealthScore.toStringAsFixed(1)} / 5 avg item',
        ),
        SizedBox(height: context.rGap(12)),
        Center(
          child: Text(
            trip.contributionValue > 0
                ? '+\$${trip.contributionValue.toStringAsFixed(2)} cashback'
                : 'No cashback this trip',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: trip.contributionValue > 0
                      ? AppTheme.neonGreen
                      : cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        SizedBox(height: context.rGap(4)),
        Center(
          child: Text(
            'This month: '
            '${vm.monthlyAvgHealthScore.toStringAsFixed(1)}/5 Health Score',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
        if (trip.capReached)
          SizedBox(
            height: context.rGap(120),
            child: Lottie.network(
              'https://assets1.lottiefiles.com/packages/lf20_touohxv0.json',
              repeat: false,
            ),
          ),
        SizedBox(height: context.rGap(14)),

        // ── Monthly cap progress ───────────────────────────────────────────
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Monthly cashback',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  _Pill(
                    label: '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                    color: AppTheme.deepGreen,
                  ),
                ],
              ),
              SizedBox(height: context.rGap(10)),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: vm.progressRatio,
                  minHeight: context.rGap(10),
                  backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.14),
                  valueColor:
                      const AlwaysStoppedAnimation(AppTheme.neonGreen),
                ),
              ),
              SizedBox(height: context.rGap(8)),
              Text(
                '\$${vm.monthlyEarned.toStringAsFixed(2)} of '
                '\$${vm.monthlyCap.toStringAsFixed(2)} cap',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (!vm.capReached) ...[
                SizedBox(height: context.rGap(2)),
                Text(
                  '\$${vm.monthlyRemaining.toStringAsFixed(2)} more available '
                  'before the 1st.',
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ],
          ),
        ),

        SizedBox(height: context.rGap(12)),
        _RedemptionCard(
          redeemable: vm.isRedeemable,
          earnedAny: vm.monthlyEarned > 0,
          monthlyEarned: vm.monthlyEarned,
          monthlyAvgHealth: vm.monthlyAvgHealthScore,
          threshold: vm.redemptionThreshold,
          capReached: vm.capReached,
        ),

        SizedBox(height: context.rGap(12)),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Itemized breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: context.rGap(8)),
              ...trip.tripItems.map((item) => ItemHealthBar(item: item)),
            ],
          ),
        ),

        if (trip.recipes.isNotEmpty) ...[
          SizedBox(height: context.rGap(12)),
          _RecipesCard(recipes: trip.recipes),
        ],

        SizedBox(height: context.rGap(12)),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How rewards work',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: context.rGap(6)),
              const _RuleLine(text: '5★ items: 5% cashback (+1% if cultural)'),
              const _RuleLine(text: '4★ items: 3% cashback (+1% if cultural)'),
              const _RuleLine(text: '3★ items: 1% cashback (+1% if cultural)'),
              const _RuleLine(
                text:
                    '≤2★ items earn no cashback and drag your monthly Health Score down',
              ),
              SizedBox(height: context.rGap(6)),
              Text(
                'Monthly cap: min(10% × SNAP, \$25 × household). '
                'Cashback is only deposited to EBT on the 1st if your monthly '
                'Health Score is at least '
                '${vm.redemptionThreshold.toStringAsFixed(1)}/5.',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),

        SizedBox(height: context.rGap(20)),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.lossRed,
            side: BorderSide(color: AppTheme.lossRed.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onPressed:
              vm.isDeleting ? null : () => _confirmDeleteFromBody(context, vm),
          icon: const Icon(Icons.delete_outline_rounded),
          label: const Text('Delete this trip'),
        ),
        SizedBox(height: context.rGap(20)),
      ],
    );
  }

  Future<void> _confirmDeleteFromBody(
    BuildContext context,
    TripResultViewModel vm,
  ) async {
    // Reuse the same dialog logic by calling the parent state's helper.
    // Simpler: reproduce the dialog inline.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this trip?'),
        content: const Text(
          'This will permanently remove this trip from your history, '
          'including the receipt image. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.lossRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await vm.deleteTrip();
      messenger.showSnackBar(const SnackBar(content: Text('Trip deleted.')));
      if (router.canPop()) {
        router.pop();
      } else {
        router.go('/');
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Could not delete trip: $e')),
      );
    }
  }
}

// ── Recipes card ─────────────────────────────────────────────────────────────

class _RecipesCard extends StatelessWidget {
  const _RecipesCard({required this.recipes});

  final List<RecipeSuggestion> recipes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.restaurant_menu_rounded,
                color: AppTheme.neonGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Recipe ideas with what you bought',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tailored to your cuisine preferences and the items in this trip.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),
          ...recipes.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _RecipeTile(recipe: r),
              )),
        ],
      ),
    );
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.recipe});

  final RecipeSuggestion recipe;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  recipe.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < recipe.healthScore ? Icons.star : Icons.star_border,
                    size: 12,
                    color: AppTheme.deepGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              if (recipe.cuisine.isNotEmpty)
                _Pill(label: recipe.cuisine, color: AppTheme.deepGreen),
              _Pill(
                label: '${recipe.prepTimeMinutes} min',
                color: AppTheme.warningAmber,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recipe.description,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurface.withValues(alpha: 0.8),
              height: 1.35,
            ),
          ),
          if (recipe.usesItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Uses: ${recipe.usesItems.join(', ')}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.55),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (recipe.steps.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...recipe.steps.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}.',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.deepGreen,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(fontSize: 13, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('·  ', style: TextStyle(fontWeight: FontWeight.w700)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  const _RedemptionCard({
    required this.redeemable,
    required this.earnedAny,
    required this.monthlyEarned,
    required this.monthlyAvgHealth,
    required this.threshold,
    required this.capReached,
  });

  final bool redeemable;
  final bool earnedAny;
  final double monthlyEarned;
  final double monthlyAvgHealth;
  final double threshold;
  final bool capReached;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = redeemable ? AppTheme.neonGreen : AppTheme.warningAmber;
    final icon = redeemable
        ? Icons.verified_rounded
        : Icons.lock_outline_rounded;
    final title = redeemable
        ? 'Cashback is REDEEMABLE'
        : 'Cashback NOT YET redeemable';
    final body = redeemable
        ? capReached
            ? 'Monthly cap maxed at \$${monthlyEarned.toStringAsFixed(2)}. '
                'Health Score ${monthlyAvgHealth.toStringAsFixed(1)}/5 is above '
                'the ${threshold.toStringAsFixed(1)}/5 floor — full deposit '
                'lands on the 1st.'
            : 'Health Score ${monthlyAvgHealth.toStringAsFixed(1)}/5 is above '
                'the ${threshold.toStringAsFixed(1)}/5 floor. '
                '\$${monthlyEarned.toStringAsFixed(2)} will deposit on the 1st '
                'if you keep it there.'
        : earnedAny
            ? 'Your monthly Health Score is '
                '${monthlyAvgHealth.toStringAsFixed(1)}/5 — below the '
                '${threshold.toStringAsFixed(1)}/5 floor. Buy more whole '
                'foods (4★ / 5★) to lift your average and unlock the '
                '\$${monthlyEarned.toStringAsFixed(2)} you\'ve earned.'
            : 'No cashback earned yet this month. Earn some on healthy items, '
                'then keep your Health Score at '
                '${threshold.toStringAsFixed(1)}/5 or higher to unlock '
                'redemption.';

    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: cs.onSurface.withValues(alpha: 0.85),
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
