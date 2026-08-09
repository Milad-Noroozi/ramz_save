import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/vault_controller.dart';
import '../../utils/app_helper.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_chip_row.dart';
import '../widgets/tag_selector.dart';
import '../widgets/vault_tile.dart';
import 'add_vault_view.dart';
import 'vault_detail_view.dart';

/// The full list, with search, health filters and tag filters stacked on top.
///
/// The query lives in the controller rather than in this widget: the tab shell
/// keeps the screen alive in an `IndexedStack`, and a search the user typed
/// should still be there when they come back from another tab.
class AllVaultView extends StatefulWidget {
  const AllVaultView({super.key});

  @override
  State<AllVaultView> createState() => _AllVaultViewState();
}

class _AllVaultViewState extends State<AllVaultView> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: context.read<VaultController>().query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vaults = context.watch<VaultController>();
    final visible = vaults.visible;

    // Distinguishes "no entries at all" from "nothing matched": the first wants
    // an invitation to add one, the second wants the filters cleared.
    final isFiltered =
        vaults.query.trim().isNotEmpty ||
        vaults.filter != VaultFilter.all ||
        vaults.tag != null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(AppStrings.allVaults, style: AppTextStyles.h2),
                  ),
                  Text(
                    '${AppHelper.number(visible.length)} '
                    '${AppStrings.passwordsCount}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomTextField(
                controller: _search,
                hint: AppStrings.searchVaultHint,
                icon: Icons.search_rounded,
                textInputAction: TextInputAction.search,
                onChanged: vaults.search,
                trailing: vaults.query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _search.clear();
                          vaults.search('');
                        },
                        icon: const Icon(Icons.close_rounded, size: 18),
                        color: AppColors.textHint,
                        tooltip: AppStrings.close,
                      ),
              ),
            ),
            const SizedBox(height: 14),

            FilterChipRow(
              selected: vaults.filter,
              health: vaults.health,
              onSelected: vaults.setFilter,
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TagSelector(
                selected: [?vaults.tag],
                showLabel: false,
                // Single-select here: the chips are a quick narrowing device,
                // and the controller holds one tag. Whatever the selector hands
                // back, only the tag that changed is applied.
                onChanged: (next) {
                  final tag = next.isEmpty ? vaults.tag : next.last;
                  if (tag != null) vaults.toggleTag(tag);
                },
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: visible.isEmpty
                  ? _empty(context, isFiltered: isFiltered, vaults: vaults)
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final vault = visible[index];
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
          ],
        ),
      ),
    );
  }

  Widget _empty(
    BuildContext context, {
    required bool isFiltered,
    required VaultController vaults,
  }) {
    if (isFiltered) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: AppStrings.noResults,
        message: AppStrings.noResultsHint,
        actionLabel: AppStrings.clearFilters,
        actionIcon: Icons.filter_alt_off_rounded,
        onAction: () {
          _search.clear();
          vaults.search('');
          vaults.setFilter(VaultFilter.all);
          final tag = vaults.tag;
          if (tag != null) vaults.toggleTag(tag);
        },
      );
    }

    return EmptyState(
      icon: Icons.lock_open_rounded,
      title: AppStrings.emptyVaultTitle,
      message: AppStrings.emptyVaultSubtitle,
      actionLabel: AppStrings.addVaultTitle,
      onAction: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AddVaultView()),
      ),
    );
  }
}
