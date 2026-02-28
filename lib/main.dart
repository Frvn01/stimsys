import 'package:flutter/material.dart';
import 'package:stimsys/app.dart'; // <-- must import app.dart


export 'app.dart'; // add this line

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}