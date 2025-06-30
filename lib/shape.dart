import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

abstract class Side {
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera);
}

class StraightEdge extends Side {
  StraightEdge();

  @override
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera) {
    ui.Offset endof = camera.latLngToScreenOffset(end);
    path.lineTo(endof.dx, endof.dy);
  }
}

class CircleEdge extends Side {
  LatLng center;
  double radius, startAngle, sweepAngle; // radius in metres

  CircleEdge({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera) {
    const double circumferenceEarthAroundEquator = 40075017; // metres
    const double circumferenceEarthAroundPoles = 40007863; // metres
    double radiusInLongitude =
        2 * radius / circumferenceEarthAroundEquator * 360;
    double radiusInLatitude = 2 * radius / circumferenceEarthAroundPoles * 180;
    ui.Offset bottomLeft = camera.latLngToScreenOffset(
      LatLng(
        center.latitude - radiusInLatitude,
        center.longitude - radiusInLongitude,
      ),
    );
    ui.Offset topRight = camera.latLngToScreenOffset(
      LatLng(
        center.latitude + radiusInLatitude,
        center.longitude + radiusInLongitude,
      ),
    );
    ui.Rect oval = ui.Rect.fromLTRB(
      bottomLeft.dx,
      topRight.dy,
      topRight.dx,
      bottomLeft.dy,
    );

    // todo: maybe create a path.linto the beginning of the arc
    // This shouldn't actually matter in a normal shape though
    // sweepangle doesn't really work yet
    // We need an extra path because methods like arcto create a new sub-path thereby not connecting the entire boundary.
    // In this way we can do it
    ui.Path extra = ui.Path();
    extra.arcTo(oval, startAngle, -sweepAngle, true);
    path.extendWithPath(extra, Offset(0, 0));
  }
}

class Segment {
  List<LatLng> vertices;
  List<Side> sides;

  Segment({required this.vertices, required this.sides});
}

class Shape {
  List<Segment> segments;

  // For every edge the inside of the shape should be on the left of the given edge (begin -> end)
  // See also PathFillType.nonZero
  // This is useful for calculating intersections
  Shape({required this.segments});

  ui.Path getPath(MapCamera camera, Size containerSize) {
    // We need this because rotating the circles doesn't work as we have to provide the bounding rectangle, which should also rotate. Therefore we calculate without rotation and then rotate everything at the end
    MapCamera cameraWithoutRotation = camera.withRotation(0);
    if (segments.isEmpty) {
      return ui.Path();
    }
    ui.Path path = ui.Path();
    path.fillType = PathFillType.nonZero;
    for (Segment s in segments) {
      ui.Offset begin = cameraWithoutRotation.latLngToScreenOffset(
        s.vertices[0],
      );
      path.moveTo(begin.dx, begin.dy);

      for (int i = 0; i < s.sides.length; i++) {
        s.sides[i].extendPath(
          path,
          s.vertices[i],
          s.vertices[(i + 1) % s.vertices.length],
          cameraWithoutRotation,
        );
      }
      path.close();
    }
    double angle = camera.rotationRad;
    Matrix4 trans = Matrix4.translationValues(
      -containerSize.width / 2,
      -containerSize.height / 2,
      0,
    );
    Matrix4 reversetrans = Matrix4.translationValues(
      containerSize.width / 2,
      containerSize.height / 2,
      0,
    );
    Matrix4 rotMatrix = Matrix4.rotationZ(angle);
    Matrix4 matrix = reversetrans * rotMatrix * trans;
    return path.transform(matrix.storage);
  }
}
