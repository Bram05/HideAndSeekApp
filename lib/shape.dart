import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;

enum SideType { straight, circle }

abstract class Side {
  SideType sideType;
  Side(this.sideType);
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera);
}

class StraightEdge extends Side {
  StraightEdge() : super(SideType.straight);

  @override
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera) {
    ui.Offset endof = camera.latLngToScreenOffset(end);
    path.lineTo(endof.dx, endof.dy);
  }
}

const double epsilon = 0.00001;
bool close(double x, double y) {
  return (x - y).abs() < epsilon;
}

double calculateT(
  LatLng point,
  LatLng begin,
  LatLng end,
  bool compareLongitude,
) {
  if (compareLongitude) {
    return ((point.longitude - begin.longitude) /
        (end.longitude - begin.longitude));
  } else {
    return ((point.latitude - begin.latitude) /
        (end.latitude - begin.latitude));
  }
}

// If the point is very close to the end of one of the points we ignore it here.
// This is because we want to see it as the intersection of two lines moving away from this point
// Because we compare all sides pairwise this point will come up again later
bool liesBetween(double t) {
  if (close(t, 1)) return false;
  if (close(t, 0)) return true;
  return t >= 0 && t <= 1;
}

class IntersectionPoint {
  LatLng point;
  double tInSide1, tInSide2;
  IntersectionPoint({
    required this.point,
    required this.tInSide1,
    required this.tInSide2,
  });
}

List<IntersectionPoint> intersectConstantWithNonConstant(
  LatLng begin1,
  LatLng end1,
  LatLng begin2,
  LatLng end2,
) {
  if (!close(begin1.latitude, end1.latitude) ||
      close(begin2.latitude, end2.latitude)) {
    throw Exception(
      "intersectConstantWithNonConstant needs the first two points to have the same latitude (that is the constant line) and the second two cannot have the same latitude (the non-constant line)",
    );
  }
  // y = ax+b
  // x = latitude
  // y = longitude
  double a =
      (end2.longitude - begin2.longitude) / (end2.latitude - begin2.latitude);
  double b = begin2.longitude - a * begin2.latitude;

  // A vertical and non-vertical line will always intersect in a single point
  LatLng intersection = LatLng(begin1.latitude, a * begin1.latitude + b);
  double t1 = calculateT(intersection, begin1, end1, true);
  double t2 = calculateT(intersection, begin2, end2, false);
  if (liesBetween(t1) && liesBetween(t2)) {
    return [IntersectionPoint(point: intersection, tInSide1: t1, tInSide2: t2)];
  }
  return [];
}

