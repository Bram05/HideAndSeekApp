import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/Maths.dart';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:jetlag/shape.dart';
import 'package:latlong2/latlong.dart';

void download(String name) async {
  File f = File("countries/${name.replaceAll(' ', '_')}.json");
  // if (await f.exists()) {
  //   return;
  // }
  // var result = await http.post(
  //   Uri.parse('https://overpass-api.de/api/interpreter'),
  //   body: {
  //     "data":
  //         '''[out:json][timeout:90];
  //           nwr["name" = "$name"];
  //           out geom;''',
  //   },
  // );
  File f2 = File("countries/Europees_Nederland");

  // print("code: ${result.statusCode}");
  // if (result.statusCode != 200) {
  //   print("ERROR getting query: code=${result.statusCode}");
  //   return;
  // }
  // print("Results are: ${result.body}");
  String result = toShapeJson(await f2.readAsString());
  // f.writeAsString(toShapeJson(await f2.readAsString()));
  // print("Got result ${result}");
  await f.writeAsString(result);
}

String ToString(LatLngDart pos) {
  return "${pos.lat};${pos.lon}";
}

void AddToMap(
  Map<String, List<(List<LatLngDart>, String, bool)>> map,
  String key,
  value,
) {
  if (map[key] == null) {
    map[key] = [];
  }
  map[key]!.add(value);
}

void removeFromMap(Map map, key, value) {
  if (map[key] == null) {
    // print("ERROR");
    // print('hi');
    return;
  }
  map[key]!.removeWhere((item) => item.$2 == value.$2);
  if (map[key].isEmpty) map.remove(key);
}

void removePairFromMap(Map map, key, value) {
  removeFromMap(map, key, value);
  removeFromMap(map, value.$2, (value.$1.reversed.toList(), key));
}

double epsilon = 0.000001;
bool areEqual(LatLngDart a, LatLngDart b) {
  return (a.lat - b.lat).abs() < epsilon && (a.lon - b.lon).abs() < epsilon;
}

