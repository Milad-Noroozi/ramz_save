import 'package:flutter/material.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../models/vault_model.dart';
import '../../utils/app_helper.dart';

/// One row in the vault list: avatar, name, and the identifier underneath.
///
/// The subtitle is Latin data — an email, a username, a masked card number — so
/// it renders in its own left-to-right island inside the right-to-left row.
class VaultTile extends StatelessWidget {
  final VaultModel vault;
  final VoidCallback? onTap;

  /// Shown as a small copy affordance at the end of the row.
  final VoidCallback? onCopy;

  /// Risk flags from `VaultController.health`, drawn as a dot on the avatar.
  final bool isWeak;
  final bool isReused;
  final bool isCompromised;

  const VaultTile({
    required this.vault,
    this.onTap,
    this.onCopy,
    this.isWeak = false,
    this.isReused = false,
    this.isCompromised = false,
    super.key,
  });

  /// The identifier line: card entries show the last four digits, accounts show
  /// the login, and a login-less account falls back to its host.
  String get _subtitle {
    if (vault.type == VaultType.payment) {
      return AppHelper.maskCardNumber(vault.cardNumber ?? '');
    }
    if (vault.login.isNotEmpty) return vault.login;
    return AppHelper.prettyHost(vault.serviceUrl ?? '');
  }

  /// Worst issue wins the badge — a leaked password matters more than a weak
  /// one, so it is what the row should say when both are true.
  Color? get _riskColor {
    if (isCompromised) return AppColors.error;
    if (isReused) return AppColors.warning;
    if (isWeak) return AppColors.warning;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final risk = _riskColor;

    return Material(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: 12,
            end: 8,
            top: 12,
            bottom: 12,
          ),
          child: Row(
            children: [
              _Avatar(vault: vault, riskColor: risk),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vault.serviceName,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // The island: without this, `user@mail.com` renders with
                    // the domain first.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Text(
                          _subtitle,
                          style: AppTextStyles.mono.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (onCopy != null)
                IconButton(
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  color: AppColors.textHint,
                  tooltip: AppStrings.copy,
                )
              else
                // `chevron_left` would point the wrong way in RTL; the
                // directional variant follows the ambient direction.
                const Padding(
                  padding: EdgeInsetsDirectional.only(end: 8),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textHint,
                    textDirection: TextDirection.rtl,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final VaultModel vault;
  final Color? riskColor;

  const _Avatar({required this.vault, this.riskColor});

  /// A stable colour per service, so the same entry keeps its tile colour
  /// between launches instead of being assigned one by list position.
  static const _palette = [
    AppColors.purple,
    AppColors.blue,
    AppColors.green,
    AppColors.warning,
  ];

  Color get _color {
    if (vault.serviceName.isEmpty) return AppColors.purple;
    final sum = vault.serviceName.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[sum % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;

    return SizedBox(
      width: 46,
      height: 46,
      child: Stack(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: vault.type == VaultType.payment
                ? Icon(Icons.credit_card_rounded, size: 22, color: color)
                : Text(
                    AppHelper.initial(vault.serviceName),
                    style: AppTextStyles.h3.copyWith(color: color),
                  ),
          ),
          if (riskColor != null)
            PositionedDirectional(
              end: 0,
              top: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: riskColor,
                  shape: BoxShape.circle,
                  // Ring in the card colour so the dot reads as separate from
                  // the avatar behind it.
                  border: Border.all(color: AppColors.cardBg, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
