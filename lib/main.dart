import 'package:ffi/ffi.dart';
// import 'package:jetlag/constants.dart';
// import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/Boundary.dart';
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

// void main() async {
//   var museums = jsonDecode(await File("downloads/museums.json").readAsString());
//   var (list, n) = convertToList(museums);
//
//   // var result = await http.post(
//   //   Uri.parse('https://overpass-api.de/api/interpreter'),
//   //   body: {
//   //     "data":
//   //         '''[out:json][timeout:90];
//   //           nwr['tourism' = 'museum'](around:1000,${pos.latitude}, ${pos.longitude});
//   //           out geom;''',
//   //   },
//   // );
//
//   LatLngDart position = Struct.create()
//     ..lat = 52.36018057185034
//     ..lon = 4.8852546013650695;
//   File f = File("newtests/boxAroundRijksmuseum.json");
//   File solutionFile = File("newtests/boxAroundRijksmuseumSolution.json");
//
//   // Updating the boundary clears it so we have to load it twice
//   var (boundaries1, _, _, _, _, _, _) = fromJson(
//     jsonDecode(await f.readAsString()),
//   );
//   var (boundaries2, _, _, _, _, _, _) = fromJson(
//     jsonDecode(await f.readAsString()),
//   );
//   assert(boundaries1.length == 1);
//   assert(boundaries2.length == 1);
//   var (solution, _, _, _, _, _, _) = fromJson(
//     jsonDecode(await solutionFile.readAsString()),
//   );
//   assert(solution.length == 1);
//   void test(Pointer<Void> result, Pointer<Void> sol) {
//     if (1 != maths.ShapesEqual(result, sol)) {
//       File f = File("out.json");
//       f.writeAsString(jsonEncode(shapeToJson(result)));
//       maths.whyUnequal(result, sol);
//       assert(false);
//     }
//   }
//
//   test(
//     maths.UpdateBoundaryWithClosests(boundaries1[0], position, list, n, 1),
//     solution[0],
//   );
//   maths.Reverse(solution[0]);
//   test(
//     maths.UpdateBoundaryWithClosests(boundaries2[0], position, list, n, 0),
//     solution[0],
//   );
//   maths.FreeShape(solution[0]);
//   malloc.free(list);
// }
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
