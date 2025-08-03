import 'package:edonation/core/theme/cons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class CustomTextField {
  static Widget defaultTextField({
    required bool obs,
    required String hintText,
    bool disable = false,
    TextEditingController? controller,
    TextInputType tinptyp = TextInputType.text,
    String? Function(String?)? val,
  }) {
    return TextFormField(
      controller: controller,
      validator: val,
      obscureText: obs,
      keyboardType: tinptyp,
      enabled: !disable,
      style: TextStyle(
        color: Colors.black87,
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.black87,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: TextStyle(
          color: Colors.black87,
          fontSize: 14.sp,
          fontWeight: FontWeight.w400,
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(213, 231, 234, 235)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: ColCons.defaultColor),
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color.fromARGB(213, 231, 234, 235)),
        ),
      ),
    );
  }
}
