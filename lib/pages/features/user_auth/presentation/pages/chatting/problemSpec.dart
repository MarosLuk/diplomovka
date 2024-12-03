import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:diplomovka/pages/features/app/global/toast.dart';

Map<String, List<String>> generateSectionWords(
    List<Map<String, dynamic>> sectionsData,
    Map<String, List<String>> selectedOptions,
    Map<String, List<Map<String, dynamic>>> optionContent) {
  final Random random = Random();
  final Map<String, List<String>> result = {};

  for (var section in sectionsData) {
    final String sectionTitle = section["title"];
    final List<String> options = selectedOptions[sectionTitle] ?? [];
    final List<String> sectionWords = [];
    final int totalWordsNeeded = 5;

    final List<Map<String, dynamic>> mostRelatable = [];
    final List<Map<String, dynamic>> middleRelatable = [];
    final List<Map<String, dynamic>> uncommon = [];

    // Categorize options based on scores
    for (final option in options) {
      final List<Map<String, dynamic>> optionWords =
          optionContent[option] ?? [];

      for (final word in optionWords) {
        final int score = word['upvotes'] - word['downvotes'];
        if (score >= 50) {
          mostRelatable.add(word);
        } else if (score >= 20) {
          middleRelatable.add(word);
        } else {
          uncommon.add(word);
        }
      }
    }

    List<String> pickRandomWords(
        List<Map<String, dynamic>> source, int count, Set<String> usedWords) {
      final List<String> pickedWords = [];
      while (count > 0 && source.isNotEmpty) {
        final randomIndex = random.nextInt(source.length);
        final wordEntry = source.removeAt(randomIndex);
        final word = wordEntry['option'] as String;

        if (!usedWords.contains(word)) {
          pickedWords.add(word);
          usedWords.add(word);
          count--;
        }
      }
      return pickedWords;
    }

    final Set<String> usedWords = {};
    print("Most Relatable:");
    mostRelatable.forEach((entry) {
      print(
          "Option: ${entry['option']}, Upvotes: ${entry['upvotes']}, Downvotes: ${entry['downvotes']}");
    });

    print("Middle Relatable:");
    middleRelatable.forEach((entry) {
      print(
          "Option: ${entry['option']}, Upvotes: ${entry['upvotes']}, Downvotes: ${entry['downvotes']}");
    });

    print("Uncommon:");
    uncommon.forEach((entry) {
      print(
          "Option: ${entry['option']}, Upvotes: ${entry['upvotes']}, Downvotes: ${entry['downvotes']}");
    });

    // Pick words randomly from each category
    sectionWords.addAll(pickRandomWords(mostRelatable, 2, usedWords));
    sectionWords.addAll(pickRandomWords(middleRelatable, 2, usedWords));
    sectionWords.addAll(pickRandomWords(uncommon, 1, usedWords));

    // If insufficient words, fill from lower categories
    if (sectionWords.length < totalWordsNeeded) {
      final int remaining = totalWordsNeeded - sectionWords.length;
      sectionWords
          .addAll(pickRandomWords(middleRelatable, remaining, usedWords));
    }
    if (sectionWords.length < totalWordsNeeded) {
      final int remaining = totalWordsNeeded - sectionWords.length;
      sectionWords.addAll(pickRandomWords(uncommon, remaining, usedWords));
    }

    while (sectionWords.length < totalWordsNeeded) {
      sectionWords.add("");
    }

    result[sectionTitle] =
        sectionWords.where((word) => word.isNotEmpty).toList();
  }

  return result;
}

