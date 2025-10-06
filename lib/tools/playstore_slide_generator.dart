import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PlaystoreSlideGenerator extends StatefulWidget {
  const PlaystoreSlideGenerator({super.key});

  @override
  State<PlaystoreSlideGenerator> createState() => _PlaystoreSlideGeneratorState();
}

class _PlaystoreSlideGeneratorState extends State<PlaystoreSlideGenerator> {
  final List<GlobalKey> _slideKeys = List.generate(7, (_) => GlobalKey());
  int _currentSlide = 0;

  Future<void> _captureAndSaveSlide(int index) async {
    try {
      RenderRepaintBoundary boundary = _slideKeys[index].currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/playstore_slide_${index + 1}.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('슬라이드 ${index + 1} 저장 완료: $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }

  Future<void> _captureAllSlides() async {
    for (int i = 0; i < 7; i++) {
      setState(() => _currentSlide = i);
      await Future.delayed(const Duration(milliseconds: 100));
      await _captureAndSaveSlide(i);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모든 슬라이드 저장 완료!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('플레이스토어 슬라이드 생성기'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_alt),
            onPressed: _captureAllSlides,
            tooltip: '모든 슬라이드 저장',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SizedBox(
                width: 360,
                height: 640,
                child: _buildCurrentSlide(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: _currentSlide > 0
                      ? () => setState(() => _currentSlide--)
                      : null,
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentSlide + 1} / 7',
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  onPressed: _currentSlide < 6
                      ? () => setState(() => _currentSlide++)
                      : null,
                ),
                const SizedBox(width: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('현재 슬라이드 저장'),
                  onPressed: () => _captureAndSaveSlide(_currentSlide),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSlide() {
    return RepaintBoundary(
      key: _slideKeys[_currentSlide],
      child: _buildSlide(_currentSlide),
    );
  }

  Widget _buildSlide(int index) {
    switch (index) {
      case 0:
        return _buildSlide1();
      case 1:
        return _buildSlide2();
      case 2:
        return _buildSlide3();
      case 3:
        return _buildSlide4();
      case 4:
        return _buildSlide5();
      case 5:
        return _buildSlide6();
      case 6:
        return _buildSlide7();
      default:
        return const SizedBox();
    }
  }

  // 슬라이드 1: 핵심 가치 제안
  Widget _buildSlide1() {
    return Container(
      color: const Color(0xFF2D3142),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '매일 한 명',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '진심 어린 만남',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Daily 1 Person, Real Connection',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 7,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F5D75),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.screenshot, size: 80, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      '여기에 매칭 화면\n스크린샷 넣기',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 슬라이드 2: 안전성
  Widget _buildSlide2() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF06D6A0), size: 32),
                        SizedBox(width: 12),
                        Text(
                          '철저한 프로필 검증',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3142),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '관리자가 직접 확인하는\n안전한 만남 시스템',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: const Color(0xFF4F5D75),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.screenshot, size: 80, color: Colors.black26),
                    SizedBox(height: 16),
                    Text(
                      '여기에 프로필 작성 화면\n스크린샷 넣기',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black26, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 슬라이드 3: 매칭
  Widget _buildSlide3() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFEF476F), Color(0xFFFF6B9D)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.all(32.0),
            child: Column(
              children: [
                Text(
                  '같은 나라, 같은 관심사',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Text(
                  '의미 있는 연결의 시작',
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.screenshot, size: 80, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      '여기에 관심사 선택 화면\n스크린샷 넣기',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 슬라이드 4: 사용자 후기
  Widget _buildSlide4() {
    return Container(
      color: const Color(0xFFF8F9FA),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  '⭐⭐⭐⭐⭐',
                  style: TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  '"하루 한 명이라서 부담 없고,\n프로필 검증으로 안심하고\n만날 수 있어요"',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    color: Color(0xFF2D3142),
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '- 블라인드데이트 사용자',
                  style: TextStyle(
                    fontSize: 16,
                    color: const Color(0xFFBFC0C0),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5E5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.screenshot, size: 60, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    '여기에 채팅 화면 스크린샷 넣기',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black26, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 슬라이드 5: 사용 방법
  Widget _buildSlide5() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStep('1️⃣', '프로필 등록', '전화번호 인증 후 프로필 작성'),
          const SizedBox(height: 48),
          _buildStep('2️⃣', '매일 한 명 추천', '관심사 기반 매칭'),
          const SizedBox(height: 48),
          _buildStep('3️⃣', '관심 표현', '서로 관심 있으면 대화 시작'),
        ],
      ),
    );
  }

  Widget _buildStep(String emoji, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 36),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF4F5D75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 슬라이드 6: 프라이버시
  Widget _buildSlide6() {
    return Container(
      color: const Color(0xFF2D3142),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '🔒 안심하고 사용하세요',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildCheckItem('국가별 매칭으로 현실적인 만남'),
          const SizedBox(height: 24),
          _buildCheckItem('프로필 검증 시스템'),
          const SizedBox(height: 24),
          _buildCheckItem('안전한 채팅 환경'),
          const SizedBox(height: 48),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFF4F5D75),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.screenshot, size: 60, color: Colors.white38),
                  SizedBox(height: 12),
                  Text(
                    '여기에 설정 화면 스크린샷 넣기',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle, color: Color(0xFF06D6A0), size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFFBFC0C0),
            ),
          ),
        ),
      ],
    );
  }

  // 슬라이드 7: CTA
  Widget _buildSlide7() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D3142), Color(0xFF4F5D75)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '내일의 인연이\n기다리고 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 56,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFEF476F),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '지금 시작하세요',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, color: Colors.white, size: 32),
                ],
              ),
            ),
            const SizedBox(height: 64),
            Container(
              height: 150,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.screenshot, size: 50, color: Colors.white38),
                    SizedBox(height: 8),
                    Text(
                      '앱 아이콘 또는\n로그인 화면',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
