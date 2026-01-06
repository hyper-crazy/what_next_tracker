import 'package:flutter/material.dart';

class PasswordChecklist extends StatelessWidget {
  final String password;

  const PasswordChecklist({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    // Logic Checks
    final hasMinLength = password.length >= 10;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSymbol = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          _buildRow("At least 10 characters", hasMinLength),
          _buildRow("At least one letter (a-z)", hasLetter),
          _buildRow("At least one number (0-9)", hasNumber),
          _buildRow("At least one symbol (!@#\$...)", hasSymbol),
        ],
      ),
    );
  }

  Widget _buildRow(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.cancel_outlined,
            color: isMet ? Colors.green : Colors.grey, // Grey looks cleaner when inactive
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isMet ? Colors.green : Colors.grey,
                fontSize: 12,
                fontWeight: isMet ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}