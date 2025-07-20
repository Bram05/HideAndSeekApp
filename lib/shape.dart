import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Plane.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'package:jetlag/constants.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;

enum SideType { straight, circle }

SideType getSideTypeFromString(String s) {
  for (SideType type in SideType.values) {
    if (type.name == s) return type;
  }
  throw Exception("String $s is not the name of a sidetype");
}

abstract class Side {
  SideType sideType;
  bool isInfinite = false;
  // todo: begin and end?
  Side(this.sideType);

  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera);
  @override
  bool operator ==(Object other) {
    if (other is! Side) return false;
    return equalsImpl(other);
  }

  bool equalsImpl(Side other) {
    return true;
  }

  Vector3 getProperCentre();

  Vector3 getTangent(Vector3 begin, Vector3 end, Vector3 point) {
    Plane p = getPlane(begin, end);
    Vector3 centre = getProperCentre();
    Vector3 cross = Vector3(0, 0, 0);
    cross3((centre - point), p.getNormal(), cross);
    return cross.normalized();
  }

  Plane getPlane(Vector3 begin, Vector3 end);

  factory Side.fromJson(Map<String, dynamic> json) {
    switch (getSideTypeFromString(json['type'])) {
      case SideType.straight:
        return StraightEdge();
      case SideType.circle:
        return CircleEdge.fromJson(json);
    }
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = {};
    output["type"] = sideType.name;
    Map<String, dynamic> sub = toJsonImpl();
    sub.forEach((name, data) {
      if (name == "type") {
        throw Exception(
          "Json value in a SideType cannot have name 'type' because that is reserved for the base class",
        );
      }
      output[name] = data;
    });

    return output;
  }

  Map<String, dynamic> toJsonImpl() {
    return {};
  }
}

class StraightEdge extends Side {
  // todo: store plane?
  StraightEdge() : super(SideType.straight);

  @override
  Plane getPlane(Vector3 begin, Vector3 end) {
    return Plane.fromTwoPointsAndOrigin(begin, end);
  }

  @override
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera) {
    ui.Offset endof = camera.latLngToScreenOffset(end);
    path.lineTo(endof.dx, endof.dy);
  }

  @override
  Vector3 getProperCentre() {
    return Vector3(0, 0, 0);
  }
}

const double epsilon = 0.00000001;
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

double det(LatLng p1, LatLng p2) {
  return p1.longitude * p2.latitude - p1.latitude * p2.longitude;
}

class IntersectionPoint {
  Vector3 point;
  double distAlong1, distAlong2;
  IntersectionPoint({
    required this.point,
    required this.distAlong1,
    required this.distAlong2,
  });

  @override
  String toString() {
    return "$point with tinSide1: $distAlong1, tinside2: $distAlong2";
  }
}

Plane getPlaneForSide(Side s, Vector3 begin, Vector3 end) {
  switch (s.sideType) {
    case SideType.straight:
      return Plane.fromTwoPointsAndOrigin(begin, end);
    case SideType.circle:
      return (s as CircleEdge).plane;
  }
}

Vector3 normalize(Vector3 v) {
  // We must compare with the zero vector and not compare its length to 0 because that leads to precision errors
  if (vec3Close(v, Vector3(0, 0, 0))) return Vector3(0, 0, 0);
  return v.normalized();
}

Vector3 normalizedCrossProduct(Vector3 a, Vector3 b) {
  Vector3 result = Vector3(0, 0, 0);
  cross3(normalize(a), normalize(b), result);
  return normalize(result);
}

