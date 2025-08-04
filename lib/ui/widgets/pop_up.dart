// campaign_dialog.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edonation/firebase/charity/charity_svc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CampaignDialog extends StatefulWidget {
  final String charityId;
  final String charityName;
  final Map<String, dynamic>? campaign;

  const CampaignDialog({
    super.key,
    required this.charityId,
    required this.charityName,
    this.campaign,
  });

  @override
  State<CampaignDialog> createState() => _CampaignDialogState();
}

class _CampaignDialogState extends State<CampaignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _charitySvc = CharitySvc();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _targetController;
  File? _pickedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.campaign?['name']);
    _descriptionController =
        TextEditingController(text: widget.campaign?['description']);
    _targetController = TextEditingController(
      text: widget.campaign?['targetAmount']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _pickedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && (_pickedImage != null || widget.campaign != null)) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.campaign == null) {
          // Create new campaign
          await _charitySvc.createCampaign(
            charityId: widget.charityId,
            charityName: widget.charityName,
            name: _nameController.text,
            description: _descriptionController.text,
            targetAmount: double.parse(_targetController.text),
            campaignImage: _pickedImage!,
          );
        } else {
          // Update existing campaign
          await _charitySvc.updateCampaign(
            campaignId: widget.campaign!['id'],
            name: _nameController.text,
            description: _descriptionController.text,
            targetAmount: double.parse(_targetController.text),
            campaignImage: _pickedImage,
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.campaign == null
                    ? 'Campaign created successfully!'
                    : 'Campaign updated successfully!',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error submitting campaign: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to ${widget.campaign == null ? 'create' : 'update'} campaign.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        widget.campaign == null ? 'Create New Campaign' : 'Edit Campaign',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Campaign Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.campaign),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.description),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetController,
                decoration: InputDecoration(
                  labelText: 'Target Amount',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value == null || double.tryParse(value) == null
                    ? 'Please enter a valid amount'
                    : null,
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _pickedImage == null && widget.campaign?['imageURL'] == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            size: 40,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          const Text('No image selected'),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _pickedImage != null
                            ? Image.file(_pickedImage!, fit: BoxFit.cover)
                            : Image.network(
                                widget.campaign!['imageURL'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error),
                              ),
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Image'),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          child: Text(widget.campaign == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}