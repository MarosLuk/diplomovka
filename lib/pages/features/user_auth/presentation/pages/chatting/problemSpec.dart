import 'dart:math';

Map<String, List<String>> generateSectionWords(
    List<Map<String, dynamic>> sectionsData,
    Map<String, List<String>> selectedOptions) {
  final Random random = Random();
  final Map<String, List<String>> result = {};

  for (var section in sectionsData) {
    final String sectionTitle = section["title"];
    final List<String> options = selectedOptions[sectionTitle] ?? [];
    final List<String> sectionWords = [];
    final int totalWordsNeeded = 5;

    final Set<String> usedWords = {};

    if (options.isNotEmpty) {
      List<int> wordsPerOption =
          List.filled(options.length, totalWordsNeeded ~/ options.length);
      for (int i = 0; i < totalWordsNeeded % options.length; i++) {
        wordsPerOption[i] += 1;
      }

      for (int i = 0; i < options.length; i++) {
        final option = options[i];
        final List<String> optionWords = optionContent[option] ?? [];
        if (optionWords.isNotEmpty) {
          final List<String> availableWords =
              optionWords.where((word) => !usedWords.contains(word)).toList();

          sectionWords.addAll(
            List.generate(wordsPerOption[i], (_) {
              if (availableWords.isEmpty) return "";
              final word =
                  availableWords[random.nextInt(availableWords.length)];
              usedWords.add(word);
              availableWords.remove(word);
              return word;
            }),
          );
        }
      }
    }

    if (sectionWords.isNotEmpty) {
      result[sectionTitle] =
          sectionWords.where((word) => word.isNotEmpty).toList();
    }
  }

  return result;
}

final Map<String, List<String>> optionContent = {
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
final List<Map<String, dynamic>> sectionsData = [
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
