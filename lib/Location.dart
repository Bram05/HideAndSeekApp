import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class LocationMarker extends StatefulWidget {
  const LocationMarker({super.key});

  @override
  State<StatefulWidget> createState() => LocationMarkerState();
}

LatLng? lastPosition;
LatLngDart lastPositionForCpp() {
  return Struct.create()
    ..lat = lastPosition!.latitude
    ..lon = lastPosition!.longitude;
}

class LocationMarkerState extends State<LocationMarker> {
  StreamSubscription<Position>? positionStream;
  @override
  void initState() {
    final LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100,
    );
    Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position? position,
    ) {
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
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (lastPosition == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: lastPosition!,
          child: Image.file(File("assets/marker.png")),
          width: 50,
          height: 50,
          rotate: true,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }
}
