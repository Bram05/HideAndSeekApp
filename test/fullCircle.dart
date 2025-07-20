import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/constants.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;

void circleStraightTest() {
  LatLng centre = LatLng(0, 0);
  double radius = 10000;
  var (plane, p1, p2) = Plane.fromCircle(centre, radius, true);
  Side s1 = CircleEdge(
    center: centre,
    radius: radius,
    startAngle: 0,
    sweepAngle: math.pi,
    plane: plane,
  );
  Side s2 = CircleEdge(
    center: centre,
    radius: radius,
    startAngle: math.pi,
    sweepAngle: 2 * math.pi,
    plane: plane,
  );
  Shape shape1 = Shape(
    segments: [
      Segment(vertices: [p1, p2], sides: [s1, s2]),
    ],
  );
  Shape shape2 = Shape(
    segments: [
      Segment(
        vertices: [
          latLngToVec3(LatLng(0, 0)),
          latLngToVec3(LatLng(0.3, 180)),
          latLngToVec3(LatLng(-0.3, 180)),
        ],
        sides: [StraightEdge(), StraightEdge(), StraightEdge()],
      ),
    ],
  );
  var result = intersectionPoints(shape1, shape2).$1;
  if (result.length != 2 ||
      !latLngClose(
        vec3ToLatLng(result[0].point),
        LatLng(0.08983152770644671, 0),
      ) ||
      !latLngClose(
        vec3ToLatLng(result[1].point),
        LatLng(-0.08983152770644671, 0),
      )) {
    // actual distance here is 9.978 km instead of 10 due to precision errors
    print(
      "Test circle-straight failed: result was ${result.map((p) => vec3ToLatLng(p.point)).toList()}",
    );
    assert(false);
  }
}

void circleCircleTest() {
  LatLng centre = LatLng(0, 0);
  double radius = 10000;
  var (plane, p1, p2) = Plane.fromCircle(centre, radius, true);
  Side s1 = CircleEdge(
    center: centre,
    radius: radius,
    startAngle: 0,
    sweepAngle: math.pi,
    plane: plane,
  );
  Side s2 = CircleEdge(
    center: centre,
    radius: radius,
    startAngle: math.pi,
    sweepAngle: 2 * math.pi,
    plane: plane,
  );
  Shape shape1 = Shape(
    segments: [
      Segment(vertices: [p1, p2], sides: [s1, s2]),
    ],
  );
  var (plane2, p21, p22) = Plane.fromCircle(
    LatLng(0, -90),
    0.25 * circumferenceEarth,
    false,
  );
  print("p: ${vec3ToLatLng(p21)}");
  print(vec3ToLatLng(p22));
  Side s3 = CircleEdge(
    center: LatLng(0, -90),
    radius: 0.25 * circumferenceEarth,
    startAngle: 0,
    sweepAngle: math.pi,
    plane: plane2,
  );
  Side s4 = CircleEdge(
    center: LatLng(0, -90),
    radius: 0.25 * circumferenceEarth,
    startAngle: math.pi,
    sweepAngle: 2 * math.pi,
    plane: plane2,
  );
  Shape shape2 = Shape(
    segments: [
      Segment(vertices: [p21, p22], sides: [s3, s4]),
    ],
  );
  var result = intersectionPoints(shape1, shape2).$1;
  if (result.length != 2 ||
      !latLngClose(
        vec3ToLatLng(result[0].point),
        LatLng(0.08983152770644671, 0),
      ) ||
      !latLngClose(
        vec3ToLatLng(result[1].point),
        LatLng(-0.08983152770644671, 0),
      )) {
    // actual distance here is 9.978 km instead of 10 due to precision errors
    print(
      "Test circle-circle failed: result was ${result.map((p) => printlatlng(vec3ToLatLng(p.point))).toList()}",
    );
    assert(false);
  }
}

void main() {
  test('circle-straight', () {
    circleStraightTest();
  });
  test('circle-circle', () {
    circleCircleTest();
  });
}
