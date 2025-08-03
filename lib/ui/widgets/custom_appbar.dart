// ignore_for_file: library_private_types_in_public_api

import 'package:edonation/core/theme/cons.dart';
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool disabled;
  final VoidCallback? leadingPress;
  const CustomAppBar({super.key, this.disabled = false, this.leadingPress})
    : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize; // default is 56.0

  @override
  Widget build(BuildContext context) {
    return AppBar(
      iconTheme: const IconThemeData(color: ColCons.defaultColor),
      leading: IconButton(
        onPressed: disabled ? () {} : leadingPress,
        icon: Icon(
          Icons.arrow_back_ios_new,
          color:
              disabled
                  ? const Color.fromARGB(192, 231, 234, 235)
                  : ColCons.defaultColor,
        ),
      ),
    );
  }
}
