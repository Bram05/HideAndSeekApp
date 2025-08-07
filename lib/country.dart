import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/Maths.dart';
import 'package:jetlag/SettingsWidget.dart';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:jetlag/shape.dart';

Future<Map<String, dynamic>?> attemptGet(String spec, String name) async {
  var result = await http.post(
    Uri.parse('https://overpass-api.de/api/interpreter'),
    body: {
      "data":
          '''[out:json][timeout:90];
            $spec;
            out geom;''',
    },
  );

  bool testAdminLevel(String level) {
    if (name == "Nederland") {
      return level == "3";
    } else
      return level == "2" || level == "3" || level == "4";
  }

  if (result.statusCode != 200) {
    throw "Query for $spec returned code ${result.statusCode}";
  }
  var json = jsonDecode(result.body);
  for (var element in json["elements"]) {
    if (json["elements"].length == 1 ||
        (element["type"] == "relation" || element["type"] == "boundary") &&
            testAdminLevel(element["tags"]["admin_level"])) {
      return element;
    }
  }
  return null;
}

Future<Map<String, dynamic>> getRequest({String? name, int? ref}) async {
  if (name != null && ref != null) throw "Internal error: Not both can be null";
  if (name != null) {
    String spec = "nwr['name' = '$name']";
    var ret = await attemptGet(spec, name);
    ret ??= await attemptGet("nwr['int_name' = '$name']", name);
    if (ret == null) throw "Cannot find such a region";
    return ret;
  } else if (ref != null) {
    String spec = "nwr($ref)";
    var el = await attemptGet(spec, "");
    if (el == null) throw "Internal error: cannot find this reference";
    return el;
  }
  throw "Internal error: at least one of name, ref must be non-null";
}

Future<void> parseAndStoreBoundary(
  Map<String, dynamic> json,
  String outFile,
) async {
  File f = File(outFile);
  String shapeJson = toShapeJson(json);
  await f.writeAsString(shapeJson);
  return Future.value();
}

Future<Map<String, dynamic>> download(
  String outFile, {
  String? name,
  int? ref,
}) async {
  var json = await getRequest(name: name, ref: ref);
  parseAndStoreBoundary(json, outFile);
  return json;
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

String toShapeJson(Map<String, dynamic> body) {
  Map<String, List<(List<LatLngDart>, String, bool)>> segmentsLeft = {};
  for (var element in body["members"]) {
    if (element["type"] != "way") {
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
      if (segmentsLeft[position] == null) {
        print("position '$position' does not exist");
        break;
      }
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
    Pointer<Void> segmentShape = maths.ConvertToShape(
      shapeDart,
      1,
      getDeltaFromQuality(Quality.full),
    );
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
    bool shapeIsCurrentlyInner = 1 == maths.hit(segmentShape, point);
    // if (wrong) {
    //   print(
    //     "inside = ${shapeIsCurrentlyInner} an isOuter = ${isOuter} point = ${point.ref.lat}, ${point.ref.lon}",
    //   );
    // }
    if (shapeIsCurrentlyInner == isOuter) {
      segment = segment.reversed.toList();
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
  Pointer<Void> shapePtr = maths.ConvertToShape(
    shape,
    1,
    getDeltaFromQuality(Quality.full),
  );
  for (int i = 0; i < shape.ref.segmentsCount; i++) {
    malloc.free(shape.ref.segments[i].vertices);
  }
  malloc.free(shape.ref.segments);
  malloc.free(shape);
  String result = jsonEncode(toJson(shapePtr, []));
  maths.FreeShape(shapePtr);
  return result;
}
