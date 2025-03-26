import 'dart:io';

import 'package:flutter/widgets.dart';

// 写真の表示用の比率を計算するクラス
class ImageSizeCalculationUtil {
  // 表示用の比率を取得する
  static Future<double> getDesignImageRatio(File imageFile) async {
    final imageRatio = await _getImageRatio(imageFile);
    final closestRate = _getClosestRatio(imageRatio);
    return closestRate;
  }

  // 画像の縦横比を計算する
  static Future<double> _getImageRatio(File imageFile) async {
    final image = await decodeImageFromList(await imageFile.readAsBytes());
    final width = image.width.toDouble();
    final height = image.height.toDouble();
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
