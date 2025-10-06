import 'package:flutter/material.dart';
import 'playstore_slide_generator.dart';

void main() {
  runApp(const PlaystoreSlideApp());
}

class PlaystoreSlideApp extends StatelessWidget {
  const PlaystoreSlideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '플레이스토어 슬라이드 생성기',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const PlaystoreSlideGenerator(),
    );
  }
}
