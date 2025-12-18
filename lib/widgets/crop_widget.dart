import 'dart:io';
import 'package:flutter/material.dart';

class CropWidget extends StatefulWidget {
  final File imageFile;
  final Function(Rect) onCropChanged;

  const CropWidget({super.key, required this.imageFile, required this.onCropChanged});

  @override
  State<CropWidget> createState() => CropWidgetState();
}

class CropWidgetState extends State<CropWidget> {
  double _left = 0.1, _top = 0.1, _right = 0.9, _bottom = 0.9;
  double? _aspectRatio;
  Size _imageSize = Size.zero;
  Size _containerSize = Size.zero;
  Offset _imageOffset = Offset.zero;

  void setAspectRatio(double? ratio) {
    setState(() {
      _aspectRatio = ratio;
      if (ratio != null) {
        double w = _right - _left;
        double h = _bottom - _top;
        double currentRatio = (w * _imageSize.width) / (h * _imageSize.height);
        if (currentRatio > ratio) {
          double newW = h * _imageSize.height * ratio / _imageSize.width;
          double center = (_left + _right) / 2;
          _left = center - newW / 2;
          _right = center + newW / 2;
        } else {
          double newH = w * _imageSize.width / ratio / _imageSize.height;
          double center = (_top + _bottom) / 2;
          _top = center - newH / 2;
          _bottom = center + newH / 2;
        }
        _clampValues();
      }
    });
    _notifyChange();
  }

  void _clampValues() {
    _left = _left.clamp(0.0, 0.9);
    _right = _right.clamp(0.1, 1.0);
    _top = _top.clamp(0.0, 0.9);
    _bottom = _bottom.clamp(0.1, 1.0);
    if (_right - _left < 0.1) _right = _left + 0.1;
    if (_bottom - _top < 0.1) _bottom = _top + 0.1;
  }

  void _notifyChange() => widget.onCropChanged(Rect.fromLTRB(_left, _top, _right, _bottom));

  Offset _toImageCoords(Offset global, BuildContext context) {
    RenderBox box = context.findRenderObject() as RenderBox;
    Offset local = box.globalToLocal(global);
    return Offset(
      ((local.dx - _imageOffset.dx) / _containerSize.width).clamp(0.0, 1.0),
      ((local.dy - _imageOffset.dy) / _containerSize.height).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FutureBuilder<Size>(
          future: _getImageSize(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            _imageSize = snapshot.data!;
            
            double imageAspect = _imageSize.width / _imageSize.height;
            double containerAspect = constraints.maxWidth / constraints.maxHeight;
            
            if (imageAspect > containerAspect) {
              _containerSize = Size(constraints.maxWidth, constraints.maxWidth / imageAspect);
              _imageOffset = Offset(0, (constraints.maxHeight - _containerSize.height) / 2);
            } else {
              _containerSize = Size(constraints.maxHeight * imageAspect, constraints.maxHeight);
              _imageOffset = Offset((constraints.maxWidth - _containerSize.width) / 2, 0);
            }

            return Stack(
              children: [
                Positioned(
                  left: _imageOffset.dx,
                  top: _imageOffset.dy,
                  width: _containerSize.width,
                  height: _containerSize.height,
                  child: Image.file(widget.imageFile, fit: BoxFit.contain),
                ),
                Positioned(
                  left: _imageOffset.dx,
                  top: _imageOffset.dy,
                  width: _containerSize.width,
                  height: _containerSize.height,
                  child: CustomPaint(
                    painter: _CropPainter(Rect.fromLTRB(_left, _top, _right, _bottom)),
                    child: Stack(
                      children: [
                        _buildHandle(Alignment.topLeft, (d) { _left += d.dx; _top += d.dy; }),
                        _buildHandle(Alignment.topRight, (d) { _right += d.dx; _top += d.dy; }),
                        _buildHandle(Alignment.bottomLeft, (d) { _left += d.dx; _bottom += d.dy; }),
                        _buildHandle(Alignment.bottomRight, (d) { _right += d.dx; _bottom += d.dy; }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHandle(Alignment align, Function(Offset) onDrag) {
    return Align(
      alignment: Alignment(
        align.x < 0 ? -1 + _left * 2 + (align.x + 1) * (_right - _left) : -1 + _left * 2 + (align.x + 1) * (_right - _left),
        align.y < 0 ? -1 + _top * 2 + (align.y + 1) * (_bottom - _top) : -1 + _top * 2 + (align.y + 1) * (_bottom - _top),
      ),
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            Offset delta = Offset(
              details.delta.dx / _containerSize.width,
              details.delta.dy / _containerSize.height,
            );
            onDrag(delta);
            _clampValues();
            if (_aspectRatio != null) setAspectRatio(_aspectRatio);
          });
          _notifyChange();
        },
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.blue, width: 2),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
        ),
      ),
    );
  }

  Future<Size> _getImageSize() async {
    final bytes = await widget.imageFile.readAsBytes();
    final image = await decodeImageFromList(bytes);
    return Size(image.width.toDouble(), image.height.toDouble());
  }
}

class _CropPainter extends CustomPainter {
  final Rect cropRect;
  _CropPainter(this.cropRect);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;
    final rect = Rect.fromLTWH(cropRect.left * size.width, cropRect.top * size.height, 
                                (cropRect.right - cropRect.left) * size.width, 
                                (cropRect.bottom - cropRect.top) * size.height);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, rect.top), paint);
    canvas.drawRect(Rect.fromLTWH(0, rect.bottom, size.width, size.height - rect.bottom), paint);
    canvas.drawRect(Rect.fromLTWH(0, rect.top, rect.left, rect.height), paint);
    canvas.drawRect(Rect.fromLTWH(rect.right, rect.top, size.width - rect.right, rect.height), paint);
    
    final borderPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(rect, borderPaint);
    
    final gridPaint = Paint()..color = Colors.white54..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawLine(Offset(rect.left + rect.width / 3, rect.top), Offset(rect.left + rect.width / 3, rect.bottom), gridPaint);
    canvas.drawLine(Offset(rect.left + rect.width * 2 / 3, rect.top), Offset(rect.left + rect.width * 2 / 3, rect.bottom), gridPaint);
    canvas.drawLine(Offset(rect.left, rect.top + rect.height / 3), Offset(rect.right, rect.top + rect.height / 3), gridPaint);
    canvas.drawLine(Offset(rect.left, rect.top + rect.height * 2 / 3), Offset(rect.right, rect.top + rect.height * 2 / 3), gridPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
