import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/constants.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;

void main() {
  var straightLines = [
    (LatLng(0, 0), LatLng(0, 10)),
    (LatLng(-10, 10), LatLng(-10, -90)),
    (LatLng(0, 179), LatLng(0, 0)),
    (LatLng(89, 0), LatLng(90, 5)),
    (LatLng(70, 0), LatLng(0, 70)),
  ];
  var normals = {0: Vector3(0, 0, 1)};
  var straightLinesShouldFail = [
    (LatLng(0, 180), LatLng(0, 0)),
    (LatLng(90, 0), LatLng(90, 5)),
  ];
  for (int i = 0; i < straightLines.length; i++) {
    var line = straightLines[i];
    test("Line $line", () {
      Vector3 begin = latLngToVec3(line.$1);
      Vector3 end = latLngToVec3(line.$2);

      Plane p = Plane.fromTwoPointsAndOrigin(begin, end);
      Plane p2 = Plane.fromTwoPointsAndOrigin(end, begin);
      bool first = p.liesInside(begin);
      bool second = p.liesInside(end);
      bool third = p2.liesInside(begin);
      bool fourth = p2.liesInside(end);
      if (!(first && second && third && fourth)) {
        print(
          "Test $line failed: $first, $second, $third, $fourth should all be true. Got plane $p",
        );
        assert(false);
      }
      if (normals[i] != null) {
        if (!vec3Close(p.getNormal(), normals[i]!) ||
            !vec3Close(p2.getNormal(), -normals[i]!)) {
          print("Normal not correct: ${p.getNormal()} and ${p2.getNormal()}");
          assert(false);
        }
      }
    });
  }

  for (var line in straightLinesShouldFail) {
    test("Line should fail: $line", () {
      Vector3 begin = latLngToVec3(line.$1);
      Vector3 end = latLngToVec3(line.$2);
      try {
        Plane.fromTwoPointsAndOrigin(begin, end);
        assert(false);
      } catch (e) {}
      try {
        Plane.fromTwoPointsAndOrigin(end, begin);
        assert(false);
      } catch (e) {}
    });
  }

  var circles = [
    (
      LatLng(0, 0),
      100.0,
      [
        LatLng(0, 0.000898),
        LatLng(0, -0.000898),
        LatLng(0.000898, 0),
        LatLng(-0.000898, 0),
      ],
    ),
    (
      LatLng(10, 10),
      10000.0,
      [
        LatLng(9.999988, 10.091217),
        LatLng(9.999988, 9.908783),
        LatLng(10.089832, 10.0),
        LatLng(9.910168, 10.0),
      ],
    ),
    (LatLng(90, 0), .0, [LatLng(90, 0)]),
    (
      LatLng(90, 0),
      0.5 * circumferenceEarth,
      [LatLng(-90, 0), LatLng(-90, 15)],
    ),
  ];
  var circleNormals = {0: Vector3(0, 1, 0)};
  for (int i = 0; i < circles.length; i++) {
    var circle = circles[i];
    test("Circle: $circle", () {
      Plane p = Plane.fromCircle(circle.$1, circle.$2, true).$1;
      for (LatLng point in circle.$3) {
        if (!p.liesInside(latLngToVec3(point))) {
          print("Point $point does not lie inside the plane");
          assert(false);
        }
      }
      if (normals[i] != null) {
        if (!vec3Close(p.getNormal(), circleNormals[i]!)) {
          print(
            "Circle normal not correct: ${p.getNormal()}, should be ${circleNormals[i]}",
          );
          assert(false);
        }
      }
    });
  }
}
