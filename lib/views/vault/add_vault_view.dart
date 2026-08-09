import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/app_text_styles.dart';
import '../../controllers/password_generator_controller.dart';
import '../../controllers/vault_controller.dart';
import '../../models/vault_model.dart';
import '../../utils/app_helper.dart';
import '../../utils/input_formatters.dart';
import '../../utils/validators.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/password_strength_bar.dart';
import '../widgets/tag_selector.dart';

/// The add / edit form for both entry kinds.
///
/// Passing [existing] switches it to edit mode: the fields start filled and the
/// id is preserved, so saving replaces the entry instead of adding a duplicate.
/// The kind is fixed while editing — an account and a card share almost no
/// fields, so switching would silently discard half the form.
class AddVaultView extends StatefulWidget {
  final VaultModel? existing;

  /// Pre-fills the password field, used when arriving from the generator.
  final String? initialPassword;

  const AddVaultView({this.existing, this.initialPassword, super.key});

  @override
  State<AddVaultView> createState() => _AddVaultViewState();
}

class _AddVaultViewState extends State<AddVaultView> {
  static const _uuid = Uuid();

  final _formKey = GlobalKey<FormState>();

  final _serviceName = TextEditingController();
  final _serviceUrl = TextEditingController();
  final _login = TextEditingController();
  final _password = TextEditingController();
  final _note = TextEditingController();

  final _cardHolder = TextEditingController();
  final _cardNumber = TextEditingController();
  final _expiry = TextEditingController();
  final _cvv = TextEditingController();

  late VaultType _type;
  late List<VaultTag> _tags;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;

    _type = existing?.type ?? VaultType.account;
    _tags = [...?existing?.tags];

