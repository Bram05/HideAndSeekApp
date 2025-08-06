import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/shape.dart';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';
import 'dart:ffi' hide Size;

import 'package:vector_math/vector_math_64.dart' hide Colors;

class Shape extends StatefulWidget {
  final Pointer<Void> shape;
  final Color color;
  final bool focussed;
  const Shape({
    super.key,
    required this.shape,
    required this.color,
    required this.focussed,
  });
  @override
  State<Shape> createState() => ShapeState();
}

ui.Path transform(
  MapCamera camera,
  ui.Path path,
  ui.Size size,
  bool addBorder,
) {
  var center = camera.center;
  ui.Offset offset = camera.latLngToScreenOffset(center);
  ui.Offset original = camera.latLngToScreenOffset(LatLng(0, 0));
  Matrix4 matrix =
      Matrix4.translation(
        Vector3(original.dx - offset.dx, original.dy - offset.dy, 0),
      ) *
      Matrix4.translationValues(size.width / 2, size.height / 2, 0) *
      Matrix4.rotationZ(camera.rotationRad) *
      Matrix4.translationValues(-size.width / 2, -size.height / 2, 0);
  // Matrix4.diagonal3(Vector3(1, 1, 1) * camera.getZoomScale(camera.zoom, 1));

  ui.Path result = path.transform(matrix.storage);
  if (addBorder) result.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
  return result;
}

class MyClipper extends CustomClipper<ui.Path> {
  BuildContext context;
  Pointer<Void> shape;
  ui.Path path;
  MyClipper({required this.context, required this.shape, required this.path});

  @override
  ui.Path getClip(Size size) {
    ui.Path p = transform(MapCamera.of(context), path, size, true);
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) {
    return true;
  }
}

class BorderPainter extends CustomPainter {
  BuildContext context;
  Pointer<Void> shape;
  Color color;
  bool focussed;
  ui.Path path;
  BorderPainter({
    required this.context,
    required this.shape,
    required this.color,
    required this.focussed,
    required this.path,
  });
  @override
  void paint(Canvas canvas, Size size) {
    ui.Paint p = ui.Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = focussed ? 20.0 : 10
      ..color = color;
    // canvas.drawPath(getPath(shape, MapCamera.of(context), size), p);
    canvas.drawPath(transform(MapCamera.of(context), path, size, false), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ShapeState extends State<Shape> {
  ui.Path? path;
  double prevzoom = -1;
  Pointer<Void> prevShape = nullptr;
  ui.Size prevSize = ui.Size(0, 0);

  @override
  Widget build(BuildContext context) {
    // size is not used currently inside the getpath
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        if (path == null ||
            (MapCamera.of(context).zoom - prevzoom).abs() > epsilon ||
            prevShape != widget.shape ||
            prevSize != size) {
          var baseCamera = MapCamera.of(
            context,
          ).withRotation(0).withPosition(center: LatLng(0, 0));
          path = getPath(widget.shape, baseCamera, ui.Size(0, 0));
          prevzoom = MapCamera.of(context).zoom;
          prevShape = widget.shape;
          prevSize = size;
        }
        MapCamera c = MapCamera.of(context);
        double width = constraints.maxWidth, height = constraints.maxHeight;
        double deltaPixels = 30;
        Offset o = c.latLngToScreenOffset(LatLng(0, 0));
        Offset end = o + Offset(deltaPixels, deltaPixels);
        Alignment topleft = Alignment(
          o.dx / width * 2 - 1,
          o.dy / height * 2 - 1,
        );
        Alignment bottomright = Alignment(
          end.dx / width * 2 - 1,
          end.dy / height * 2 - 1,
        );

        return ClipPath(
          clipper: MyClipper(
            context: context,
            shape: widget.shape,
            path: path!,
          ),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: topleft,
                end: bottomright,
                stops: [0.0, 0.4, 0.4, 1.0],
                colors: [
                  widget.color,
                  widget.color,
                  Colors.transparent,
                  Colors.transparent,
                ],
                tileMode: TileMode.repeated,
              ),
            ),
            child: CustomPaint(
              painter: BorderPainter(
                context: context,
                shape: widget.shape,
                color: widget.color,
                focussed: widget.focussed,
                path: path!,
              ),
            ),
          ),
          //   ),
          //   CustomPaint(painter: BorderPainter(context: context)),
          // ],
        );
      },
    );
  }
}
