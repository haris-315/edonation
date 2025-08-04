import 'dart:io';

import 'package:edonation/firebase/charity/charity_svc.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CharityMainScreen extends StatefulWidget {
  final String charityId;
  final String charityName;

  const CharityMainScreen({
    super.key,
    required this.charityId,
    required this.charityName,
  });

  @override
  State<CharityMainScreen> createState() => _CharityMainScreenState();
}

class _CharityMainScreenState extends State<CharityMainScreen> {
  final CharitySvc _charitySvc = CharitySvc();

  Future<void> _deleteCampaign(String campaignId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text(
            'Are you sure you want to delete this campaign? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _charitySvc.deleteCampaign(campaignId: campaignId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete campaign: $e')),
          );
        }
      }
    }
  }

  Future<void> _showCreateCampaignDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final targetController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    File? pickedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create New Campaign'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Campaign Name',
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter a name'
                                    : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter a description'
                                    : null,
                      ),
                      TextFormField(
                        controller: targetController,
                        decoration: const InputDecoration(
                          labelText: 'Target Amount',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                value == null || double.tryParse(value) == null
                                    ? 'Please enter a valid amount'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      pickedImage == null
                          ? const Text('No image selected.')
                          : Image.file(pickedImage!, height: 100),
                      ElevatedButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              pickedImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: const Text('Select Campaign Image'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate() &&
                        pickedImage != null) {
                      try {
                        await _charitySvc.createCampaign(
                          charityId: widget.charityId,
                          charityName: widget.charityName,
                          name: nameController.text,
                          description: descriptionController.text,
                          targetAmount: double.parse(targetController.text),
                          campaignImage: pickedImage!,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Campaign created and sent for approval!',
                              ),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to create campaign: $e'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditCampaignDialog(Map<String, dynamic> campaign) async {
    final nameController = TextEditingController(text: campaign['name']);
    final descriptionController = TextEditingController(
      text: campaign['description'],
    );
    final targetController = TextEditingController(
      text: campaign['targetAmount'].toString(),
    );
    final formKey = GlobalKey<FormState>();
    File? pickedImage;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Campaign'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Campaign Name',
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter a name'
                                    : null,
                      ),
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 3,
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? 'Please enter a description'
                                    : null,
                      ),
                      TextFormField(
                        controller: targetController,
                        decoration: const InputDecoration(
                          labelText: 'Target Amount',
                        ),
                        keyboardType: TextInputType.number,
                        validator:
                            (value) =>
                                value == null || double.tryParse(value) == null
                                    ? 'Please enter a valid amount'
                                    : null,
                      ),
                      const SizedBox(height: 16),
                      pickedImage == null
                          ? (campaign['imageUrl'] != null
                              ? Image.network(campaign['imageUrl'], height: 100)
                              : const Text('No image selected.'))
                          : Image.file(pickedImage!, height: 100),
                      ElevatedButton(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (pickedFile != null) {
                            setState(() {
                              pickedImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: const Text('Change Image'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        await _charitySvc.updateCampaign(
                          campaignId: campaign['campaignId'],
                          name: nameController.text,
                          description: descriptionController.text,
                          targetAmount: double.parse(targetController.text),
                          campaignImage: pickedImage,
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Campaign updated successfully!'),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update campaign: $e'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.charityName}\'s Campaigns')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Campaigns',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Container(
              height: 1,
              color: Colors.grey,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
            ),
            const SizedBox(height: 16.0),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _charitySvc.getCharityCampaignsStream(
                  charityId: widget.charityId,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final campaigns = snapshot.data ?? [];
                  if (campaigns.isEmpty) {
                    return const Center(
                      child: Text('No campaigns found. Tap + to create one.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: campaigns.length,
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: ListTile(
                          leading:
                              campaign['imageUrl'] != null
                                  ? Image.network(
                                    campaign['imageUrl'],
                                    width: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.broken_image),
                                  )
                                  : const Icon(Icons.image, size: 50),
                          title: Text(campaign['name'] ?? 'No Title'),
                          subtitle: Text(
                            'Target: \$${campaign['targetAmount'] ?? 0}\nStatus: ${campaign['isApproved'] ? 'Approved' : 'Pending'}',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed:
                                    () => _showEditCampaignDialog(campaign),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    () =>
                                        _deleteCampaign(campaign['campaignId']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateCampaignDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
