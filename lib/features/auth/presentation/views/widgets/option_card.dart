import 'package:flutter/material.dart';

class OptionCard extends StatelessWidget {
  final int index;
  final int selectedOption;
  final String optionText;
  final ValueChanged<int> onOptionSelected;

  const OptionCard({
    super.key,
    required this.index,
    required this.selectedOption,
    required this.optionText,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Card(
        color: selectedOption == index ? Colors.green : Colors.grey,
        elevation: 10,
        child: ListTile(
          onTap: () => onOptionSelected(index),
          title: Text(
            optionText,
            style: TextStyle(
              fontSize: 20,
              color: selectedOption == index ? Colors.white : Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          trailing: selectedOption == index
              ? const Icon(Icons.check_box)
              : const Icon(Icons.check_box_outline_blank),
        ),
      ),
    );
  }
}
