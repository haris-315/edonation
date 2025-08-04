// ignore_for_file: use_build_context_synchronously

import 'package:edonation/core/funcs/push_func.dart';
import 'package:edonation/firebase/auth/auth_svc.dart' as asv;
import 'package:edonation/services.dart';
import 'package:edonation/ui/pages/auth/welcome_screen.dart';
import 'package:edonation/ui/pages/home/charity_home.dart';
import 'package:edonation/ui/pages/home/donor_home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("userId");
    final id = prefs.get("userId");
    if (id == null) {
      Navigator.pushReplacement(context, mprChange(WelcomeScreen()));
      return;
    }
    final usr = await asv.FirebaseService().getUser(id: id as String? ?? "");
    if (usr == null) {
      Navigator.pushReplacement(context, mprChange(WelcomeScreen()));
      return;
    }
    serviceLocator.registerFactory<asv.AppUser>(() => usr);
    Navigator.pushReplacement(
      context,
      mprChange(
        usr.accountType == asv.UserType.charity
            ? CharityDashboardScreen(
              charityId: usr.userId,
              charityName: usr.charity?.charityName ?? "",
            )
            : usr.accountType == asv.UserType.donor
            ? DonorMainScreen()
            : WelcomeScreen(),
      ),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((t) {
      _loadUserInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[800],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.volunteer_activism, size: 80, color: Colors.white),
            const SizedBox(height: 24),
            const Text(
              'eDonation',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Connecting generosity with need',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
