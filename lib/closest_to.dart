import 'package:ffi/ffi.dart';
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
