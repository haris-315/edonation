import 'package:edonation/core/theme/cons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
class CustomBtn extends StatelessWidget {
  const CustomBtn({super.key, required this.func, this.h, this.w, required this.text});
final VoidCallback func;
final double? h;
final double? w;
final String text;
  @override
  Widget build(BuildContext context) {
    return   InkWell(
      onTap: func,
      child: Container(
          color: ColCons.defaultColor,
          height: h??48.h,
          width:w??343.w,
          child: Center(child: Text(text,style: Theme.of(context).textTheme.titleLarge?.copyWith(color:Colors.white)),)
      ),
    );
  }
}
