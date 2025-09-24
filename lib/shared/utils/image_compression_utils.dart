import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImageCompressionUtils {
  static const int _targetSizeKB = 100;
  static const int _targetSizeBytes = _targetSizeKB * 1024;

  /// 이미지를 100KB 이하로 압축합니다.
  /// [imageFile] 압축할 이미지 파일
  /// [quality] 초기 압축 품질 (기본값: 85)
  /// 반환: 압축된 이미지 파일
  static Future<File> compressImageIfNeeded(
    File imageFile, {
    int quality = 85,
  }) async {
    try {
      // 파일 크기 확인
      final int fileSizeBytes = await imageFile.length();

      // 100KB 이하면 압축하지 않음
      if (fileSizeBytes <= _targetSizeBytes) {
        return imageFile;
      }

      // 압축 수행
      return await _compressImage(imageFile, quality: quality);
    } catch (e) {
      // 압축 실패시 원본 반환
      return imageFile;
    }
  }

  /// 이미지를 압축하여 100KB 이하로 만듭니다.
  static Future<File> _compressImage(
    File imageFile, {
    int quality = 85,
  }) async {
    // WebP 지원 여부에 따라 포맷 결정
    CompressFormat format;
    String newExtension;

    if (await _isWebPSupported()) {
      format = CompressFormat.webp;
      newExtension = '.webp';
    } else {
      format = CompressFormat.jpeg;
      newExtension = '.jpg';
    }

    // 압축된 파일을 저장할 임시 경로 생성
    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = path.basenameWithoutExtension(imageFile.path);
    final String compressedPath = path.join(
      tempDir.path,
      '${fileName}_compressed_${DateTime.now().millisecondsSinceEpoch}$newExtension',
    );

    int currentQuality = quality;
    Uint8List? compressedBytes;

    // 목표 크기에 도달할 때까지 품질을 단계적으로 낮춤
    while (currentQuality >= 10) {
      final Uint8List? result = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: currentQuality,
        format: format,
        minWidth: 800,
        minHeight: 800,
        rotate: 0,
      );

      if (result != null) {
        compressedBytes = result;
        if (compressedBytes.length <= _targetSizeBytes) {
          break;
        }
      }

      // 품질을 15씩 낮춤
      currentQuality -= 15;
    }

    // 여전히 크거나 압축 실패시 최소 품질로 재압축
    if (compressedBytes == null || compressedBytes.length > _targetSizeBytes) {
      compressedBytes = await FlutterImageCompress.compressWithFile(
        imageFile.absolute.path,
        quality: 10,
        format: format,
        minWidth: 600,
        minHeight: 600,
        rotate: 0,
      );
    }

    // 압축된 파일 저장
    if (compressedBytes != null) {
      final File compressedFile = File(compressedPath);
      await compressedFile.writeAsBytes(compressedBytes);
      return compressedFile;
    }

    // 모든 압축 시도 실패시 원본 반환
    return imageFile;
  }

  /// WebP 포맷 지원 여부 확인
  static Future<bool> _isWebPSupported() async {
    try {
      // 간단한 WebP 테스트 이미지로 지원 여부 확인
      final Uint8List? testResult = await FlutterImageCompress.compressWithList(
        Uint8List.fromList([0xFF, 0xD8, 0xFF]), // 최소한의 JPEG 헤더
        quality: 50,
        format: CompressFormat.webp,
      );
      return testResult != null;
    } catch (e) {
      return false;
    }
  }

  /// 파일 크기를 KB 단위로 반환
  static Future<double> getFileSizeKB(File file) async {
    final int bytes = await file.length();
    return bytes / 1024;
  }

  /// 파일 크기를 사람이 읽기 쉬운 형태로 반환
  static Future<String> getReadableFileSize(File file) async {
    final int bytes = await file.length();

    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }
}