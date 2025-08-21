import 'dart:async';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'maths_generated_bindings.dart';
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
    positionStream =
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
    super.initState();
  }

  @override
  void dispose() {
    if (positionStream != null) {
      positionStream!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // lastPosition = LatLng(52.3676, 4.90414);
    // if (second) lastPosition = LatLng(52.03354662932838, 4.981643376818461);
    if (lastPosition == null) return const SizedBox.shrink();
    return MarkerLayer(
      markers: [
        Marker(
          point: lastPosition!,
          child: Image(image: AssetImage("assets/marker.png")),
          width: 40,
          height: 40,
          rotate: true,
          alignment: Alignment.topCenter,
        ),
      ],
    );
  }
}
