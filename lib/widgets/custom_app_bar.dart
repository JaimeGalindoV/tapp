import 'package:flutter/material.dart';
import 'package:tapp/pages/config_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool logoCentered;
  final bool showConfigButton;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.logoCentered = false,
    this.showConfigButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AppBar(
        backgroundColor: Colors.transparent,
        // 1. lado izquierdo
        leading: showBackButton 
          ? IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context))
          : (!logoCentered ? _buildLogo() : null),
      
        // 2. centro
        title: logoCentered ? _buildLogo() : Text(title ?? ""),
        centerTitle: true,
      
        // 3. lado derecho
        actions: [
            Opacity(
              opacity: showConfigButton ? 1.0 : 0.0,
              child: IconButton(
                icon: const Icon(Icons.tune), 
                onPressed: showConfigButton ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConfigPage()),
                  );
                } : null,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    // El leading del AppBar agranda más el logo, así que lo hacemos más pequeño ahí
    
    return Center(
      child: SizedBox(
        height: 30,
        width: 30,
        child: Image.asset(
          'assets/images/LogoShortWhite.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}