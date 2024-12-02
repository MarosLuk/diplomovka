import 'dart:math';

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
