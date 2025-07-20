import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Map.dart';
import 'package:jetlag/Plane.dart';
import 'package:jetlag/constants.dart';
import 'package:jetlag/shape.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/geolocation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

import 'package:vector_math/vector_math_64.dart' hide Plane;

Shape getShapeOfEqualDistance(Vector3 a, Vector3 b, bool closeToA) {
  Vector3 coefficients = (a - b) * (closeToA ? 1 : -1);
  coefficients.normalize();
  Plane p = Plane(coefficients.x, coefficients.y, coefficients.z, 0);
  // print('dot: ${dot3((a - b).normalized(), (a + b).normalized())}');
  Vector3 centre = p.getNormal().normalized();
  LatLng centreLatLng = vec3ToLatLng(centre);
  Side s1 = CircleEdge(
    center: centreLatLng,
    radius: 0.25 * circumferenceEarth,
    startAngle: 0,
    sweepAngle: math.pi,
    plane: p,
  );
  Side s2 = CircleEdge(
    center: centreLatLng,
    radius: 0.25 * circumferenceEarth,
    startAngle: math.pi,
    sweepAngle: math.pi,
    plane: p,
  );
  Vector3 middle = (a + b) / 2;
  assert(p.liesInside(middle));
  return Shape(
    segments: [
      Segment(vertices: [middle, -middle], sides: [s1, s2]),
    ],
  );
}

Vector3 getPos(var museum) {
  if (museum["type"] == "node") {
    print("Found 'node' museum");
    return latLngToVec3(LatLng(museum["lat"], museum["lon"]));
  } else if (museum["type"] == "way") {
    Vector3 min = latLngToVec3(
      LatLng(museum["bounds"]["minlat"], museum["bounds"]["minlon"]),
    );
    Vector3 max = latLngToVec3(
      LatLng(museum["bounds"]["maxlat"], museum["bounds"]["maxlon"]),
    );
    return (min + max) / 2;
  } else {
    print("Found different type of museum ${museum["type"]}");
    return Vector3(0, 0, 0);
  }
}

Future<LatLng> getPosition() async {
  // return determinePosition().then((val) => LatLng(val.latitude, val.longitude));
  return LatLng(52.358430, 4.883357);
  // return LatLng(52.3578609, 4.88499575);
}

Future<Shape> updateBoundary(
  Shape boundary,
  MapWidgetState state,
  MapCamera camera,
) async {
  LatLng pos = await getPosition();
  print("Current position is $pos");

  // var result = await http.post(
  //   Uri.parse('https://overpass-api.de/api/interpreter'),
  //   body: {
  //     "data":
  //         '''[out:json][timeout:90];
  //           nwr['tourism' = 'museum'](around:1000,${pos.latitude}, ${pos.longitude});
  //           out geom;''',
  //   },
  // );
  var result = await File("downloads/museums.json").readAsString();
  // File("downloads/museums.json").writeAsString(result.body);
  // var json = jsonDecode(result.body);
  var json = jsonDecode(result);
  Vector3 posVector = latLngToVec3(pos);
  Shape currentBoundary = boundary;
  Shape s = Shape(segments: []);
  print("Got ${json["elements"].length} museums");
  int count = 0;
  for (var museum in json["elements"]) {
    if (museum["type"] == "relation") {
      continue;
    }
    ++count;
    // if (count != 8) continue;
    Vector3 museumPosition = getPos(museum);
    // posVector = Vector.fromLatLng(LatLng(0, 0));
    // ui.Offset museumoffset = camera.latLngToScreenOffset(
    //   vec3ToLatLng(museumPosition),
    // );
    // ui.Offset posOffset = camera.latLngToScreenOffset(vec3ToLatLng(posVector));
    // ui.Offset diff = ui.Offset(
    //   museumoffset.dx - posOffset.dx,
    //   museumoffset.dy - posOffset.dy,
    // );
    // ui.Offset vector = ui.Offset(-diff.dy, diff.dx);
    // ui.Offset middle = ui.Offset(
    //   (museumoffset.dx + posOffset.dx) / 2,
    //   (museumoffset.dy + posOffset.dy) / 2,
    // );
    // // museumPosition = Vector.fromLatLng(LatLng(1, 1));
    // // state.points.add(museumPosition.toLatLng());
    // // Vector diff = museumPosition - posVector;
    // // // diff = Vector(
    // // //   diff.x / 180,
    // // //   diff.y / 90,
    // // // ); // Make sure both are in range [-1, 1]
    // // Vector vector = Vector(-diff.y, diff.x); // rotate left
    // // // vector.x *= 180;
    // // // vector.y *= 90;
    // // // Vector vector = Vector(diff.
    // // Vector middle = (museumPosition + posVector) / 2;
    // // state.points.add(middle.toLatLng());
    // // state.points.add((middle - vector).toLatLng());
    // // Vector middle = Vector((position.latitude + pos.latitude)/2, (position.longitude + pos.longitude)/2);
    // // Vector begin = middle - vector * 2;
    // // Vector end = middle + vector * 2;
    //
    // // todo: they are currently swapped because offsets are zero at the top left
    // ui.Offset begin = ui.Offset(
    //   middle.dx + vector.dx * 5,
    //   middle.dy + vector.dy * 5,
    // );
    // ui.Offset end = ui.Offset(
    //   middle.dx - vector.dx * 5,
    //   middle.dy - vector.dy * 5,
    // );
    // print("begin: $begin, end: $end");
    // LatLng beginLatLng = camera.screenOffsetToLatLng(begin);
    // LatLng endLatLng = camera.screenOffsetToLatLng(end);
    // Vector3 beginVector = latLngToVec3(beginLatLng);
    // Vector3 endVector = latLngToVec3(endLatLng);
    // s = Shape(
    //   segments: [
    //     Segment(vertices: [beginVector, endVector], sides: [StraightEdge()]),
    //   ],
    // );
    // state.lines.add((beginLatLng, endLatLng));
    Shape s = getShapeOfEqualDistance(museumPosition, posVector, false);
    print(currentBoundary);
    Shape nextboundary = intersect(
      s,
      currentBoundary,
      state,
      // firstIsForHit: true,
    );
    // state.points.add(vec3ToLatLng(museumPosition));
    // state.points.add(vec3ToLatLng(posVector));
    // state.points.add(vec3ToLatLng((museumPosition + posVector) / 2));
    // print("length: ${nextboundary.segments.last.vertices.length}");
    if (nextboundary.segments.isEmpty) {
      print("Warning boundary empty after $count museums");
      // todo: this breaks because they don't intersect and then the ray does not intersect the boundary, although it does lie 'inside' = to the left of the line
      // print("begin = $beginLatLng, end = $endLatLng");
      // state.points.add(beginLatLng);
      // state.points.add(endLatLng);
      // state.pinks.add(s);
      return nextboundary;
    }
    currentBoundary = nextboundary;
    return currentBoundary;
  }
  return currentBoundary;
}
