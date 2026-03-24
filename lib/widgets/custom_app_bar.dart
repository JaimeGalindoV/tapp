import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool logoCentered;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.logoCentered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        // 1. Manejo del lado IZQUIERDO
        leading: showBackButton 
          ? IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context))
          : (!logoCentered ? _buildLogo() : null),
      
        // 2. Manejo del CENTRO
        title: logoCentered ? _buildLogo() : Text(title ?? ""),
        centerTitle: true,
      
        // 3. Manejo del lado DERECHO (Siempre igual)
        actions: [
          IconButton(
            icon: const Icon(Icons.tune), // El icono de settings de tu imagen
            onPressed: () => print("Settings tap"),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.all(8.0),
      child: Image.asset(
            'assets/images/LogoShortWhite.png',
          ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}