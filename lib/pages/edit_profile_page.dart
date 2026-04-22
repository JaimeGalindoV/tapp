import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _photoUrlController;
  late final TextEditingController _emailController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = _currentUser;
    _displayNameController = TextEditingController(
      text: (user?.displayName ?? '').trim(),
    );
    _photoUrlController = TextEditingController(
      text: (user?.photoURL ?? '').trim(),
    );
    _emailController = TextEditingController(
      text: (user?.email ?? 'demo@tapp.app').trim(),
    );
  }

  User? get _currentUser {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _photoUrlController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = _currentUser;
    if (user == null) {
      _showMessage('No hay una sesion activa.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final displayName = _displayNameController.text.trim();
      final photoUrl = _photoUrlController.text.trim();

      await user.updateDisplayName(displayName.isEmpty ? null : displayName);
      await user.updatePhotoURL(photoUrl.isEmpty ? null : photoUrl);
      await user.reload();

      if (mounted) {
        _showMessage('Perfil actualizado.');
      }
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo actualizar el perfil.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return _ChangePasswordDialog(
          currentUser: _currentUser,
          onMessage: _showMessage,
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final photoUrl = _photoUrlController.text.trim();

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
                'Editar perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: _EditableProfileAvatar(photoUrl: photoUrl)),
              const SizedBox(height: 20),
              TextField(
                key: const Key('config_email_text'),
                controller: _emailController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('config_display_name_field'),
                controller: _displayNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre visible',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                key: const Key('config_photo_url_field'),
                controller: _photoUrlController,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (_) {
                  setState(() {});
                },
                decoration: const InputDecoration(
                  labelText: 'URL de foto',
                  prefixIcon: Icon(Icons.image_outlined),
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                key: const Key('config_change_password_button'),
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_outline_rounded),
                label: const Text('Cambiar contraseña'),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                key: const Key('config_save_profile_button'),
                onPressed: _isSaving ? null : _saveProfile,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Guardando...' : 'Guardar cambios'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({required this.photoUrl});

  final String photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const Key('edit_profile_avatar'),
      width: 92,
      height: 92,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainer,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: photoUrl.isEmpty
          ? _LogoAvatar(isDarkMode: isDarkMode)
          : Image.network(
              photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return _LogoAvatar(isDarkMode: isDarkMode);
              },
            ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog({
    required this.currentUser,
    required this.onMessage,
  });

  final User? currentUser;
  final ValueChanged<String> onMessage;

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();
  bool _isChangingPassword = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitPasswordChange() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final repeatPassword = _repeatPasswordController.text.trim();

    if (currentPassword.isEmpty) {
      widget.onMessage('Escribe tu contraseña actual.');
      return;
    }

    if (newPassword.isEmpty) {
      widget.onMessage('Escribe una nueva contraseña.');
      return;
    }

    if (newPassword.length < 6) {
      widget.onMessage('La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }

    if (repeatPassword.isEmpty) {
      widget.onMessage('Repite la nueva contraseña.');
      return;
    }

    if (newPassword != repeatPassword) {
      widget.onMessage('Las contraseñas no coinciden.');
      return;
    }

    final user = widget.currentUser;
    if (user == null) {
      widget.onMessage('No hay una sesion activa.');
      return;
    }

    final email = (user.email ?? '').trim();
    final hasPasswordProvider = user.providerData.any((provider) {
      return provider.providerId == 'password';
    });

    if (email.isEmpty || !hasPasswordProvider) {
      widget.onMessage(
        'El cambio de contraseña solo aplica para cuentas con correo y contraseña.',
      );
      return;
    }

    setState(() {
      _isChangingPassword = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onMessage('Contraseña actualizada.');
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      if (error.code == 'wrong-password' ||
          error.code == 'invalid-credential') {
        widget.onMessage('La contraseña actual no es correcta.');
      } else {
        widget.onMessage('No se pudo actualizar la contraseña.');
      }

      setState(() {
        _isChangingPassword = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      widget.onMessage('No se pudo actualizar la contraseña.');
      setState(() {
        _isChangingPassword = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar contraseña'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('change_password_current_field'),
            controller: _currentPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Contraseña actual',
              prefixIcon: Icon(Icons.lock_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('change_password_new_field'),
            controller: _newPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña',
              prefixIcon: Icon(Icons.lock_reset_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            key: const Key('change_password_repeat_field'),
            controller: _repeatPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nueva contraseña repetida',
              prefixIcon: Icon(Icons.lock_reset_rounded),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isChangingPassword
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          key: const Key('change_password_submit_button'),
          onPressed: _isChangingPassword ? null : _submitPasswordChange,
          child: Text(_isChangingPassword ? 'Cambiando...' : 'Cambiar'),
        ),
      ],
    );
  }
}

class _LogoAvatar extends StatelessWidget {
  const _LogoAvatar({required this.isDarkMode});

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Image.asset(
        isDarkMode
            ? 'assets/images/LogoShortWhite.png'
            : 'assets/images/LogoShortBlack.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
