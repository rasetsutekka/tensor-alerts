import 'package:flutter/material.dart';

void main() => runApp(const App());

class App extends StatelessWidget {
const App({super.key});
@override
Widget build(BuildContext context) {
return const MaterialApp(
debugShowCheckedModeBanner: false,
home: Scaffold(
backgroundColor: Color(0xFF0A0A0A),
body: Center(
child: Text(
'Tensor Alerts boots ✅',
style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
),
),
),
);
}
}
