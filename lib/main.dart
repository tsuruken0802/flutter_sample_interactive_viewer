import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sample_transformation/design_image_size_calculation_util.dart';
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
        appBar: AppBar(
          title: Text('InteractiveViewer Example'),
        ),
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) =>
                InteractiveViewerExample(size: constraints.biggest),
          ),
        ),
      ),
    );
  }
}

class InteractiveViewerExample extends StatefulWidget {
  const InteractiveViewerExample({super.key, required this.size});

  final Size size;

  @override
  _InteractiveViewerExampleState createState() =>
      _InteractiveViewerExampleState();
}

class _InteractiveViewerExampleState extends State<InteractiveViewerExample> {
  TransformationController? _transformationController;

  final imageName = 'yoko1.jpg';

  bool _isZoomedIn = false;
  // double imageWidth = 0;
  // double imageHeight = 0;
  ImageSizeResponse? imageSize;

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
  }

  void _onTapped() {
    if (_isZoomedIn) {
      _transformationController!.value = _scaleMatrix(1.5);
    } else {
      _transformationController!.value = _scaleMatrix(1.0);
    }
    setState(() {
      _isZoomedIn = !_isZoomedIn;
    });
  }

  Matrix4 _scaleMatrix(double scale) {
    // Create a matrix that scales around the center without changing the view position
    final Matrix4 matrix = Matrix4.identity();

    // Get the center point of the view
    final double centerX = 0.5;
    final double centerY = 0.5;

    // Translate to the center point
    matrix.translate(centerX, centerY);

    // Apply the scale
    matrix.scale(scale, scale);

    // Translate back from the center point
    matrix.translate(-centerX, -centerY);

    return matrix;
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
      imageSize = result;
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

  @override
  Widget build(BuildContext context) {
    final containerWidth = MediaQuery.of(context).size.width;
    final containerHeight = containerWidth;

    final imageRatio = imageSize?.closestRatio;
    if (imageRatio == null) {
      return FilledButton(
        onPressed: () async {
          final file = await bundleAssetsImageToFile();
          debugPrint(file.path);
        },
        child: Text('Save Image'),
      );
    }

    final isWide = imageRatio > 1.0;
    final isNarrow = imageRatio < 1.0;

    double imageWidth, imageHeight;
    if (isWide) {
      imageHeight = containerHeight / imageSize!.closestRatio;
      imageWidth = imageHeight * imageSize!.realRatio;
    } else if (isNarrow) {
      imageWidth = containerWidth / imageRatio;
      imageHeight = containerHeight;
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

    if (_transformationController == null) {
      _transformationController = TransformationController();
      _transformationController!.value =
          Matrix4.translationValues(horizontalPadding, verticalPadding, 0);
    }

    return Column(
      children: [
        SizedBox(
          width: containerWidth,
          height: containerHeight,
          child: Container(
            color: Colors.red.withAlpha(100),
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.symmetric(
                vertical: verticalPadding,
                horizontal: horizontalPadding,
              ),
              panAxis: PanAxis.free,
              // trackpadScrollCausesScale: true,
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 5,
              onInteractionStart: (details) {
                // print(details);
              },
              onInteractionEnd: (details) {
                // print(details);
              },
              constrained: false,
              child: Container(
                color: Colors.blue.withAlpha(100),
                width: imageWidth,
                height: imageHeight,
                child: Image.asset(
                  'assets/images/$imageName',
                  width: imageWidth,
                  height: imageHeight,
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
            FilledButton(
              onPressed: () async {
                final file = await bundleAssetsImageToFile();
                print(file);
              },
              child: Text('Save Image'),
            ),
            FilledButton(
              onPressed: () async {},
              child: Text('比率確認'),
            ),
          ],
        ),
      ],
    );
  }
}
