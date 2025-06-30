import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:jetlag/ShapeRenderer.dart';
import 'package:jetlag/shape.dart';
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
    Shape shape = Shape(
      segments: [
        Segment(
          vertices: [
            LatLng(51.5, 0.0),
            LatLng(51.5, 1.0),
            LatLng(53.5, 1.0),
            LatLng(53.5, 0.0),
          ],
          sides: [
            StraightEdge(),
            CircleEdge(
              center: LatLng(52.5, 1),
              radius: 111111,
              startAngle: 1 / 2 * math.pi,
              sweepAngle: math.pi,
            ),
            CircleEdge(
              center: LatLng(53.5, 0.5),
              radius: 33000,
              startAngle: 0,
              sweepAngle: math.pi,
            ),
            // StraightEdge(),
            CircleEdge(
              center: LatLng(52.5, 0),
              radius: 111111,
              startAngle: -1 / 2 * math.pi,
              sweepAngle: math.pi,
            ),
          ],
        ),
        Segment(
          vertices: [LatLng(52, 0.5), LatLng(52.5, 0.7), LatLng(52, 0.7)],
          sides: [
            StraightEdge(),
            CircleEdge(
              center: LatLng(52.25, 0.7),
              radius: 55556 / 2,
              startAngle: -1 / 2 * math.pi,
              sweepAngle: -math.pi,
            ),
            StraightEdge(),
          ],
        ),
      ],
    );
    return FlutterMap(
      options: const MapOptions(initialCenter: LatLng(51.5, -0.12)),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        Child(shape: shape),
        // PolygonLayer(
        //   polygons: [
        //     Polygon(
        //       // borderStrokeWidth: 100,
        //       // borderColor: Colors.red,
        //       points: [
        //         LatLng(60, 20),
        //         LatLng(70, 20),
        //         LatLng(70, 30),
        //         LatLng(60, 30),
        //       ],
        //     ),
        //   ],
        // ),
        // CircleLayer(
        //   circles: [
        //     CircleMarker(
        //       point: LatLng(65, 25),
        //       radius: 10000,
        //       useRadiusInMeter: true,
        //       color: Colors.transparent,
        //       borderColor: Colors.blue,
        //       borderStrokeWidth: 10,
        //     ),
        //   ],
        // ),
      ],
      // PolygonLayer(
      //   polygons: Polygon(
      //     points: [LatLng(40, 30), LatLng(20, 50), LatLng(25, 45)],
      //     color: Colors.blue,
      //   ),
    );
    // return Text("Hello there");
  }
}
