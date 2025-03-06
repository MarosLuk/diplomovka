import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';

import '../../../app/global/toast.dart';
import 'inspirationFoundedPage.dart';

class InspirationPage extends ConsumerStatefulWidget {
  const InspirationPage({Key? key}) : super(key: key);

  @override
  _InspirationPageState createState() => _InspirationPageState();
}

class _InspirationPageState extends ConsumerState<InspirationPage> {
  final TextEditingController _searchController = TextEditingController();

  String _selectedGPTFilter = "none";
  String _spilledHatFilter = "all";
  String _solutionDomainFilter = "all";
  String _useContextFilter = "all";

  final List<Map<String, dynamic>> _problems = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 50) {
        _fetchProblems(loadMore: true);
      }
    });

    _searchController.addListener(_onSearchChanged);

    _fetchProblems(loadMore: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    if (text.length >= 2 || text.isEmpty) {
      _resetAndFetch();
    }
  }

  void _resetAndFetch() {
    _lastDoc = null;
    _hasMore = true;
    _problems.clear();
    setState(() {});
    _fetchProblems(loadMore: false);
  }

  Future<void> _fetchProblems({required bool loadMore}) async {
    if (_isLoading || (!_hasMore && loadMore)) return;
    setState(() => _isLoading = true);

    Query query = FirebaseFirestore.instance
        .collection('problems')
        .where('isSharedHat', isEqualTo: true);

    final text = _searchController.text.trim();
    if (text.length >= 2) {
      query = query
          .where('problemName', isGreaterThanOrEqualTo: text)
          .where('problemName', isLessThanOrEqualTo: text + '\uf8ff');
    }

    if (_selectedGPTFilter == "gpt") {
      query = query.where('isVerifiedTerms', isEqualTo: true);
    } else if (_selectedGPTFilter == "verified") {
      query = query.where('isVerifiedTerms', isEqualTo: false);
    }

    if (_spilledHatFilter == "true") {
      query = query.where('isSpilledHat', isEqualTo: true);
    } else if (_spilledHatFilter == "false") {
      query = query.where('isSpilledHat', isEqualTo: false);
    }

    if (_solutionDomainFilter == "true") {
      query = query.where('isSolutionDomain', isEqualTo: true);
    } else if (_solutionDomainFilter == "false") {
      query = query.where('isSolutionDomain', isEqualTo: false);
    }

    if (_useContextFilter == "true") {
      query = query.where('isUseContext', isEqualTo: true);
    } else if (_useContextFilter == "false") {
      query = query.where('isUseContext', isEqualTo: false);
    }

    query = query.orderBy('creationDateTime', descending: true).limit(10);

    if (loadMore && _lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    try {
      final snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        final newProblems = snapshot.docs
            .map((doc) => {
                  ...doc.data() as Map<String, dynamic>,
                  'docId': doc.id,
                })
            .toList();
        setState(() {
          _problems.addAll(newProblems);
        });
      } else {
        setState(() {
          if (!loadMore) _problems.clear();
          _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching Hats: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onGPTFilterChanged(String newFilter) {
    if (_selectedGPTFilter == newFilter) return;
    setState(() => _selectedGPTFilter = newFilter);
    _resetAndFetch();
  }

  void _onSpilledHatFilterChanged(String newValue) {
    if (_spilledHatFilter == newValue) return;
    setState(() => _spilledHatFilter = newValue);
    _resetAndFetch();
  }

  void _onSolutionDomainFilterChanged(String newValue) {
    if (_solutionDomainFilter == newValue) return;
    setState(() => _solutionDomainFilter = newValue);
    _resetAndFetch();
  }

  void _onUseContextFilterChanged(String newValue) {
    if (_useContextFilter == newValue) return;
    setState(() => _useContextFilter = newValue);
    _resetAndFetch();
  }

  Future<void> _copyProblem(Map<String, dynamic> problem) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      debugPrint("User not logged in!");
      return;
    }

    try {
      final newProblem = {
        'problemName': problem['problemName'],
        'problemDescription': problem['problemDescription'],
        'creationDateTime': FieldValue.serverTimestamp(),
        'containers': problem['containers'],
        'messagesProblem': [],
        'isSpilledHat': problem['isSpilledHat'],
        'isUseContext': problem['isUseContext'],
        'isSolutionDomain': problem['isSolutionDomain'],
        'isVerifiedTerms': problem['isVerifiedTerms'],
        'sliderValue': problem['sliderValue'],
        'userId': userId,
      };

      await FirebaseFirestore.instance.collection('problems').add(newProblem);
      debugPrint("Hat copied successfully!");
      showToast(message: "Hat copied successfully!", isError: false);
    } catch (e) {
      debugPrint("Error copying Hat: $e");
      showToast(message: "Error copying Hat: $e", isError: true);
    }
  }

  void _showCopyDialog(Map<String, dynamic> problem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppStyles.Primary50(),
        title: const Text("Copy Problem"),
        content: const Text(
            "Do you want to copy this inspiration Hat to your Hats?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _copyProblem(problem);
            },
            child: const Text("Copy"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspiration', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // 1) Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: "Search Hat name...",
                labelStyle: TextStyle(color: Colors.white),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          ExpansionTile(
            title: const Text(
              "Filters",
              style: TextStyle(color: Colors.white),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    _buildFilterButton(
                      "none",
                      "None",
                      currentValue: _selectedGPTFilter,
                      onTap: _onGPTFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "gpt",
                      "GPT",
                      currentValue: _selectedGPTFilter,
                      onTap: _onGPTFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "verified",
                      "Verified",
                      currentValue: _selectedGPTFilter,
                      onTap: _onGPTFilterChanged,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    _buildFilterButton(
                      "all",
                      "None",
                      currentValue: _spilledHatFilter,
                      onTap: _onSpilledHatFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "true",
                      "Spilled Hat",
                      currentValue: _spilledHatFilter,
                      onTap: _onSpilledHatFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "false",
                      "Non-Spilled",
                      currentValue: _spilledHatFilter,
                      onTap: _onSpilledHatFilterChanged,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    _buildFilterButton(
                      "all",
                      "None",
                      currentValue: _solutionDomainFilter,
                      onTap: _onSolutionDomainFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "true",
                      "Solution Domain",
                      currentValue: _solutionDomainFilter,
                      onTap: _onSolutionDomainFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "false",
                      "Application Domain",
                      currentValue: _solutionDomainFilter,
                      onTap: _onSolutionDomainFilterChanged,
                    ),
                  ],
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                child: Row(
                  children: [
                    _buildFilterButton(
                      "all",
                      "None",
                      currentValue: _useContextFilter,
                      onTap: _onUseContextFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "true",
                      "Use Context",
                      currentValue: _useContextFilter,
                      onTap: _onUseContextFilterChanged,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterButton(
                      "false",
                      "No Context",
                      currentValue: _useContextFilter,
                      onTap: _onUseContextFilterChanged,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: _problems.isEmpty && !_isLoading
                ? const Center(child: Text("No problems found."))
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _problems.length,
                    itemBuilder: (context, index) {
                      final problem = _problems[index];
                      final name = problem['problemName'] ?? 'Untitled';
                      final description = problem['problemDescription'] ??
                          'No description available';
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 6.0, horizontal: 8.0),
                        color: AppStyles.backgroundLight(),
                        child: ListTile(
                          title: Text(
                            name,
                            style: AppStyles.labelLarge(
                              color: AppStyles.onBackground(),
                            ),
                          ),
                          subtitle: Text(
                            description,
                            style: AppStyles.labelSmall(
                              color: AppStyles.onBackground(),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProblemContainersPage(
                                    problemId: problem['docId']),
                              ),
                            );
                          },
                          onLongPress: () => _showCopyDialog(problem),
                        ),
                      );
                    },
                  ),
          ),

          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(
    String value,
    String label, {
    required String currentValue,
    required void Function(String) onTap,
  }) {
    final bool isSelected = (currentValue == value);
    return Expanded(
      child: ElevatedButton(
        style: ButtonStyle(
          splashFactory: NoSplash.splashFactory,
          backgroundColor: MaterialStateProperty.all(
              isSelected ? Colors.blue : const Color(0xFF212121)),
          foregroundColor: MaterialStateProperty.all(
              isSelected ? Colors.white : Colors.black),
        ),
        onPressed: () => onTap(value),
        child: Text(
          label,
          style: AppStyles.labelSmall(
            color: AppStyles.onBackground(),
          ),
        ),
      ),
    );
  }
}