    if (existing != null) {
      _serviceName.text = existing.serviceName;
      _serviceUrl.text = existing.serviceUrl ?? '';
      _login.text = existing.login;
      _password.text = existing.password;
      _note.text = existing.note ?? '';
      _cardHolder.text = existing.cardHolder ?? '';
      _cardNumber.text = AppHelper.formatCardNumber(existing.cardNumber ?? '');
      _expiry.text = existing.cardExpiry ?? '';
      _cvv.text = existing.cvv ?? '';
    } else if (widget.initialPassword != null) {
      _password.text = widget.initialPassword!;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _serviceName,
      _serviceUrl,
      _login,
      _password,
      _note,
      _cardHolder,
      _cardNumber,
      _expiry,
      _cvv,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Borrows the generator's saved options so the password produced here obeys
  /// the same rules the user set on that screen.
  void _generatePassword() {
    final generator = context.read<PasswordGeneratorController>();
    generator.regenerate();
    if (generator.password.isEmpty) return;
    setState(() => _password.text = generator.password);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final vaults = context.read<VaultController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _saving = true);

    final existing = widget.existing;
    final isPayment = _type == VaultType.payment;

    // A card with no tag would fall out of the payment category card on the
    // home screen, which is where users go looking for it.
    final tags = isPayment && _tags.isEmpty ? [VaultTag.payment] : _tags;

    // Stored without its display spaces: the grouping is a reading aid, and
    // comparing two numbers formatted differently would report them as unequal.
    final rawCard = AppHelper.toEnglishDigits(
      _cardNumber.text,
    ).replaceAll(RegExp(r'\D'), '');

    final model = VaultModel(
      id: existing?.id ?? _uuid.v4(),
      type: _type,
      serviceName: _serviceName.text.trim(),
      serviceUrl: isPayment ? null : _nullIfBlank(_serviceUrl.text),
      login: isPayment ? '' : _login.text.trim(),
      password: isPayment ? '' : _password.text,
      tags: tags,
      note: _nullIfBlank(_note.text),
      createdAt: existing?.createdAt ?? DateTime.now(),
      updatedAt: existing == null ? null : DateTime.now(),
      cardHolder: isPayment ? _cardHolder.text.trim() : null,
      cardNumber: isPayment ? rawCard : null,
      cardExpiry: isPayment ? AppHelper.toEnglishDigits(_expiry.text) : null,
      cvv: isPayment ? AppHelper.toEnglishDigits(_cvv.text.trim()) : null,
    );

    await vaults.save(model);

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text(AppStrings.vaultSaved)),
    );
  }

  static String? _nullIfBlank(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editVaultTitle : AppStrings.addVaultTitle,
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              // Editing keeps the kind fixed: the two forms barely overlap, so
              // switching would throw away everything already typed.
              if (!_isEditing) ...[
                _TypeTabs(
                  selected: _type,
                  onChanged: (type) => setState(() => _type = type),
                ),
                const SizedBox(height: 24),
              ],

              CustomTextField(
                controller: _serviceName,
                label: AppStrings.serviceName,
                hint: AppStrings.serviceNameHint,
                icon: Icons.apps_rounded,
                textInputAction: TextInputAction.next,
                validator: Validators.required,
              ),
              const SizedBox(height: 18),

              if (_type == VaultType.account)
                ..._accountFields()
              else
                ..._cardFields(),

              const SizedBox(height: 18),
              CustomTextField(
                controller: _note,
                label: AppStrings.note,
                hint: AppStrings.noteHint,
                icon: Icons.notes_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 22),

              TagSelector(
                selected: _tags,
                onChanged: (tags) => setState(() => _tags = tags),
              ),
              const SizedBox(height: 32),

              CustomButton(
                text: _isEditing
                    ? AppStrings.saveChanges
                    : AppStrings.createTheVault,
                icon: Icons.check_rounded,
                isLoading: _saving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _accountFields() => [
    CustomTextField(
      controller: _serviceUrl,
      label: AppStrings.siteAddress,
      hint: AppStrings.siteAddressHint,
      latin: true,
      icon: Icons.link_rounded,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.next,
      validator: Validators.url,
    ),
    const SizedBox(height: 18),
    CustomTextField(
      controller: _login,
      label: AppStrings.login,
      hint: AppStrings.loginHint,
      latin: true,
      icon: Icons.person_outline,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: Validators.loginIdentifier,
    ),
    const SizedBox(height: 18),
    CustomTextField.password(
      controller: _password,
      validator: Validators.required,
      // Rebuilds the strength bar as the user types, which is the whole point
      // of showing it while the password is still being chosen.
      onChanged: (_) => setState(() {}),
      footer: Row(
        children: [
          Expanded(child: PasswordStrengthBar.of(_password.text)),
          const SizedBox(width: 12),
          TextButton.icon(
            onPressed: _generatePassword,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: const Text(AppStrings.generateStrongPassword),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.green,
              textStyle: AppTextStyles.label,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    ),
  ];

  List<Widget> _cardFields() => [
    CustomTextField(
      controller: _cardHolder,
      label: AppStrings.cardHolder,
      hint: AppStrings.cardHolderHint,
      icon: Icons.person_outline,
      textInputAction: TextInputAction.next,
      validator: Validators.required,
    ),
    const SizedBox(height: 18),
    CustomTextField.numeric(
      controller: _cardNumber,
      label: AppStrings.cardNumber,
      hint: AppStrings.cardNumberHint,
      icon: Icons.credit_card_rounded,
      textInputAction: TextInputAction.next,
      // 19 digits plus the grouping spaces the formatter inserts.
      maxLength: 23,
      inputFormatters: const [CardNumberFormatter()],
      validator: Validators.cardNumber,
    ),
    const SizedBox(height: 18),
    Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CustomTextField.numeric(
            controller: _expiry,
            label: AppStrings.expiryDate,
            hint: AppStrings.expiryHint,
            icon: Icons.event_outlined,
            textInputAction: TextInputAction.next,
            maxLength: 5,
            inputFormatters: const [ExpiryDateFormatter()],
            validator: Validators.expiryDate,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: CustomTextField.numeric(
            controller: _cvv,
            label: AppStrings.cvv,
            hint: AppStrings.cvvHint,
            icon: Icons.password_rounded,
            textInputAction: TextInputAction.done,
            maxLength: 4,
            inputFormatters: const [LatinDigitsFormatter()],
            validator: Validators.cvv,
          ),
        ),
      ],
    ),
  ];
}

/// The account / card switch at the top of the form.
class _TypeTabs extends StatelessWidget {
  final VaultType selected;
  final ValueChanged<VaultType> onChanged;

  const _TypeTabs({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(14),
      ),
      // A plain Row: the first tab lands on the right in RTL without any
      // reordering here.
      child: Row(
        children: [
          for (final type in VaultType.values)
            Expanded(
              child: _Tab(
                label: type.label,
                icon: type == VaultType.account
                    ? Icons.person_outline
                    : Icons.credit_card_rounded,
                selected: type == selected,
                onTap: () => onChanged(type),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.purple : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : AppColors.textHint,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
