import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomButtons {
  static defaultButton(
      {required BuildContext context,
      required String text,
      required Color btnColor,
      required VoidCallback func,
      double? w,
      required Color textColor,
      double? h,
      double radius = 4}) {
    return InkWell(
      onTap: func,
      child: Container(
          decoration: BoxDecoration(
              color: btnColor, borderRadius: BorderRadius.circular(radius)),
          height: h ?? 48.h,
          width: w ?? 343.w,
          child: Center(
            child: Text(text,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: textColor,
                    )),
          )),
    );
  }
}
