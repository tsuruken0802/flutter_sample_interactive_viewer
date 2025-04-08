import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample_transformation/image_size_calculation_util.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: CupertinoNavigationBar.large(
          largeTitle: Text('サンプル'),
        ),
        body: TransformationPage(),
      ),
    );
  }
}

class TransformationPage extends StatefulWidget {
  const TransformationPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _TransformationPageState createState() => _TransformationPageState();
}

class _TransformationPageState extends State<TransformationPage> {
  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();

  final imageName = 'tate1.jpg';

  final threshold = 200.0;

  bool _isZoomedIn = false;
  double scale = 1.0;
  ImageSizeResponse? _imageSize;

  Future<File> get _imageFile async {
    // Get temporary directory
    final Directory tempDir = await getApplicationDocumentsDirectory();
    // Create a file path in the temporary directory
    final String tempPath = '${tempDir.path}/$imageName';
    return File(tempPath);
  }

  @override
  void initState() {
    super.initState();
    _initImageSize();

    _transformationController.addListener(() {
      final currentScale = _transformationController.value.getMaxScaleOnAxis();
      // print("scale: $currentScale");
      setState(() {
        scale = currentScale;
      });
    });
  }

  void _onTapped() {
    if (_isZoomedIn) {
      _transformationController.value = _scaleMatrix(1);
    } else {
      _transformationController.value = _scaleMatrix(1.25);
    }
    setState(() {
      _isZoomedIn = !_isZoomedIn;
    });
  }

  Matrix4 _scaleMatrix(double scale) {
    final controller = _transformationController;
    final ImageSizeResponse imageSize = _imageSize!;
    final containerWidth = MediaQuery.of(context).size.width;
    final containerHeight = containerWidth;
    final response = _calculateImageSize(containerWidth, containerHeight)!;
    final isZoomMode = scale > 1.0;

    // Translationできる最大値を取得する
    final maxX = max(0.0, response.imageWidth - containerWidth);
    final maxY = max(0.0, response.imageHeight - containerHeight);

    final isWide = imageSize.realRatio > 1.0;
    final isNarrow = imageSize.realRatio < 1.0;
    Matrix4 matrix = controller.value;
    final oldMatrix = Matrix4.copy(matrix);

    final xPadding = isZoomMode ? 0.0 : response.horizontalPadding;
    final yPadding = isZoomMode ? 0.0 : response.verticalPadding;

    final translationX = isNarrow ? xPadding : oldMatrix.getTranslation().x;
    final translationY = isWide ? yPadding : oldMatrix.getTranslation().y;

    final translationMatrix = Matrix4.translationValues(
      max(translationX, -maxX),
      max(translationY, -maxY),
      oldMatrix.getTranslation().z,
    );

    final scaleMatrix = Matrix4.diagonal3Values(scale, scale, scale);
    final result = translationMatrix * scaleMatrix;

    // Translate back from the center point
    // matrix = matrix.translate(centerX, centerY);

    return result;
  }

  Future<void> _initImageSize() async {
    final file = await _imageFile;
    if (!(await file.exists())) {
      await bundleAssetsImageToFile();
      return;
    }
    final result = await ImageSizeCalculationUtil.getDesignImageRatio(
      file,
    );
    setState(() {
      _imageSize = result;
    });
  }

  Future<File> bundleAssetsImageToFile() async {
    // Load the image from assets
    final ByteData data = await rootBundle.load('assets/images/$imageName');

    // Write the image data to the file
    final File file = await _imageFile;
    await file.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );

