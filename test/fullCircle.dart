import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Maths.dart';

void circleStraightTest() {
  if (1 != maths.CircleStraightTest(0)) {
    print('failed');
    maths.CircleStraightTest(1);
    assert(false);
  }
}

void circleCircleTest() {
  if (1 != maths.CircleCircleTest(0)) {
    print('failed');
    maths.CircleCircleTest(1);
    assert(false);
  }
}

void main() {
  test('circle-straight', () {
    circleStraightTest();
  });
  test('circle-circle', () {
    circleCircleTest();
  });
}
