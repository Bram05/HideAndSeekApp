import 'package:jetlag/constants.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:jetlag/shape.dart';
import 'package:jetlag/Map.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:jetlag/Plane.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Plane;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM Flutter Application',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const OSMFlutterMap(),
    );
  }
}

class OSMFlutterMap extends StatefulWidget {
  const OSMFlutterMap({super.key});

  @override
  State<OSMFlutterMap> createState() => _OSMFlutterMapState();
}

class _OSMFlutterMapState extends State<OSMFlutterMap> {
  @override
  Widget build(BuildContext context) {
    // var p1 = LatLng(-10, 10);
    // var p2 = LatLng(-10, -90);
    // Vector3 v1 = latLngToVec3(p1);
    // Vector3 v2 = latLngToVec3(p2);
    // print(v1);
    // print(v2);
    //
    // Plane p = Plane.fromTwoPointsAndOrigin(v1, v2);
    // print(p.liesInside(v1));

    // print(
    //   "NORMAL: ${vec3ToLatLng(Vector3(-0.06448797987826106, 0.5957289207447599, 0.8005925014884318))}",
    // );
    // print(
    //   "CROSS: ${vec3ToLatLng(Vector3(-0.10564873666214382, 0.6401757307854266, 0.7609292859096947))}",
    // );
    // return Text('hi');
    // Vector3 point = Vector3(0, 0, radiusEarth);
    // print(vec3ToLatLng(point));
    // print(latLngToVec3(vec3ToLatLng(point)));
    // LatLng point = LatLng(10, -80);
    // print(latLngToVec3(point));
    // print(vec3ToLatLng(latLngToVec3(point)));
    // return TextButton(
    //   onPressed: () async {
    //     var data = await request();
    //     var json = jsonDecode(data.body);
    //     for (var element in json["elements"]) {
    //       print("Element: ${element}");
    //     }
    //     print(data.body);
    //   },
    //   child: Text("hi"),
    // );
    // List<IntersectionPoint> p = intersectStraights(
    //   LatLng(49.798359587085926, -2.1991629121674143),
    //   LatLng(48.99717532020741, -2.1696485682447113),
    //   LatLng(49.798359587085926, -2.1991629121674143),
    //   LatLng(48.99717532020741, -2.1696485682447113),
    // );
    // print('hi');
    // for (IntersectionPoint i in p) {
    //   print(i.point);
    // }
    // return Text('hi');
    // Shape shape = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(51.5, 0.0),
    //         LatLng(51.5, 1.0),
    //         LatLng(53.5, 1.0),
    //         LatLng(53.5, 0.0),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         CircleEdge(
    //           center: LatLng(52.5, 1),
    //           radius: 111111,
    //           startAngle: 1 / 2 * math.pi,
    //           sweepAngle: math.pi,
    //         ),
    //         CircleEdge(
    //           center: LatLng(53.5, 0.5),
    //           radius: 33000,
    //           startAngle: 0,
    //           sweepAngle: math.pi,
    //         ),
    //         // StraightEdge(),
    //         CircleEdge(
    //           center: LatLng(52.5, 0),
    //           radius: 111111,
    //           startAngle: -1 / 2 * math.pi,
    //           sweepAngle: math.pi,
    //         ),
    //       ],
    //     ),
    //     Segment(
    //       vertices: [LatLng(52, 0.5), LatLng(52.5, 0.7), LatLng(52, 0.7)],
    //       sides: [
    //         StraightEdge(),
    //         CircleEdge(
    //           center: LatLng(52.25, 0.7),
    //           radius: 55556 / 2,
    //           startAngle: -1 / 2 * math.pi,
    //           sweepAngle: -math.pi,
    //         ),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );

    // Shape shape = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(51.5, 0.0),
    //         LatLng(51.5, 1.0),
    //         LatLng(53.5, 1.0),
    //         LatLng(53.5, 0.0),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         CircleEdge(
    //           center: LatLng(52.5, 1),
    //           radius: 111111,
    //           startAngle: 1 / 2 * math.pi,
    //           sweepAngle: math.pi,
    //         ),
    //         CircleEdge(
    //           center: LatLng(53.5, 0.5),
    //           radius: 33000,
    //           startAngle: 0,
    //           sweepAngle: math.pi,
    //         ),
    //         // StraightEdge(),
    //         CircleEdge(
    //           center: LatLng(52.5, 0),
    //           radius: 111111,
    //           startAngle: -1 / 2 * math.pi,
    //           sweepAngle: math.pi,
    //         ),
    //       ],
    //     ),
    //     Segment(
    //       vertices: [LatLng(52, 0.5), LatLng(52.5, 0.7), LatLng(52, 0.7)],
    //       sides: [
    //         StraightEdge(),
    //         CircleEdge(
    //           center: LatLng(52.25, 0.7),
    //           radius: 55556 / 2,
    //           startAngle: -1 / 2 * math.pi,
    //           sweepAngle: -math.pi,
    //         ),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );
    // Shape shape1 = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(50, 0.0),
    //         LatLng(50, 1.0),
    //         LatLng(51, 1.0),
    //         LatLng(51, 0.0),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );
    // Shape shape2 = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(49, 0.4),
    //         LatLng(49, 0.6),
    //         LatLng(55, 0.6),
    //         LatLng(55, 0.4),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );
    // print("Intersection is ");
    // print(intersectionPoints(shape1, shape2));
    // Shape s = intersect(shape1, shape2);
    // print(s.segments[0].vertices.length);
    //
    // Shape shape11 = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(50, 2.0),
    //         LatLng(50, 3.0),
    //         LatLng(51, 3.0),
    //         LatLng(51, 2.0),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );
    // Shape shape12 = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(49, 2.4),
    //         LatLng(49, 2.6),
    //         LatLng(50.5, 2.6),
    //         LatLng(50.5, 2.4),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );
    // print("Intersection is ");
    // print(intersectionPoints(shape11, shape12));
    // Shape s2 = intersect(shape11, shape12);
    // print(s2.segments[0].vertices.length);
    //
    // Shape shape21 = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(52, 2.0),
    //         LatLng(52, 3.0),
    //         LatLng(53, 3.0),
    //         LatLng(53, 2.0),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );
    // Shape shape22 = Shape(
    //   segments: [
    //     Segment(
    //       vertices: [
    //         LatLng(51.5, 2.4),
    //         LatLng(51.5, 2.6),
    //         LatLng(52.5, 3.3),
    //         LatLng(52.5, 2.4),
    //       ],
    //       sides: [
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //         StraightEdge(),
    //       ],
    //     ),
    //   ],
    // );

    // print("Intersection is ");
    // print("${intersectionPoints(shape21, shape22)}");
    // Shape s3 = intersect(shape21, shape22);
    // print(s3.segments[0].vertices.length);

    LatLng centre = LatLng(51.84598708237366, 4.5466773833741705);
    double radius = 10000;
    var (p, p1, p2) = Plane.fromCircle(centre, radius, true);
    Side s = CircleEdge(
      center: centre,
      radius: radius,
      startAngle: 0,
      sweepAngle: math.pi,
      plane: p,
    );
    Side s2 = CircleEdge(
      center: centre,
      radius: radius,
      startAngle: math.pi,
      sweepAngle: math.pi,
      plane: p,
    );
    Segment seg = Segment(vertices: [p1, p2], sides: [s, s2]);
    Shape shape = Shape(segments: [seg]);

    return MaterialApp(
      home: Scaffold(
        body: SafeArea(child: MapWidget(shapes: [shape])),
      ),
    );
    // return Text("Hello there");
  }
}
