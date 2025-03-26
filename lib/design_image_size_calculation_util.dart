import 'dart:io';

import 'package:flutter/widgets.dart';

// 写真の表示用の比率を計算するクラス
class ImageSizeCalculationUtil {
  // 表示用の比率を取得する
  static Future<ImageSizeResponse> getDesignImageRatio(File imageFile) async {
    final imageSize = await _getDesignImageSize(imageFile);
    final imageRatio = _getImageRatio(imageSize.$1, imageSize.$2);
    final closestRate = _getClosestRatio(imageRatio);
    return ImageSizeResponse(
      width: imageSize.$1,
      height: imageSize.$2,
      closestRatio: closestRate,
    );
  }

  static Future<(double, double)> _getDesignImageSize(File imageFile) async {
    final image = await decodeImageFromList(await imageFile.readAsBytes());
    final width = image.width.toDouble();
    final height = image.height.toDouble();
    return (width, height);
  }

  static double _getImageRatio(double width, double height) {
    if (height <= 0.0) {
      return 1.0; // 0割禁止
    }
    return width / height;
  }

  // 画像で表示する比率に最も近い比率を返す
  static double _getClosestRatio(double target) {
    return [
      1.0, // 正方形
      4 / 5, // 縦長
      5 / 4, // 横長
    ].reduce((closest, current) =>
        (target - current).abs() < (target - closest).abs()
            ? current
            : closest);
  }
}

class ImageSizeResponse {
  final double width;
  final double height;
  final double closestRatio;

  ImageSizeResponse({
    required this.width,
    required this.height,
    required this.closestRatio,
  });
}
