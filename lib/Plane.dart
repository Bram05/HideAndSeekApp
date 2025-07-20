import 'dart:math' as math;

import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math_64.dart' hide Plane;
import 'package:jetlag/constants.dart';

bool isZero(Vector3 v) {
  return close(v.x, 0) && close(v.y, 0) && close(v.z, 0);
}

class Line {
  Vector3 dir, point;
  Line(this.dir, this.point) {
    assert(!isZero(dir));
  }

  Vector3 intersect(Line other) {
    Vector3 perpendicularToBothLines = Vector3(0, 0, 0);
    cross3(dir, other.dir, perpendicularToBothLines);
    assert(!isZero(perpendicularToBothLines)); // they are parallel
    Vector3 perpendicularToLine1 = Vector3(0, 0, 0);
    cross3(dir, perpendicularToBothLines, perpendicularToLine1);
    double constantForLine1 = dot3(perpendicularToLine1, point);
    double t =
        (constantForLine1 - dot3(other.point, perpendicularToLine1)) /
        (dot3(other.dir, perpendicularToLine1));
    return other.point + other.dir * t; // we have to use the other line here
  }

  @override
  String toString() {
    return "dir = $dir, point = $point";
  }
}

// Solve ax^2+bx+c=0
List<double> solveQuadratic(double a, double b, double c) {
  assert(!close(a, 0));
  double disc = b * b - 4 * a * c;
  if (close(disc, 0)) {
    return [-b / (2 * a)];
  }
  if (disc < 0) return [];
  return [(-b - math.sqrt(disc)) / (2 * a), (-b + math.sqrt(disc)) / (2 * a)];
}

enum IntersectionType { normal, parallel, coincide }

class Plane {
  double a, b, c, d;
  Plane(this.a, this.b, this.c, this.d) {
    assert(!isZero(getNormal()));
    assert(close(Vector3(a, b, c).length, 1));
  }
  static Plane fromNormal(Vector3 normal, Vector3 point) {
    Vector3 normalized = normal.normalized();
    double a = normalized.x;
    double b = normalized.y;
    double c = normalized.z;
    double d = a * point.x + b * point.y + c * point.z;
    return Plane(a, b, c, d);
  }

  Map<String, dynamic> toJson() {
    return {
      "coords": [a, b, c, d],
    };
  }

  static Plane fromJson(var json) {
    return Plane(
      json["coords"][0],
      json["coords"][1],
      json["coords"][2],
      json["coords"][3],
    );
  }

  Vector3 getNormal() {
    return Vector3(a, b, c);
  }

  Vector3 getPointClosestToCentre() {
    // return getNormal().normalized() * d;
    return getNormal() * d / getNormal().length2;
  }

  Vector3 getAPointOn() {
    return getPointClosestToCentre();
  }

  static Plane fromThreePoints(Vector3 a, Vector3 b, Vector3 c) {
    Vector3 d1 = a - b;
    Vector3 d2 = c - b;
    Vector3 cross = Vector3(0, 0, 0);
    cross3(d1, d2, cross);
    return fromNormal(cross, a);
  }

  static Plane fromTwoPointsAndOrigin(Vector3 a, Vector3 b) {
    Vector3 cross = normalizedCrossProduct(a, b);
    return fromNormal(cross, Vector3(0, 0, 0));
  }

  // radius in metres
  static (Plane, Vector3, Vector3) fromCircle(
    LatLng centre,
    double radius,
    bool clockwise,
  ) {
    assert(radius >= 0 && radius <= 0.5 * circumferenceEarth + epsilon);
    Matrix3 rotation = Matrix3.rotationX(
      -(0.5 * math.pi - centre.latitudeInRad),
    ); // the rotation is when viewing it along the axis in the positive direction
    // print(vec3ToLatLng(rotation * Vector3(0, 0, radiusEarth)));
    rotation = Matrix3.rotationZ(centre.longitudeInRad) * rotation;
    // print("rotated: ${vec3ToLatLng(rotation * Vector3(0, 0, radiusEarth))}");
    double theta = 2 * math.pi * radius / circumferenceEarth;
    Matrix3 rotationWithTheta = rotation * Matrix3.rotationY(theta);
    Matrix3 rotationWithThetaInverse = rotation * Matrix3.rotationY(-theta);
    // Matrix3 rotationWithTheta1 = rotation * Matrix3.rotationY(-theta);
    // Matrix3 rotationWithTheta2 = rotation * Matrix3.rotationX(theta);
    // Matrix3 rotationWithTheta3 = rotation * Matrix3.rotationX(-theta);
    Vector3 northPole = Vector3(0, 0, 1);
    Vector3 pointOnPlane = rotationWithTheta * northPole;
    Vector3 pointOnPlaneOpposite = rotationWithThetaInverse * northPole;
    // Vector3 pointOnPlane2 = rotationWithTheta1 * northPole;
    // Vector3 pointOnPlane3 = rotationWithTheta2 * northPole;
    // Vector3 pointOnPlane4 = rotationWithTheta3 * northPole;
    // Vector3 rotatedPointOnPlane = rotation * pointOnPlane;

    // print("test2: ${Matrix3.rotationY(theta) * northPole}");
    // print("test: ${vec3ToLatLng(Matrix3.rotationY(theta) * northPole)}");
    // print("point: ${vec3ToLatLng(pointOnPlane)}");
    // print("point: ${vec3ToLatLng(pointOnPlane2)}");
    // print("point: ${vec3ToLatLng(pointOnPlane3)}");
    // print("point: ${vec3ToLatLng(pointOnPlane4)}");
    // Vector3 normal = rotation * Vector3(0, 0, 1);
    // print("p = ${vec3ToLatLng(rotatedPointOnPlane)}");
    return (
      Plane.fromNormal(
        latLngToVec3(centre) * (clockwise ? 1 : -1),
        pointOnPlane,
      ),
      pointOnPlane,
      pointOnPlaneOpposite,
    );
  }

