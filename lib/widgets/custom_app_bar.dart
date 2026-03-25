import 'package:flutter/material.dart';
import 'package:tapp/pages/config_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool logoCentered;
  final bool showConfigButton;
  final bool isOverlay;

  const CustomAppBar({
    super.key,
    this.title,
    this.showBackButton = false,
    this.logoCentered = false,
    this.showConfigButton = true,
    this.isOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foregroundColor = isOverlay ? Colors.white : colorScheme.onSurface;

    final appBar = AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: IconThemeData(color: foregroundColor),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios),
              onPressed: () => Navigator.pop(context),
            )
          : (!logoCentered
                ? _buildLogo(useLightAsset: isOverlay || isDark)
                : null),
      title: logoCentered
          ? _buildLogo(useLightAsset: isOverlay || isDark)
          : Text(title ?? ''),
      centerTitle: true,
      titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: foregroundColor,
        fontWeight: FontWeight.w700,
      ),
      actions: [
        Opacity(
          opacity: showConfigButton ? 1.0 : 0.0,
          child: IconButton(
            icon: const Icon(Icons.tune),
            onPressed: showConfigButton
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConfigPage(),
                      ),
                    );
                  }
                : null,
          ),
        ),
      ],
    );

    if (isOverlay) {
      return appBar;
    }

    return Padding(padding: const EdgeInsets.all(8), child: appBar);
  }

  Widget _buildLogo({required bool useLightAsset}) {
    return Center(
      child: SizedBox(
        height: 30,
        width: 30,
        child: Image.asset(
          useLightAsset
              ? 'assets/images/LogoShortWhite.png'
              : 'assets/images/LogoShortBlack.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(kToolbarHeight + (isOverlay ? 0 : 16));
  }
}
