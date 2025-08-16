import 'dart:async';
import 'dart:ffi' hide Size;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Maths.dart';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:jetlag/renderer.dart';
import 'package:latlong2/latlong.dart';

class CircleWidget extends StatefulWidget {
  const CircleWidget({super.key});
  @override
  State<StatefulWidget> createState() => CircleWidgetState();
}

LatLngDart toLatLngDart(LatLng l) {
  return Struct.create()
    ..lat = l.latitude
    ..lon = l.longitude;
}

class CircleWidgetState extends State<CircleWidget> {
  late LatLng centre;
  late Pointer<Void> circle;
  late double radius = 100000;
  final FocusNode _focusNode = FocusNode();
  bool singlePress = true;
  DateTime? atpress;
  Timer? t;
  void updateCircle() {
    if (radius > 20000000) radius = 20000000;
    // if (radius < 1) radius = 1;
    maths.FreeShape(circle);
    circle = maths.CreateCircle(toLatLngDart(centre), radius);
  }

  @override
  void initState() {
    // Size size = MediaQuery.of(context).size;
    // centre = MapCamera.of(context).screenOffsetToLatLng(Offset(0, 0));
    centre = LatLng(0, 0);
    circle = maths.CreateCircle(toLatLngDart(centre), radius);
    super.initState();
  }

  @override
  void dispose() {
    if (t != null) t!.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ShortcutRegistry.of(context).addAll({
      SingleActivator(LogicalKeyboardKey.keyU): VoidCallbackIntent(() {
        setState(() {
          radius *= 1.2;
          updateCircle();
        });
      }),
      SingleActivator(LogicalKeyboardKey.keyD): VoidCallbackIntent(() {
        setState(() {
          radius /= 1.2;
          updateCircle();
        });
      }),
    });
    void updateCentre(Offset location) {
      setState(() {
        centre = MapCamera.of(context).screenOffsetToLatLng(location);
        print("New centre $centre");
        updateCircle();
      });
    }

    return GestureDetector(
      onLongPressStart: (e) {
        t = Timer.periodic(Duration(milliseconds: 5), (Timer t) {
          setState(() {
            if (singlePress)
              radius *= 1.005;
            else
              radius /= 1.005;
            updateCircle();
          });
        });
      },
      onLongPressEnd: (e) {
        t!.cancel();
      },
      onDoubleTapDown: (e) {
        singlePress = false;
        atpress = DateTime.now();
      },
      onTapDown: (e) {
        if (DateTime.now().difference(atpress!) <
            (Duration(milliseconds: 400))) {
          return;
        }
        singlePress = true;
      },
      onTapUp: (e) {
        updateCentre(e.localPosition);
      },
      child: MouseRegion(
        onHover: (e) {
          updateCentre(e.localPosition);
        },
        child: Shape(
          shape: circle,
          color: Colors.blue,
          focussed: false,
          renderAsBoundary: false,
        ),
      ),
    );
  }
}
