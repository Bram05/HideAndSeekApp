import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;

void main() {
  test("Tangent to line", () {
    Side s = StraightEdge();
    List<(LatLng, LatLng, Vector3)> tests = [
      (LatLng(0, 0), LatLng(90, 0), Vector3(0, 0, 1)),
      (LatLng(0, 0), LatLng(-90, 0), Vector3(0, 0, -1)),
      (LatLng(0, 0), LatLng(-4, 0), Vector3(0, 0, -1)),
      (LatLng(0, 0), LatLng(-4, 0), Vector3(0, 0, -1)),
      (
        LatLng(10, -10),
        LatLng(0, 0),
        Vector3(-0.6805157878878377, 0.24371732440918834, -0.6910138408297056),
      ), // this result seemed reasonable
    ];
    for (var test in tests) {
      Vector3 begin = latLngToVec3(test.$1);
      Vector3 result = s.getTangent(begin, latLngToVec3(test.$2), begin);
      if (!vec3Close(result, test.$3)) {
        print("Test failed: $test got result $result");
        assert(false);
      }
    }
  });

  test("Tangent to circle", () {
    Side s = CircleEdge(
      center: LatLng(0, 0),
      radius: 111111,
      startAngle: 0,
      sweepAngle: 5,
      plane: Plane.fromCircle(LatLng(0, 0), 111111, true).$1,
    );
    Vector3 begin = latLngToVec3(LatLng(-1, 0));
    Vector3 result = s.getTangent(begin, latLngToVec3(LatLng(0, 0)), begin);

    // This should be (-1, 0, 0) because the circle is vertical and the bottom its tangent is in this direction
    if (!vec3Close(result, Vector3(-1, 0, 0))) {
      print("circle tangent failed: got $result");
      assert(false);
    }
    Side s2 = CircleEdge(
      center: LatLng(0, 180),
      radius: 111111,
      startAngle: 0,
      sweepAngle: 5,
      plane: Plane.fromCircle(LatLng(0, -180), 111111, true).$1,
    );
    Vector3 begin2 = latLngToVec3(LatLng(-1, 180));

    Vector3 result2 = s2.getTangent(
      begin2,
      latLngToVec3(LatLng(0, 180)),
      begin2,
    );

    // This should be (1, 0, 0) because the circle turned (its inside is now to the left) and therefore it 'moves' in the positive x direction
    if (!vec3Close(result2, Vector3(1, 0, 0))) {
      print("circle tangent failed: got $result2");
      assert(false);
    }
  });
}
