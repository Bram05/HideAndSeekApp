import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;

void circleLine() {
  Side s = CircleEdge(
    center: LatLng(0, 0),
    radius: 1000,
    startAngle: 0,
    sweepAngle: math.pi,
    plane: Plane.fromCircle(LatLng(0, 0), 1000, true).$1,
  );
  Side s2 = StraightEdge();
  List<IntersectionPoint> ps = intersectSides(
    s,
    s2,
    latLngToVec3(LatLng(0.0, 0.008983)),
    latLngToVec3(LatLng(0.0, -0.008983)),
    latLngToVec3(LatLng(0.3, 180)),
    latLngToVec3(LatLng(0, 0)),
  );
  assert(
    ps.length == 1 &&
        vec3Close(
          ps[0].point,
          Vector3(
            -3.66702957743798e-18,
            0.9999999877091389,
            0.0001567855927765379,
          ),
        ),
    'We have ${ps.length} intersections: $ps',
  );
}

void main() {
  test("circleLine", circleLine);
}
