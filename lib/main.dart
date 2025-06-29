import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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

class Child extends StatefulWidget {
  const Child({super.key});
  @override
  State<Child> createState() => ChildState();
}

ui.Path getPath(BuildContext context) {
  ui.Path path = ui.Path();

  MapCamera c = MapCamera.of(context);
  path.moveTo(0, 0);
  path.addPolygon([
    c.latLngToScreenOffset(LatLng(51.5, 0.0)),
    c.latLngToScreenOffset(LatLng(51.5, 1.0)),
    c.latLngToScreenOffset(LatLng(53.5, 1.0)),
    c.latLngToScreenOffset(LatLng(53.5, 0.0)),
  ], false);
  Offset bottomleft = c.latLngToScreenOffset(LatLng(51.5, -1));
  Offset topright = c.latLngToScreenOffset(LatLng(53.5, 1));
  Rect rec = Rect.fromLTRB(
    bottomleft.dx,
    topright.dy,
    topright.dx,
    bottomleft.dy,
  );
  path.addArc(rec, 1 / 2 * math.pi, math.pi);
  return path;
}

class MyClipper extends CustomClipper<ui.Path> {
  BuildContext context;
  MyClipper({required this.context});

  @override
  ui.Path getClip(Size size) {
    return getPath(context);
  }

  @override
  bool shouldReclip(covariant CustomClipper<ui.Path> oldClipper) {
    return true;
  }
}

class BorderPainter extends CustomPainter {
  BuildContext context;
  BorderPainter({required this.context});
  @override
  void paint(Canvas canvas, Size size) {
    ui.Paint p = ui.Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..color = Colors.black;
    canvas.drawPath(getPath(context), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class ChildState extends State<Child> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        MapCamera c = MapCamera.of(context);
        double width = constraints.maxWidth, height = constraints.maxHeight;
        double stop = 0.05;
        Offset o = c.latLngToScreenOffset(LatLng(stop, 0));
        Offset end = c.latLngToScreenOffset(LatLng(0, stop));
        Alignment topleft = Alignment(
          o.dx / width * 2 - 1,
          o.dy / height * 2 - 1,
        );
        Alignment bottomright = Alignment(
          end.dx / width * 2 - 1,
          end.dy / height * 2 - 1,
        );

        return ClipPath(
          clipper: MyClipper(context: context),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: topleft,
                end: bottomright,
                stops: [0.0, 0.5, 0.5, 1.0],
                colors: [
                  Colors.grey,
                  Colors.grey,
                  Colors.transparent,
                  Colors.transparent,
                ],
                tileMode: TileMode.repeated,
              ),
            ),
            child: CustomPaint(painter: BorderPainter(context: context)),
          ),
          //   ),
          //   CustomPaint(painter: BorderPainter(context: context)),
          // ],
        );
      },
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
    // return Child();
    return FlutterMap(
      options: const MapOptions(initialCenter: LatLng(51.5, -0.12)),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
        Child(),
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
