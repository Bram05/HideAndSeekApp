import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'maths.dart';
import 'dart:ffi';
import 'maths_generated_bindings.dart';
import 'package:ffi/ffi.dart';

LatLngDart latLngFromJson(Map<String, dynamic> json) {
  // This would fail if a coordinate is an integer so we add .0 to automatically convert it to a double
  return Struct.create()
    ..lat = json["latitude"] + .0
    ..lon = json["longitude"] + .0;
}

Map<String, dynamic> latLngToJson(LatLngDart latLng) {
  return {"latitude": latLng.lat, "longitude": latLng.lon};
}

(SegmentDart, double, double, double, double) segmentfromJson(
  List<dynamic> json,
  double minLat,
  double minLon,
  double maxLat,
  double maxLon,
) {
  Pointer<LatLngDart> vertices = malloc(json.length);
  for (int i = 0; i < json.length; i++) {
    vertices[i] = latLngFromJson(json[i]);
    minLat = math.min(minLat, vertices[i].lat);
    maxLat = math.max(maxLat, vertices[i].lat);
    minLon = math.min(minLon, vertices[i].lon);
    maxLon = math.max(maxLon, vertices[i].lon);
  }
  return (
    malloc<SegmentDart>().ref
      ..vertices = vertices
      ..verticesCount = json.length,
    minLat,
    minLon,
    maxLat,
    maxLon,
  );
}

List<Map<String, dynamic>> segmentToJson(Pointer<Void> shape, int index) {
  List<Map<String, dynamic>> vertices = [];
  Pointer<Int> lengthPtr = malloc.allocate<Int>(sizeOf<Int>());
  Pointer<LatLngDart> verticesP = maths.GetAllVertices(shape, index, lengthPtr);
  for (int i = 0; i < lengthPtr.value; i++) {
    vertices.add(latLngToJson(verticesP[i]));
  }
  // int numVertices = lengthPtr.value;
  // Pointer<SideDart> sidesP = maths.GetSides(segments, index, lengthPtr);
  // for (int i = 0; i < numVertices; i++) {
  //   vertices.add(latLngToJson(verticesP[i]));
  //   vertices.add(latLngToJson(sidesP[i].thirdPointOn));
  // }
  // maths.FreeSides(sidesP);
  maths.FreeVertices(verticesP);
  malloc.free(lengthPtr);

  return vertices;
}

(Pointer<Void>, double, double, double, double) shapeFromJson(
  List<dynamic> json,
  int toSkipForQuality,
) {
  Pointer<SegmentDart> segments = malloc(json.length);
  double minLat = 10000, minLon = 10000, maxLat = -10000, maxLon = -10000;
  for (int i = 0; i < json.length; i++) {
    var ret = segmentfromJson(json[i], minLat, minLon, maxLat, maxLon);
    segments[i] = ret.$1;
    minLat = ret.$2;
    minLon = ret.$3;
    maxLat = ret.$4;
    maxLon = ret.$5;
  }
  var p = malloc<ShapeDart>()
    ..ref.segments = segments
    ..ref.segmentsCount = json.length;
  var res = maths.ConvertToShape(p, 0, toSkipForQuality);
  for (int i = 0; i < p.ref.segmentsCount; i++) {
    SegmentDart s = p.ref.segments[i];
    malloc.free(s.vertices);
  }
  return (res, minLat, minLon, maxLat, maxLon);
}

List<List<Map<String, dynamic>>> shapeToJson(Pointer<Void> shape) {
  Pointer<Int> lengthPtr = malloc.allocate<Int>(sizeOf<Int>());
  Pointer<Void> _ = maths.GetSegments(shape, lengthPtr);
  int length = lengthPtr.value;
  List<List<Map<String, dynamic>>> segmentsJson = [];
  for (int i = 0; i < length; i++) {
    segmentsJson.add(segmentToJson(shape, i));
  }
  malloc.free(lengthPtr);
  return segmentsJson;
}