bool vec3LiesBetween(
  Vector3 point,
  Vector3 begin,
  Vector3 end,
  Plane plane,
  Vector3 centre,
  bool isFirst,
) {
  assert(plane.liesInside(point));
  assert(plane.liesInside(begin));
  assert(plane.liesInside(end));
  assert(plane.liesInside(centre));
  if (vec3Close(point, begin)) return true;
  if (vec3Close(point, end)) return false; // this is handled by the next side
  // Vector3 delta1 = point - begin;
  // Vector3 delta2 = end - begin;
  Vector3 delta1 = begin - centre;
  Vector3 delta2 = point - centre;
  Vector3 delta3 = end - centre;
  // print('delta1: $delta1');
  // print('delta2: $delta2');
  // print('delta3: $delta3');
  Vector3 cross1 = normalizedCrossProduct(delta1, delta2);
  Vector3 cross2 = normalizedCrossProduct(delta2, delta3);
  // Vector3 test = normalizedCrossProduct(delta1, delta3);
  // Vector3 cross2 = Vector3(0, 0, 0);
  // cross3(delta2, delta3, cross2);
  // cross2.normalize();
  // Vector3 cross3v = Vector3(0, 0, 0);
  // cross3(delta1, delta3, cross3v);
  // if (close(cross3v.length2, 0)) {
  //   cross3v =
  // }
  // cross3v.normalize();
  // print("normal:  ${plane.getNormal()}, cross1: ${cross1}, cross2: ${cross2}");
  // print('centre: $centre');
  // print('test: $test');
  if (vec3Close(cross1, plane.getNormal()) &&
      vec3Close(cross2, plane.getNormal())) {
    return true;
  }
  return false;
  // Vector3 normal = plane.getNormal().normalized();
  // print("Result was: normal = $normal and cross = $cross");
  // if (!vec3Close(normal, cross) && !vec3Close(-normal, cross)) {
  //   print("isfirst: $isFirst");
  //   print("errororor");
  //   print("normal: $normal");
  //   print("d1: $delta1");
  //   print("d2: $delta2");
  //   print("cross: $cross");
  //   print("dot: ${dot3(cross, delta1)}");
  //   print("dot: ${dot3(cross, delta2)}");
  //   print("dot: ${dot3(normal, delta1)}");
  //   print("dot: ${dot3(normal, delta2)}");
  // }
  // return vec3Close(normal, cross);
}

List<IntersectionPoint> intersectSides(
  Side s1,
  Side s2,
  Vector3 begin1,
  Vector3 end1,
  Vector3 begin2,
  Vector3 end2,
) {
  Plane p1 = getPlaneForSide(s1, begin1, end1);
  Plane p2 = getPlaneForSide(s2, begin2, end2);
  var (type, intersections) = p1.intersectOnEarth(p2);
  switch (type) {
    case IntersectionType.parallel:
      return [];
    case IntersectionType.coincide:
      intersections = [begin1, end1, begin2, end2];
    default:
  }
  return intersections.fold<List<IntersectionPoint>>([], (
    result,
    intersection,
  ) {
    bool first =
        /* s1.isInfinite ||  */ vec3LiesBetween(
          intersection,
          begin1,
          end1,
          p1,
          s1.getProperCentre(),
          true,
        );
    bool second =
        /* s2.isInfinite ||  */ vec3LiesBetween(
          intersection,
          begin2,
          end2,
          p2,
          s2.getProperCentre(),
          false,
        );
    // second = true;
    // first = true;
    if (!first || !second) {
      // print(intersection);
      // print(
      //   "Ignoring intersection ${vec3ToLatLng(intersection)} becuase it does not lie between the others (first = $first, second = $second)",
      // );
      return result;
    }
    result.add(
      IntersectionPoint(
        point: intersection,
        distAlong1: getDistanceAlongSphere(intersection, begin1),
        distAlong2: getDistanceAlongSphere(intersection, begin2),
      ),
    );
    return result;
  });
}

class IntersectionData {
  Vector3 point;
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
  Vector3 point;
  double distanceAlong;
  IntersectionOnLine({required this.point, required this.distanceAlong});

  @override
  String toString() {
    return "point: $point, t: $distanceAlong \n";
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
      Vector3 begin = seg.vertices[j];
      Vector3 end = seg.vertices[(j + 1) % seg.vertices.length];
      map[(first, i, j)] = [
        IntersectionOnLine(point: begin, distanceAlong: 0),
        IntersectionOnLine(
          point: end,
          distanceAlong: getDistanceAlongSphere(begin, end),
        ),
      ];
    }
  }
}

// todo:
double getAngle(Vector2 x) {
  Offset o = Offset(x.x, -x.y); // - because it uses the wrong axis
  double val = -o.direction;
  return val;
}

bool compareLessThan(double a, double b, bool mayBeEqual) {
  if (close(a, b)) {
    return mayBeEqual;
  }
  return a < b;
}

