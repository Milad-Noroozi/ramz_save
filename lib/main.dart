import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_routes.dart';
import 'config/app_strings.dart';
import 'config/app_theme.dart';
import 'controllers/auth_controller.dart';
import 'controllers/password_generator_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/vault_controller.dart';
import 'views/auth/login_view.dart';
import 'views/auth/register_view.dart';
import 'views/auth/splash_view.dart';
import 'views/main_page.dart';
import 'views/profile/profile_view.dart';
import 'views/settings/backup_view.dart';
import 'views/settings/change_master_password_view.dart';
import 'views/settings/premium_view.dart';
import 'views/settings/settings_view.dart';
import 'views/vault/add_vault_view.dart';
import 'views/vault/all_vault_view.dart';
import 'views/vault/password_generator_view.dart';
import 'views/vault/vault_health_view.dart';

void main() {
  runApp(const RamzSaveApp());
}

class RamzSaveApp extends StatelessWidget {
  const RamzSaveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Owns the key material and the database handle, so everything under it
        // is built from it rather than opening its own.
        ChangeNotifierProvider(
          create: (_) => AuthController()..bootstrap(),
          lazy: false,
        ),

        // Proxied on auth: entries only exist while the box is open, so loading
        // follows unlocking and clear() follows locking.
        ChangeNotifierProxyProvider<AuthController, VaultController>(
          create: (context) =>
              VaultController(db: context.read<AuthController>().db),
          update: (_, auth, vaults) {
            final controller = vaults!;
            if (auth.isUnlocked) {
              controller.load();
            } else if (controller.isLoaded) {
              controller.clear();
            }
            return controller;
          },
        ),

        ChangeNotifierProxyProvider<
          AuthController,
          PasswordGeneratorController
        >(
          create: (context) => PasswordGeneratorController(
            db: context.read<AuthController>().db,
          ),
          update: (_, _, generator) => generator!,
        ),

        ChangeNotifierProxyProvider2<
          AuthController,
          VaultController,
          SettingsController
        >(
          create: (context) => SettingsController(
            auth: context.read<AuthController>(),
            vaults: context.read<VaultController>(),
          ),
          // Rebuilt only to re-notify: every value it exposes is read through
          // to auth, so it holds no state of its own to refresh here.
          update: (_, _, _, settings) => settings!,
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,

        // Persian only, and declared rather than left to the device: without the
        // delegates the framework's own strings — the text-selection menu, the
        // date picker — fall back to English inside an otherwise Persian app.
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],

        // Belt and braces over the locale: this also wraps the overlays —
        // dialogs, snackbars, bottom sheets — that hang off the app's Navigator
        // rather than off the page that opened them.
        builder: (context, child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),

        home: const _AuthGate(),
        routes: {
          AppRoutes.home: (_) => const MainPage(),
          AppRoutes.allVaults: (_) => const AllVaultView(),
          AppRoutes.addVault: (_) => const AddVaultView(),
          AppRoutes.passwordGenerator: (_) => const PasswordGeneratorView(),
          AppRoutes.vaultHealth: (_) => const VaultHealthView(),
          AppRoutes.settings: (_) => const SettingsView(),
          AppRoutes.profile: (_) => const ProfileView(),
          AppRoutes.backup: (_) => const BackupView(),
          AppRoutes.premium: (_) => const PremiumView(),
          AppRoutes.changeMasterPassword: (_) =>
              const ChangeMasterPasswordView(),
        },
      ),
    );
  }
}

/// Picks the screen from the auth status.
///
/// Swapping the whole subtree rather than pushing a lock route on top: a lock
/// has to take the vault off the screen however deep the user had navigated,
/// and anything left mounted above it would go on rendering entries it captured
/// before the box closed.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthController, AuthStatus>((a) => a.status);

    return switch (status) {
      AuthStatus.unknown => const SplashView(),
      AuthStatus.needsSetup => const RegisterView(),
      AuthStatus.locked => const LoginView(),
      AuthStatus.unlocked => const MainPage(),
    };
  }
}
