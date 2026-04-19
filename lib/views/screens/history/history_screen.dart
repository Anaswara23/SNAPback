import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/month_utils.dart';
import '../../../core/utils/score_color.dart';
import '../../../core/utils/ui_scale.dart';
import '../../../viewmodels/history_view_model.dart';
import '../../../viewmodels/session_view_model.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/snapback_loader.dart';
import '../../shared/widgets/snapback_scaffold.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<HistoryViewModel>(
      create: (ctx) => HistoryViewModel(
        session: ctx.read<SessionViewModel>(),
      ),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HistoryViewModel>();
    final cs = Theme.of(context).colorScheme;

    return SnapbackScaffold(
      title: 'History',
      child: vm.isLoading
          ? const Center(
              child: SnapbackLoader(size: 84, label: 'Loading history...'),
            )
          : RefreshIndicator(
              onRefresh: vm.refresh,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _BalanceCard(vm: vm),
                  SizedBox(height: context.rGap(20)),
                  _MonthFilter(vm: vm),
                  SizedBox(height: context.rGap(12)),
                  _MonthSummary(vm: vm),
                  SizedBox(height: context.rGap(16)),
                  Padding(
                    padding: context.rPad(left: 4, bottom: 10),
                    child: Text(
                      vm.isViewingCurrentMonth
                          ? 'Trips this month'
                          : 'Trips in ${MonthUtils.monthLabel(vm.selectedMonth)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  if (vm.trips.isEmpty)
                    Center(
                      child: Padding(
                        padding: context.rPad(vertical: 40),
                        child: Text(
                          vm.isViewingCurrentMonth
                              ? 'No trips yet — scan your first receipt!'
                              : 'No trips in this month.',
                          style: TextStyle(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                    )
                  else
                    ...vm.trips.map(
                      (trip) => Padding(
                        padding: context.rPad(bottom: 10),
                        child: Container(
                          decoration: glassCardDecoration(context),
                          child: ListTile(
                            contentPadding: context.rPad(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: scoreColor(
                                trip.score.toDouble(),
                              ).withValues(alpha: 0.15),
                              child: Text(
                                '${trip.score}',
                                style: TextStyle(
                                  color: scoreColor(trip.score.toDouble()),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            title: Text(
                              trip.storeName.isNotEmpty
                                  ? trip.storeName
                                  : 'Trip ${trip.date}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${trip.date} · Health ${trip.score}/100 · '
                              '\$${trip.credit.toStringAsFixed(2)} earned',
                              style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => context.push('/trip/${trip.id}'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// ── Month filter chip row ────────────────────────────────────────────────────

class _MonthFilter extends StatelessWidget {
  const _MonthFilter({required this.vm});

  final HistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final months = vm.availableMonths;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Filter',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
          ),
        ),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: months.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final month = months[index];
              final selected = MonthUtils.sameMonth(month, vm.selectedMonth);
              return ChoiceChip(
                label: Text(MonthUtils.monthLabel(month)),
                selected: selected,
                onSelected: (_) => vm.selectMonth(month),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Per-month earnings summary chip row ──────────────────────────────────────

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.vm});

  final HistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final monthTrips = vm.trips;
    final monthEarned =
        monthTrips.fold<double>(0, (a, t) => a + t.credit);

    var weightedSum = 0;
    var totalItems = 0;
    for (final t in monthTrips) {
      final items = t.itemCount > 0 ? t.itemCount : 1;
      weightedSum += t.score * items;
      totalItems += items;
    }
    final avgHealth100 =
        totalItems == 0 ? 0 : (weightedSum / totalItems).round();
    final avgHealth5 = (avgHealth100 / 20).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryStat(
              label: 'Earned',
              value: '\$${monthEarned.toStringAsFixed(2)}',
              accent: AppTheme.neonGreen,
            ),
          ),
          _Divider(),
          Expanded(
            child: _SummaryStat(
              label: 'Trips',
              value: '${monthTrips.length}',
            ),
          ),
          _Divider(),
          Expanded(
            child: _SummaryStat(
              label: 'Health Score',
              value: '$avgHealth5/5',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 1,
      height: 28,
      color: cs.outlineVariant.withValues(alpha: 0.4),
    );
  }
}

// ── Balance card with cap + days-until-reset ─────────────────────────────────

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.vm});

  final HistoryViewModel vm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppTheme.neonGreen : AppTheme.deepGreen;

    final cap = vm.monthlyCap;
    final earned = vm.currentMonthEarned;
    final remaining = vm.monthlyRemaining;
    final daysLeft = vm.daysUntilReset;
    final ratio = vm.monthlyProgressRatio;
    final hitCap = ratio >= 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0D2B17), const Color(0xFF0A1F22)]
              : [const Color(0xFFE6F9EE), const Color(0xFFDFF4FA)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Rewards Balance',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${earned.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  'of \$${cap.toStringAsFixed(2)} cap',
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            hitCap
                ? 'Cap reached. Resets in $daysLeft day${daysLeft == 1 ? '' : 's'}.'
                : '\$${remaining.toStringAsFixed(2)} left to earn this month.',
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              valueColor: AlwaysStoppedAnimation(accent),
              backgroundColor: accent.withValues(alpha: 0.14),
            ),
          ),
          const SizedBox(height: 12),
          _RedemptionBadge(
            redeemable: vm.isRedeemable,
            earnedAny: earned > 0,
            avgHealth: vm.currentMonthAvgHealthScore,
            threshold: vm.redemptionThreshold,
          ),
          const SizedBox(height: 10),
          Text(
            'Cap = min(10% × SNAP, \$25 × household). Deposit on the 1st only '
            'if your monthly Health Score stays at '
            '${vm.redemptionThreshold.toStringAsFixed(1)}/5 or above.',
            style: TextStyle(
              fontSize: 11,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
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
        ? 'REDEEMABLE'
        : 'NOT YET REDEEMABLE';
    final body = redeemable
        ? 'Health Score ${avgHealth.toStringAsFixed(1)}/5 — above the '
            '${threshold.toStringAsFixed(1)} floor.'
        : earnedAny
            ? 'Health Score ${avgHealth.toStringAsFixed(1)}/5. Reach '
                '${threshold.toStringAsFixed(1)}/5 by month-end to unlock.'
            : 'Earn cashback on healthy items, then keep Health Score at '
                '${threshold.toStringAsFixed(1)}/5 or higher to unlock.';

    return Semantics(
      container: true,
      label: 'Cashback $title. $body',
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 11,
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
