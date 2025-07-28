import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:ffi/ffi.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Map.dart';
import 'package:jetlag/shape.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/geolocation.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'Maths.dart';
import 'dart:ffi';
import 'maths_generated_bindings.dart';

LatLngDart getPos(var museum) {
  if (museum["type"] == "node") {
    return Struct.create()
      ..lat = museum["lat"]
      ..lon = museum["lon"];
  } else if (museum["type"] == "way") {
    double minlat = museum["bounds"]["minlat"];
    double minlon = museum["bounds"]["minlon"];
    double maxlat = museum["bounds"]["maxlat"];
    double maxlon = museum["bounds"]["maxlon"];
    return Struct.create()
      ..lat = (minlat + maxlat) / 2
      ..lon = (minlon + maxlon) / 2;
  } else {
    print("Found different type of museum ${museum["type"]}");
    return Struct.create()
      ..lat = 0
      ..lon = 0;
  }
}

(Pointer<LatLngDart>, int) convertToList(var json) {
  int n = json["elements"].length;
  int p = 0;
  Pointer<LatLngDart> list = malloc(n);
  for (int i = 0; i < n; i++) {
    if (json["elements"][i]["type"] == "relation") {
      continue;
    }
    list[p] = getPos(json["elements"][i]);
    ++p;
  }
  return (list, p);
}

Future<LatLngDart> getPosition() async {
  // return determinePosition().then((val) => LatLng(val.latitude, val.longitude));
  // return Struct.create()
  //   ..lat = 52.358430
  //   ..lon = 4.883357;
  // return LatLng(52.3578609, 4.88499575);
  return Struct.create()
    ..lat = 52.36018057185034
    ..lon = 4.8852546013650695;
}

Future<Pointer<Void>> updateBoundary(
  Pointer<Void> boundary,
  bool closestToTheSame,
) async {
  LatLngDart pos = await getPosition();
  // print("Current position is $pos");

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
  var json = jsonDecode(result);
  var (list, n) = convertToList(json);

  Pointer<Void> res = maths.UpdateBoundaryWithClosests(
    boundary,
    pos,
    list,
    n,
    closestToTheSame ? 1 : 0,
  );
  malloc.free(list);
  return res;
  // File("downloads/museums.json").writeAsString(result.body);
  // var json = jsonDecode(result.body);
  // var json = jsonDecode(result);
  // Pointer<Void> currentBoundary = boundary;
  // print("Got ${json["elements"].length} museums");
  // int count = 0;
  // for (var museum in json["elements"]) {
  //   if (museum["type"] == "relation") {
  //     continue;
  //   }
  //   ++count;
  //   // if (count != 8) continue;
  //   LatLngDart museumPosition = getPos(museum);
  //   Pointer<Void> newBoundary = maths.UpdateBoundaryWithClosestToObject(
  //     currentBoundary,
  //     pos,
  //     museumPosition,
  //     1,
  //   );
  //   maths.FreeShape(currentBoundary);
  //   currentBoundary = newBoundary;
  //   return currentBoundary;
  // }
  // return currentBoundary;
}