    return file;
  }

  Response? _calculateImageSize(double containerWidth, double containerHeight) {
    final imageRatio = _imageSize?.closestRatio;
    if (imageRatio == null) {
      return null;
    }
    final isWide = imageRatio > 1.0;
    final isNarrow = imageRatio < 1.0;
    double imageWidth, imageHeight;
    if (isWide) {
      imageHeight = containerHeight / _imageSize!.closestRatio;
      imageWidth = imageHeight * _imageSize!.realRatio;
    } else if (isNarrow) {
      imageWidth = containerWidth * _imageSize!.closestRatio;
      imageHeight = imageWidth / _imageSize!.realRatio;
    } else {
      imageWidth = containerWidth;
      imageHeight = containerHeight;
    }
    double verticalPadding = 0;
    double horizontalPadding = 0;
    if (isWide) {
      verticalPadding = (containerHeight - imageHeight) / 2;
    } else if (isNarrow) {
      horizontalPadding = (containerWidth - imageWidth) / 2;
    }
    return Response(
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      horizontalPadding: horizontalPadding,
      verticalPadding: verticalPadding,
    );
  }

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width;
    final containerHeight = containerWidth;
    final response = _calculateImageSize(containerWidth, containerHeight);
    if (response == null) {
      return FilledButton(
        onPressed: () async {
          final file = await bundleAssetsImageToFile();
          debugPrint(file.path);
        },
        child: Text('Save Image'),
      );
    }
    double imageWidth = response.imageWidth;
    double imageHeight = response.imageHeight;
    double horizontalPadding = _isZoomedIn ? 0.0 : response.horizontalPadding;
    double verticalPadding = _isZoomedIn ? 0.0 : response.verticalPadding;
    final vPadding = imageHeight - imageHeight / scale;
    final hPadding = imageWidth - imageWidth / scale;

    return Column(
      children: [
        SizedBox(
          width: containerWidth,
          height: containerHeight,
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              width: containerWidth + hPadding,
              height: imageHeight + vPadding,
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.symmetric(
                  vertical: verticalPadding,
                  horizontal: horizontalPadding,
                ),
                panAxis: PanAxis.free,
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 5,
                onInteractionStart: (details) {},
                onInteractionEnd: (details) {},
                constrained: false,
                child: Image.asset(
                  'assets/images/$imageName',
                  width: imageWidth + hPadding,
                  height: imageHeight + vPadding,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _onTapped,
              child: Text(_isZoomedIn ? 'Zoom Out' : 'Zoom In'),
            ),
            // FilledButton(
            //   onPressed: () async {
            //     await bundleAssetsImageToFile();
            //   },
            //   child: Text('Save Image'),
            // ),
            // FilledButton(
            //   onPressed: () async {},
            //   child: Text('比率確認'),
            // ),
          ],
        ),
      ],
    );
  }
}

class Response {
  final double imageWidth;
  final double imageHeight;
  final double horizontalPadding;
  final double verticalPadding;

  Response(
      {required this.imageWidth,
      required this.imageHeight,
      required this.horizontalPadding,
      required this.verticalPadding});
}

class CustomScrollPhysics extends ScrollPhysics {
  // final double imageWidth;
  final double imageHeight;

  /// Creates scroll physics that always lets the user scroll.
  const CustomScrollPhysics({super.parent, required this.imageHeight});

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    // print("scroll applyTo: $ancestor");
    return CustomScrollPhysics(
        parent: buildParent(ancestor), imageHeight: imageHeight);
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // print("shouldAcceptUserOffset: ${position.pixels}");
    return true;
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    // print("applyPhysicsToUserOffset: $offset");
    return super.applyPhysicsToUserOffset(position, offset);
  }

  @override
  bool get allowUserScrolling {
    // print("ユーザーがスクロールできるかどうかを返す");
    // ユーザーがスクロールできるかどうかを返す
    return false;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    print("applyBoundaryConditions: ${position.pixels}");
    if (position.pixels > imageHeight) {
      return 0.0;
    }
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // print("createBallisticSimulation: $velocity");
    return super.createBallisticSimulation(position, velocity);
  }

  @override
  double carriedMomentum(double existingVelocity) {
    // print("carriedMomentum: $existingVelocity");
    return super.carriedMomentum(existingVelocity);
  }
}