final Map<String, List<String>> sectionToSubsections = {
  "Security": [
    "Authentication and Authorization",
    "Data Encryption",
    "Vulnerability Analysis",
    "Secure Storage",
    "Protection Against Attacks",
  ],
  "Performance": [
    "App Responsiveness",
    "Memory Usage Optimization",
    "Efficient Network Requests",
    "Caching and Lazy Loading",
    "Profiling and Debugging",
  ],
  "User Interface (UI)": [
    "Design Consistency",
    "Accessibility Features",
    "Typography and Colors",
    "Adherence to Guidelines",
    "Component Reusability",
  ],
  "User Experience (UX)": [
    "Intuitive Navigation",
    "User Feedback",
    "Bug-Free Interactions",
    "Satisfaction Metrics",
    "Improved User Retention",
  ],
  "Code Quality": [
    "Readability and Maintainability",
    "Adherence to Standards",
    "Refactoring Opportunities",
    "Modularization",
    "Technical Debt Analysis",
  ],
  "Scalability": [
    "Efficient Database Design",
    "API Scalability",
    "Load Balancing",
    "Rate Limiting",
    "Handling Growth",
  ],
};

void showVoteDialog(BuildContext context, List<String> subsections,
    String option, WidgetRef ref) async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  int currentUpvotes = 0;
  int currentDownvotes = 0;

  try {
    final snapshot = await firestore
        .collection('problemSpecifications')
        .doc('optionContent')
        .get();

    final optionContent =
        snapshot.data()?['optionContent'] as Map<String, dynamic>?;
    if (optionContent == null) {
      throw Exception("optionContent not found in Firestore.");
    }

    for (final subsection in subsections) {
      if (optionContent.containsKey(subsection)) {
        final subsectionOptions = optionContent[subsection] as List<dynamic>;
        final entry = subsectionOptions.firstWhere(
          (item) => item['option'] == option,
          orElse: () => null,
        );

        if (entry != null) {
          currentUpvotes = entry['upvotes'] ?? 0;
          currentDownvotes = entry['downvotes'] ?? 0;
          break;
        }
      }
    }
  } catch (e) {
    print("Error fetching option data: $e");
    showToast(
      message: "Error fetching option data: $e",
      isError: true,
    );
    return;
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      int upvotesToAdd = 0;
      int downvotesToAdd = 0;

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            backgroundColor: AppStyles.Primary50(),
            title: Text("Set Votes for $option"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Upvotes to Add:"),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (upvotesToAdd > 0) {
                          setState(() {
                            upvotesToAdd--;
                          });
                        }
                      },
                    ),
                    Text(upvotesToAdd.toString()),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (upvotesToAdd < 5) {
                          setState(() {
                            upvotesToAdd++;
                          });
                        } else {
                          showToast(
                            message: "Maximum 5 votes can be added per save.",
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Downvotes to Add:"),
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (downvotesToAdd > 0) {
                          setState(() {
                            downvotesToAdd--;
                          });
                        }
                      },
                    ),
                    Text(downvotesToAdd.toString()),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (downvotesToAdd < 5) {
                          setState(() {
                            downvotesToAdd++;
                          });
                        } else {
                          showToast(
                            message: "Maximum 5 votes can be added per save.",
                            isError: true,
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    final optionContentRef = firestore
                        .collection('problemSpecifications')
                        .doc('optionContent');

                    final snapshot = await optionContentRef.get();
                    final optionContent = snapshot.data()?['optionContent'];

                    if (optionContent == null) {
                      throw Exception("optionContent not found during update.");
                    }

                    for (final subsection in subsections) {
                      if (optionContent.containsKey(subsection)) {
                        final updatedSubsection =
                            (optionContent[subsection] as List<dynamic>)
                                .map((entry) {
                          if (entry['option'] == option) {
                            return {
                              'option': entry['option'],
                              'upvotes': entry['upvotes'] + upvotesToAdd,
                              'downvotes': entry['downvotes'] + downvotesToAdd,
                            };
                          }
                          return entry;
                        }).toList();

                        await optionContentRef.update({
                          'optionContent.$subsection': updatedSubsection,
                        });

                        print(
                            "Votes updated for $option: Upvotes added=$upvotesToAdd, Downvotes added=$downvotesToAdd");
                        showToast(
                          message:
                              "Votes updated: +$upvotesToAdd upvotes, +$downvotesToAdd downvotes for $option.",
                        );
                        break;
                      }
                    }
                    Navigator.of(context).pop();
                  } catch (e) {
                    print("Error updating votes: $e");
                    showToast(
                      message: "Failed to update votes.",
                      isError: true,
                    );
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}

void regenerateContainer(BuildContext context, String problemId,
    String containerId, String containerName, WidgetRef ref) async {
  try {
    final parts = containerName.split(": ");
    if (parts.length != 2) {
      throw Exception("Invalid container name format: $containerName");
    }

    final section = parts[0].trim();
    final previousOption = parts[1].trim();

    final firestore = FirebaseFirestore.instance;
    final problemRef = firestore.collection('problems').doc(problemId);
    final snapshot = await problemRef.get();

    if (!snapshot.exists) {
      throw Exception("Problem not found: $problemId");
    }

    final problemData = snapshot.data();
    if (problemData == null || !problemData.containsKey('containers')) {
      throw Exception("Invalid problem data format.");
    }

    final containersRaw = problemData['containers'];
    if (containersRaw is! List ||
        containersRaw.isEmpty ||
        containersRaw[0] is! Map<String, dynamic>) {
      throw Exception("Invalid format for containers in problem data.");
    }
    final containers = List<Map<String, dynamic>>.from(containersRaw);

    final containerIndex =
        containers.indexWhere((c) => c['containerId'] == containerId);
    if (containerIndex == -1) {
      throw Exception("Container not found: $containerId");
    }

    final optionContentSnapshot = await firestore
        .collection('problemSpecifications')
        .doc('optionContent')
        .get();

    final optionContent =
        optionContentSnapshot.data()?['optionContent'] as Map<String, dynamic>?;
    if (optionContent == null) {
      throw Exception("OptionContent not found in Firestore.");
    }

    // Get all already used options in containers
    final usedOptions = containers
        .map((c) => c['containerName'].toString().split(": ").last.trim())
        .toSet();

    final subsections = sectionToSubsections[section];
    if (subsections == null) {
      throw Exception("Section '$section' not found in sectionToSubsections.");
    }

    String? newWord;
    for (final subsection in subsections) {
      if (!optionContent.containsKey(subsection)) continue;

      final optionsRaw = optionContent[subsection];
      if (optionsRaw is! List ||
          optionsRaw.isEmpty ||
          optionsRaw[0] is! Map<String, dynamic>) {
        throw Exception(
            "Invalid format for options in subsection: $subsection");
      }

      final optionsList = List<Map<String, dynamic>>.from(optionsRaw);

      // Filter options to exclude already used ones and the previous option
      final availableOptions = optionsList
          .map((o) => o['option'] as String)
          .where((o) => o != previousOption && !usedOptions.contains(o))
          .toList();

      if (availableOptions.isNotEmpty) {
        final random = availableOptions..shuffle();
        newWord = random.first;
        break;
      }
    }

    if (newWord == null) {
      throw Exception("No new word could be generated for section '$section'.");
    }

    containers[containerIndex]['containerName'] = "$section: $newWord";

    await problemRef.update({'containers': containers});

    showToast(message: "Container name regenerated successfully!");
  } catch (e) {
    print("Error regenerating container: $e");
    showToast(message: "Failed to regenerate container: $e", isError: true);
  }
}

/*
final Map<String, List<String>> optionsContent = {
  "Authentication and Authorization": [
    "user",
    "login",
    "password",
    "secure",
    "session",
    "token",
    "access",
    "control",
    "verification",
    "roles",
    "credentials",
    "keys",
    "authorization",
    "authentication",
    "identity",
    "permissions",
    "tokens",
    "multi-factor",
    "SSO",
    "OTP"
  ],
  "Data Encryption": [
    "cipher",
    "cryptography",
    "encrypt",
    "decrypt",
    "key",
    "secure",
    "AES",
    "RSA",
    "private",
    "public",
    "algorithm",
    "ciphertext",
    "plaintext",
    "hash",
    "encoding",
    "TLS",
    "SSL",
    "cryptanalysis",
    "blockchain",
    "symmetric"
  ],
  "Vulnerability Analysis": [
    "scan",
    "threat",
    "assessment",
    "risk",
    "attack",
    "weakness",
    "penetration",
    "testing",
    "report",
    "exploitation",
    "mitigation",
    "remediation",
    "audit",
    "security",
    "flaws",
    "breach",
    "investigation",
    "malware",
    "defense",
    "patch"
  ],
  "Secure Storage": [
    "encryption",
    "protection",
    "data",
    "key",
    "vault",
    "confidentiality",
    "backup",
    "access",
    "restriction",
    "policy",
    "disk",
    "cloud",
    "files",
    "authorization",
    "integrity",
    "secure",
    "tokens",
    "secrets",
    "storage",
    "management"
  ],
  "Protection Against Attacks": [
    "firewall",
    "antivirus",
    "intrusion",
    "detection",
    "prevention",
    "security",
    "system",
    "access",
    "control",
    "authentication",
    "authorization",
    "malware",
    "spam",
    "ransomware",
    "spyware",
    "phishing",
    "DDOS",
    "defense",
    "block",
    "response"
  ],
  "App Responsiveness": [
    "performance",
    "fast",
    "UI",
    "smooth",
    "animation",
    "frames",
    "response",
    "speed",
    "snappy",
    "optimization",
    "lazy-loading",
    "instant",
    "reactive",
    "rendering",
    "refresh",
    "timing",
    "metrics",
    "interactive",
    "experience",
    "transition"
  ],
  "Memory Usage Optimization": [
    "garbage",
    "collection",
    "heap",
    "stack",
    "management",
    "efficient",
    "allocation",
    "release",
    "cache",
    "reuse",
    "reduce",
    "footprint",
    "optimize",
    "storage",
    "objects",
    "analyze",
    "process",
    "memory",
    "debugging",
    "performance"
  ],
  "Efficient Network Requests": [
    "latency",
    "bandwidth",
    "requests",
    "responses",
    "optimization",
    "API",
    "calls",
    "caching",
    "fetch",
    "streaming",
    "transfer",
    "protocol",
    "HTTP",
    "HTTPS",
    "headers",
    "compression",
    "payload",
    "requests",
    "retry",
    "connectivity"
  ],
  "Caching and Lazy Loading": [
    "assets",
    "loading",
    "lazy",
    "image",
    "data",
    "cache",
    "memory",
    "storage",
    "retrieval",
    "optimization",
    "framework",
    "preload",
    "stream",
    "efficient",
    "performance",
    "content",
    "lazy",
    "initialize",
    "reduce",
    "memory"
  ],
  "Profiling and Debugging": [
    "analyze",
    "profile",
    "debug",
    "optimize",
    "performance",
    "tools",
    "memory",
    "CPU",
    "utilization",
    "debugging",
    "frame",
    "render",
    "analysis",
    "reactive",
    "logs",
    "breakpoints",
    "timeline",
    "tracing",
    "inspection",
    "report"
  ]
};
final List<Map<String, dynamic>> sectionsDatas = [
  {
    "title": "Security",
    "keyFocus": [
      "Authentication and Authorization",
      "Data Encryption",
      "Vulnerability Analysis",
      "Secure Storage",
      "Protection Against Attacks"
    ],
  },
  {
    "title": "Performance",
    "keyFocus": [
      "App Responsiveness",
      "Memory Usage Optimization",
      "Efficient Network Requests",
      "Caching and Lazy Loading",
      "Profiling and Debugging"
    ],
  },
  {
    "title": "User Interface (UI)",
    "keyFocus": [
      "Design Consistency",
      "Accessibility Features",
      "Typography and Colors",
      "Adherence to Guidelines",
      "Component Reusability"
    ],
  },
  {
    "title": "User Experience (UX)",
    "keyFocus": [
      "Intuitive Navigation",
      "User Feedback",
      "Bug-Free Interactions",
      "Satisfaction Metrics",
      "Improved User Retention"
    ],
  },
  {
    "title": "Code Quality",
    "keyFocus": [
      "Readability and Maintainability",
      "Adherence to Standards",
      "Refactoring Opportunities",
      "Modularization",
      "Technical Debt Analysis"
    ],
  },
  {
    "title": "Scalability",
    "keyFocus": [
      "Efficient Database Design",
      "API Scalability",
      "Load Balancing",
      "Rate Limiting",
      "Handling Growth"
    ],
  },
];

 */
