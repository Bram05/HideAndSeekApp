import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Maths.dart';

void circleLine() {
  if (1 != maths.IntersectionTest(0)) {
    maths.IntersectionTest(1);
    assert(false);
  }
  // // Technically a memory leak
  // SideDart s = malloc<SideDart>().ref..
  //   centre= (malloc<LatLngDart>().ref..lat = 0..lon=0)
  //   ..radius= 1000
  //   ..startAngle= 0
  //   ..sweepAngle= math.pi
  //   ..isClockwise = 1;
  // SideDart s2 = malloc<SideDart>().ref..isStraight = 1;
  // var result = maths.
  // // List<IntersectionPoint> ps = intersectSides(
  // //   s,
  // //   s2,
  // //   latLngToVec3(LatLng(0.0, 0.008983)),
  // //   latLngToVec3(LatLng(0.0, -0.008983)),
  // //   latLngToVec3(LatLng(0.3, 180)),
  // //   latLngToVec3(LatLng(0, 0)),
  // // );
  // assert(
  //   ps.length == 1 &&
  //       vec3Close(
  //         ps[0].point,
  //         Vector3(
  //           -3.66702957743798e-18,
  //           0.9999999877091389,
  //           0.0001567855927765379,
  //         ),
  //       ),
  //   'We have ${ps.length} intersections: $ps',
  // );
}

void main() {
  test("circleLine", circleLine);
}
