import 'dart:math' as math;

import 'package:flutter/material.dart';

class CustomInteractiveViewer extends StatefulWidget {
  final Widget child;
  final double maxScale;
  final double minScale;
  final Function(Matrix4)? onInteractionUpdate;
  final Function()? onInteractionEnd;

  const CustomInteractiveViewer({
    super.key,
    required this.child,
    this.maxScale = 5.0,
    this.minScale = 1.0,
    this.onInteractionUpdate,
    this.onInteractionEnd,
  });

  @override
  State<CustomInteractiveViewer> createState() =>
      _CustomInteractiveViewerState();
}

class _CustomInteractiveViewerState extends State<CustomInteractiveViewer> {
  final TransformationController _transformationController =
      TransformationController();
  late Matrix4 _currentMatrix;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _currentMatrix = Matrix4.identity();
    _transformationController.addListener(_onTransformationChanged);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    if (_isInteracting) {
      _currentMatrix = _transformationController.value;
      widget.onInteractionUpdate?.call(_currentMatrix);
    }
  }

  void _onInteractionStart(ScaleStartDetails details) {
    _isInteracting = true;
  }

  void _onInteractionUpdate(ScaleUpdateDetails details) {
    if (!_isInteracting) return;

    final newMatrix = _currentMatrix.clone();

    // Handle translation
    newMatrix.translate(details.focalPointDelta.dx, details.focalPointDelta.dy);

    // Handle scaling
    final scale = details.scale;
    final currentScale = _getCurrentScale(newMatrix);
    final newScale = currentScale * scale;

    if (newScale >= widget.minScale && newScale <= widget.maxScale) {
      final focalPoint = details.focalPoint;
      final focalPointScaled = _transformationController.toScene(focalPoint);

      newMatrix.translate(focalPointScaled.dx, focalPointScaled.dy);
      newMatrix.scale(scale);
      newMatrix.translate(-focalPointScaled.dx, -focalPointScaled.dy);
    }

    _transformationController.value = newMatrix;
  }

  void _onInteractionEnd(ScaleEndDetails details) {
    _isInteracting = false;
    widget.onInteractionEnd?.call();
  }

  double _getCurrentScale(Matrix4 matrix) {
    final values = matrix.storage;
    return math.sqrt(values[0] * values[0] + values[1] * values[1]);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onScaleStart: _onInteractionStart,
      onScaleUpdate: _onInteractionUpdate,
      onScaleEnd: _onInteractionEnd,
      child: Transform(
        transform: _transformationController.value,
        child: widget.child,
      ),
    );
  }
}