bool vec2LiesBetween(
  Vector2 vector1,
  Vector2 vector2,
  Vector2 other,
  bool isOutward,
  bool isForHit,
) {
  double a1 = getAngle(vector1);
  double a2 = getAngle(vector2) - a1;
  double ao = getAngle(other) - a1;
  // return (ao > 0 || (isOutward && !isForHit && close(ao, 0))) &&
  //     (ao < a2 || (!isOutward && !isForHit && close(ao, a2)));
  return compareLessThan(0, ao, isOutward && !isForHit) &&
      compareLessThan(ao, a2, !isOutward && !isForHit);

  // double det1 = det(vector1, other);
  // double det2 = det(other, vector2);
  // The outward vector can only overlap with the first and not with the second
  // If it overlaps with the second then its inside is to the left of the second, thereby outside the other
  //
  // return (det1 > 0 || (isOutward && close(det1, 0))) &&
  //     (det2 > 0 || (!isOutward && close(det2, 0)));
}

bool vectorLiesBetween(
  Vector3 vector1,
  Vector3 vector2,
  Vector3 other,
  Vector3 point,
  bool isOutward,
  bool isForHit,
) {
  // Vector3 cross = Vector3(0, 0, 0);
  // cross3(vector1, vector2, cross);
  Vector3 cross = normalizedCrossProduct(vector1, vector2);
  if (close(cross.length2, 0)) {
    // vectors are dependant
    // if (isOutward) return false; // We want to check if it is to the left of this line and this side
    Vector3 otherCross = normalizedCrossProduct(vector1, other);
    if (vec3Close(otherCross, point)) {
      return true;
    }
    assert(
      vec3Close(otherCross, -point) || close(otherCross.length2, 0),
      "othercross = $otherCross and point = $point",
    );
    return false;
  }
  Matrix3 transformation = Matrix3.columns(vector1, vector2, cross);
  transformation.invert();
  Vector3 transformed = transformation * other;
  if (!close(transformed.z, 0)) {
    throw Exception("Transformed z was not close to zero: $transformed");
  }
  Vector2 otherAs2 = Vector2(transformed.x, transformed.y);
  Vector2 vector1As2 = Vector2(1, 0);
  Vector2 vector2As2 = Vector2(0, 1);
  return vec2LiesBetween(vector1As2, vector2As2, otherAs2, isOutward, isForHit);
}

(Vector3, Vector3) getoutwardVectors(
  Shape s,
  int segmentIndex,
  int sideIndex,
  bool atStart,
  Vector3 centre,
) {
  Segment seg = s.segments[segmentIndex];
  Vector3 outward = seg.sides[sideIndex].getTangent(
    seg.vertices[sideIndex],
    seg.vertices[(sideIndex + 1) % seg.vertices.length],
    centre,
  );

  Vector3 reverseInward = atStart
      ? -seg.sides[(sideIndex - 1) % seg.sides.length].getTangent(
          seg.vertices[(sideIndex - 1) % seg.vertices.length],
          seg.vertices[sideIndex],
          centre,
        )
      : -outward;

  return (outward, reverseInward);
  // Vector3 endOfOutwardVector =
  //     seg.vertices[(sideIndex + 1) % seg.vertices.length];
  // Vector3 beginOfInwardVector = atStart
  //     ? seg.vertices[(sideIndex - 1) % seg.vertices.length]
  //     : seg.vertices[sideIndex];
  // LatLng v1 = LatLng(
  //   (endOfOutwardVector.latitude - centre.latitude),
  //   (endOfOutwardVector.longitude - centre.longitude),
  // );
  // LatLng v2 = LatLng(
  //   (beginOfInwardVector.latitude - centre.latitude),
  //   (beginOfInwardVector.longitude - centre.longitude),
  // );
  // return (v1, v2);
  // return (endOfOutwardVector - centre, beginOfInwardVector - centre);
}