  bool liesInside(Vector3 point) {
    return close(a * point.x + b * point.y + c * point.z, d);
  }

  (IntersectionType, Line?) intersect(Plane other) {
    Vector3 directionOfFinalLine = Vector3(0, 0, 0);
    cross3(getNormal(), other.getNormal(), directionOfFinalLine);
    if (close(directionOfFinalLine.length, 0)) {
      // both planes are parallel
      if (close(d / getNormal().length, other.d / other.getNormal().length)) {
        // They overlap
        return (IntersectionType.coincide, null);
      }
      return (IntersectionType.parallel, null);
    }

    Vector3 directionInPlane1 = Vector3(0, 0, 0);
    cross3(getNormal(), directionOfFinalLine, directionInPlane1);
    directionInPlane1.normalize();
    Vector3 directionInPlane2 = Vector3(0, 0, 0);
    cross3(other.getNormal(), directionOfFinalLine, directionInPlane2);
    directionInPlane2.normalize();
    Line l1 = Line(directionInPlane1, getAPointOn());
    Line l2 = Line(directionInPlane2, other.getAPointOn());
    Vector3 pointOnLine = l1.intersect(l2);
    return (IntersectionType.normal, Line(directionOfFinalLine, pointOnLine));
  }

  (IntersectionType, List<Vector3>) intersectOnEarth(Plane other) {
    var (type, l) = intersect(other);
    if (type != IntersectionType.normal) {
      return (type, []);
    }
    List<double> sols = solveQuadratic(
      l!.dir.length2,
      2 * dot3(l.dir, l.point),
      // l.point.length2 - radiusEarth * radiusEarth,
      l.point.length2 - 1,
    );
    var ints = sols.map<Vector3>((double t) => l.point + l.dir * t).toList();

    // print("IntersectOnEarth found ${ints.length} intersections: $ints");
    return (type, ints);
  }

  @override
  String toString() {
    return "(a,b,c,d)=($a, $b, $c, $d)";
  }
}

Vector3 latLngToVec3(LatLng point) {
  double theta = point.longitudeInRad;
  // double phi = 0.5 * math.pi - point.latitudeInRad;
  double phi = point.latitudeInRad;
  return Vector3(
    -math.sin(theta) * math.cos(phi),
    math.cos(theta) * math.cos(phi),
    math.sin(phi),
  );
}

double clamp(double val) {
  if (val > 1) {
    assert(val - epsilon <= 1);
    return 1;
  } else if (val < -1) {
    assert(val + epsilon >= -1);
    return -1.0;
  }
  return val;
}

LatLng vec3ToLatLng(Vector3 point) {
  assert(close(point.length2, 1));
  double longitude;
  if (close(point.x, 0) && close(point.y, 0)) {
    // this value does not matter
    longitude = 0;
  } else {
    double r2 = point.length2;
    double s = math.sqrt(r2 - point.z * point.z); // r^2-z^2 = x^2+y^2 >= 0
    if (close(point.x, 0)) {
      // This check is needed because we are outside the 'correct' domain of arcsin
      if (point.y > 0) {
        longitude = 0;
      } else {
        longitude = 180;
      }
    } else {
      double inner = -point.x / s;
      inner = clamp(inner);
      longitude = math.asin(inner) / math.pi * 180;
      if (point.y < 0) {
        longitude = 180 - longitude;
      }
      if (longitude > 180) {
        longitude -= 360;
        assert(longitude <= 180);
      }
    }
  }
  return LatLng(math.asin(point.z / point.length) / math.pi * 180, longitude);
}

double getDistanceAlongSphere(Vector3 a, Vector3 b) {
  // we don't care if a and b are on the scale of the planet, or between -1 and 1
  // print("distance between ${a} and ${b}");
  // print("Value is ${dot3(a.normalized(), b.normalized())}");
  double inner = clamp(dot3(a.normalized(), b.normalized()));
  // return math.acos(inner) / (2 * math.pi) * circumferenceEarth;
  return math.acos(inner) / (2 * math.pi);
}

String printlatlng(LatLng p) {
  return "(latitude: ${p.latitude}, longitude: ${p.longitude})";
}
