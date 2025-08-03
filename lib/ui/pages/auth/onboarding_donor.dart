// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:edonation/core/theme/cons.dart';
import 'package:edonation/firebase/auth/auth_svc.dart';
import 'package:edonation/ui/widgets/custom_buttons.dart';
import 'package:edonation/ui/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({super.key});

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen> {
  int currentStep = 0;
  bool isLoading = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController docNumberController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  String selectedDocType = "";
  File? frontImage;
  File? backImage;
  File? selfieImage;

  final FirebaseService _firebaseService = FirebaseService();

  Future<void> pickImage(bool isFront, {bool isSelfie = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null && mounted) {
      setState(() {
        if (isSelfie) {
          selfieImage = File(picked.path);
        } else if (isFront) {
          frontImage = File(picked.path);
        } else {
          backImage = File(picked.path);
        }
      });
    }
  }

  void nextStep() {
    if (currentStep < 5 && !isLoading) {
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
    } else if (currentStep == 5 && !isLoading && _validateCurrentStep()) {
      _submitIdentityData();
    }
  }

  void previousStep() {
    if (currentStep > 0 && !isLoading) {
      setState(() => currentStep--);
    }
  }

  Future<void> _submitIdentityData() async {
    if (isLoading) return;

    setState(() => isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? '';
      if (userId.isEmpty) throw Exception('User ID not found');

      await _firebaseService.saveDonorIdentity(
        userId: userId,
        firstName: firstNameController.text,
        lastName: lastNameController.text,
        docType: selectedDocType,
        docNumber: docNumberController.text,
        phone: phoneController.text,
        frontImage: frontImage,
        backImage: backImage,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Identity verification submitted successfully!'),
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
      case 3:
        return selfieImage != null;
      case 4:
        return frontImage != null;
      case 5:
        return backImage != null;
      default:
        return true;
    }
  }

  String _getButtonText() {
    if (isLoading) return "Submitting...";
    if (currentStep == 5) return "Submit Verification";
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
                    6,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        decoration: BoxDecoration(
                          color:
                              index < currentStep ||
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
                    btnColor:
                        isLoading
                            ? const Color(0xFFD3D3D3)
                            : const Color(0xFFF5F5F5),
                    textColor:
                        isLoading
                            ? const Color(0xFF808080)
                            : const Color(0xFF424242),
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
                  "Tell us about yourself",
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
                  hintText: "Legal first name",
                  controller: firstNameController,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter your first name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField.defaultTextField(
                  hintText: "Legal last name",
                  controller: lastNameController,
                  obs: false,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter your last name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                DropdownButtonFormField<String>(
                  value: selectedDocType.isEmpty ? null : selectedDocType,
                  hint: const Text("Select Verification Document"),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                      borderSide: const BorderSide(
                        color: Color(0xFF1E90FF),
                        width: 2.0,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 14.0,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                  ),
                  dropdownColor: const Color(0xFFF5F5F5),
                  style: const TextStyle(
                    color: Color(0xFF212121),
                    fontSize: 16.0,
                  ),
                  iconEnabledColor: const Color(0xFF1E90FF),
                  items:
                      ["CNIC", "CMS-ID"]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged:
                      isLoading
                          ? null
                          : (val) => setState(() => selectedDocType = val!),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return "Please select a document type";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField.defaultTextField(
                  obs: false,
                  hintText:
                      selectedDocType == "CMS-ID"
                          ? "2019-XXXXX"
                          : "XXXXX-XXXXXXX-X",
                  controller: docNumberController,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter document number";
                    }
                    if (selectedDocType == "CNIC" &&
                        !RegExp(r'^\d{5}-\d{7}-\d$').hasMatch(txt)) {
                      return "Please enter a valid CNIC (XXXXX-XXXXXXX-X)";
                    }
                    if (selectedDocType == "CMS-ID" &&
                        !RegExp(r'^\d{4}-\d{5}$').hasMatch(txt)) {
                      return "Please enter a valid CMS-ID (YYYY-XXXXX)";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                CustomTextField.defaultTextField(
                  obs: false,
                  hintText: "03XXXXXXXXX",
                  controller: phoneController,
                  tinptyp: TextInputType.phone,
                  val: (txt) {
                    if (txt == null || txt.isEmpty) {
                      return "Please enter phone number";
                    }
                    if (!RegExp(r'^03\d{9}$').hasMatch(txt)) {
                      return "Please enter a valid phone number (03XXXXXXXXX)";
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
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF1976D2),
                        size: 20.0,
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Text(
                          "Use your official name as it appears on your national ID card",
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
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Review Details",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                "Please review the details provided",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16.0,
                  color: const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 24.0),
              _buildReviewField("First Name", firstNameController.text),
              const SizedBox(height: 16.0),
              _buildReviewField("Last Name", lastNameController.text),
              const SizedBox(height: 16.0),
              _buildReviewField("Document Type", selectedDocType),
              const SizedBox(height: 16.0),
              _buildReviewField("Document Number", docNumberController.text),
              const SizedBox(height: 16.0),
              _buildReviewField("Phone Number", phoneController.text),
              const SizedBox(height: 24.0),
            ],
          ),
        );

      case 2:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Verify your identity with a quick photo",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32.0),
              Icon(Icons.face, size: 120.0, color: ColCons.defaultColor),
              const SizedBox(height: 32.0),
              Text(
                "This won't be your profile picture",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16.0,
                  color: const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              Text(
                "Your photo is secure and used for verification only",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14.0,
                  color: const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );

      case 3:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Face Verification",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 28.0,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 32.0),
              Container(
                width: 200.0,
                height: 200.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ColCons.defaultColor, width: 3.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE0E0E0),
                      blurRadius: 10.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
                child:
                    selfieImage == null
                        ? const Icon(
                          Icons.camera_alt,
                          size: 60.0,
                          color: Color(0xFFB0BEC5),
                        )
                        : ClipOval(
                          child: Image.file(selfieImage!, fit: BoxFit.cover),
                        ),
              ),
              const SizedBox(height: 32.0),
              CustomButtons.defaultButton(
                context: context,
                text: selfieImage == null ? "Take Selfie" : "Retake Selfie",
                btnColor:
                    isLoading ? const Color(0xFFD3D3D3) : ColCons.defaultColor,
                textColor: isLoading ? const Color(0xFF808080) : Colors.white,
                w: 200.0,
                func:
                    isLoading ? () {} : () => pickImage(false, isSelfie: true),
              ),
            ],
          ),
        );

      case 4:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Take a picture of your ${selectedDocType.isNotEmpty ? selectedDocType : 'Document'}",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Position all 4 corners of the document clearly in the frame.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14.0,
                    color: const Color(0xFF757575),
                  ),
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
                    child:
                        frontImage != null
                            ? Image.file(frontImage!, fit: BoxFit.cover)
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 60.0,
                                    color: const Color(0xFFB0BEC5),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    "Front Side",
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
                  text: frontImage == null ? "Capture Front" : "Retake Front",
                  btnColor:
                      isLoading
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

      case 5:
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Take a picture of back side",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 28.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF212121),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8.0),
                Text(
                  "Position all 4 corners of the document clearly in the frame.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14.0,
                    color: const Color(0xFF757575),
                  ),
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
                    child:
                        backImage != null
                            ? Image.file(backImage!, fit: BoxFit.cover)
                            : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    size: 60.0,
                                    color: const Color(0xFFB0BEC5),
                                  ),
                                  const SizedBox(height: 8.0),
                                  Text(
                                    "Back Side",
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
                  text: backImage == null ? "Capture Back" : "Retake Back",
                  btnColor:
                      isLoading
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

  Widget _buildReviewField(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12.0),
        color: const Color(0xFFF5F5F5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE0E0E0),
            blurRadius: 6.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14.0,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value.isEmpty ? "Not provided" : value,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
        ],
      ),
    );
  }
 
  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    docNumberController.dispose();
    phoneController.dispose();
    super.dispose();
  }
}
