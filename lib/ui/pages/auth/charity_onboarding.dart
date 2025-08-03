
// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:edonation/core/theme/cons.dart';
import 'package:edonation/firebase/auth/auth_svc.dart';
import 'package:edonation/ui/widgets/custom_buttons.dart';
import 'package:edonation/ui/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CharityIdentityVerificationScreen extends StatefulWidget {
  const CharityIdentityVerificationScreen({super.key});

  @override
  State<CharityIdentityVerificationScreen> createState() =>
      _CharityIdentityVerificationScreenState();
}

class _CharityIdentityVerificationScreenState
    extends State<CharityIdentityVerificationScreen> {
  int currentStep = 0;
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController charityNameController = TextEditingController();
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController cnicNumberController = TextEditingController();

  File? charityVerificationDocument;
  File? charityLogo;

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> pickImage(bool isDocument) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null && mounted) {
      setState(() {
        if (isDocument) {
          charityVerificationDocument = File(picked.path);
        } else {
          charityLogo = File(picked.path);
        }
      });
    }
  }

  void nextStep() {
    if (currentStep < 2 && !isLoading) {
      if (_validateCurrentStep()) {
        setState(() => currentStep++);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all required fields'),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (currentStep == 2 && !isLoading && _validateCurrentStep()) {
      _submitCharityData();
    }
  }

  void previousStep() {
    if (currentStep > 0 && !isLoading) {
      setState(() => currentStep--);
    }
  }

  Future<void> _submitCharityData() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) throw Exception('User ID not found');

      await _firebaseService.saveCharityIdentity(
        userId: userId,
        charityName: charityNameController.text,
        ownerName: ownerNameController.text,
        contactNumber: contactNumberController.text,
        cnicNumber: cnicNumberController.text,
        verificationDocument: charityVerificationDocument,
        charityLogo: charityLogo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Charity verification submitted successfully!'),
            backgroundColor: Color(0xFF388E3C),
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Color(0xFFD32F2F),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  bool _validateCurrentStep() {
    switch (currentStep) {
      case 0:
        return _formKey.currentState?.validate() ?? false;
      case 1:
        return charityVerificationDocument != null;
      case 2:
        return charityLogo != null;
      default:
        return true;
    }
  }

  String _getButtonText() {
    if (isLoading) return "Submitting...";
    if (currentStep == 2) return "Submit Verification";
    return "Continue";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16.0),
              SizedBox(
                height: 8.0,
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          color: index < currentStep ||
                                  (index == currentStep && !isLoading)
                              ? ColCons.defaultColor
                              : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32.0),
              Expanded(child: buildStep()),
              const SizedBox(height: 24.0),
              if (currentStep > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: CustomButtons.defaultButton(
                    context: context,
                    text: "Back",
                    btnColor: isLoading
                        ? const Color(0xFFD3D3D3)
                        : const Color(0xFFF5F5F5),
                    textColor:
                        isLoading ? const Color(0xFF808080) : const Color(0xFF424242),
                    w: double.infinity,
                    func: isLoading ? () {} : previousStep,
                  ),
                ),
              CustomButtons.defaultButton(
                context: context,
                text: _getButtonText(),
                btnColor:
                    isLoading ? const Color(0xFFD3D3D3) : ColCons.defaultColor,
                textColor: isLoading ? const Color(0xFF808080) : Colors.white,
                w: double.infinity,
                func: nextStep,
              ),
              const SizedBox(height: 16.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStep() {
    switch (currentStep) {
      case 0:
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Tell us about your charity",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  "We need this information to verify your identity.",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16.0,
                    color: const Color(0xFF757575),
                  ),
                ),
                const SizedBox(height: 24.0),
                CustomTextField.defaultTextField(
                  obs: false,
                  hintText: "Charity Name",
                  controller: charityNameController,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter charity name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField.defaultTextField(
                  hintText: "Charity's Owner Full name",
                  controller: ownerNameController,
                  obs: false,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter owner's full name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField.defaultTextField(
                  obs: false,
                  hintText: "Contact number",
                  controller: contactNumberController,
                  tinptyp: TextInputType.phone,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter contact number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField.defaultTextField(
                  obs: false,
                  hintText: "CNIC number of owner",
                  controller: cnicNumberController,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter CNIC number";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: const Color(0xFFBBDEFB),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF1976D2),
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          "Use your official name used with identity for the charity",
                          style: TextStyle(
                            color: const Color(0xFF1976D2),
                            fontSize: 14.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

      case 1:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Upload Charity Verification Document by government",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                Container(
                  width: double.infinity,
                  height: 200.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE0E0E0),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: charityVerificationDocument != null
                        ? Image.file(charityVerificationDocument!, fit: BoxFit.cover)
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.camera_alt,
                                  size: 60.0,
                                  color: Color(0xFFB0BEC5),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  "Verification Document",
                                  style: TextStyle(
                                    color: const Color(0xFF757575),
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24.0),
                CustomButtons.defaultButton(
                  context: context,
                  text: charityVerificationDocument == null ? "Upload Document" : "Retake Document",
                  btnColor: isLoading
                      ? const Color(0xFFD3D3D3)
                      : ColCons.defaultColor,
                  textColor: isLoading ? const Color(0xFF808080) : Colors.white,
                  w: double.infinity,
                  func: isLoading ? () {} : () => pickImage(true),
                ),
              ],
            ),
          ),
        );

      case 2:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Upload Charity's Logo",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24.0),
                Container(
                  width: 200.0,
                  height: 200.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE0E0E0),
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFE0E0E0),
                        blurRadius: 10.0,
                        spreadRadius: 2.0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: charityLogo != null
                        ? Image.file(charityLogo!, fit: BoxFit.cover)
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.image,
                                  size: 60.0,
                                  color: Color(0xFFB0BEC5),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  "Charity Logo",
                                  style: TextStyle(
                                    color: const Color(0xFF757575),
                                    fontSize: 14.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24.0),
                CustomButtons.defaultButton(
                  context: context,
                  text: charityLogo == null ? "Upload Logo" : "Retake Logo",
                  btnColor: isLoading
                      ? const Color(0xFFD3D3D3)
                      : ColCons.defaultColor,
                  textColor: isLoading ? const Color(0xFF808080) : Colors.white,
                  w: double.infinity,
                  func: isLoading ? () {} : () => pickImage(false),
                ),
              ],
            ),
          ),
        );

      default:
        return const SizedBox();
    }
  }

  @override
  void dispose() {
    charityNameController.dispose();
    ownerNameController.dispose();
    contactNumberController.dispose();
    cnicNumberController.dispose();
    super.dispose();
  }
}
