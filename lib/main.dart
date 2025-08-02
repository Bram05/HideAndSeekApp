import 'package:ffi/ffi.dart';
// import 'package:jetlag/constants.dart';
// import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
// import 'package:jetlag/shape.dart';
import 'package:jetlag/Map.dart';
import 'package:jetlag/choose_boundary.dart';
import 'package:jetlag/country.dart';
import 'package:jetlag/new_border.dart';
// import 'dart:math' as math;
// import 'dart:convert';
// // import 'package:jetlag/Plane.dart' hide Plane;
// import 'package:vector_math/vector_math_64.dart' hide Colors, Plane;

import 'Maths.dart';
import 'dart:ffi';
import 'maths_generated_bindings.dart';
import 'shape.dart';
import 'dart:io';
import 'dart:convert';

void main() => runApp(MyApp());

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name:
          'ChooseBoundary', // Optional, add name to your routes. Allows you navigate by name instead of path
      path: '/',
      builder: (context, state) => ChooseBoundary(),
    ),
    GoRoute(
      name: 'Map',
      path: '/map/:path',
      builder: (context, state) =>
          MapWidget(renderExtras: true, border: state.pathParameters["path"]!),
    ),
    GoRoute(
      name: "CreateBoundary",
      path: "/create",
      builder: (context, state) => NewBorder(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OSM Flutter Application',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(body: const OSMFlutterMap()),
    );
    // return OSMFlutterMap();
  }
}

class OSMFlutterMap extends StatefulWidget {
  const OSMFlutterMap({super.key});

  @override
  State<OSMFlutterMap> createState() => _OSMFlutterMapState();
}

class _OSMFlutterMapState extends State<OSMFlutterMap> {
  bool running = false;
  String border = "";
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: _router);
  }
}
