import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_routes.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../models/vault_model.dart';
import '../../utils/app_helper.dart';
import '../vault/vault_detail_view.dart';
import '../widgets/empty_state.dart';
import '../widgets/safety_score_gauge.dart';
import '../widgets/section_header.dart';
import '../widgets/tag_selector.dart';
import '../widgets/vault_tile.dart';

/// The landing tab: greeting, safety score, category counts, recent entries.
class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final vaults = context.watch<VaultController>();
    final name = context.select<AuthController, String>(
      (a) => a.user?.name ?? '',
    );
    final recent = vaults.topVaults();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(name: name)),
            SliverToBoxAdapter(
              child: Center(
                child: SafetyScoreGauge(
                  percentage: vaults.health.score.toDouble(),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            SliverToBoxAdapter(child: _CategoryRow(vaults: vaults)),
            const SliverToBoxAdapter(child: SizedBox(height: 28)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(
                  title: AppStrings.topVaults,
                  onActionTap: recent.isEmpty
                      ? null
                      : () =>
                            Navigator.of(context).pushNamed(
                              AppRoutes.allVaults,
                            ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (recent.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: EmptyState(
                    icon: Icons.lock_open_rounded,
                    title: AppStrings.emptyVaultTitle,
                    message: AppStrings.emptyVaultSubtitle,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList.separated(
                  itemCount: recent.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final vault = recent[index];
                    return VaultTile(
                      vault: vault,
                      isWeak: vaults.isWeak(vault.id),
                      isReused: vaults.isReused(vault.id),
                      isCompromised: vaults.isCompromised(vault.id),
                      onTap: () => VaultDetailSheet.show(context, vault),
                    );
                  },
                ),
              ),
            // Clears the floating nav bar, which `extendBody` lets the list
            // scroll underneath.
            const SliverToBoxAdapter(child: SizedBox(height: 110)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;

  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppStrings.welcomeBack, style: AppTextStyles.bodyMedium),
                const SizedBox(height: 2),
                Text(
                  name.isEmpty ? AppStrings.appName : name,
                  style: AppTextStyles.h2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            color: AppColors.textSecondary,
            tooltip: AppStrings.settings,
          ),
          IconButton(
            onPressed: () => context.read<AuthController>().lock(),
            icon: const Icon(Icons.lock_outline),
            color: AppColors.textSecondary,
            tooltip: AppStrings.logOut,
          ),
        ],
      ),
    );
  }
}

/// Three counts, one per tag, doubling as shortcuts into the filtered list.
class _CategoryRow extends StatelessWidget {
  final VaultController vaults;

  const _CategoryRow({required this.vaults});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          for (final tag in VaultTag.values) ...[
            Expanded(
              child: _CategoryCard(
                tag: tag,
                count: vaults.countByTag(tag),
                onTap: () {
                  // Selecting the tag before navigating means the list opens
                  // already filtered rather than flashing the full set first.
                  if (vaults.tag != tag) vaults.toggleTag(tag);
                  Navigator.of(context).pushNamed(AppRoutes.allVaults);
                },
              ),
            ),
            if (tag != VaultTag.values.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final VaultTag tag;
  final int count;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.tag,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: tag.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(tag.icon, size: 20, color: tag.color),
              ),
              const SizedBox(height: 10),
              Text(
                AppHelper.number(count),
                style: AppTextStyles.h3.copyWith(color: tag.color),
              ),
              const SizedBox(height: 2),
              Text(
                tag.label,
                style: AppTextStyles.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
