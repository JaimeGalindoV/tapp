import 'package:flutter/material.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    required this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String hintText;
  final Widget prefixIcon;
  final String? Function(String?) validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
  }
}
