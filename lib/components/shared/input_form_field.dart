import 'package:flutter/material.dart';

class InputFormField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final TextEditingController controller;

  const InputFormField({
    super.key,
    required this.labelText,
    this.hintText = '',
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final kPrimaryColor = Theme.of(context).primaryColor;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          contentPadding:
              const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          hintText: labelText,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkTheme
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.black.withValues(alpha: 0.6),
          ),
          // Border when the TextField is enabled but not focused
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: kPrimaryColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          // Border when the TextField is focused
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: kPrimaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          // Border when there is an error
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.red, // Error color
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          // Border when the TextField is focused and there is an error
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(
              color: Colors.red,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          // Default border
          border: OutlineInputBorder(
            borderSide: BorderSide(
              color: kPrimaryColor.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        style: const TextStyle(fontSize: 14.0),
      ),
    );
  }
}
