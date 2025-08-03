import 'package:edonation/core/funcs/push_func.dart';
import 'package:edonation/core/theme/cons.dart';
import 'package:edonation/ui/pages/auth/login_screen.dart';
import 'package:edonation/ui/pages/auth/signup_screen.dart';
import 'package:edonation/ui/widgets/custom_buttons.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/splash.jpg"),
            fit: BoxFit.cover,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Text(
                  "Chairty Managment System",
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: ColCons.defaultColor,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              const Spacer(),
              // Image.asset(AppImages.appLogo,height: 300.h,width: 300.w,),
              //     const Spacer(),
              CustomButtons.defaultButton(
                textColor: Colors.white,
                text: "Sign up",
                btnColor: ColCons.defaultColor,
                func: () {
                  Navigator.push(context, mprChange(SignupScreen()));
                },
                context: context,
              ),
              SizedBox(height: h * 0.015),
              CustomButtons.defaultButton(
                textColor: Colors.black87,
                text: "Log in",
                btnColor: Colors.grey.shade400.withValues(alpha: .8),
                func: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => const LoginScreen()),
                  );
                },
                context: context,
              ),
              SizedBox(height: h * 0.015),
            ],
          ),
        ),
      ),
    );
  }
}