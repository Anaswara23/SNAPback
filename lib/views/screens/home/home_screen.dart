import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../viewmodels/home_view_model.dart';
import '../../../viewmodels/session_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/score_ring.dart';
import '../../shared/widgets/snapback_loader.dart';
import '../../shared/widgets/snapback_scaffold.dart';
import '../../shared/widgets/stat_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HomeViewModel>(
      create: (context) =>
          HomeViewModel(session: context.read<SessionViewModel>()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();
    return SnapbackScaffold(
      title: 'Dashboard',
      child: vm.isLoading || vm.stats == null
          ? const Center(
              child: SnapbackLoader(
                size: 84,
                label: 'Loading your dashboard...',
              ),
            )
          : RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    'Welcome back, ${vm.greetingName}',
                    style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                  ),
                  SizedBox(height: context.rGap(16)),
                  ScoreRing(
                    score: vm.stats!.monthlyAvgHealthScore.toDouble(),
                    label: 'Health Score (this month)',
                    sublabel:
                        '${vm.monthlyAvgHealthScore.toStringAsFixed(1)} / 5 avg',
                  ),
                  SizedBox(height: context.rGap(18)),
                  Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          label: 'Trips this month',
                          value: '${vm.stats!.monthlyTripCount}',
                          color: AppTheme.neonBlue,
                        ),
                      ),
                      SizedBox(width: context.rGap(10)),
                      Expanded(
                        child: StatCard(
                          label: 'SNAP Earned',
                          value:
                              '\$${vm.stats!.monthlyCredit.toStringAsFixed(2)}',
                          color: AppTheme.neonGreen,
                        ),
                      ),
                      SizedBox(width: context.rGap(10)),
                      Expanded(
                        child: StatCard(
                          label: 'Days left',
                          value: '${vm.daysUntilReset}',
                          color: AppTheme.warningAmber,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: context.rGap(16)),
                  _CapCountdown(vm: vm),
                  SizedBox(height: context.rGap(16)),
                  GlassCard(child: Text(vm.latestHighlights)),
                  SizedBox(height: context.rGap(16)),
                  FilledButton.icon(
                    onPressed: () =>
                        ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tap the Scan tab below'),
                      ),
                    ),
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scan Receipt'),
                  ),
                ],
              ),
            ),
    );
  }
}

class _CapCountdown extends StatelessWidget {
  const _CapCountdown({required this.vm});

  final HomeViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final daysLeft = vm.daysUntilReset;
    final ratio = vm.monthlyProgressRatio;
    final hitCap = ratio >= 1;
    final redeemable = vm.isRedeemable;
    final avgHealth = vm.monthlyAvgHealthScore;
    final threshold = vm.redemptionThreshold;
    final earnedAny = vm.monthlyEarned > 0;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_repeat_rounded,
                color: AppTheme.neonGreen,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Monthly cashback',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.neonGreen.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.neonGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: AppTheme.neonGreen.withValues(alpha: 0.14),
              valueColor: const AlwaysStoppedAnimation(AppTheme.neonGreen),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${vm.monthlyEarned.toStringAsFixed(2)} of '
            '\$${vm.monthlyCap.toStringAsFixed(2)} cap',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            hitCap
                ? 'You\'ve maxed out this month. Keep eating well!'
                : '\$${vm.monthlyRemaining.toStringAsFixed(2)} more available '
                    'before the 1st.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 12),
          _RedemptionBadge(
            redeemable: redeemable,
            earnedAny: earnedAny,
            avgHealth: avgHealth,
            threshold: threshold,
          ),
        ],
      ),
    );
  }
}

class _RedemptionBadge extends StatelessWidget {
  const _RedemptionBadge({
    required this.redeemable,
    required this.earnedAny,
    required this.avgHealth,
    required this.threshold,
  });

  final bool redeemable;
  final bool earnedAny;
  final double avgHealth;
  final double threshold;

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
        ? 'Health Score ${avgHealth.toStringAsFixed(1)}/5 is above the '
            '${threshold.toStringAsFixed(1)}/5 threshold. Keep it up!'
        : earnedAny
            ? 'Your monthly Health Score is '
                '${avgHealth.toStringAsFixed(1)}/5. Keep it at '
                '${threshold.toStringAsFixed(1)}/5 or higher by month-end '
                'to unlock the deposit.'
            : 'Earn cashback on healthy items first. Then keep your monthly '
                'Health Score at ${threshold.toStringAsFixed(1)}/5 or higher '
                'to unlock redemption.';

    return Semantics(
      container: true,
      label: '$title. $body',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
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
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
