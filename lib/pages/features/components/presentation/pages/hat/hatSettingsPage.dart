import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/providers/hat_provider.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

class SettingsProblemPage extends ConsumerStatefulWidget {
  final String problemId;

  const SettingsProblemPage({Key? key, required this.problemId})
      : super(key: key);

  @override
  _SettingsProblemPageState createState() => _SettingsProblemPageState();
}

class _SettingsProblemPageState extends ConsumerState<SettingsProblemPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  Future<Map<String, dynamic>>? _problemDetailsFuture;

  final ValueNotifier<bool> _isVerifiedTerms = ValueNotifier(false);
  final ValueNotifier<bool> _isSpilledHat = ValueNotifier(false);
  final ValueNotifier<bool> _isSolutionDomain = ValueNotifier(false);
  final ValueNotifier<bool> _isApplicationDomain = ValueNotifier(false);
  final ValueNotifier<bool> _isUseContext = ValueNotifier(false);
  final ValueNotifier<double> _sliderValue = ValueNotifier(5);
  final ValueNotifier<bool> _isSharedHat = ValueNotifier(false);
  final ValueNotifier<bool> _isOutsideSoftware = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _problemDetailsFuture = _fetchProblemDetails(widget.problemId);
  }

  void _refreshProblemDetails() {
    setState(() {
      _problemDetailsFuture = _fetchProblemDetails(widget.problemId);
    });
  }

  Future<Map<String, dynamic>> _fetchProblemDetails(String problemId) async {
    final docSnapshot =
        await _firestore.collection('problems').doc(problemId).get();

    if (!docSnapshot.exists) {
      showToast(
        message: "Problem not found",
        isError: true,
      );
      throw Exception("Problem not found");
    }

    final data = docSnapshot.data()!;

    // Set the initial values for switches and slider
    _isVerifiedTerms.value = data['isVerifiedTerms'] ?? false;
    _isSpilledHat.value = data['isSpilledHat'] ?? false;
    _isSolutionDomain.value = data['isSolutionDomain'] ?? false;
    _isApplicationDomain.value = data['isApplicationDomain'] ?? false;
    _isUseContext.value = data['isUseContext'] ?? false;
    _sliderValue.value = (data['sliderValue'] ?? 1).toDouble();
    _isSharedHat.value = data['isSharedHat'] ?? false;
    _isOutsideSoftware.value = data['isOutsideSoftware'] ?? false;

    return data;
  }

  Future<String> _fetchOwnerEmail(String userId) async {
    try {
      final userSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (userSnapshot.exists) {
        return userSnapshot.data()?['email'] ?? 'Unknown Email';
      } else {
        return 'Unknown Email';
      }
    } catch (e) {
      print("Error fetching owner's email: $e");
      return 'Unknown Email';
    }
  }

  Future<void> _updateProblemField(
      String problemId, String field, String newValue) async {
    try {
      await _firestore
          .collection('problems')
          .doc(problemId)
          .update({field: newValue});
      showToast(message: "Updated successfully", isError: false);
      _refreshProblemDetails();
    } catch (e) {
      print("Error updating $field: $e");
      showToast(message: "Error updating $field: $e", isError: true);
    }
  }

  Future<void> _updateProblemFieldSettings(
      String problemId, String field, dynamic newValue) async {
    try {
      await _firestore
          .collection('problems')
          .doc(problemId)
          .update({field: newValue});
      showToast(message: "Updated successfully", isError: false);
    } catch (e) {
      print("Error updating $field: $e");
      showToast(message: "Error updating $field: $e", isError: true);
    }
  }

  Future<void> _removeCollaborator(
      String problemId, String collaborator) async {
    try {
      await _firestore.collection('problems').doc(problemId).update({
        'collaborators': FieldValue.arrayRemove([collaborator]),
      });
      showToast(message: "Collaborator deleted.", isError: false);
      _refreshProblemDetails();
    } catch (e) {
      print("Error removing collaborator: $e");
      showToast(message: "Error removing collaborator: $e", isError: true);
    }
  }

  Future<void> _deleteContainer(
      String problemId, Map<String, dynamic> container) async {
    try {
      final containersSnapshot =
          await _firestore.collection('problems').doc(problemId).get();

      if (containersSnapshot.exists) {
        final containers =
            List<dynamic>.from(containersSnapshot.data()?['containers'] ?? []);
        containers
            .removeWhere((c) => c['containerId'] == container['containerId']);

        await _firestore
            .collection('problems')
            .doc(problemId)
            .update({'containers': containers});

        showToast(message: "Container deleted.", isError: false);
        _refreshProblemDetails();
      }
    } catch (e) {
      print("Error deleting container: $e");
      showToast(message: "Error deleting container: $e", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        title: Text(
          'Settings',
          style: AppStyles.headLineMedium(color: AppStyles.onBackground()),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _problemDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading problem details",
                style: AppStyles.headLineSmall(color: Colors.red),
              ),
            );
          }

          final problemData = snapshot.data!;
          final collaborators =
              List<String>.from(problemData['collaborators'] ?? []);
          final containers =
              List<dynamic>.from(problemData['containers'] ?? []);
          final isOwner = currentUser?.uid == problemData['userId'];

          _nameController.text = problemData['problemName'];
          _descriptionController.text =
              problemData['problemDescription'] ?? 'No description';

          return FutureBuilder<String>(
            future: _fetchOwnerEmail(problemData['userId']),
            builder: (context, emailSnapshot) {
              if (emailSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final ownerEmail = emailSnapshot.data ?? 'Unknown Email';

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: ElevatedButton(
                          onPressed: () async {
                            await ref
                                .read(problemProvider.notifier)
                                .promptForInviteEmail(
                                  context,
                                  widget.problemId,
                                  problemData['problemName'],
                                );
                          },
                          child: const Text("Add Collaborator"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Generate the Hat content",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 8),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isVerifiedTerms,
                        builder: (context, isGPTEnabled, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSwitch(
                                label: "Allow for any terms",
                                valueNotifier: _isOutsideSoftware,
                                firestoreField: 'isOutsideSoftware',
                                onChanged: (bool newValue) {
                                  _updateProblemFieldSettings(widget.problemId,
                                      'isVerifiedTerms', true);
                                  _updateProblemFieldSettings(
                                      widget.problemId, 'isUseContext', true);
                                  _isOutsideSoftware.value = newValue;
                                  _isVerifiedTerms.value = true;
                                  _isUseContext.value = true;
                                },
                              ),
                              _buildSwitch(
                                label: "Use GPT",
                                valueNotifier: _isVerifiedTerms,
                                firestoreField: 'isVerifiedTerms',
                                isEnabled: !_isOutsideSoftware.value,
                                onChanged: (bool newValue) {
                                  _isVerifiedTerms.value = newValue;

                                  _updateProblemFieldSettings(widget.problemId,
                                      'isVerifiedTerms', newValue);
                                  if (newValue == false) {
                                    _updateProblemFieldSettings(
                                        widget.problemId,
                                        'isApplicationDomain',
                                        false);

                                    _isApplicationDomain.value = false;
                                  }
                                },
                              ),
                              _buildSwitch(
                                label: "Include one completely random term",
                                valueNotifier: _isSpilledHat,
                                firestoreField: 'isSpilledHat',
                                isEnabled:
                                    isGPTEnabled && !_isOutsideSoftware.value,
                                onChanged: (bool newValue) {},
                              ),
                              _buildSwitch(
                                label: "Use context description",
                                valueNotifier: _isUseContext,
                                firestoreField: 'isUseContext',
                                isEnabled:
                                    isGPTEnabled && !_isOutsideSoftware.value,
                                onChanged: (bool newValue) {},
                              ),
                              _buildSwitch(
                                label: "Application Domain",
                                valueNotifier: _isApplicationDomain,
                                isEnabled: !_isOutsideSoftware.value,
                                firestoreField: 'isApplicationDomain',
                                onChanged: (bool newValue) {
                                  _updateProblemFieldSettings(widget.problemId,
                                      'isApplicationDomain', newValue);
                                  if (newValue == true) {
                                    _updateProblemFieldSettings(
                                        widget.problemId,
                                        'isApplicationDomain',
                                        true);
                                    _updateProblemFieldSettings(
                                        widget.problemId,
                                        'isVerifiedTerms',
                                        true);
                                    _updateProblemFieldSettings(
                                        widget.problemId, 'isUseContext', true);
                                    _isVerifiedTerms.value = true;
                                    _isUseContext.value = true;
                                  }
                                },
                              ),
                              _buildSwitch(
                                label: "Solution Domain",
                                valueNotifier: _isSolutionDomain,
                                isEnabled: !_isOutsideSoftware.value,
                                firestoreField: 'isSolutionDomain',
                                onChanged: (bool newValue) {
                                  _updateProblemFieldSettings(widget.problemId,
                                      'isSolutionDomain', newValue);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<double>(
                        valueListenable: _sliderValue,
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "How many terms to pick from Hat (1-10): ${value.round()}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              Slider(
                                value: value,
                                min: 1,
                                max: 10,
                                divisions: 9,
                                label: value.round().toString(),
                                onChanged: (double newValue) async {
                                  _sliderValue.value = newValue;
                                  await _updateProblemFieldSettings(
                                      widget.problemId,
                                      'sliderValue',
                                      newValue);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Share the Hat",
                        style: AppStyles.headLineSmall(
                          color: AppStyles.onBackground(),
                        ),
                      ),
                      _buildSwitch(
                        label: "Share the Hat",
                        valueNotifier: _isSharedHat,
                        firestoreField: 'isSharedHat',
                        onChanged: (bool newValue) {},
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Hat Details",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Name",
                        style: AppStyles.titleSmall(
                            color: AppStyles.onBackground()),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _isEditingName
                                ? TextField(
                                    controller: _nameController,
                                    decoration: InputDecoration(
                                      labelText: 'Hat Name',
                                      border: OutlineInputBorder(),
                                    ),
                                  )
                                : Text(
                                    "${_nameController.text}",
                                    style: AppStyles.bodyLarge(
                                        color: AppStyles.onBackground()),
                                  ),
                          ),
                          if (isOwner)
                            IconButton(
                              icon: Icon(
                                _isEditingName ? Icons.check : Icons.edit,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                if (_isEditingName) {
                                  _updateProblemField(widget.problemId,
                                      'problemName', _nameController.text);
                                }
                                setState(() {
                                  _isEditingName = !_isEditingName;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Context Description",
                        style: AppStyles.titleSmall(
                            color: AppStyles.onBackground()),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _isEditingDescription
                                ? TextField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Hat Context Description',
                                      border: OutlineInputBorder(),
                                    ),
                                  )
                                : Text(
                                    "${_descriptionController.text}",
                                    style: AppStyles.bodyLarge(
                                        color: AppStyles.onBackground()),
                                  ),
                          ),
                          if (isOwner)
                            IconButton(
                              icon: Icon(
                                _isEditingDescription
                                    ? Icons.check
                                    : Icons.edit,
                                color: Colors.blue,
                              ),
                              onPressed: () {
                                if (_isEditingDescription) {
                                  _updateProblemField(
                                      widget.problemId,
                                      'problemDescription',
                                      _descriptionController.text);
                                }
                                setState(() {
                                  _isEditingDescription =
                                      !_isEditingDescription;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Created",
                        style: AppStyles.titleSmall(
                            color: AppStyles.onBackground()),
                      ),
                      Text(
                        "${problemData['creationDateTime']}",
                        style: AppStyles.bodyLarge(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Owner:",
                        style: AppStyles.titleSmall(
                            color: AppStyles.onBackground()),
                      ),
                      Text(
                        "$ownerEmail",
                        style: AppStyles.bodyLarge(
                            color: AppStyles.onBackground()),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Collaborators:",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      ...collaborators.map((collaborator) => Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "- $collaborator",
                                style: AppStyles.bodyLarge(
                                    color: AppStyles.onBackground()),
                              ),
                              if (isOwner)
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeCollaborator(
                                      widget.problemId, collaborator),
                                ),
                            ],
                          )),
                      const SizedBox(height: 12),
                      Text(
                        "Terms:",
                        style: AppStyles.headLineSmall(
                            color: AppStyles.onBackground()),
                      ),
                      ...containers.map(
                        (container) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                "- ${container['containerName']}",
                                style: AppStyles.bodyLarge(
                                    color: AppStyles.onBackground()),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor: AppStyles.Primary50(),
                                    title: const Text("Delete Container"),
                                    content: const Text(
                                        "Are you sure you want to delete this container?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("Cancel"),
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                      ),
                                      TextButton(
                                        child: const Text("Delete"),
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  await _deleteContainer(
                                      widget.problemId, container);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditing,
    required VoidCallback onSave,
    required bool isOwner,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppStyles.titleSmall(color: AppStyles.onBackground()),
        ),
        Row(
          children: [
            Expanded(
              child: isEditing
                  ? TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        labelText: label,
                        border: OutlineInputBorder(),
                      ),
                    )
                  : Text(
                      controller.text,
                      style:
                          AppStyles.bodyLarge(color: AppStyles.onBackground()),
                    ),
            ),
            if (isOwner)
              IconButton(
                icon: Icon(
                  isEditing ? Icons.check : Icons.edit,
                  color: Colors.blue,
                ),
                onPressed: () {
                  if (isEditing) {
                    onSave();
                  }
                  setState(() {
                    isEditing = !isEditing;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSwitch({
    required String label,
    required ValueNotifier<bool> valueNotifier,
    required String firestoreField,
    required Function(bool) onChanged,
    bool isEnabled = true,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        ValueListenableBuilder<bool>(
          valueListenable: valueNotifier,
          builder: (context, value, child) {
            return CupertinoSwitch(
              value: value,
              onChanged: isEnabled
                  ? (bool newValue) async {
                      valueNotifier.value = newValue;
                      setState(() {});
                      await _updateProblemFieldSettings(
                          widget.problemId, firestoreField, newValue);
                      onChanged(newValue);
                    }
                  : null,
            );
          },
        ),
      ],
    );
  }
}
