import 'package:flutter/material.dart';

void main() {
WidgetsFlutterBinding.ensureInitialized();
runApp(const TensorAlertsSafeApp());
}

class TensorAlertsSafeApp extends StatelessWidget {
const TensorAlertsSafeApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
debugShowCheckedModeBanner: false,
title: 'Tensor Alerts',
theme: ThemeData.dark(),
home: const Scaffold(
backgroundColor: Color(0xFF0A0A0A),
body: Center(
child: Text(
'Tensor Alerts Safe Mode',
style: TextStyle(
color: Colors.white,
fontSize: 24,
fontWeight: FontWeight.bold,
),
),
),
),
);
}
}
