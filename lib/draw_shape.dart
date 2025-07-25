import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Maths.dart';
import 'package:jetlag/renderer.dart';
import 'package:latlong2/latlong.dart';
import 'maths_generated_bindings.dart';

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
      ..ref.verticesCount = 0
      ..ref.sides = Pointer.fromAddress(0)
      ..ref.sidesCount = 0;
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
        print("Modifying");
        Pointer<LatLngDart> point = malloc()
          ..ref.lat = pos.latitude
          ..ref.lon = pos.longitude;
        maths.ModifyLastVertex(shape, point.ref);
        malloc.free(point);
        createShapeWidget();
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (TapUpDetails details) {
          LatLng pos = MapCamera.of(
            context,
          ).screenOffsetToLatLng(details.localPosition);
          Pointer<LatLngDart> posDart = malloc()
            ..ref.lat = pos.latitude
            ..ref.lon = pos.longitude;
          Pointer<SideDart> side = malloc()..ref.isStraight = 1;
          if (firstClick) {
            maths.AddVertex(shape, posDart.ref, side);
            maths.AddVertex(shape, posDart.ref, side);
          } else {
            maths.ModifyLastVertex(shape, posDart.ref);
            maths.AddVertex(
              shape,
              posDart.ref,
              side,
            ); // The next one: to be modified by hovering
          }
          malloc.free(side);
          malloc.free(posDart);
          firstClick = false;
          createShapeWidget();
        },
        onLongPress: () {
          maths.RemoveLastVertexAndSide(shape);
          widget.callback(shape);
        },
        child: shapeWidget,
      ),
    );
  }
}
