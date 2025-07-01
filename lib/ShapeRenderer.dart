import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/shape.dart';
import 'dart:ui' as ui;
import 'package:latlong2/latlong.dart';

class Child extends StatefulWidget {
  Shape shape;
  Color color;
  Child({super.key, required this.shape, required this.color});
  @override
  State<Child> createState() => ChildState();
}

class MyClipper extends CustomClipper<ui.Path> {
  BuildContext context;
  Shape shape;
  MyClipper({required this.context, required this.shape});

  @override
  ui.Path getClip(Size size) {
    return shape.getPath(MapCamera.of(context), size);
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) {
    return true;
  }
}

class BorderPainter extends CustomPainter {
  BuildContext context;
  Shape shape;
  Color color;
  BorderPainter({
    required this.context,
    required this.shape,
    required this.color,
  });
  @override
  void paint(Canvas canvas, Size size) {
    ui.Paint p = ui.Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = color;
    canvas.drawPath(shape.getPath(MapCamera.of(context), size), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ChildState extends State<Child> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        MapCamera c = MapCamera.of(context);
        double width = constraints.maxWidth, height = constraints.maxHeight;
        double stop = 0.05;
        Offset o = c.latLngToScreenOffset(LatLng(stop, 0));
        Offset end = c.latLngToScreenOffset(LatLng(0, stop));
        Alignment topleft = Alignment(
          o.dx / width * 2 - 1,
          o.dy / height * 2 - 1,
        );
        Alignment bottomright = Alignment(
          end.dx / width * 2 - 1,
          end.dy / height * 2 - 1,
        );
        // return Container(
        //   width: width,
        //   height: height,
        //   child: CustomPaint(
        //     painter: BorderPainter(context: context, shape: widget.shape),
        //   ),
        //   color: Colors.white,
        // );

        return ClipPath(
          clipper: MyClipper(context: context, shape: widget.shape),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: topleft,
                end: bottomright,
                stops: [0.0, 0.5, 0.5, 1.0],
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
