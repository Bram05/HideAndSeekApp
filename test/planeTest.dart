import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;
import 'package:jetlag/Maths.dart';
import 'dart:ffi';

LatLngDart createLatLng(double lat, double lon) {
  return malloc<LatLngDart>().ref
    ..lat = lat
    ..lon = lon;
}

void main() {
  var straightLines = [
    (createLatLng(0, 0), createLatLng(0, 10)),
    (createLatLng(-10, 10), createLatLng(-10, -90)),
    (createLatLng(0, 179), createLatLng(0, 0)),
    (createLatLng(89, 0), createLatLng(90, 5)),
    (createLatLng(70, 0), createLatLng(0, 70)),
  ];
  var normals = {0: Vector3(0, 0, 1)};
  var straightLinesShouldFail = [
    (createLatLng(0, 180), createLatLng(0, 0)),
    (createLatLng(90, 0), createLatLng(90, 5)),
  ];
  for (int i = 0; i < straightLines.length; i++) {
    var line = straightLines[i];
    test("Line $line", () {
      Pointer<Vector3Dart> p = Pointer.fromAddress(0);
      if (normals[i] != null) {
        p = malloc()
          ..ref.x = normals[i]!.x
          ..ref.y = normals[i]!.y
          ..ref.z = normals[i]!.z;
      }
      if (1 != maths.PlaneTest(line.$1, line.$2, p, 0)) {
        maths.PlaneTest(line.$1, line.$2, p, 1);
        assert(false);
      }
    });
  }

  for (var line in straightLinesShouldFail) {
    test("Line should fail: $line", () {
      LatLngDart begin = line.$1;
      LatLngDart end = line.$2;
      if (2 != maths.PlaneTest(begin, end, Pointer.fromAddress(0), 0)) {
        print("Test $line dit not fail");
        assert(false);
      }
      // We fail after creating the first plane so we also seperately check this version
      if (2 != maths.PlaneTest(end, begin, Pointer.fromAddress(0), 0)) {
        print("Test $line dit not fail");
        assert(false);
      }
    });
  }

  var circles = [
    (
      createLatLng(0, 0),
      100.0,
      [
        createLatLng(0, 0.000898),
        createLatLng(0, -0.000898),
        createLatLng(0.000898, 0),
        createLatLng(-0.000898, 0),
      ],
    ),
    (
      createLatLng(10, 10),
      10000.0,
      [
        createLatLng(9.999988, 10.091217),
        createLatLng(9.999988, 9.908783),
        createLatLng(10.089832, 10.0),
        createLatLng(9.910168, 10.0),
      ],
    ),
    (createLatLng(90, 0), .0, [createLatLng(90, 0)]),
    (
      createLatLng(90, 0),
      0.5 * 40075017,
      [createLatLng(-90, 0), createLatLng(-90, 15)],
    ),
  ];
  var circleNormals = {0: Vector3(0, 1, 0)};
  for (int i = 0; i < circles.length; i++) {
    var circle = circles[i];
    test("Circle: ${circle.$1} and radius ${circle.$2}", () {
      Pointer<Vector3Dart> p = Pointer.fromAddress(0);
      if (circleNormals[i] != null) {
        p = malloc()
          ..ref.x = circleNormals[i]!.x
          ..ref.y = circleNormals[i]!.y
          ..ref.z = circleNormals[i]!.z;
      }
      Pointer<LatLngDart> list = malloc(circle.$3.length);
      for (int i = 0; i < circle.$3.length; i++) {
        list[i] = circle.$3[i];
      }
      if (1 !=
          maths.CircleTest(
            circle.$1,
            circle.$2,
            p,
            list,
            circle.$3.length,
            0,
          )) {
        maths.CircleTest(circle.$1, circle.$2, p, list, circle.$3.length, 1);
        assert(false);
      }
    });
  }
}
