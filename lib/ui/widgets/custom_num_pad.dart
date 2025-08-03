import 'package:flutter/material.dart';

class CustomNumPad extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;
  final VoidCallback? onCompleted;

  const CustomNumPad({
    super.key,
    required this.controller,
    this.maxLength = 4,
    this.onCompleted,
  });

  void _onKeyTap(BuildContext context, String key) {
    final currentText = controller.text;

    if (key == '←') {
      if (currentText.isNotEmpty) {
        controller.value = TextEditingValue(
          text: currentText.substring(0, currentText.length - 1),
          selection: TextSelection.collapsed(
            offset: currentText.length - 1,
          ),
        );
      }
    } else {
      if (currentText.length < maxLength) {
        final newText = currentText + key;
        controller.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
        if (newText.length == maxLength) {
          onCompleted?.call();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '←'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: row.map((key) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: key.isEmpty
                    ? const SizedBox.shrink()
                    : Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onKeyTap(context, key),
                          borderRadius: BorderRadius.circular(8),
                          splashColor: Colors.grey.withValues(alpha: 0.5),
                          highlightColor: Colors.transparent,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Center(
                              child: Text(
                                key,
                                style: const TextStyle(
                                    fontSize: 28,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}