bool intersectTransversely(
  Shape s1,
  Shape s2,
  IntersectionPoint point,
  int seg1Index,
  int side1Index,
  int seg2Index,
  int side2Index,
  bool isForHit,
) {
  var (outward1, reverseInward1) = getoutwardVectors(
    s1,
    seg1Index,
    side1Index,
    close(point.distAlong1, 0),
    point.point,
  );
  var (outward2, reverseInward2) = getoutwardVectors(
    s2,
    seg2Index,
    side2Index,
    close(point.distAlong2, 0),
    point.point,
  );

  // print("TRANSVERSE at point ${vec3ToLatLng(point.point)}");
  // print(
  //   vectorLiesBetween(
  //     outward1,
  //     reverseInward1,
  //     outward2,
  //     point.point,
  //     true,
  //     isForHit,
  //   ),
  // );
  // print(
  //   vectorLiesBetween(
  //     outward1,
  //     reverseInward1,
  //     reverseInward2,
  //     point.point,
  //     false,
  //     isForHit,
  //   ),
  // );
  // print(
  //   vectorLiesBetween(
  //     outward2,
  //     reverseInward2,
  //     outward1,
  //     point.point,
  //     true,
  //     isForHit,
  //   ),
  // );
  // print(
  //   vectorLiesBetween(
  //     outward2,
  //     reverseInward2,
  //     reverseInward1,
  //     point.point,
  //     false,
  //     isForHit,
  //   ),
  // );

  return (!isForHit &&
          vectorLiesBetween(
            outward1,
            reverseInward1,
            outward2,
            point.point,
            true,
            isForHit,
          )) ||
      (!isForHit &&
          vectorLiesBetween(
            outward1,
            reverseInward1,
            reverseInward2,
            point.point,
            false,
            isForHit,
          )) ||
      vectorLiesBetween(
        outward2,
        reverseInward2,
        outward1,
        point.point,
        true,
        isForHit,
      ) ||
      vectorLiesBetween(
        outward2,
        reverseInward2,
        reverseInward1,
        point.point,
        false,
        isForHit,
      );
}

(List<IntersectionData>, Map<(bool, int, int), List<IntersectionOnLine>>)
intersectionPoints(
  Shape s1,
  Shape s2, {
  bool isForHit = false,
  bool checkTransverse = true,
}) {
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
      for (int seg2Index = 0; seg2Index < s2.segments.length; seg2Index++) {
        Segment segment2 = s2.segments[seg2Index];

        for (
          int side2Index = 0;
          side2Index < s2.segments[seg2Index].sides.length;
          side2Index++
        ) {
          Vector3 begin1 = segment1.vertices[side1Index];
          Vector3 end1 =
              segment1.vertices[(side1Index + 1) % segment1.vertices.length];
          Vector3 begin2 = segment2.vertices[side2Index];
          Vector3 end2 =
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
            if (close(point.distAlong1, 0) || close(point.distAlong2, 0)) {
              if (checkTransverse &&
                  !intersectTransversely(
                    s1,
                    s2,
                    point,
                    seg1Index,
                    side1Index,
                    seg2Index,
                    side2Index,
                    isForHit,
                  )) {
                print(
                  "The curves do not intersect transversely at $point  from segments 1index: $side1Index and 2index: $side2Index -> ignoring",
                );
                continue;
              }
            }
            intersections.add(
              IntersectionData(
                point: point.point,
                indexInS1: (seg1Index, side1Index),
                indexInS2: (seg2Index, side2Index),
              ),
            );
            intersectionsPerSide[(true, seg1Index, side1Index)]!.add(
              IntersectionOnLine(
                point: point.point,
                distanceAlong: point.distAlong1,
              ),
            );
            intersectionsPerSide[(false, seg2Index, side2Index)]!.add(
              IntersectionOnLine(
                point: point.point,
                distanceAlong: point.distAlong2,
              ),
            );
            // print(
            //   "Adding intersection ${point.point} from segments 1index: $side1Index and 2index: $side2Index",
            // );
          }
        }
      }
    }
  }
  intersectionsPerSide.forEach(
    (k, list) =>
        list.sort((a, b) => a.distanceAlong.compareTo(b.distanceAlong)),
  );

  return (intersections, intersectionsPerSide);
}

class CurrentPoint {
  Vector3 point;
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
  // When the two shapes share a side the currentLine can contain that point twice (once from the current shape and a second time as 'intersection' with the other shape).
  // We therefore choose the last index where it occurs so we can actually move on instead of getting into an infinite loop
  int index = currentLine.lastIndexWhere(
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
  } else if (index == currentLine.length - 2) {
    currentPoint.indices = (
      currentPoint.indices.$1,
      (currentPoint.indices.$2 + 1) % segment.vertices.length,
    );
    currentPoint.point = segment.vertices[currentPoint.indices.$2];
  } else {
    currentPoint.point = currentLine[index + 1].point;
  }
}