List<IntersectionPoint> intersectStraights(
  LatLng begin1,
  LatLng end1,
  LatLng begin2,
  LatLng end2,
) {
  if (close(begin1.latitude, end1.latitude)) {
    if (close(begin2.latitude, end2.latitude)) {
      if (!close(begin1.latitude, begin2.latitude)) {
        return [];
      }
      // Both lines have constant latitude
      // Check if one they intersect anywhere
      LatLng begin1copy = begin1,
          begin2copy = begin2,
          end1copy = end1,
          end2copy = end2;
      if (begin1.longitude > end1.longitude) (begin1, end1) = (end1, begin1);
      if (begin2.longitude > end2.longitude) (begin2, end2) = (end2, begin2);

      double lower = math.max(begin1.longitude, begin2.longitude);
      double upper = math.min(end1.longitude, end2.longitude);
      List<LatLng> intersects;
      if (close(upper, lower)) {
        intersects = [LatLng(begin1.latitude, lower)];
      } else if (lower < upper) {
        intersects = [
          // This is kindof unneceassry because we only add the point at both beginnings anyways
          LatLng(begin1.latitude, lower),
          LatLng(begin1.latitude, upper),
        ];
      } else {
        intersects = [];
      }
      List<IntersectionPoint> finalIntersects = [];
      for (LatLng point in intersects) {
        double t1 = calculateT(point, begin1copy, end1copy, true);
        double t2 = calculateT(point, begin2copy, end2copy, true);
        if (liesBetween(t1) && liesBetween(t2)) {
          finalIntersects.add(
            IntersectionPoint(point: point, tInSide1: t1, tInSide2: t2),
          ); // Both lines are vertical so we explicitly choose points that lie at the edge
        }
      }
      return finalIntersects;
    }
    return intersectConstantWithNonConstant(begin1, end1, begin2, end2);
  }
  if (close(begin2.latitude, end2.latitude)) {
    List<IntersectionPoint> result = intersectConstantWithNonConstant(
      begin2,
      end2,
      begin1,
      end1,
    );
    for (IntersectionPoint p in result) {
      double temp = p.tInSide1;
      p.tInSide1 = p.tInSide2;
      p.tInSide2 = temp;
    }
    return result;
  }

  // y = ax+b
  // x = latitude
  // y = longitude
  double a1 =
      (end1.longitude - begin1.longitude) / (end1.latitude - begin1.latitude);
  double a2 =
      (end2.longitude - begin2.longitude) / (end2.latitude - begin2.latitude);
  double b1 = begin1.longitude - a1 * begin1.latitude;
  double b2 = begin2.longitude - a2 * begin2.latitude;
  List<LatLng> intersections;
  if (close(a1, a2)) {
    if (close(b1, b2)) {
      // The lines coincide
      double lower = math.max(begin1.latitude, begin2.latitude);
      double upper = math.min(end1.latitude, end2.latitude);
      if (close(lower, upper)) {
        intersections = [LatLng(upper, a1 * upper + b1)];
      } else if (lower < upper) {
        intersections = [
          LatLng(lower, a1 * lower + b1),
          LatLng(upper, a1 * upper + b1),
        ];
      } else {
        intersections = [];
      }
    } else {
      // The lines are parallel
      intersections = [];
    }
  } else {
    // a1x+b1 = a2x + b2
    double latitude = (b2 - b1) / (a1 - a2);
    intersections = [LatLng(latitude, a1 * latitude + b1)];
  }
  List<IntersectionPoint> finalIntersections = [];
  for (LatLng point in intersections) {
    double t1 = calculateT(point, begin1, end1, false);
    double t2 = calculateT(point, begin2, end2, false);
    if (liesBetween(t1) && liesBetween(t2)) {
      finalIntersections.add(
        IntersectionPoint(point: point, tInSide1: t1, tInSide2: t2),
      );
    }
  }
  return finalIntersections;
}

List<IntersectionPoint> intersectSides(
  Side s1,
  Side s2,
  LatLng begin1,
  LatLng end1,
  LatLng begin2,
  LatLng end2,
) {
  if (s1.sideType == SideType.straight && s2.sideType == SideType.straight) {
    return intersectStraights(begin1, end1, begin2, end2);
  }
  throw UnimplementedError("Cannot intersect circles yet");
}

class IntersectionData {
  LatLng point;
  (int, int) indexInS1;
  (int, int) indexInS2;
  IntersectionData({
    required this.point,
    required this.indexInS1,
    required this.indexInS2,
  });

  @override
  String toString() {
    return "pos: $point, indexInS1: $indexInS1, indexInS2: $indexInS2";
  }
}

class IntersectionOnLine {
  LatLng point;
  double t;
  IntersectionOnLine({required this.point, required this.t});

  @override
  String toString() {
    return "point: $point, t: $t \n";
  }
}

void addBeginAndEnds(
  Map<(bool, int, int), List<IntersectionOnLine>> map,
  Shape s,
  bool first,
) {
  for (int i = 0; i < s.segments.length; i++) {
    Segment seg = s.segments[i];
    for (int j = 0; j < seg.vertices.length; j++) {
      map[(first, i, j)] = [
        IntersectionOnLine(point: seg.vertices[j], t: 0),
        IntersectionOnLine(
          point: seg.vertices[(j + 1) % seg.vertices.length],
          t: 1,
        ),
      ];
    }
  }
}

