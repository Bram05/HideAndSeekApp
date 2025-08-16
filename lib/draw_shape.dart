import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/Maths.dart';
import 'package:jetlag/SettingsWidget.dart';
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
  LatLngDart? lastclick;
  List<Pointer<Void>> shapes = [];
  late Shape shapeWidget;
  List<Shape> finished = [];
  late Pointer<ShapeDart> shapeDart;

  void createShapeWidget() {
    setState(() {
      shapeWidget = Shape(
        key: UniqueKey(),
        shape: shapes.last,
        color: Colors.lime,
        focussed: false,
        renderAsBoundary: false,
        centerOfCountry: LatLng(0, 0),
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
    shapeDart = malloc()
      ..ref.segmentsCount = 1
      ..ref.segments = s;

    shapes.add(
      maths.ConvertToShape(shapeDart, 0, getDeltaFromQuality(Quality.full)),
    );
    createShapeWidget();
  }

  @override
  void dispose() {
    malloc.free(shapeDart.ref.segments);
    malloc.free(shapeDart);
    for (Pointer<Void> shape in shapes) maths.FreeShape(shape);
    super.dispose();
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
        maths.ModifyLastVertex(shapes.last, point);
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
            maths.AddFirstSide(shapes.last, posDart);
          } else {
            maths.ModifyLastVertex(shapes.last, posDart);
            maths.AddStraightSide(
              shapes.last,
            ); // The next one: to be modified by hovering
          }
          lastclick = posDart;
          firstClick = false;
          createShapeWidget();
        },
        onLongPress: () {
          print("Long pressed");
          maths.RemoveLastVertexAndSide(shapes.last);
          maths.CloseShape(shapes.last);
          widget.callback(shapes.last);
          finished.add(
            Shape(
              shape: shapes.last,
              color: Colors.blue,
              focussed: false,
              renderAsBoundary: false,
              centerOfCountry: LatLng(0, 0),
            ),
          );
          shapes.add(
            maths.ConvertToShape(
              shapeDart,
              0,
              getDeltaFromQuality(Quality.full),
            ),
          );
          setState(() {
            firstClick = true;
            createShapeWidget();
          });
        },
        child: Stack(children: [for (Shape s in finished) s, shapeWidget]),
      ),
    );
  }
}
