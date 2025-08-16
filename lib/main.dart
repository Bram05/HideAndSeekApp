import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jetlag/Map.dart';
import 'package:jetlag/choose_boundary.dart';
import 'package:jetlag/map_fun.dart';
import 'package:jetlag/new_border.dart';
import 'package:path_provider/path_provider.dart';

late String documentsdir;
bool init = false;

Future<void> setAppDir() async {
  if (init) return;
  documentsdir = (await getApplicationDocumentsDirectory()).path;
  Directory f = Directory(documentsdir);
  if (!await f.exists()) await f.create(recursive: true);
  init = true;
}

void main() async {
  print("Running");
  runApp(MyApp());
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      name: 'ChooseBoundary',
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
    GoRoute(
      path: "/mapfun",
      name: "MapFun",
      builder: (context, state) => MapFunWidget(),
    ),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
    return SafeArea(child: MaterialApp.router(routerConfig: _router));
  }
}