Shape intersect(Shape s1, Shape s2, var state, {bool firstIsForHit = false}) {
  print("Intersecting");
  var (intersections, intersectionsPerLine) = intersectionPoints(
    s1,
    s2,
    isForHit: firstIsForHit,
  );
  for (var p in intersections) {
    if (state != null) state.points.add(vec3ToLatLng(p.point));
    print(
      "Intersection: ${vec3ToLatLng(p.point)}, ${p.indexInS1}, ${p.indexInS2}",
    );
  }
  Map<Vector3, ((int, int), (int, int))> intersectionsTotal = {};
  Set<Vector3> intersectionsLeft = {};
  int count = 0;
  for (IntersectionData data in intersections) {
    intersectionsTotal[data.point] = (data.indexInS1, data.indexInS2);

    intersectionsLeft.add(data.point);
  }
  List<bool> segmentsIntersected1 = List.filled(s1.segments.length, false);
  List<bool> segmentsIntersected2 = List.filled(s2.segments.length, false);
  for (IntersectionData ints in intersections) {
    segmentsIntersected1[ints.indexInS1.$1] = true;
    segmentsIntersected2[ints.indexInS2.$1] = true;
  }
  // ui.Path firstPath = s1.getPath(camera, size);
  // ui.Path secondPath = s2.getPath(camera, size);
  Shape result = Shape(segments: []);
  for (int i = 0; i < segmentsIntersected1.length; i++) {
    if (!segmentsIntersected1[i]) {
      print("Segment $i in shape 1 has no intersections");
      if (s1.segments[i].vertices.isEmpty) {
        print("WARNING: empty segment!!!");
        continue;
      }
      if (s2.hit(s1.segments[i].vertices.first, null)) {
        result.segments.add(s1.segments[i]);
      }

      // if (secondPath.contains(
      //   camera.latLngToScreenOffset(s1.segments[i].vertices.first),
      // )) {
      //   result.segments.add(s1.segments[i]);
      // }
    }
  }
  for (int i = 0; i < segmentsIntersected2.length; i++) {
    if (!segmentsIntersected2[i]) {
      print("Segment $i in shape 2 has no intersections");
      if (s2.segments[i].vertices.isEmpty) {
        print("WARNING: empty segment!!!");
        continue;
      }
      if (s1.hit(s2.segments[i].vertices.first, null)) {
        result.segments.add(s2.segments[i]);
      }
      // if (firstPath.contains(
      //   camera.latLngToScreenOffset(s2.segments[i].vertices.first),
      // )) {
      //   result.segments.add(s2.segments[i]);
      // }
    }
  }
  print("Found ${intersectionsLeft.length} intersections");
  while (intersectionsLeft.isNotEmpty) {
    Vector3 startPoint = intersectionsLeft.first;
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
      // print(
      //   "current point = ${currentPoint.point} and start point = $startPoint",
      // );
      ++count;
      if (count > 1000) {
        print("WARNING: Stopping due to too many loops");
        // return Shape(segments: []);
        result.segments.add(newSegment);
        return result;
      }
      // state.points.add(vec3ToLatLng(currentPoint.point));
      if (intersectionsTotal[currentPoint.point] != null) {
        intersectionsLeft.remove(currentPoint.point);
        var indices = intersectionsTotal[currentPoint.point]!;
        var vertices1 = s1.segments[indices.$1.$1].vertices;
        var sides1 = s1.segments[indices.$1.$1].sides;
        var vertices2 = s2.segments[indices.$2.$1].vertices;
        var sides2 = s2.segments[indices.$2.$1].sides;
        Vector3 endAlongS1 = vertices1[(indices.$1.$2 + 1) % vertices1.length];
        Vector3 endAlongS2 = vertices2[(indices.$2.$2 + 1) % vertices2.length];

        // vertices does not contain the intersections so use currentpoint and not vertices
        Vector3 tangentAlongS1 = sides1[indices.$1.$2].getTangent(
          // vertices1[indices.$1.$2],
          currentPoint.point,
          endAlongS1,
          currentPoint.point,
        );
        // print(
        //   'vertex: ${vertices1[indices.$1.$2]} and currpoint = ${currentPoint.point}',
        // );
        Vector3 tangentAlongS2 = sides2[indices.$2.$2].getTangent(
          // vertices2[indices.$2.$2],
          currentPoint.point,
          endAlongS2,
          currentPoint.point,
        );
        Vector3 cross = Vector3(0, 0, 0);
        cross3(tangentAlongS1, tangentAlongS2, cross);
        // if both are dependant then it does not matter which path we choose
        cross.normalize();
        if (!vec3Close(cross, currentPoint.point.normalized())) {
          // print("Continuing along shape 1");
          // Vector3 delta1 = endAlongS1 - currentPoint.point;
          // Vector3 delta2 = endAlongS2 - currentPoint.point;
          // Vector3 delta1 = Vector3(
          //   endAlongS1.latitude - currentPoint.point.latitude,
          //   endAlongS1.longitude - currentPoint.point.longitude,
          // );
          // Vector3 delta2 = Vector3(
          //   endAlongS2.latitude - currentPoint.point.latitude,
          //   endAlongS2.longitude - currentPoint.point.longitude,
          // );
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
          // print("Continuing along shape 2");
          currentPoint.isFirstShape = false;
          currentPoint.indices = (indices.$2.$1, indices.$2.$2);
          setNextPoint(intersectionsPerLine, currentPoint, s1, s2);
          newSegment.sides.add(
            s2.segments[indices.$2.$1].sides[currentPoint
                .indices
                .$2], // todo: IMPORTANT: When adding circles: make change the side a bit to only contain part of the circle arc
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
      }
    } while (!vec3Close(currentPoint.point, startPoint));
    newSegment.vertices
        .removeLast(); // We always add the start vertex again at the very end
    result.segments.add(newSegment);
  }

  return result;
}

Map<String, dynamic> vector3ToJson(Vector3 point) {
  LatLng p = vec3ToLatLng(point);
  return {"latitude": p.latitude, "longitude": p.longitude};
  // return {"x": point.x, "y": point.y, "z": point.z};
}

Vector3 vector3FromJson(Map<String, dynamic> json) {
  // This would fail if a coordinate is an integer so we add .0 to automatically convert it to a double
  if (json["x"] != null) {
    // it is still the old version
    print(
      "WARNING: json file was still the old version. Loading as if new version",
    );
    // return latLngToVec3(latLngFromJson(json));
    return Vector3(json["x"] + .0, json["y"] + .0, json["z"] + .0);
  }
  return latLngToVec3(latLngFromJson(json));
}

LatLng latLngFromJson(Map<String, dynamic> json) {
  // This would fail if a coordinate is an integer so we add .0 to automatically convert it to a double
  return LatLng(json["latitude"] + .0, json["longitude"] + .0);
}

Map<String, dynamic> latLngToJson(LatLng point) {
  return {"latitude": point.latitude, "longitude": point.longitude};
}

bool vec3Close(Vector3 x, Vector3 y) {
  return close(x.x, y.x) && close(x.y, y.y) && close(x.z, y.z);
}

bool latLngClose(LatLng x, LatLng y) {
  return close(x.longitude, y.longitude) && close(x.latitude, y.latitude);
}

class CircleEdge extends Side {
  LatLng center;
  late Vector3 properCentre;
  double radius, startAngle, sweepAngle; // radius in metres
  Plane plane;

  CircleEdge({
    required this.center,
    required this.radius,
    required this.startAngle,
    required this.sweepAngle,
    required this.plane,
  }) : super(SideType.circle) {
    properCentre = plane.getPointClosestToCentre();
    // print(
    //   "For circle: got a plane with normal: ${vec3ToLatLng(plane.getNormal())}",
    // );
    // print("LIES INSIDE: ${plane.liesInside(properCentre)}");
  }

  @override
  Map<String, dynamic> toJsonImpl() {
    Map<String, dynamic> output = {};
    output["center"] = latLngToJson(center);
    output["radius"] = radius;
    output["startAngle"] = startAngle;
    output["sweepAngle"] = sweepAngle;
    output["plane"] = plane.toJson();
    return output;
  }

  factory CircleEdge.fromJson(Map<String, dynamic> json) {
    return CircleEdge(
      center: latLngFromJson(json["center"]),
      radius: json["radius"],
      startAngle: json["startAngle"],
      sweepAngle: json["sweepAngle"],
      plane: Plane.fromJson(json["plane"]),
    );
  }

  @override
  bool equalsImpl(Side other) {
    CircleEdge otherCircle = other as CircleEdge;
    return latLngClose(center, otherCircle.center) &&
        close(radius, otherCircle.radius) &&
        close(startAngle, otherCircle.startAngle) &&
        close(sweepAngle, otherCircle.sweepAngle);
  }

  @override
  void extendPath(ui.Path path, LatLng begin, LatLng end, MapCamera camera) {
    double radiusInLongitude = 2 * radius / circumferenceEarth * 360;
    double radiusInLatitude = 2 * radius / circumferenceEarth * 180;
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

  @override
  String toString() {
    return 'CircleEdge with centre $center and radius $radius';
  }

  @override
  Plane getPlane(Vector3 begin, Vector3 end) {
    return plane;
  }

  @override
  Vector3 getProperCentre() {
    return properCentre;
  }
}

class Segment {
  List<Vector3> vertices;
  List<Side> sides;

  Segment({required this.vertices, required this.sides});

  factory Segment.fromJson(Map<String, dynamic> json) {
    List<Vector3> vertices = [];
    for (var vertex in json["vertices"]) {
      vertices.add(vector3FromJson(vertex));
    }

    List<Side> sides = [];
    for (var side in json["sides"]) {
      sides.add(Side.fromJson(side));
    }
    return Segment(vertices: vertices, sides: sides);
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = {};
    List<Map<String, dynamic>> verticesJson = [];
    for (Vector3 p in vertices) {
      verticesJson.add(vector3ToJson(p));
    }
    output["vertices"] = verticesJson;

    List<Map<String, dynamic>> sidesJson = [];
    for (Side s in sides) {
      sidesJson.add(s.toJson());
    }
    output["sides"] = sidesJson;

    return output;
  }

  @override
  bool operator ==(Object other) {
    if (other is! Segment) return false;
    if (vertices.length != other.vertices.length) return false;
    for (int i = 0; i < vertices.length; i++) {
      if (!vec3Close(vertices[i], other.vertices[i])) return false;
    }
    return listEquals(sides, other.sides);
  }
}

(Vector3, Vector3) getBeginAndEndFromIntersection(
  Shape s,
  Vector3 point,
  (int, int) index,
) {
  Segment seg = s.segments[index.$1];
  Vector3 end = seg.vertices[(index.$2 + 1) % seg.vertices.length];
  Vector3 begin = seg.vertices[index.$2 % seg.vertices.length];
  return (begin, end);
}

enum OrientationResult { positive, negative, undeterminated }

OrientationResult areOrientedPositively(Vector3 a, Vector3 b, Vector3 point) {
  Vector3 cross = Vector3(0, 0, 0);
  cross3(a, b, cross);
  cross.normalize();
  if (close(cross.length, 0)) return OrientationResult.undeterminated;
  return vec3Close(cross, point.normalized())
      ? OrientationResult.positive
      : OrientationResult.negative;
}

class Shape {
  List<Segment> segments;

  // For every edge the inside of the shape should be on the left of the given edge (begin -> end)
  // See also PathFillType.nonZero
  // This is useful for calculating intersections
  Shape({required this.segments});

  factory Shape.fromJson(Map<String, dynamic> json) {
    List<Segment> segments = [];
    for (dynamic segment in json["segments"]) {
      segments.add(Segment.fromJson(segment));
    }
    return Shape(segments: segments);
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> output = {};
    List<Map<String, dynamic>> segmentsJson = [];
    for (Segment s in segments) {
      segmentsJson.add(s.toJson());
    }
    output["segments"] = segmentsJson;
    return output;
  }

  @override
  String toString() {
    return "shape with ${segments.length} segments and the first has ${segments.isNotEmpty ? segments[0].vertices.length.toString() : "----"} vertices";
  }

  @override
  bool operator ==(Object other) {
    if (other is! Shape) {
      return false;
    }
    // todo: this should probably also return true if they are ordered differently
    return listEquals(segments, other.segments);
  }

  ui.Path getPath(MapCamera camera, Size containerSize) {
    // We need this because rotating the circles doesn't work as we have to provide the bounding rectangle, which should also rotate. Therefore we calculate without rotation and then rotate everything at the end
    MapCamera cameraWithoutRotation = camera.withRotation(0);
    if (segments.isEmpty) {
      return ui.Path();
    }

    ui.Path path = ui.Path();
    path.fillType = PathFillType.nonZero;
    for (Segment s in segments) {
      // if (s.vertices.length != s.sides.length) {
      //   throw Exception(
      //     "Number of vertices (${s.vertices.length}) must equal the number of sides (${s.sides.length}) in the shape when rendering it",
      //   );
      // }
      if (s.vertices.isEmpty) return ui.Path();

      ui.Offset begin = cameraWithoutRotation.latLngToScreenOffset(
        vec3ToLatLng(s.vertices[0]),
      );
      path.moveTo(begin.dx, begin.dy);

      for (int i = 0; i < s.sides.length; i++) {
        s.sides[i].extendPath(
          path,
          vec3ToLatLng(s.vertices[i]),
          vec3ToLatLng(s.vertices[(i + 1) % s.vertices.length]),
          cameraWithoutRotation,
        );
      }
      // path.relativeLineTo(-200, -200);
      // path.lineTo(0, 0);
      // path.lineTo(1000, 0);
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

  Vector3 getTangentAtIntersection((int, int) index, Vector3 point) {
    Segment s = segments[index.$1];
    return s.sides[index.$2].getTangent(
      s.vertices[index.$2],
      s.vertices[(index.$2 + 1) % s.vertices.length],
      point,
    );
  }

  bool hit(Vector3 pos, var state) {
    // return getPath(
    //   camera,
    //   containerSize,
    // ).contains(camera.latLngToScreenOffset(pos));
    print("Testing if point ${vec3ToLatLng(pos)} lies inside");
    Vector3 begin = pos;
    LatLng l = vec3ToLatLng(begin);
    Vector3 end = latLngToVec3(LatLng(l.latitude, l.longitude - 180));
    // todo: this does not work if latitude == 0 or 90
    // Vector3 end = Vector3(
    //   pos.latitude,
    //   pos.longitude + 180,
    // ); // loop around half the circle. We assume that this is enough and no curve will loop around more than half the earth todo: add a check and explicitly fail otherwise
    // todo: make sure that the intersections also work when looping around the earth
    Side side = StraightEdge()..isInfinite = true;
    int count = 0;
    // for (Segment s in segments) {
    //   for (int i = 0; i < s.vertices.length; i++) {
    //     Vector3 begin2 = s.vertices[i];
    //     Vector3 end2 = s.vertices[(i + 1) % s.vertices.length];
    //     List<IntersectionPoint> points = intersectSides(
    //       side,
    //       s.sides[i],
    //       begin,
    //       end,
    //       begin2,
    //       end2,
    //     );
    //
    //     // with circles we have to take the tangent line again
    Shape s = Shape(
      segments: [
        Segment(vertices: [begin, end], sides: [side]),
      ],
    );

    var (points, _) = intersectionPoints(s, this, isForHit: true);
    for (IntersectionData p in points) {
      // if (state != null) state.points.add(vec3ToLatLng(p.point));
      Vector3 t1 = s.getTangentAtIntersection(p.indexInS1, p.point);
      Vector3 t2 = getTangentAtIntersection(p.indexInS2, p.point);

      switch (areOrientedPositively(t1, t2, p.point)) {
        case OrientationResult.positive:
          ++count;
        case OrientationResult.negative:
          --count;
        default:
        // do nothing
        // We ignore it: think about turning the ray an infinitesimal amount making sure it does not intersect this line anymore. The other lines are still intersected the same way though
      }

      // double detval = det(
      //   LatLng(end.latitude - begin.latitude, end.longitude - begin.longitude),
      //   LatLng(
      //     end2.latitude - begin2.latitude,
      //     end2.longitude - end2.longitude,
      //   ),
      // );

      // if detval == 0 then we ignore it: think about turning the ray an infinitesimal amount making sure it does not intersect this line anymore. The other lines are still intersected the same way though
      // if (close(detval, 0)) continue;
      // if (detval < 0) {
      //   --count;
      // } else {
      //   ++count;
      // }
    }
    //   }
    // }
    // return true;
    // return false;
    return count != 0;
  }
}
