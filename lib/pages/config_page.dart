import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapp/pages/edit_profile_page.dart';
import 'package:tapp/providers/theme_provider.dart';
import 'package:tapp/theme/app_colors.dart';
import 'package:tapp/widgets/custom_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: const CustomAppBar(
        showBackButton: true,
        logoCentered: true,
        showConfigButton: false,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: [
              Text(
                'Configuracion',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.withValues(
                    alpha: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: SwitchListTile.adaptive(
                  key: const Key('config_theme_switch_tile'),
                  title: const Text(
                    'Modo oscuro',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    isDarkMode ? 'Activado' : 'Desactivado',
                    key: const Key('config_theme_mode_label'),
                  ),
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    color: AppColors.brandPrimary,
                  ),
                  value: isDarkMode,
                  onChanged: context.read<ThemeProvider>().setDarkMode,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.withValues(
                    alpha: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  key: const Key('config_edit_profile_tile'),
                  leading: const Icon(Icons.person_outline_rounded),
                  title: const Text(
                    'Editar perfil',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Nombre, correo y foto'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const EditProfilePage(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow.withValues(
                    alpha: 0.75,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: ListTile(
                  key: const Key('config_logout_tile'),
                  leading: const Icon(Icons.logout_rounded),
                  title: const Text(
                    'Cerrar sesion',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Volver al inicio de sesion'),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onTap: () async {
                    try {
                      await FirebaseAuth.instance.signOut();
                    } catch (_) {
                      // Firebase may not be initialized in widget tests.
                    }
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
