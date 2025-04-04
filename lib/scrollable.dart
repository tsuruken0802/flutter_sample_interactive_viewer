import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ScrollableImage extends StatefulWidget {
  final String imagePath;
  final double maxScale;
  final double minScale;

  const ScrollableImage({
    super.key,
    required this.imagePath,
    this.maxScale = 5.0,
    this.minScale = 1.0,
  });

  @override
  State<ScrollableImage> createState() => _ScrollableImageState();
}

class _ScrollableImageState extends State<ScrollableImage> {
  final TransformationController _transformationController =
      TransformationController();
  final ScrollController _scrollController = ScrollController();
  bool _isZoomedIn = false;

  void _onTapped() {
    setState(() {
      _isZoomedIn = !_isZoomedIn;
      if (_isZoomedIn) {
        _transformationController.value = Matrix4.identity()..scale(2.0);
      } else {
        _transformationController.value = Matrix4.identity();
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Column(
      children: [
        Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              debugPrint('mouse scrolled ${event.scrollDelta}');
            }
          },
          onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
            debugPrint('trackpad scroll started');
          },
          onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
            debugPrint('trackpad scrolled ${event.panDelta}');
          },
          onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
            debugPrint('trackpad scroll ended');
          },
          child: SizedBox(
            width: screenWidth,
            height: screenWidth,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Image.asset(
                widget.imagePath,
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: _onTapped,
            child: Text(_isZoomedIn ? 'Zoom Out' : 'Zoom In'),
          ),
        ),
      ],
    );
  }
}
