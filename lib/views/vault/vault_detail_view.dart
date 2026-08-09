import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/password_generator_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../models/vault_model.dart';
import '../../utils/app_helper.dart';
import '../widgets/custom_button.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/section_header.dart';
import '../widgets/tag_selector.dart';
import 'add_vault_view.dart';

/// The bottom sheet shown when a vault row is tapped.
///
/// The password starts hidden and reveals on demand. Copying goes through
/// [PasswordGeneratorController.copyToClipboard], which wipes the clipboard
/// after 30 seconds — the clipboard is readable by every app on the device and
/// outlives the vault locking, so a copied secret has no protection until then.
class VaultDetailSheet extends StatefulWidget {
  final String vaultId;

  const VaultDetailSheet({required this.vaultId, super.key});

  static Future<void> show(BuildContext context, VaultModel vault) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => VaultDetailSheet(vaultId: vault.id),
    );
  }

  @override
  State<VaultDetailSheet> createState() => _VaultDetailSheetState();
}

class _VaultDetailSheetState extends State<VaultDetailSheet> {
  bool _revealed = false;

  Future<void> _copy(BuildContext context, String value, String message) async {
    await context.read<PasswordGeneratorController>().copyToClipboard(value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message — ${AppStrings.clipboardAutoClear}'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, VaultModel vault) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.deleteVaultTitle),
        content: const Text(AppStrings.deleteVaultMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text(AppStrings.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<VaultController>().delete(vault.id);
    if (!context.mounted) return;

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(AppStrings.vaultDeleted)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VaultController>();

    // Read by id rather than holding the model: an edit made from this sheet
    // replaces the entry, and a captured copy would keep showing stale values.
    final vault = controller.byId(widget.vaultId);
    if (vault == null) return const SizedBox.shrink();

    final isCompromised = controller.isCompromised(vault.id);
    final isReused = controller.isReused(vault.id);
    final isWeak = controller.isWeak(vault.id);

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _SheetHeader(vault: vault),
          const SizedBox(height: 20),

          if (isCompromised || isReused || isWeak) ...[
            _RiskBanner(
              compromised: isCompromised,
              reused: isReused,
              weak: isWeak,
            ),
            const SizedBox(height: 20),
          ],

          if (vault.type == VaultType.account) ...[
            DetailRow(
              label: AppStrings.login,
              value: vault.login,
              latin: true,
              icon: Icons.person_outline,
              trailing: _CopyButton(
                onTap: () =>
                    _copy(context, vault.login, AppStrings.loginCopied),
              ),
            ),
            _PasswordRow(
              password: vault.password,
              revealed: _revealed,
              onToggle: () => setState(() => _revealed = !_revealed),
              onCopy: () =>
                  _copy(context, vault.password, AppStrings.passwordCopied),
            ),
            if (vault.serviceUrl?.isNotEmpty ?? false)
              DetailRow(
                label: AppStrings.siteAddress,
                value: vault.serviceUrl!,
                latin: true,
                icon: Icons.link_rounded,
              ),
          ] else ...[
            DetailRow(
              label: AppStrings.cardHolder,
              value: vault.cardHolder ?? '—',
              icon: Icons.person_outline,
            ),
            DetailRow(
              label: AppStrings.cardNumber,
              value: _revealed
                  ? AppHelper.formatCardNumber(vault.cardNumber ?? '')
                  : AppHelper.maskCardNumber(vault.cardNumber ?? ''),
              latin: true,
              icon: Icons.credit_card_rounded,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RevealButton(
                    revealed: _revealed,
                    onTap: () => setState(() => _revealed = !_revealed),
                  ),
                  _CopyButton(
                    onTap: () => _copy(
                      context,
                      vault.cardNumber ?? '',
                      AppStrings.copied,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: DetailRow(
                    label: AppStrings.expiryDate,
                    value: vault.cardExpiry ?? '—',
                    latin: true,
                    icon: Icons.event_outlined,
                  ),
                ),
                Expanded(
                  child: DetailRow(
                    label: AppStrings.cvv,
                    value: _revealed ? (vault.cvv ?? '—') : '•••',
                    latin: true,
                    icon: Icons.password_rounded,
                  ),
                ),
              ],
            ),
          ],

          if (vault.note?.isNotEmpty ?? false)
            DetailRow(
              label: AppStrings.note,
              value: vault.note!,
              icon: Icons.notes_rounded,
            ),

          if (vault.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(AppStrings.tags, style: AppTextStyles.bodySmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in vault.tags) TagChip(tag: tag)],
            ),
          ],

          const SizedBox(height: 18),
          _Timestamps(vault: vault),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: AppStrings.edit,
                  icon: Icons.edit_outlined,
                  onPressed: () async {
                    Navigator.pop(context);
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddVaultView(existing: vault),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomButton.outlined(
                  text: AppStrings.delete,
                  icon: Icons.delete_outline,
                  color: AppColors.error,
                  onPressed: () => _confirmDelete(context, vault),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  final VaultModel vault;

  const _SheetHeader({required this.vault});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: vault.type == VaultType.payment
              ? const Icon(
                  Icons.credit_card_rounded,
                  color: AppColors.purple,
                  size: 24,
                )
              : Text(
                  AppHelper.initial(vault.serviceName),
                  style: AppTextStyles.h2.copyWith(color: AppColors.purple),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                vault.serviceName,
                style: AppTextStyles.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(vault.type.label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// The password row: hidden by default, with strength shown underneath.
class _PasswordRow extends StatelessWidget {
  final String password;
  final bool revealed;
  final VoidCallback onToggle;
  final VoidCallback onCopy;

  const _PasswordRow({
    required this.password,
    required this.revealed,
    required this.onToggle,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DetailRow(
          label: AppStrings.password,
          // A fixed-width mask rather than one bullet per character: the length
          // of a password is itself worth not leaking over someone's shoulder.
          value: revealed ? password : '••••••••••••',
          latin: true,
          icon: Icons.lock_outline,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _RevealButton(revealed: revealed, onTap: onToggle),
              _CopyButton(onTap: onCopy),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 36, bottom: 6),
          child: PasswordStrengthBar.of(password),
        ),
      ],
    );
  }
}

class _RevealButton extends StatelessWidget {
  final bool revealed;
  final VoidCallback onTap;

  const _RevealButton({required this.revealed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        size: 20,
      ),
      color: AppColors.textHint,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _CopyButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CopyButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: const Icon(Icons.copy_rounded, size: 18),
      color: AppColors.green,
      tooltip: AppStrings.copy,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _RiskBanner extends StatelessWidget {
  final bool compromised;
  final bool reused;
  final bool weak;

  const _RiskBanner({
    required this.compromised,
    required this.reused,
    required this.weak,
  });

  @override
  Widget build(BuildContext context) {
    final color = compromised ? AppColors.error : AppColors.warning;
    final issues = [
      if (compromised) AppStrings.filterCompromised,
      if (reused) AppStrings.filterReused,
      if (weak) AppStrings.filterWeak,
    ].join('، ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issues,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.weakPasswordAdvice,
                  style: AppTextStyles.bodySmall.copyWith(height: 1.7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Timestamps extends StatelessWidget {
  final VaultModel vault;

  const _Timestamps({required this.vault});

  @override
  Widget build(BuildContext context) {
    final updated = vault.updatedAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _row(
            AppStrings.createdOn,
            AppHelper.formatJalali(vault.createdAt),
          ),
          if (updated != null) ...[
            const SizedBox(height: 8),
            _row(
              AppStrings.lastUpdated,
              '${AppHelper.formatJalali(updated)} · '
              '${AppHelper.relativeTime(updated)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTextStyles.bodySmall),
      Text(
        value,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    ],
  );
}
