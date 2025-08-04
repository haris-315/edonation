import 'package:edonation/core/constants.dart';
import 'package:edonation/core/funcs/push_func.dart';
import 'package:edonation/core/theme/cons.dart';
import 'package:edonation/firebase/auth/auth_svc.dart';
import 'package:edonation/ui/pages/admin/admin_controll_page.dart';
import 'package:edonation/ui/pages/home/charity_home.dart';
import 'package:edonation/ui/pages/home/donor_home.dart' as dh;
import 'package:edonation/ui/widgets/custom_appbar.dart';
import 'package:edonation/ui/widgets/custom_buttons.dart';
import 'package:edonation/ui/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';

enum UserType { admin, charity, donor }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoading = false;
  UserType _selectedUserType = UserType.donor; // Default to donor

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedUserType == UserType.admin &&
          _emailController.text.trim() == Constants.superAdmin &&
          _passwordController.text.trim() == Constants.adminPassword) {
        if (mounted) {
          Navigator.pushReplacement(context, mprChange(AdminMainScreen()));
        }
        return;
      }

      final user = await _firebaseService.loginUser(
        // accountType: _selectedUserType.name,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (user != null && mounted) {
        if (_selectedUserType == UserType.charity) {
          Navigator.pushReplacement(
            context,
            mprChange(
              CharityMainScreen(
                charityId: user.userId,
                charityName: user.charity?.charityName ?? "Haris",
              ),
            ),
          );
        }
        if (_selectedUserType == UserType.donor) {
          Navigator.pushReplacement(context, mprChange(dh.DonorMainScreen()));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedUserType.name} login successful!'),
            backgroundColor: ColCons.defaultColor,
          ),
        );
        // TODO: Navigate to appropriate screen based on _selectedUserType
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid email or password'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(disabled: _isLoading),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Log in to eDonation",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: h * 0.03),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  color: ColCons.greyColor,
                ),
                child: TabBar(
                  onTap: (index) {
                    setState(() {
                      _selectedUserType = UserType.values[index];
                      _formKey.currentState?.reset();
                      _emailController.clear();
                      _passwordController.clear();
                    });
                  },
                  splashBorderRadius: BorderRadius.circular(12),
                  unselectedLabelColor: Colors.black87,
                  labelColor: Colors.black87,
                  dividerColor: Colors.transparent,
                  indicatorPadding: const EdgeInsets.all(4),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelStyle: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  tabs: const [
                    Tab(text: "Admin"),
                    Tab(text: "Charity"),
                    Tab(text: "Donor"),
                  ],
                ),
              ),
              SizedBox(height: h * 0.03),
              _buildForm(h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm(double h) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Email", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: h * 0.01),
          CustomTextField.defaultTextField(
            obs: false,
            hintText: 'Enter email address',
            controller: _emailController,
            val: (val) {
              if (val == null || val.isEmpty) {
                return "Kindly enter email address";
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                return "Please enter a valid email address";
              }
              return null;
            },
          ),
          SizedBox(height: h * 0.03),
          Text("Password", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: h * 0.01),
          CustomTextField.defaultTextField(
            obs: true,
            hintText: 'Enter password',
            controller: _passwordController,
            val: (val) {
              if (val == null || val.isEmpty) {
                return "Kindly enter password";
              }
              if (_selectedUserType == UserType.admin) {
                return null; // Admin uses Constants.adminPassword, no length check
              }
              // if (val.length != 4) {
              //   return "Password must be 4 digits";
              // }
              return null;
            },
          ),
          SizedBox(height: h * 0.03),
          Align(
            alignment: Alignment.center,
            child: CustomButtons.defaultButton(
              textColor: Colors.white,
              text: _isLoading ? 'Loading...' : 'Continue',
              btnColor: _isLoading ? Colors.grey : ColCons.defaultColor,
              func: _isLoading ? () {} : _login,
              context: context,
            ),
          ),
        ],
      ),
    );
  }
}
