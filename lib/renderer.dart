import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/shape.dart';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';
import 'dart:ffi' hide Size;

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

class MyClipper extends CustomClipper<ui.Path> {
  BuildContext context;
  Pointer<Void> shape;
  MyClipper({required this.context, required this.shape});

  @override
  ui.Path getClip(Size size) {
    return getPath(shape, MapCamera.of(context), size);
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
  BorderPainter({
    required this.context,
    required this.shape,
    required this.color,
    required this.focussed,
  });
  @override
  void paint(Canvas canvas, Size size) {
    ui.Paint p = ui.Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = focussed ? 30.0 : 10
      ..color = color;
    canvas.drawPath(getPath(shape, MapCamera.of(context), size), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ShapeState extends State<Shape> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
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
          clipper: MyClipper(context: context, shape: widget.shape),
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
