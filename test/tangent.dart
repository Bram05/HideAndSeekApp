import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bigbrother/maths_generated_bindings.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;
import 'package:bigbrother/Maths.dart';
import 'dart:ffi';

LatLngDart createLatLng(double lat, double lon) {
  return malloc<LatLngDart>().ref
    ..lat = lat
    ..lon = lon;
}

void main() {
  var datas = [
    (createLatLng(0, 0), createLatLng(90, 0), Vector3(0, 0, 1), false),
    (createLatLng(0, 0), createLatLng(-90, 0), Vector3(0, 0, -1), false),
    (createLatLng(0, 0), createLatLng(-4, 0), Vector3(0, 0, -1), false),
    (createLatLng(0, 0), createLatLng(-4, 0), Vector3(0, 0, -1), false),
    (
      createLatLng(10, -10),
      createLatLng(0, 0),
      Vector3(-0.6805157878878377, 0.24371732440918834, -0.6910138408297056),
      true,
    ), // this result seemed reasonable
  ];
  for (var data in datas) {
    test("Tangent to line", () {
      Vector3Dart p = malloc<Vector3Dart>().ref
        ..x = data.$3.x
        ..y = data.$3.y
        ..z = data.$3.z;
      if (1 != maths.TangentToLine(data.$1, data.$2, p, 0, data.$4 ? 1 : 0)) {
        maths.TangentToLine(data.$1, data.$2, p, 1, data.$4 ? 1 : 0);
        assert(false);
      }
    });
  }

  var datas2 = [
    (
      createLatLng(0, 0),
      111111.0,
      createLatLng(-1, 0),
      malloc<Vector3Dart>()
        ..ref.x = -1
        ..ref.y = 0
        ..ref.z = 0,
    ),
    (
      createLatLng(0, 180),
      111111.0,
      createLatLng(-1, 180),
      malloc<Vector3Dart>()
        ..ref.x = 1
        ..ref.y = 0
        ..ref.z = 0,
    ),
  ];

  for (var data in datas2) {
    test("Tangent to circle", () {
      if (1 !=
          maths.TangentToCircle(data.$1, data.$2, data.$3, data.$4.ref, 0)) {
        maths.TangentToCircle(data.$1, data.$2, data.$3, data.$4.ref, 1);
      }
      malloc.free(data.$4);
    });
  }
}
