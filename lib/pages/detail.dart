import 'package:flutter/material.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.contentId});

  final String contentId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(showBackButton: true, logoCentered: true),
      body: const Center(
        child: Text(
          'Página de información de película o serie',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