(
  List<Pointer<Void>>,
  List<(int, int)>,
  List<Pointer<Void>>,
  double,
  double,
  double,
  double,
  List<List<bool>>,
)
fromJson(Map<String, dynamic> json, int toSkipForQuality) {
  List<Pointer<Void>> extraShapes = [];
  List<(int, int)> intersections = [];
  List<Pointer<Void>> solutions = [];
  double minLat = -100000, minLon = -100000, maxLat = -100000, maxLon = -100000;
  for (var shape in json["shapes"]) {
    var ret = shapeFromJson(shape, toSkipForQuality);
    extraShapes.add(ret.$1);
    minLat = ret.$2;
    minLon = ret.$3;
    maxLat = ret.$4;
    maxLon = ret.$5;
  }
  for (var intersection in json["intersections"]) {
    intersections.add((intersection["first"], intersection["second"]));
    var ret = shapeFromJson(intersection["solution"], toSkipForQuality);
    solutions.add(ret.$1);
  }

  List<List<bool>> questionsUsed = [];
  if (json["questionsUsed"] != null) {
    for (var item in json["questionsUsed"]) {
      List<bool> list = [];
      for (var q in item) list.add(q);
      questionsUsed.add(list);
    }
  }

  return (
    extraShapes,
    intersections,
    solutions,
    minLat,
    minLon,
    maxLat,
    maxLon,
    questionsUsed,
  );
}

// For single shape
Map<String, dynamic> toJson(
  Pointer<Void> shape,
  List<List<bool>> questionsUsed,
) {
  return {
    "shapes": [shapeToJson(shape)],
    "intersections": [],
    "questionsUsed": questionsUsed,
  };
}

LatLng latLngDartToLatLng(LatLngDart latLng) {
  return LatLng(latLng.lat, latLng.lon);
}

Pointer<LatLngDart> latLngToLatLngDart(LatLng latLng) {
  return malloc<LatLngDart>()
    ..ref.lat = latLng.latitude
    ..ref.lon = latLng.longitude;
}

ui.Offset getCoordinates(LatLngDart point, MapCamera camera) {
  return camera.latLngToScreenOffset(latLngDartToLatLng(point));
}

ui.Path getPath(Pointer<Void> shape, MapCamera camera, ui.Size containerSize) {
  int numSegments = maths.GetNumberOfSegments(shape);
  if (numSegments == 0) {
    return ui.Path();
  }

  const double meterPerIntermediatePoint = 100;
  const int maxIntermediatePoints = 1000;

  ui.Path path = ui.Path();
  path.fillType = ui.PathFillType.evenOdd;
  for (int i = 0; i < numSegments; i++) {
    int numSides = maths.GetNumberOfSidesInSegment(shape, i);
    int delta = 1;
    int min = 10;
    if (numSides > 1000) {
      min = 2; // Neede to render Germany properly on mobile
    }
    if (numSides > 10000) {
      delta = (numSides / 1000).toInt();
      min = 2;
    }
    if (numSides < 2) return ui.Path();
    for (int j = 0; j < numSides; j += delta) {
      Pointer<LatLngDart> intermediatePoints;
      int numIntermediatePoints;
      Pointer<Int> k = malloc();
      intermediatePoints = maths.GetIntermediatePoints(
        shape,
        i,
        j,
        meterPerIntermediatePoint,
        k,
        maxIntermediatePoints,
        min,
      );
      numIntermediatePoints = k.value;
      malloc.free(k);
      if (intermediatePoints == Pointer.fromAddress(0)) return path;

      ui.Offset coords = getCoordinates(intermediatePoints[0], camera);
      if (j == 0) path.moveTo(coords.dx, coords.dy);
      for (int k = 1; k < numIntermediatePoints; k++) {
        coords = getCoordinates(intermediatePoints[k], camera);
        path.lineTo(coords.dx, coords.dy);
      }
      maths.FreeIntermediatePoints(intermediatePoints);
    }
    path.close();
  }
  path.fillType = PathFillType.nonZero;

  return path;
}
