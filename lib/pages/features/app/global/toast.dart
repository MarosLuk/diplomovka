import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast({required String message, required bool isError}) {
  final color = isError ? Colors.red : Colors.green;
  final icon = isError ? Icons.error : Icons.check_circle;

  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.TOP,
    backgroundColor: color,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}

void showToastLong({required String message, required bool isError}) {
  final color = isError ? Colors.red : Colors.green;
  final icon = isError ? Icons.error : Icons.check_circle;

  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.TOP,
    backgroundColor: color,
    textColor: Colors.white,
    fontSize: 16.0,
  );
}
