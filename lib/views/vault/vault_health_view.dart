import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../utils/app_helper.dart';
import '../widgets/empty_state.dart';
import '../widgets/safety_score_gauge.dart';
import '../widgets/section_header.dart';
import '../widgets/vault_tile.dart';
import 'vault_detail_view.dart';

/// The health report: the score, a breakdown by issue, and the at-risk entries.
///
/// Everything here is computed offline from what is already decrypted in memory.
/// The online breach check is a separate, opt-in refresh — see
/// [VaultController.refreshOnlineBreaches].
class VaultHealthView extends StatefulWidget {
  const VaultHealthView({super.key});

  @override
  State<VaultHealthView> createState() => _VaultHealthViewState();
}

class _VaultHealthViewState extends State<VaultHealthView> {
  bool _checking = false;

  Future<void> _checkOnline() async {
    setState(() => _checking = true);
    await context.read<VaultController>().refreshOnlineBreaches();
    if (mounted) setState(() => _checking = false);
  }

  @override
  Widget build(BuildContext context) {
    final vaults = context.watch<VaultController>();
    final health = vaults.health;
    final onlineEnabled = context.select<SettingsController, bool>(
      (s) => s.checkBreachesOnline,
    );

    final atRisk = [
      for (final v in vaults.all)
        if (health.atRiskIds.contains(v.id)) v,
    ];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Text(AppStrings.vaultsHealth, style: AppTextStyles.h2),
            const SizedBox(height: 12),
            Center(
              child: SafetyScoreGauge(
                percentage: health.score.toDouble(),
              ),
            ),
            const SizedBox(height: 20),

            _StatGrid(health: health),
            const SizedBox(height: 20),

            if (onlineEnabled)
              _OnlineCheckCard(
                busy: _checking,
                onCheck: _checking ? null : _checkOnline,
              ),

            const SizedBox(height: 24),
            if (atRisk.isEmpty)
              EmptyState(
                icon: Icons.verified_user_outlined,
                title: AppStrings.allHealthy,
                message: health.total == 0
                    ? AppStrings.emptyVaultSubtitle
                    : null,
                color: AppColors.green,
              )
            else ...[
              SectionHeader(
                title:
                    '${AppHelper.number(atRisk.length)} '
                    '${AppStrings.vaultsAtRisk}',
              ),
              const SizedBox(height: 12),
              for (final vault in atRisk)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VaultTile(
                    vault: vault,
                    isWeak: vaults.isWeak(vault.id),
                    isReused: vaults.isReused(vault.id),
                    isCompromised: vaults.isCompromised(vault.id),
                    onTap: () => VaultDetailSheet.show(context, vault),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The four counts. Tapping one is not wired to the list filter on purpose —
/// this screen already shows every at-risk entry underneath.
class _StatGrid extends StatelessWidget {
  final VaultHealth health;

  const _StatGrid({required this.health});

  @override
  Widget build(BuildContext context) {
    final stats = [
      (AppStrings.totalVaults, health.total, AppColors.purple, Icons.folder_outlined),
      (AppStrings.safeVaults, health.safeCount, AppColors.green, Icons.shield_outlined),
      (
        AppStrings.compromisedVaults,
        health.compromisedCount,
        AppColors.error,
        Icons.dangerous_outlined,
      ),
      (
        AppStrings.weakVaults,
        health.weakCount,
        AppColors.warning,
        Icons.priority_high_rounded,
      ),
      (
        AppStrings.reusedVaults,
        health.reusedCount,
        AppColors.blue,
        Icons.content_copy_outlined,
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        for (final (label, count, color, icon) in stats)
          // Two per row, minus the spacing. LayoutBuilder-free: the padding is
          // fixed and known here.
          SizedBox(
            width: (MediaQuery.sizeOf(context).width - 52) / 2,
            child: _StatCard(
              label: label,
              count: count,
              color: color,
              icon: icon,
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelper.number(count),
                  style: AppTextStyles.h3.copyWith(color: color),
                ),
                Text(
                  label,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnlineCheckCard extends StatelessWidget {
  final bool busy;
  final VoidCallback? onCheck;

  const _OnlineCheckCard({required this.busy, this.onCheck});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.checkBreaches,
                  style: AppTextStyles.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.checkBreachesDesc,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.7),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : IconButton(
                  onPressed: onCheck,
                  icon: const Icon(Icons.cloud_sync_outlined),
                  color: AppColors.green,
                  tooltip: AppStrings.checkBreaches,
                ),
        ],
      ),
    );
  }
}
