import 'package:flutter/material.dart';

/// Icon vocabulary for the app.
///
/// SVG paths point at files that already ship in `assets/svg/`; everything else
/// uses Material icons so no extra assets are needed.
class AppIcons {
  AppIcons._();

  // ── Bundled SVGs ─────────────────────────────────────────────────────────
  static const _svg = 'assets/svg';

  static const svgHome = '$_svg/house-chimney.svg';
  static const svgUser = '$_svg/user.svg';
  static const svgCircleUser = '$_svg/circle-user.svg';
  static const svgSettings = '$_svg/settings.svg';
  static const svgCopy = '$_svg/copy-alt.svg';
  static const svgSite = '$_svg/site-alt.svg';
  static const svgCard = '$_svg/credit-card-check.svg';
  static const svgFigma = '$_svg/Figma-logo.svg';

  // ── Navigation ───────────────────────────────────────────────────────────
  static const home = Icons.home_outlined;
  static const homeActive = Icons.home_rounded;
  static const vault = Icons.lock_outline_rounded;
  static const vaultActive = Icons.lock_rounded;
  static const add = Icons.add_rounded;
  static const generator = Icons.auto_awesome_outlined;
  static const generatorActive = Icons.auto_awesome_rounded;
  static const health = Icons.shield_outlined;
  static const healthActive = Icons.shield_rounded;

  // ── Actions ──────────────────────────────────────────────────────────────
  static const copy = Icons.copy_rounded;
  static const copied = Icons.check_rounded;
  static const refresh = Icons.refresh_rounded;
  static const visible = Icons.visibility_outlined;
  static const hidden = Icons.visibility_off_outlined;
  static const edit = Icons.edit_outlined;
  static const delete = Icons.delete_outline_rounded;
  static const close = Icons.close_rounded;
  static const search = Icons.search_rounded;
  static const settings = Icons.settings_outlined;

  /// Chevron pointing toward the end of the line — flips automatically under
  /// RTL because the glyph is direction-aware.
  static const chevron = Icons.chevron_left_rounded;

  // ── Status ───────────────────────────────────────────────────────────────
  static const warning = Icons.warning_amber_rounded;
  static const success = Icons.check_circle_outline_rounded;
  static const error = Icons.error_outline_rounded;
  static const info = Icons.info_outline_rounded;

  // ── Settings rows ────────────────────────────────────────────────────────
  static const fingerprint = Icons.fingerprint_rounded;
  static const faceId = Icons.face_rounded;
  static const passcode = Icons.password_rounded;
  static const person = Icons.person_outline_rounded;
  static const shield = Icons.shield_outlined;
  static const backup = Icons.backup_outlined;
  static const help = Icons.help_outline_rounded;
  static const privacy = Icons.policy_outlined;
  static const terms = Icons.description_outlined;
  static const logout = Icons.lock_outline_rounded;
  static const premium = Icons.workspace_premium_rounded;
  static const timer = Icons.timer_outlined;

  // ── Vault categories ─────────────────────────────────────────────────────
  static const browser = Icons.language_rounded;
  static const mobileApp = Icons.phone_iphone_rounded;
  static const payment = Icons.credit_card_rounded;
}
