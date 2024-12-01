import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast({required String message, bool isError = false}) {
  // Example toast implementation with error handling
  final color = isError ? Colors.red : Colors.green;
  final icon = isError ? Icons.error : Icons.check_circle;

  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: color,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
