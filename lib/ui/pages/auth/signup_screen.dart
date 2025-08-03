import 'package:edonation/core/funcs/push_func.dart';
import 'package:edonation/core/theme/cons.dart';
import 'package:edonation/firebase/auth/auth_svc.dart';
import 'package:edonation/ui/pages/auth/charity_onboarding.dart';
import 'package:edonation/ui/pages/auth/login_screen.dart';
import 'package:edonation/ui/pages/auth/onboarding_donor.dart';
import 'package:edonation/ui/widgets/custom_appbar.dart';
import 'package:edonation/ui/widgets/custom_buttons.dart';
import 'package:edonation/ui/widgets/custom_num_pad.dart';
import 'package:edonation/ui/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum UserType { donor, charity }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final PageController _controller = PageController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();

  late final VoidCallback _pinListener;
  late final VoidCallback _passwordListener;
  late final VoidCallback _confirmPasswordListener;

  int _currentStep = 0;
  String _pin = '';
  String _password = '';
  String _confirmPassword = '';
  String _accountType = UserType.donor.name;
  bool _isLoading = false;
  String? _generatedOtp;

  void _setAccountType(String type) {
    setState(() {
      _accountType = type;
    });
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return _pin == _generatedOtp;
      case 2:
        return _password.length == 4 &&
            _confirmPassword.length == 4 &&
            _password == _confirmPassword;
      default:
        return true;
    }
  }

  Future<void> _sendOtp() async {
    if (_isLoading || !_validateCurrentStep()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _generatedOtp = await _firebaseService.sendOtpEmail(
        _emailController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email!'),
            backgroundColor: ColCons.defaultColor,
          ),
        );
        setState(() {
          _isLoading = false;
          _currentStep = 1;
        });
        _controller.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitSignupData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await _firebaseService.signupUser(
        accountType: _accountType,
        email: _emailController.text,
        phone: _phoneController.text,
        password: _password,
      );

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('userId', userId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save user ID: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signup successful!'),
            backgroundColor: ColCons.defaultColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          mprChange(
            _accountType == UserType.donor.name
                ? IdentityVerificationScreen()
                : const CharityIdentityVerificationScreen(),
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
  void initState() {
    super.initState();
    _pinListener = () {
      setState(() {
        _pin = _pinController.text;
      });
      if (_pinController.text.length == 4) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) _nextStep();
        });
      }
    };

    _passwordListener = () {
      setState(() {
        _password = _passwordController.text;
      });
    };

    _confirmPasswordListener = () {
      setState(() {
        _confirmPassword = _confirmPasswordController.text;
      });
      // if (_confirmPasswordController.text.length == 4 &&
      //     _passwordController.text.length == 4 &&
      //     _passwordController.text == _confirmPasswordController.text) {
      //   Future.delayed(const Duration(milliseconds: 300), () {
      //     if (mounted) _submitSignupData();
      //   });
      // }
    };

    _pinController.addListener(_pinListener);
    _passwordController.addListener(_passwordListener);
    _confirmPasswordController.addListener(_confirmPasswordListener);
  }

  @override
  void dispose() {
    _pinController.removeListener(_pinListener);
    _passwordController.removeListener(_passwordListener);
    _confirmPasswordController.removeListener(_confirmPasswordListener);
    _pinController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2 && !_isLoading) {
      if (_validateCurrentStep()) {
        setState(() => _currentStep++);
        _controller.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else if (_currentStep == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (!_isLoading && _validateCurrentStep()) {
      _submitSignupData();
    }
  }

  void _previousStep() {
    if (_currentStep <= 1 && _currentStep > 0 && !_isLoading) {
      setState(() => _currentStep--);
      _controller.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        disabled: _currentStep > 1 || _currentStep == 0 || _isLoading,
        leadingPress: _previousStep,
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressIndicator(),
            const SizedBox(height: 10),
            Expanded(child: _buildPageView()),
            if (_currentStep == 0)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: CustomButtons.defaultButton(
                  context: context,
                  text: _isLoading ? 'Loading...' : 'Continue',
                  btnColor: _isLoading ? Colors.grey : ColCons.defaultColor,
                  textColor: Colors.white,
                  w: double.infinity,
                  func: _isLoading ? () {} : _sendOtp,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (index) {
          final hasDone = index < _currentStep;
          final isActive = index == _currentStep;
          if (isActive && _isLoading) {
            return Expanded(
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: Colors.grey.shade300,
                color: ColCons.defaultColor,
              ),
            );
          }
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color:
                    hasDone || isActive
                        ? ColCons.defaultColor
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPageView() {
    return PageView(
      controller: _controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildAccountDetailsForm(),
        _buildPasscodeEntry(),
        _buildPasswordCreation(),
      ],
    );
  }

  Widget _buildAccountDetailsForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _AccountTypeToggle(
              accountType: _accountType,
              onTypeChanged: _setAccountType,
            ),
            const SizedBox(height: 30),
            Align(
              alignment: Alignment.topLeft,
              child: Text(
                "Email Address",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "We will use your email to verify your account status",
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField.defaultTextField(
              obs: false,
              hintText: 'Enter email address',
              controller: _emailController,
              val: (val) {
                if (val == null || val.isEmpty) {
                  return "Kindly enter email address";
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(val)) {
                  return "Please enter a valid email address";
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomTextField.defaultTextField(
              tinptyp: TextInputType.phone,
              obs: false,
              hintText: 'Phone Number',
              controller: _phoneController,
              val: (val) {
                if (val == null || val.isEmpty) {
                  return "Kindly enter mobile number";
                }
                if (val.length < 10) {
                  return "Please enter a valid phone number";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Have an account?",
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed:
                      _isLoading
                          ? null
                          : () => Navigator.push(
                            context,
                            mprChange(const LoginScreen()),
                          ),
                  child: const Text(
                    " Log in here.",
                    style: TextStyle(color: ColCons.defaultColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasscodeEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter OTP",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            "Enter the OTP sent to your email",
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final hasValue = index < _pin.length;
              final isActive = index == _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 48,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: isActive ? ColCons.defaultColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasValue ? '•' : '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text.rich(
              TextSpan(
                text: "By entering the OTP, you agree to our ",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                children: const [
                  TextSpan(
                    text: "Terms & Conditions",
                    style: TextStyle(
                      color: ColCons.defaultColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CustomNumPad(
            controller: _pinController,
            maxLength: 4,
            onCompleted: () {},
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPasswordCreation() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Create password",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final hasValue = index < _password.length;
              final isActive =
                  index == _password.length && _confirmPassword.isEmpty;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color: isActive ? ColCons.defaultColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasValue ? '•' : '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Text(
            "Confirm password",
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) {
              final hasValue = index < _confirmPassword.length;
              final isActive =
                  index == _confirmPassword.length && _password.length == 4;
              final isError =
                  _password.length == 4 &&
                  _confirmPassword.length == 4 &&
                  _password != _confirmPassword;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  border: Border.all(
                    color:
                        isError
                            ? Colors.red
                            : isActive
                            ? ColCons.defaultColor
                            : Colors.transparent,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  hasValue ? '•' : '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
          ),
          if (_password.length == 4 &&
              _confirmPassword.length == 4 &&
              _password != _confirmPassword)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  "Passwords don't match",
                  style: TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Center(
            child: Text.rich(
              TextSpan(
                text: "By creating password, you agree to our ",
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                children: const [
                  TextSpan(
                    text: "Terms & Conditions",
                    style: TextStyle(
                      color: ColCons.defaultColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          CustomNumPad(
            controller:
                _password.length < 4
                    ? _passwordController
                    : _confirmPasswordController,
            maxLength: 4,
            onCompleted: () {
              if (_passwordController.text == _confirmPasswordController.text) {
                _submitSignupData();
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _AccountTypeToggle extends StatelessWidget {
  final String accountType;
  final ValueChanged<String> onTypeChanged;
  final tabs = [UserType.donor, UserType.charity];

  _AccountTypeToggle({required this.accountType, required this.onTypeChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children:
            tabs.map((tab) {
              final isSelected = accountType == tab.name;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTypeChanged(tab.name),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        tab.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