(List<IntersectionData>, Map<(bool, int, int), List<IntersectionOnLine>>)
intersectionPoints(Shape s1, Shape s2) {
  List<IntersectionData> intersections = [];
  Map<(bool, int, int), List<IntersectionOnLine>> intersectionsPerSide = {};
  addBeginAndEnds(intersectionsPerSide, s1, true);
  addBeginAndEnds(intersectionsPerSide, s2, false);
  for (int seg1Index = 0; seg1Index < s1.segments.length; seg1Index++) {
    Segment segment1 = s1.segments[seg1Index];
    for (
      int side1Index = 0;
      side1Index < s1.segments[seg1Index].sides.length;
      side1Index++
    ) {
      Side side1 = segment1.sides[side1Index];

      for (int seg2Index = 0; seg2Index < s2.segments.length; seg2Index++) {
        Segment segment2 = s2.segments[seg2Index];

        for (
          int side2Index = 0;
          side2Index < s2.segments[seg2Index].sides.length;
          side2Index++
        ) {
          Side side2 = segment2.sides[side2Index];

          LatLng begin1 = segment1.vertices[side1Index];
          LatLng end1 =
              segment1.vertices[(side1Index + 1) % segment1.vertices.length];
          LatLng begin2 = segment2.vertices[side2Index];
          LatLng end2 =
              segment2.vertices[(side2Index + 1) % segment2.vertices.length];

          List<IntersectionPoint> currentIntersections = intersectSides(
            s1.segments[seg1Index].sides[side1Index],
            s2.segments[seg2Index].sides[side2Index],
            begin1,
            end1,
            begin2,
            end2,
          );
          for (IntersectionPoint point in currentIntersections) {
            if (close(point.tInSide1, 0) || close(point.tInSide2, 0)) {
              print(
                "Cannot have an intersection close to a starting point yet. Later: Check if one of the points is 'inside' the other polygon",
              );

              // throw UnimplementedError(
              //   "Cannot have an intersection close to a starting point yet. Later: Check if one of the points is 'inside' the other polygon",
              // );
            }
            intersections.add(
              IntersectionData(
                point: point.point,
                indexInS1: (seg1Index, side1Index),
                indexInS2: (seg2Index, side2Index),
              ),
            );
            intersectionsPerSide[(true, seg1Index, side1Index)]!.add(
              IntersectionOnLine(point: point.point, t: point.tInSide1),
            );
            intersectionsPerSide[(false, seg2Index, side2Index)]!.add(
              IntersectionOnLine(point: point.point, t: point.tInSide2),
            );
            print(
              "Adding intersection ${point.point} from segments 1index: $side1Index and 2index: $side2Index",
            );
          }
        }
      }
    }
  }
  intersectionsPerSide.forEach(
    (k, list) => list.sort((a, b) => a.t.compareTo(b.t)),
  );
  return (intersections, intersectionsPerSide);
}

double det(LatLng p1, LatLng p2) {
  return p1.longitude * p2.latitude - p1.latitude * p2.longitude;
}

class CurrentPoint {
  LatLng point;
  bool isFirstShape;
  (int, int) indices;

  CurrentPoint({
    required this.point,
    required this.isFirstShape,
    required this.indices,
  });
}

void setNextPoint(
  Map<(bool, int, int), List<IntersectionOnLine>> intersectionsPerLine,
  CurrentPoint currentPoint,
  Shape s1,
  Shape s2,
) {
  List<IntersectionOnLine> currentLine =
      intersectionsPerLine[(
        currentPoint.isFirstShape,
        currentPoint.indices.$1,
        currentPoint.indices.$2,
      )]!;
  int index = currentLine.indexWhere(
    (point) => currentPoint.point == point.point,
  );
  Segment segment =
      (currentPoint.isFirstShape ? s1 : s2).segments[currentPoint.indices.$1];

  if (index == currentLine.length - 1) {
    currentPoint.indices = (
      currentPoint.indices.$1,
      (currentPoint.indices.$2 + 1) % segment.vertices.length,
    );
    currentPoint.point = segment.vertices[currentPoint.indices.$2];
  } else {
    currentPoint.point = currentLine[index + 1].point;
  }
}