String toShapeJson(var body) {
  var json = jsonDecode(body);
  if (json["elements"].length != 1 ||
      json["elements"][0]["type"] != "relation") {
    print("Body $body is not a valid result");
    return "";
  }
  Map<String, List<(List<LatLngDart>, String, bool)>> segmentsLeft = {};
  for (var element in json["elements"][0]["members"]) {
    if (element["type"] != "way") {
      print("WARNING: element type ${element["type"]} is not way");
      continue;
    }
    List<LatLngDart> coordinates = [];
    for (var geom in element["geometry"]) {
      coordinates.add(
        Struct.create()
          ..lat = geom["lat"]
          ..lon = geom["lon"],
      );
    }
    AddToMap(segmentsLeft, ToString(coordinates[0]), (
      coordinates,
      ToString(coordinates.last),
      element["role"] == "outer",
    ));
    AddToMap(segmentsLeft, ToString(coordinates.last), (
      coordinates.reversed.toList(),
      ToString(coordinates[0]),
      element["role"] == "outer",
    ));
  }

  Pointer<ShapeDart> shape = malloc();
  List<List<LatLngDart>> shapeCoordinates = [];
  shape.ref.segmentsCount = 0;
  while (segmentsLeft.isNotEmpty) {
    List<LatLngDart> segment = [];
    String begin = segmentsLeft.keys.first;
    // String begin = ToString(segmentsLeft[first]![0].$1[0]);
    String position = begin;
    bool isFirst = true;
    bool isOuter = false;
    // removePairFromMap(segmentsLeft, ToString(position), segmentsLeft[first]![0]);
    do {
      var list = segmentsLeft[position]!;
      // Baarle Nassau :(
      // if ((!isFirst && list.length != 1) || (isFirst && list.length != 2)) {
      //   print("ERROR: list contained not one item!");
      //   print(
      //     "Got ${segment.length} segments and ${segmentsLeft.length} segments left",
      //   );
      //   assert(false);
      // }
      var (coords, endString, b) = list[0];
      if (isFirst)
        isOuter = b;
      else if (isOuter != b) {
        print("ERROR: side has the wrong role!");
        exit(-1);
      }
      isFirst = false;
      removePairFromMap(segmentsLeft, position, (coords, endString, b));

      for (LatLngDart p in coords) {
        segment.add(p);
      }
      position = endString;
    } while (position != begin);
    for (int i = 0; i < segment.length - 1; i++) {
      if (areEqual(segment[i], segment[i + 1])) {
        print("Removing index $i");
        segment.removeAt(i);
        --i;
      }
    }
    if (areEqual(segment[0], segment[segment.length - 1])) {
      segment.removeAt(segment.length - 1);
    }

    Pointer<LatLngDart> segmentDarts = malloc(segment.length);
    for (int i = 0; i < segment.length; i++) {
      segmentDarts[i] = segment[i];
    }
    Pointer<SegmentDart> segmentDart = malloc()
      ..ref.vertices = segmentDarts
      ..ref.verticesCount = segment.length;
    Pointer<ShapeDart> shapeDart = malloc()
      ..ref.segmentsCount = 1
      ..ref.segments = segmentDart;
    Pointer<Void> segmentShape = maths.ConvertToShape(shapeDart, 1);
    double minlat = 1000, minLon = 1000, maxLon = -1000;
    for (int i = 0; i < segment.length; i++) {
      minlat = min(minlat, segment[i].lat);
      minLon = min(minLon, segment[i].lon);
      maxLon = max(maxLon, segment[i].lon);
    }

    Pointer<LatLngDart> point = malloc()
      ..ref.lat = minlat - 0.01
      ..ref.lon = (minLon + maxLon) / 2;
    // bool inside = 1 == maths.hit(segmentShape, point);
    if (minlat < 0) {
      print(
        "ERROR: boundaries on southern hemisphere are currently not supported!",
      );
      // The firstHit does not work for these because the ray goes down and therefore we don't intersect the boundary
      exit(-1);
    }
    // bool wrong = false;
    // if (segment
    //         .firstWhere(
    //           (el) =>
    //               (el.lat - 51.4335299).abs() < epsilon,
    //               // (el.lon - 4.9138316).abs() < epsilon,
    //           orElse: () => Struct.create<LatLngDart>()
    //             ..lat = -1
    //             ..lon = -1,
    //         )
    //         .lat !=
    //     -1) {
    //   print("INFO: here is the wrong one!!!");
    //   wrong = true;
    //   // shapeIsCurrentlyInner = !shapeIsCurrentlyInner;
    // }
    bool shapeIsCurrentlyInner =
        1 == maths.FirstHitOrientedPositively(segmentShape, point);
    // if (wrong) {
    //   print(
    //     "inside = ${shapeIsCurrentlyInner} an isOuter = ${isOuter} point = ${point.ref.lat}, ${point.ref.lon}",
    //   );
    // }
    if (shapeIsCurrentlyInner == isOuter) {
      print("INFO: reversing order");
      segment = segment.reversed.toList();
    } else {
      print("INFO: not reversing");
    }
    shapeCoordinates.add(segment);
  }
  shape.ref.segmentsCount = shapeCoordinates.length;
  shape.ref.segments = malloc(shapeCoordinates.length);
  for (int i = 0; i < shapeCoordinates.length; i++) {
    shape.ref.segments[i].vertices = malloc(shapeCoordinates[i].length);
    shape.ref.segments[i].verticesCount = shapeCoordinates[i].length;
    for (int j = 0; j < shapeCoordinates[i].length; j++) {
      shape.ref.segments[i].vertices[j] = shapeCoordinates[i][j];
    }
  }
  Pointer<Void> shapePtr = maths.ConvertToShape(shape, 1);
  for (int i = 0; i < shape.ref.segmentsCount; i++) {
    malloc.free(shape.ref.segments[i].vertices);
  }
  malloc.free(shape.ref.segments);
  malloc.free(shape);
  String result = jsonEncode(toJson(shapePtr));
  maths.FreeShape(shapePtr);
  print("Finished");
  return result;
}
