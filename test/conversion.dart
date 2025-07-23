import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/constants.dart';
import 'package:jetlag/Maths.dart';
import 'dart:ffi';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:ffi/ffi.dart';

Pointer<LatLngDart> CreateLatLng(double lat, double lon) {
  return malloc()
    ..ref.lat = lat
    ..ref.lon = lon;
}

Pointer<Vector3Dart> CreateVec3(double x, double y, double z) {
  return malloc()
    ..ref.x = x
    ..ref.y = y
    ..ref.z = z;
}

void main() {
  List<Pointer<LatLngDart>> points = [
    CreateLatLng(0, 0),
    CreateLatLng(90, 0),
    CreateLatLng(10, 5),
    CreateLatLng(-17, -70),
    CreateLatLng(7, 15),
    CreateLatLng(3, -4),
    CreateLatLng(0, 7),
    CreateLatLng(-13, 0),
    CreateLatLng(-13, 90),
    CreateLatLng(0, -10),
    CreateLatLng(10, -10),
    CreateLatLng(10, 170),
    CreateLatLng(-45, 170),
    CreateLatLng(-45, -170),
    CreateLatLng(0, 90),
  ];
  test("LatLng -> vec3 -> LatLng", () {
    for (Pointer<LatLngDart> p in points) {
      if (1 != maths.ConversionTestFromLatLng(p.ref, 0)) {
        maths.ConversionTestFromLatLng(p.ref, 1);
        assert(false);
      }
      malloc.free(p);
      // Vector3 l = latLngToVec3(p);
      // LatLng result = vec3ToLatLng(l);
      // if (!latLngClose(result, p)) {
      //   print("test failed: $p -> $l -> $result");
      //   assert(false);
      // }
    }
  });

  List<Pointer<Vector3Dart>> test2 = [
    CreateVec3(0, 0, 1),
    CreateVec3(1, 0, 0),
    CreateVec3(0, 1, 0),
    CreateVec3(0, 0, -1),
    CreateVec3(-1, 0, 0),
    CreateVec3(0, -1, 0),
    CreateVec3(
      6178890.84351351 / radiusEarth,
      1089505.166563918 / radiusEarth,
      1106312.5399160131 / radiusEarth,
    ),
  ];
  test("vec3 -> LatLng -> vec3", () {
    for (var p in test2) {
      if (1 != maths.ConversionTestFromVec3(p.ref, 0)) {
        maths.ConversionTestFromVec3(p.ref, 1);
        assert(false);
      }
      // LatLng l = vec3ToLatLng(p);
      // Vector3 result = latLngToVec3(l);
      // if (!vec3Close(result, p)) {
      //   print("test failed: $p -> $l -> $result");
      //   assert(false);
      // }
      // print("Passed first check");
    }
  });
}
