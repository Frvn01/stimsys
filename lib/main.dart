import 'package:flutter/material.dart';
import 'package:stimsys/app.dart'; // <-- must import app.dart
import 'package:provider/provider.dart'; // ← add this
import 'package:stimsys/screens/logic_file.dart';

export 'app.dart'; // add this line

void main() {
  WidgetsFlutterBinding.ensureInitialized();
    runApp(
    ChangeNotifierProvider(
      create: (context) => StudentManagement(),
      child: MyApp(),
    ),
  );
}