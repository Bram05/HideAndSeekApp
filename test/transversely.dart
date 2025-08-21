import 'package:flutter_test/flutter_test.dart';
import 'package:ffi/ffi.dart';
import 'package:bigbrother/maths_generated_bindings.dart';
import 'package:bigbrother/Maths.dart';
import 'dart:ffi';

Pointer<LatLngDart> createLatLng(double lat, double lon) {
  return malloc()
    ..ref.lat = lat
    ..ref.lon = lon;
}

void main() {
  var datas = [
    (
      createLatLng(10, 10),
      createLatLng(-9.9, 190),
      createLatLng(-10.1, 190),
      createLatLng(10, 10),
      createLatLng(12, 12),
      createLatLng(10, 12),
    ),
    (
      createLatLng(10, 10),
      createLatLng(-9.9, 190),
      createLatLng(-10.1, 190),
      createLatLng(15, 10),
      createLatLng(17, 12),
      createLatLng(15, 12),
    ),
  ];
  //   Shape s2 = getShape([]);
  //   checkShapesWithOneNonTransverseIntersections(s1, s2);
  //   checkShapesWithOneNonTransverseIntersections(s2, s1);
  // });
  // test("transverse2", () {
  //   Shape s1 = getShape([
  //   ]);
  //   Shape s2 = getShape([]);
  //   checkShapesWithOneNonTransverseIntersections(s1, s2);
  //   checkShapesWithOneNonTransverseIntersections(s2, s1);
  // });
  //
  for (var data in datas) {
    test("Transverse", () {
      if (1 !=
          maths.OneNonTransverseIntersection(
            data.$1.ref,
            data.$2.ref,
            data.$3.ref,
            data.$4.ref,
            data.$5.ref,
            data.$6.ref,
            0,
          )) {
        maths.OneNonTransverseIntersection(
          data.$1.ref,
          data.$2.ref,
          data.$3.ref,
          data.$4.ref,
          data.$5.ref,
          data.$6.ref,
          1,
        );
        assert(false);
      }
      malloc.free(data.$1);
      malloc.free(data.$2);
      malloc.free(data.$3);
      malloc.free(data.$4);
      malloc.free(data.$5);
      malloc.free(data.$6);
    });
  }
}
