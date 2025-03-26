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

const _childWidth = 994.0;
const _childHeight = 408.0;

class _InteractiveViewerExampleState extends State<InteractiveViewerExample> {
  final TransformationController _transformationController =
      TransformationController();

  bool _isZoomedIn = false;

  Future<File> get _imageFile async {
    // Get temporary directory
    final Directory tempDir = await getApplicationDocumentsDirectory();
    // Create a file path in the temporary directory
    final String tempPath = '${tempDir.path}/image.png';
    return File(tempPath);
  }

  @override
  void initState() {
    super.initState();
    // _transformationController.value = Matrix4.translationValues(
    //   -_childWidth / 2 + widget.size.width / 2,
    //   -_childHeight / 2 + widget.size.height / 2,
    //   0,
    // );
  }

  void _onTapped() {
    setState(() {
      _isZoomedIn = !_isZoomedIn;
    });
  }

  // final image = AssetImage('assets/images/image.png');
  Future<File> bundleAssetsImageToFile() async {
    // Load the image from assets
    final ByteData data = await rootBundle.load('assets/images/image.png');

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
    final width = MediaQuery.of(context).size.width;
    final height = width;
    final verticalPadding = (height - _childHeight) / 2;
    return Column(
      children: [
        SizedBox(
          width: width,
          height: height,
          child: Container(
            color: Colors.red.withAlpha(100),
            child: InteractiveViewer(
              boundaryMargin: EdgeInsets.symmetric(vertical: verticalPadding),
              panAxis: PanAxis.free,
              // trackpadScrollCausesScale: true,
              transformationController: _transformationController,
              minScale: 0.1,
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
                width: _childWidth,
                height: _childHeight,
                child: Image.asset(
                  'assets/images/image.png',
                  width: _childWidth,
                  height: _childHeight,
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
            //     final file = await bundleAssetsImageToFile();
            //     print(file);
            //   },
            //   child: Text('Save Image'),
            // ),
            FilledButton(
              onPressed: () async {
                final ratio =
                    await ImageSizeCalculationUtil.getDesignImageRatio(
                  await _imageFile,
                );
                print(ratio);
              },
              child: Text('比率確認'),
            ),
          ],
        ),
      ],
    );
  }
}
