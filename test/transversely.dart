import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart';

Shape getShape(List<LatLng> points) {
  List<Vector3> vertices = [];
  List<Side> sides = [];
  for (var p in points) {
    vertices.add(latLngToVec3(p));
    sides.add(StraightEdge());
  }
  return Shape(
    segments: [Segment(vertices: vertices, sides: sides)],
  );
}

void checkShapesWithOneNonTransverseIntersections(Shape s1, Shape s2) {
  var (ints, _) = intersectionPoints(s1, s2, checkTransverse: false);
  assert(ints.length == 1, "ints = $ints");
  var (list, _) = intersectionPoints(s1, s2);
  assert(list.isEmpty, "List = $list");
}

void main() {
  test("transverse1", () {
    Shape s1 = getShape([
      LatLng(10, 10),
      LatLng(-9.9, 190),
      LatLng(-10.1, 190),
    ]);
    Shape s2 = getShape([LatLng(10, 10), LatLng(12, 12), LatLng(10, 12)]);
    checkShapesWithOneNonTransverseIntersections(s1, s2);
    checkShapesWithOneNonTransverseIntersections(s2, s1);
  });
  test("transverse2", () {
    Shape s1 = getShape([
      LatLng(10, 10),
      LatLng(-9.9, 190),
      LatLng(-10.1, 190),
    ]);
    Shape s2 = getShape([LatLng(15, 10), LatLng(17, 12), LatLng(15, 12)]);
    checkShapesWithOneNonTransverseIntersections(s1, s2);
    checkShapesWithOneNonTransverseIntersections(s2, s1);
  });
}
