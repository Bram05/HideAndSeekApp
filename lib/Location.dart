import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Boundary.dart';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationMarker extends StatefulWidget {
  const LocationMarker({super.key});

  @override
  State<StatefulWidget> createState() => LocationMarkerState();
}

LatLng lastPosition = LatLng(0, 0);
LatLngDart lastPositionForCpp() {
  return Struct.create()
    ..lat = lastPosition.latitude
    ..lon = lastPosition.longitude;
}

class LocationMarkerState extends State<LocationMarker> {
  @override
  Widget build(BuildContext context) {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    StreamSubscription<Position> positionStream =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position? position) {
          print(
            position == null
                ? 'Unknown'
                : '${position.latitude.toString()}, ${position.longitude.toString()}',
          );
          if (position != null)
            setState(() {
              lastPosition = LatLng(position.latitude, position.longitude);
            });
        });
    return FutureBuilder(
      future: getPosition(),
      builder: (contetxt, snapshot) {
        if (snapshot.hasError)
          return Text("Something went wrong: ${snapshot.error.toString()}");
        if (!snapshot.hasData) return Text("Loading...");
        return MarkerLayer(
          markers: [
            Marker(
              point: lastPosition,
              child: Image.file(File("assets/marker.png")),
              width: 50,
              height: 50,
              rotate: true,
              alignment: Alignment.topCenter,
            ),
          ],
        );
      },
    );
  }
}
