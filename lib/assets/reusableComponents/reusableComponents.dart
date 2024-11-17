import 'package:flutter/material.dart';
import 'package:diplomovka/assets/colorsStyles/text_and_color_styles.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class Reusablecomponents {
  static Center bottomSheetTopButton() {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
