import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:tapp/providers/user_profile_provider.dart';
import 'package:tapp/repositories/user_repository.dart';
import 'package:tapp/widgets/custom_app_bar.dart';
import 'package:tapp/widgets/platform_profile_image.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedPhoto;
  bool _isSaving = false;
  bool _isTakingPhoto = false;

  @override
  void initState() {
    super.initState();
    final user = _currentUser;
    _displayNameController = TextEditingController(
      text: (user?.displayName ?? '').trim(),
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

  UserRepository get _userRepository => context.read<UserRepository>();

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (pickedFile == null || !mounted) {
        return;
      }
      setState(() {
        _selectedPhoto = pickedFile;
      });
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo abrir la galería.');
      }
    }
  }

  Future<void> _takePhoto() async {
    setState(() {
      _isTakingPhoto = true;
    });

    try {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          _showMessage('Permiso de cámara denegado.');
        }
        return;
      }

      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 88,
      );
      if (pickedFile == null) {
        return;
      }

      final storedPath = await _userRepository.saveCapturedPhotoToSystemGallery(
        pickedFile,
      );
      if (storedPath == null || !mounted) {
        if (mounted) {
          _showMessage('No se pudo guardar la foto en tu galería.');
        }
        return;
      }

      setState(() {
        _selectedPhoto = pickedFile;
      });
      _showMessage(
        'Foto guardada en tu galería. Ya puedes verla desde seleccionar desde galería.',
      );
    } catch (_) {
      if (mounted) {
        _showMessage('No se pudo tomar la foto.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPhoto = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = _currentUser;
    if (user == null) {
      _showMessage('No hay una sesión activa.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<UserProfileProvider>().saveProfile(
        user: user,
        displayName: _displayNameController.text.trim(),
        localPhoto: _selectedPhoto,
      );

      if (mounted) {
        setState(() {
          _selectedPhoto = null;
        });
        _showMessage('Perfil actualizado.');
      }
    } catch (error) {
      if (mounted) {
        final providerError = context.read<UserProfileProvider>().errorMessage;
        final resolvedMessage = (providerError ?? error.toString()).trim();
        _showMessage(
          resolvedMessage.isEmpty
              ? 'No se pudo actualizar el perfil.'
              : 'No se pudo actualizar el perfil: $resolvedMessage',
        );
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final profile = context.watch<UserProfileProvider>().profile;
    final photoUrl =
        _selectedPhoto?.path ?? profile?.photoUrl ?? _currentUser?.photoURL;

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
            colors: <Color>[
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.38),
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
            children: <Widget>[
              Text(
                'Editar perfil',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Center(child: _EditableProfileAvatar(photoUrl: photoUrl)),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextButton.icon(
                      key: const Key('config_pick_profile_photo_button'),
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Seleccionar desde galería'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton.icon(
                      key: const Key('config_take_profile_photo_button'),
                      onPressed: _isTakingPhoto ? null : _takePhoto,
                      icon: _isTakingPhoto
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_camera_outlined),
                      label: Text(
                        _isTakingPhoto ? 'Abriendo...' : 'Tomar foto',
                      ),
                    ),
                  ),
                ],
              ),
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
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nombre visible',
                  prefixIcon: Icon(Icons.person_outline_rounded),
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

  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final imageUrl = (photoUrl ?? '').trim();

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
      child: imageUrl.isEmpty
          ? _LogoAvatar(isDarkMode: isDarkMode)
          : PlatformProfileImage(
              photoUrl: imageUrl,
              fit: BoxFit.cover,
              fallback: _LogoAvatar(isDarkMode: isDarkMode),
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
      widget.onMessage('No hay una sesión activa.');
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
        children: <Widget>[
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
      actions: <Widget>[
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
