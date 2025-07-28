import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Maths.dart';
import 'package:jetlag/renderer.dart';
import 'package:latlong2/latlong.dart';
import 'maths_generated_bindings.dart';
import 'dart:math' as math;

class ShapeCreator extends StatefulWidget {
  final Function(Pointer<Void>) callback;
  const ShapeCreator({super.key, required this.callback});

  @override
  State<StatefulWidget> createState() {
    return ShapeCreatorState();
  }
}

class ShapeCreatorState extends State<ShapeCreator> {
  bool firstClick = true;
  LatLngDart? lastclick;
  late Pointer<Void> shape;
  late Shape shapeWidget;

  void createShapeWidget() {
    setState(() {
      shapeWidget = Shape(
        key: UniqueKey(),
        shape: shape,
        color: Colors.lime,
        focussed: false,
      );
    });
  }

  @override
  void initState() {
    super.initState();
    Pointer<SegmentDart> s = malloc()
      ..ref.vertices = Pointer.fromAddress(0)
      ..ref.verticesCount = 0;
    // ..ref.sides = Pointer.fromAddress(0)
    // ..ref.sidesCount = 0;
    Pointer<ShapeDart> shapeDart = malloc()
      ..ref.segmentsCount = 1
      ..ref.segments = s;

    shape = maths.ConvertToShape(shapeDart);
    malloc.free(s);
    malloc.free(shapeDart);
    createShapeWidget();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (PointerHoverEvent e) {
        LatLng pos = MapCamera.of(
          context,
        ).screenOffsetToLatLng(e.localPosition);
        // print("Modifying");
        LatLngDart point = Struct.create()
          ..lat = pos.latitude
          ..lon = pos.longitude;
        if (firstClick ||
            (point.lat - lastclick!.lat).abs() < 0.0001 &&
                (point.lon - lastclick!.lon).abs() < 0.0001)
          return;
        maths.ModifyLastVertex(shape, point);
        createShapeWidget();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          print("tapped up");
          LatLng pos = MapCamera.of(
            context,
          ).screenOffsetToLatLng(details.localPosition);
          LatLngDart posDart = Struct.create()
            ..lat = pos.latitude
            ..lon = pos.longitude;
          // Pointer<SideDart> side = malloc()..ref.isStraight = 1;
          if (firstClick) {
            maths.AddFirstSide(shape, posDart);
          } else {
            print("Here");
            maths.ModifyLastVertex(shape, posDart);
            maths.AddStraightSide(
              shape,
            ); // The next one: to be modified by hovering
          }
          lastclick = posDart;
          firstClick = false;
          createShapeWidget();
        },
        onLongPress: () {
          maths.RemoveLastVertexAndSide(shape);
          maths.CloseShape(shape);
          widget.callback(shape);
        },
        child: shapeWidget,
      ),
    );
  }
}
