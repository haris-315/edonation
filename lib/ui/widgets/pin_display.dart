import 'package:flutter/material.dart';

class PinDisplay extends StatelessWidget {
  final TextEditingController controller;
  final int length;
  final bool obscure;
  final double size;
  final Color filledColor;
  final Color emptyColor;
  final TextStyle? digitStyle;

  const PinDisplay({
    super.key,
    required this.controller,
    this.length = 4,
    this.obscure = true,
    this.size = 20.0,
    this.filledColor = Colors.black54,
    this.emptyColor = Colors.black12,
    this.digitStyle,
  });

  @override
  Widget build(BuildContext context) {
    final digits = controller.text.characters.toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final hasValue = index < digits.length;
        final value = hasValue ? digits[index] : '';

        return Container(
          width: size,
          height: size,
          margin: EdgeInsets.symmetric(horizontal: size * 0.3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: hasValue
                ? (obscure ? filledColor : Colors.transparent)
                : emptyColor,
            border: obscure
                ? null
                : Border.all(color: filledColor.withValues(alpha: 0.6)),
          ),
          alignment: Alignment.center,
          child: (!obscure && hasValue)
              ? Text(
                  value,
                  style: digitStyle ??
                      TextStyle(
                        fontSize: size * 0.8,
                        color: filledColor,
                        fontWeight: FontWeight.w500,
                      ),
                )
              : null,
        );
      }),
    );
  }
}
