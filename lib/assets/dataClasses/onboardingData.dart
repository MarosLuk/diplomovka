import 'package:flutter/material.dart';

class Block {
  final String name;
  final bool isScheduled;
  final List<String> days;
  int sessionsPerWeek;
  final String duration;
  final IconData? icon; // Updated to store IconData

  Block({
    this.name = '',
    this.isScheduled = false,
    this.days = const [],
    this.sessionsPerWeek = 0,
    this.duration = '',
    this.icon, // IconData is now used instead of iconPath
  });

  // Convert Block to JSON, icon is serialized to codePoint and fontFamily
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'isScheduled': isScheduled,
      'days': days,
      'sessionsPerWeek': sessionsPerWeek,
      'duration': duration,
      'iconCodePoint': icon?.codePoint, // Convert IconData to codePoint
      'iconFontFamily': icon?.fontFamily, // Store font family of the icon
    };
  }

  // Create Block from JSON, rebuild the IconData from codePoint and fontFamily
  factory Block.fromJson(Map<String, dynamic> json) {
    return Block(
      name: json['name'] ?? '',
      isScheduled: json['isScheduled'] ?? false,
      days: List<String>.from(json['days'] ?? []),
      sessionsPerWeek: json['sessionsPerWeek'] ?? 0,
      duration: json['duration'] ?? '',
      icon: json['iconCodePoint'] != null && json['iconFontFamily'] != null
          ? IconData(
              json['iconCodePoint'],
              fontFamily: json['iconFontFamily'],
            )
          : null, // Rebuild IconData from codePoint and fontFamily
    );
  }
}

class Blocks {
  final String blockClass;
  final String typeOfBlock;
  final String date;

  Blocks({
    this.blockClass = '',
    this.typeOfBlock = '',
    this.date = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'blockClass': blockClass,
      'blockType': typeOfBlock,
      'date': date,
    };
  }

  factory Blocks.fromJson(Map<String, dynamic> json) {
    return Blocks(
      blockClass: json['blockClass'] ?? '',
      typeOfBlock: json['blockType'] ?? '',
      date: json['date'] ?? '',
    );
  }
}

class OnboardingData {
  List<String> goals;
  int? birthYear;
  String? gender;
  int? height;
  double? weight;
  List<String> workDays;
  String? workStartTime;
  String? workEndTime;
  double? dailyTimeOutdoors;
  List<Block> blocks;
  List<Blocks> injuries;
  String? healthCondition;
  String? medications;
  int? mealsPerDay;
  List<String> allergies;
  List<String> supplements;
  String? smoke;
  String? alcohol;
  String? stressLevel;
  String? sleepPattern;
  String? mentalState;
  int? mentalStateDuration;

  OnboardingData({
    this.goals = const [],
    this.birthYear,
    this.gender,
    this.height,
    this.weight,
    this.workDays = const [],
    this.workStartTime,
    this.workEndTime,
    this.dailyTimeOutdoors,
    this.blocks = const [],
    this.injuries = const [],
    this.healthCondition,
    this.medications,
    this.mealsPerDay,
    this.allergies = const [],
    this.supplements = const [],
    this.smoke,
    this.alcohol,
    this.stressLevel,
    this.sleepPattern,
    this.mentalState,
    this.mentalStateDuration,
  });

  Map<String, dynamic> toJson() {
    return {
      'goals': goals,
      'birthYear': birthYear,
      'gender': gender,
      'height': height,
      'weight': weight,
      'workDays': workDays,
      'workStartTime': workStartTime,
      'workEndTime': workEndTime,
      'dailyTimeOutdoors': dailyTimeOutdoors,
      'workouts': blocks.map((workout) => workout.toJson()).toList(),
      'injuries': injuries.map((injury) => injury.toJson()).toList(),
      'healthCondition': healthCondition,
      'medications': medications,
      'mealsPerDay': mealsPerDay,
      'allergies': allergies,
      'supplements': supplements,
      'smoke': smoke,
      'alcohol': alcohol,
      'stressLevel': stressLevel,
      'sleepPattern': sleepPattern,
      'mentalState': mentalState,
      'mentalStateDuration': mentalStateDuration,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      goals: List<String>.from(json['goals'] ?? []),
      birthYear: json['birthYear'],
      gender: json['gender'],
      height: json['height'],
      weight: json['weight'],
      workDays: List<String>.from(json['workDays'] ?? []),
      workStartTime: json['workStartTime'],
      workEndTime: json['workEndTime'],
      dailyTimeOutdoors: json['dailyTimeOutdoors'],
      blocks: (json['workouts'] as List<dynamic>?)
              ?.map((e) => Block.fromJson(e))
              .toList() ??
          [],
      injuries: (json['injuries'] as List<dynamic>?)
              ?.map((e) => Blocks.fromJson(e))
              .toList() ??
          [],
      healthCondition: json['healthCondition'],
      medications: json['medications'],
      mealsPerDay: json['mealsPerDay'],
      allergies: List<String>.from(json['allergies'] ?? []),
      supplements: List<String>.from(json['supplements'] ?? []),
      smoke: json['smoke'],
      alcohol: json['alcohol'],
      stressLevel: json['stressLevel'],
      sleepPattern: json['sleepPattern'],
      mentalState: json['mentalState'],
      mentalStateDuration: json['mentalStateDuration'],
    );
  }
}
