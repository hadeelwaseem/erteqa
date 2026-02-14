import 'package:flutter/material.dart';

//first Step of How the Components should be and the level of abstraction
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? backgroundColor;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
