import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';
import 'package:vector_math/vector_math.dart';
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
    print(
      "On line1: ${point + dir * t} and on line2: ${other.point + other.dir * t}",
    );
    return other.point + other.dir * t; // we have to use the other line here
  }

  @override
  String toString() {
    return "dir = $dir, point = $point";
  }
}

// Solve ax^2+bx+c=0
List<double> solveQuadratic(double a, double b, double c) {
  double disc = b * b - 4 * a * c;
  if (close(disc, 0)) {
    return [-b / (2 * a)];
  }
  if (disc < 0) return [];
  return [(-b - math.sqrt(disc)) / (2 * a), (-b + math.sqrt(disc)) / (2 * a)];
}

class Plane {
  double a, b, c, d;
  Plane(this.a, this.b, this.c, this.d) {
    assert(!(close(a, 0) && close(b, 0) && close(c, 0)));
  }
  static Plane fromNormal(Vector3 normal, Vector3 point) {
    double a = normal.x;
    double b = normal.y;
    double c = normal.z;
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

  Vector3 getAPointOn() {
    // return getNormal().normalized() * d;
    return getNormal() * d / getNormal().length2;
  }

  static Plane fromThreePoints(Vector3 a, Vector3 b, Vector3 c) {
    Vector3 d1 = a - b;
    Vector3 d2 = c - b;
    Vector3 cross = Vector3(0, 0, 0);
    cross3(d1, d2, cross);
    return fromNormal(cross, a);
  }

  static Plane fromTwoPointsAndOrigin(Vector3 a, Vector3 b) {
    Vector3 cross = Vector3(0, 0, 0);
    cross3(a, b, cross);
    return fromNormal(cross, Vector3(0, 0, 0));
  }

  // radius in metres
  static Plane ofCircle(LatLng centre, double radius) {
    assert(radius >= 0 && radius <= 0.5 * circumferenceEarth + epsilon);
    Matrix3 rotation = Matrix3.rotationX(centre.latitudeInRad - 0.5 * math.pi);
    rotation = Matrix3.rotationZ(-centre.longitudeInRad) * rotation;
    double theta = 2 * math.pi * radius / circumferenceEarth;
    print("got theta = $theta");
    Matrix3 rotationWithTheta = Matrix3.rotationY(theta);
    Vector3 northPole = Vector3(0, 0, radiusEarth);
    Vector3 pointOnPlane = rotationWithTheta * northPole;
    Vector3 rotatedPointOnPlane = rotation * pointOnPlane;

    Vector3 normal = rotation * Vector3(0, 0, 1);
    return Plane.fromNormal(normal, rotatedPointOnPlane);
  }

  Line intersect(Plane other) {
    Vector3 directionOfFinalLine = Vector3(0, 0, 0);
    cross3(getNormal(), other.getNormal(), directionOfFinalLine);
    Vector3 directionInPlane1 = Vector3(0, 0, 0);
    cross3(getNormal(), directionOfFinalLine, directionInPlane1);
    Vector3 directionInPlane2 = Vector3(0, 0, 0);
    cross3(other.getNormal(), directionOfFinalLine, directionInPlane2);
    Line l1 = Line(directionInPlane1, getAPointOn());
    Line l2 = Line(directionInPlane2, other.getAPointOn());
    Vector3 pointOnLine = l1.intersect(l2);
    return Line(directionOfFinalLine, pointOnLine);
  }

  List<Vector3> intersectOnEarth(Plane other) {
    Line l = intersect(other);
    List<double> sols = solveQuadratic(
      l.dir.length2,
      2 * dot3(l.dir, l.point),
      l.point.length2 - radiusEarth * radiusEarth,
    );
    return sols.map<Vector3>((double t) => l.point + l.dir * t).toList();
  }

  @override
  String toString() {
    return "(a,b,c,d)=($a, $b, $c, $d)";
  }
}

Vector3 latLngToVec3(LatLng point) {
  return latLngToVec3ForDistance(point) * circumferenceEarth;
}

Vector3 latLngToVec3ForDistance(LatLng point) {
  double theta = point.longitudeInRad;
  double phi = 0.5 * math.pi + point.latitudeInRad;
  return Vector3(
    math.cos(theta) * math.sin(phi),
    math.sin(theta) * math.sin(phi),
    math.cos(phi),
  );
}

double getDistanceAlongSphere(Vector3 a, Vector3 b) {
  print("distance between ${a} and ${b}");
  print("Value is ${dot3(a, b)}");
  double inner = dot3(a, b);
  if (inner > 1) inner -= epsilon;
  if (inner < -1) inner += epsilon;
  return math.acos(inner) / (2 * math.pi) * circumferenceEarth;
}
