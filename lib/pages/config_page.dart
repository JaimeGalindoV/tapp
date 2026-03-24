import 'package:flutter/material.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: true, 
        logoCentered: true,
        showConfigButton: false,
      ),
      body: const Center(child: Text('Hello World')),
    );
  }
}
