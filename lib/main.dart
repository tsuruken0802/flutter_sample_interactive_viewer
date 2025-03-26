import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    // _transformationController.value = Matrix4.translationValues(
    //   -_childWidth / 2 + widget.size.width / 2,
    //   -_childHeight / 2 + widget.size.height / 2,
    //   0,
    // );
  }

  void _zoomIn() {
    // setState(() {
    //   _transformationController.value = _scaleMatrix(_scaleFactor);
    // });
  }

  void _zoomOut() {
    // setState(() {
    //   _transformationController.value = _scaleMatrix(1 / _scaleFactor);
    // });
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
              onPressed: _zoomIn,
              child: Text('Zoom In'),
            ),
            SizedBox(width: 20),
            ElevatedButton(
              onPressed: _zoomOut,
              child: Text('Zoom Out'),
            ),
          ],
        ),
      ],
    );
  }
}
