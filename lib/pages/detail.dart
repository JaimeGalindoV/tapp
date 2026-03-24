import 'package:flutter/material.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        showBackButton: true, 
        logoCentered: true,
      ),
      body: const Center(child: Text('Página de información de una publicación', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),)),
    );
  }
}
