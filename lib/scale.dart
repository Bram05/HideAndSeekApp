import 'dart:ffi' hide Size;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Map.dart';
import 'package:jetlag/Maths.dart';
import 'package:latlong2/latlong.dart';

class ScaleWidget extends StatefulWidget {
  const ScaleWidget({super.key});

  @override
  State<StatefulWidget> createState() => ScaleWidgetState();
}

class ScaleWidgetState extends State<ScaleWidget> {
  @override
  Widget build(BuildContext context) {
    MapCamera c = MapCamera.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          double lengthOfBar = 50;
          LatLng begin = c.screenOffsetToLatLng(
            Offset(0, constraints.maxHeight),
          );
          LatLng end = c.screenOffsetToLatLng(
            Offset(lengthOfBar, constraints.maxHeight),
          );
          double distance = maths.DistanceBetween(
            Struct.create()
              ..lat = begin.latitude
              ..lon = begin.longitude,
            Struct.create()
              ..lat = end.latitude
              ..lon = end.longitude,
          );
          return Align(
            alignment: Alignment.bottomLeft,
            child: Row(
              spacing: 10,
              children: [
                CustomPaint(
                  painter: ScalePainter(),
                  size: Size(lengthOfBar, 17),
                ),
                Text(
                  prettyDistance(distance),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class ScalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()..strokeWidth = 3;
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), p);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), p);
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