Shape intersect(Shape s1, Shape s2) {
  var (intersections, intersectionsPerLine) = intersectionPoints(s1, s2);
  Map<LatLng, ((int, int), (int, int))> intersectionsTotal = {};
  Set<LatLng> intersectionsLeft = {};
  for (IntersectionData data in intersections) {
    intersectionsTotal[data.point] = (data.indexInS1, data.indexInS2);
    intersectionsTotal[data.point] = (data.indexInS1, data.indexInS2);

    intersectionsLeft.add(data.point);
  }

  Shape result = Shape(segments: []);
  while (intersectionsLeft.isNotEmpty) {
    LatLng startPoint = intersectionsLeft.first;
    CurrentPoint currentPoint = CurrentPoint(
      point: startPoint,
      isFirstShape: false,
      indices: (-1, -1),
    );
    // LatLng currentPoint = startPoint;
    // (int, int) currentIndex = (-1, -1);
    // bool inShape1 = false;
    Segment newSegment = Segment(vertices: [currentPoint.point], sides: []);
    do {
      print(
        "current point = ${currentPoint.point} and start point = $startPoint",
      );
      if (intersectionsTotal[currentPoint.point] != null) {
        intersectionsLeft.remove(currentPoint.point);
        var indices = intersectionsTotal[currentPoint.point]!;
        var vertices1 = s1.segments[indices.$1.$1].vertices;
        var vertices2 = s2.segments[indices.$2.$1].vertices;
        LatLng endAlongS1 = vertices1[(indices.$1.$2 + 1) % vertices1.length];
        LatLng endAlongS2 = vertices2[(indices.$2.$2 + 1) % vertices2.length];
        LatLng delta1 = LatLng(
          endAlongS1.latitude - currentPoint.point.latitude,
          endAlongS1.longitude - currentPoint.point.longitude,
        );
        LatLng delta2 = LatLng(
          endAlongS2.latitude - currentPoint.point.latitude,
          endAlongS2.longitude - currentPoint.point.longitude,
        );
        if (det(delta2, delta1) > 0) {
          // continue along shape 1
          // currentPoint = vertices1[(indices.$1.$2 + 1) % vertices1.length];
          // currentPoint =
          currentPoint.isFirstShape = true;
          currentPoint.indices = (indices.$1.$1, indices.$1.$2);
          setNextPoint(intersectionsPerLine, currentPoint, s1, s2);
          newSegment.sides.add(
            s1.segments[indices.$1.$1].sides[currentPoint
                .indices
                .$2], // see below
          );
        } else {
          currentPoint.isFirstShape = false;
          currentPoint.indices = (indices.$2.$1, indices.$2.$2);
          setNextPoint(intersectionsPerLine, currentPoint, s1, s2);
          newSegment.sides.add(
            s2.segments[indices.$2.$1].sides[currentPoint
                .indices
                .$2], // When adding circles: make change the side a bit to only contain part of the circle arc
          );
        }
        // newSegment.sides.add(StraightEdge());
        // print("adding side");
        newSegment.vertices.add(currentPoint.point);
      } else {
        setNextPoint(intersectionsPerLine, currentPoint, s1, s2);
        // if () {
        //   segment = s1.segments[currentIndex.$1];
        // } else {
        //   segment = s2.segments[currentIndex.$1];
        // }
        // currentPoint =
        //     segment.vertices[(currentIndex.$2 + 1) % segment.vertices.length];
        // currentIndex = (
        //   currentIndex.$1,
        //   (currentIndex.$2 + 1) % segment.vertices.length,
        // );
        newSegment.vertices.add(currentPoint.point);
        Segment segment = (currentPoint.isFirstShape ? s1 : s2)
            .segments[currentPoint.indices.$1];
        newSegment.sides.add(segment.sides[currentPoint.indices.$2]);
        print("adding vertex");
      }
    } while (currentPoint.point != startPoint);
    newSegment.vertices
        .removeLast(); // We always add the start vertex again at the very end
    print("length is");
    print(newSegment.sides.length);
    result.segments.add(newSegment);
  }

  return result;
}

class CircleEdge extends Side {
  LatLng center;
  double radius, startAngle, sweepAngle; // radius in metres

  CircleEdge({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
  }) : super(SideType.circle);

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

  bool hit(LatLng pos, MapCamera camera, Size containerSize) {
    return getPath(
      camera,
      containerSize,
    ).contains(camera.latLngToScreenOffset(pos));
  }
}
