import 'package:flutter/material.dart';
import 'package:tapp/pages/detail.dart';
import 'package:tapp/widgets/custom_app_bar.dart';

// This is a template to test nagivation but is necessary to create the home page.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "Home",
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'página principal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Ir a un detalle',
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DetailPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
