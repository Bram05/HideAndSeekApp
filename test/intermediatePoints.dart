import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Maths.dart';

void main() {
  test("IntermediatePoints", () {
    if (1 != maths.IntermediatePointsTest(0)) {
      maths.IntermediatePointsTest(1);
      assert(false);
    }
  });
}
