import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/constants.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

void main() {
  List<LatLng> points = [
    LatLng(0, 0),
    LatLng(90, 0),
    LatLng(10, 5),
    LatLng(-17, -70),
    LatLng(7, 15),
    LatLng(3, -4),
    LatLng(0, 7),
    LatLng(-13, 0),
    LatLng(-13, 90),
    LatLng(0, -10),
    LatLng(10, -10),
    LatLng(10, 170),
    LatLng(-45, 170),
    LatLng(-45, -170),
    // LatLng(-13, 190),
  ];
  print(latLngToVec3(LatLng(0, 90)));
  test("LatLng -> vec3 -> LatLng", () {
    for (LatLng p in points) {
      Vector3 l = latLngToVec3(p);
      LatLng result = vec3ToLatLng(l);
      if (!latLngClose(result, p)) {
        print("test failed: $p -> $l -> $result");
        assert(false);
      }
    }
  });

  List<Vector3> test2 = [
    Vector3(0, 0, radiusEarth) / radiusEarth,
    Vector3(radiusEarth, 0, 0) / radiusEarth,
    Vector3(6178890.84351351, 1089505.166563918, 1106312.5399160131) /
        radiusEarth,
    Vector3(0, -radiusEarth, 0) / radiusEarth,
  ];
  test("vec3 -> LatLng -> vec3", () {
    for (Vector3 p in test2) {
      LatLng l = vec3ToLatLng(p);
      Vector3 result = latLngToVec3(l);
      if (!vec3Close(result, p)) {
        print("test failed: $p -> $l -> $result");
        assert(false);
      }
      print("Passed first check");
    }
  });
}
