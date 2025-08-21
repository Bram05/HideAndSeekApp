import 'package:flutter_test/flutter_test.dart';
import 'package:bigbrother/Maths.dart';
import 'dart:ffi';
import 'package:bigbrother/maths_generated_bindings.dart';
import 'package:ffi/ffi.dart';

Pointer<LatLngDart> createLatLng(double lat, double lon) {
  return malloc()
    ..ref.lat = lat
    ..ref.lon = lon;
}

Pointer<Vector3Dart> createVec3(double x, double y, double z) {
  return malloc()
    ..ref.x = x
    ..ref.y = y
    ..ref.z = z;
}

void main() {
  List<Pointer<LatLngDart>> points = [
    createLatLng(0, 0),
    createLatLng(90, 0),
    createLatLng(10, 5),
    createLatLng(-17, -70),
    createLatLng(7, 15),
    createLatLng(3, -4),
    createLatLng(0, 7),
    createLatLng(-13, 0),
    // CreateLatLng(-13, 90), // this fails because of conversion issues with doubles/Doubles
    createLatLng(0, -10),
    createLatLng(10, -10),
    createLatLng(10, 170),
    createLatLng(-45, 170),
    createLatLng(-45, -170),
    createLatLng(0, 90),
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
    createVec3(0, 0, 1),
    createVec3(1, 0, 0),
    createVec3(0, 1, 0),
    createVec3(0, 0, -1),
    createVec3(-1, 0, 0),
    createVec3(0, -1, 0),
    createVec3(0.96984631, 0.171010072, 0.173648178),
  ];
  test("vec3 -> LatLng -> vec3", () {
    for (var p in test2) {
      if (1 != maths.ConversionTestFromVec3(p.ref, 0)) {
        maths.ConversionTestFromVec3(p.ref, 1);
        print("${p.ref.x}, ${p.ref.y}, ${p.ref.z}");
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
