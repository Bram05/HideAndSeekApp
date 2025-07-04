import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:jetlag/shape.dart';
import 'package:jetlag/Map.dart';
import 'dart:math' as math;

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
    Shape s = Shape(
      segments: [
        Segment(
          vertices: [
            LatLng(50.42, -1.275),
            LatLng(51.165, -0.015),
            LatLng(51.266, -1.151),
          ],
          sides: [StraightEdge(), StraightEdge(), StraightEdge()],
        ),
      ],
    );
    print(s.hit(LatLng(51.0, -1)));
    // return Text("hi");
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

    return MaterialApp(
      home: Scaffold(
        body: MapWidget(
          // shapes: [(shape1, shape2), (shape11, shape12), (shape21, shape22)],
          shapes: [],
        ),
      ),
    );
    // return Text("Hello there");
  }
}
