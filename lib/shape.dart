import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:ui' as ui;
import 'package:vector_math/vector_math_64.dart' hide Plane;
import 'Maths.dart';
import 'dart:ffi';
import 'maths_generated_bindings.dart';
import 'package:ffi/ffi.dart';

LatLngDart latLngFromJson(Map<String, dynamic> json) {
  // This would fail if a coordinate is an integer so we add .0 to automatically convert it to a double
  if (json["x"] != null) {
    // it is still the old version
    print(
      "WARNING: json file was still the old version. Convert to new version!!!!",
    );
    LatLng v = vec3ToLatLng(
      Vector3(json["x"] + .0, json["y"] + .0, json["z"] + .0),
    );
    return Struct.create()
      ..lat = v.latitude
      ..lon = v.longitude;
  }
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
  var res = maths.ConvertToShape(p, 0);
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
)
fromJson(Map<String, dynamic> json) {
  List<Pointer<Void>> extraShapes = [];
  List<(int, int)> intersections = [];
  List<Pointer<Void>> solutions = [];
  double minLat = -100000, minLon = -100000, maxLat = -100000, maxLon = -100000;
  for (var shape in json["shapes"]) {
    var ret = shapeFromJson(shape);
    extraShapes.add(ret.$1);
    minLat = ret.$2;
    minLon = ret.$3;
    maxLat = ret.$4;
    maxLon = ret.$5;
  }
  for (var intersection in json["intersections"]) {
    intersections.add((intersection["first"], intersection["second"]));
    var ret = shapeFromJson(intersection["solution"]);
    solutions.add(ret.$1);
  }

  // print("Loaded ${extraShapes.length} extra shapes from json");
  return (
    extraShapes,
    intersections,
    solutions,
    minLat,
    minLon,
    maxLat,
    maxLon,
  );
}

// For single shape
Map<String, dynamic> toJson(Pointer<Void> shape) {
  return {
    "shapes": [shapeToJson(shape)],
    "intersections": [],
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

// todo: delete when starting new shape
Map<(int, int), (Pointer<LatLngDart>, int)> cachedIntPoints = {};
ui.Path getPath(Pointer<Void> shape, MapCamera camera, ui.Size containerSize) {
  int numSegments = maths.GetNumberOfSegments(shape);
  if (numSegments == 0) {
    return ui.Path();
  }

  // const int numIntermediatePoints = 5;
  const int meterPerIntermediatePoint = 10;

  int numPoints = 0;
  int total = 0;

  ui.Path path = ui.Path();
  // path.fillType = ui.PathFillType.nonZero;
  path.fillType = ui.PathFillType.evenOdd;
  for (int i = 0; i < numSegments; i++) {
    int numSides = maths.GetNumberOfSidesInSegment(shape, i);
    int delta = 1;
    if (numSides > 600) {
      delta = 10;
      // delta = 1;
    }
    if (numSides <= 2) return ui.Path();
    for (int j = 0; j < numSides; j += delta) {
      Pointer<LatLngDart> intermediatePoints;
      int numIntermediatePoints;
      if (cachedIntPoints[(i, j)] == null) {
        Pointer<Int> k = malloc();
        intermediatePoints = maths.GetIntermediatePoints(
          shape,
          i,
          j,
          meterPerIntermediatePoint,
          k,
        );
        numIntermediatePoints = k.value;
        malloc.free(k);
        // cachedIntPoints[(i, j)] = (intermediatePoints, numIntermediatePoints);
      } else {
        (intermediatePoints, numIntermediatePoints) = cachedIntPoints[(i, j)]!;
      }
      numPoints += numIntermediatePoints;
      ++total;
      if (intermediatePoints == Pointer.fromAddress(0)) return path;

      ui.Offset coords = getCoordinates(intermediatePoints[0], camera);
      if (j == 0) path.moveTo(coords.dx, coords.dy);
      for (int k = 1; k < numIntermediatePoints; k++) {
        coords = getCoordinates(intermediatePoints[k], camera);
        path.lineTo(coords.dx, coords.dy);
      }

      // maths.FreeIntermediatePoints(intermediatePoints);
    }
    path.close();
  }
  // print("Finished getting path");
  // // ui.Path path = getPath(shape, MapCamera.of(context), size);
  // ui.Path otherPath = ui.Path();
  // otherPath.moveTo(0, 0);
  // // otherPath.lineTo(200, 200);
  // // otherPath.lineTo(100, 200);
  // otherPath.lineTo(0, containerSize.height);
  // otherPath.lineTo(containerSize.width, containerSize.height);
  // otherPath.lineTo(containerSize.width, 0);
  // otherPath.close();
  // path.addPath(otherPath, ui.Offset(0, 0));
  path.fillType = PathFillType.nonZero;

  return path;
  // return otherPath;
}

double epsilon = 0.000001;
bool close(double a, double b) {
  return (a - b).abs() < epsilon;
}

double clamp(double val) {
  if (val > 1) {
    assert(val - epsilon <= 1);
    return 1;
  } else if (val < -1) {
    assert(val + epsilon >= -1);
    return -1.0;
  }
  return val;
}

// Todo: remove this
LatLng vec3ToLatLng(Vector3 point) {
  assert(close(point.length2, 1));
  double longitude;
  if (close(point.x, 0) && close(point.y, 0)) {
    // this value does not matter
    longitude = 0;
  } else {
    double r2 = point.length2;
    double s = math.sqrt(r2 - point.z * point.z); // r^2-z^2 = x^2+y^2 >= 0
    if (close(point.x, 0)) {
      // This check is needed because we are outside the 'correct' domain of arcsin
      if (point.y > 0) {
        longitude = 0;
      } else {
        longitude = 180;
      }
    } else {
      double inner = -point.x / s;
      inner = clamp(inner);
      longitude = math.asin(inner) / math.pi * 180;
      if (point.y < 0) {
        longitude = 180 - longitude;
      }
      if (longitude > 180) {
        longitude -= 360;
        assert(longitude <= 180);
      }
    }
  }
  return LatLng(math.asin(point.z / point.length) / math.pi * 180, longitude);
}
