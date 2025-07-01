import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/shape.dart';
import 'package:jetlag/ShapeRenderer.dart';
import 'package:latlong2/latlong.dart';

class Map extends StatefulWidget {
  List<(Shape, Shape)> shapes;
  Map({super.key, required this.shapes});
  @override
  State<StatefulWidget> createState() {
    return MapState();
  }
}

const Size size = Size(1000, 1000);

class MapState extends State<Map> {
  bool drawingShape = false;
  List<Shape> extraShapes = [];
  List<(int, int)> intersections = [];
  int firstIntersection = -1;
  final mapController = MapController();
  @override
  Widget build(BuildContext context) {
    print("Have ${extraShapes.length} extra Shapes");
    return Row(
      children: [
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                setState(() {
                  drawingShape = true;
                  extraShapes.add(
                    Shape(
                      segments: [Segment(vertices: [], sides: [])],
                    ),
                  );
                });
              },
              child: Text("Start new boundary"),
            ),
            TextButton(
              onPressed: () {
                if (!drawingShape) {
                  print("Cannot add segment when not drawing a shape!");
                  return;
                }
                setState(() {
                  extraShapes.last.segments.add(
                    Segment(vertices: [], sides: []),
                  );
                });
              },
              child: Text("Add new segment"),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  extraShapes.clear();
                  intersections.clear();
                  firstIntersection = -1;
                  drawingShape = false;
                });
              },
              child: Text("Clear everything"),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints.loose(size),
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: LatLng(50.5, 1.5),
              initialZoom: 7,

              // Tapposition contains screen coordinates, which we do not want
              onTap: (TapPosition _, LatLng pos) {
                print("Clicked at position $pos");
                if (drawingShape) {
                  setState(() {
                    extraShapes.last.segments.last.vertices.add(pos);
                    if (extraShapes.last.segments.last.vertices.length > 1) {
                      extraShapes.last.segments.last.sides.add(StraightEdge());
                    }
                  });
                } else {
                  print("hit?");
                  for (int i = extraShapes.length - 1; i >= 0; i--) {
                    if (extraShapes[i].hit(pos, mapController.camera, size)) {
                      print("hit index $i");
                      if (firstIntersection == -1) {
                        firstIntersection = i;
                        return;
                      } else {
                        setState(() {
                          intersections.add((firstIntersection, i));
                          firstIntersection = -1;
                          print(
                            "Now seeing ${intersections.length} intersections",
                          );
                        });
                        return;
                      }
                    }
                  }
                  print("Did not intersect anything");
                }
                ;
              },
              onSecondaryTap: (TapPosition _, LatLng pos) {
                print("Right click at position $pos");
                setState(() {
                  if (drawingShape) {
                    if (extraShapes.last.segments.last.vertices.length <= 2) {
                      extraShapes.removeLast();
                    } else {
                      extraShapes.last.segments.last.sides.add(StraightEdge());
                    }
                  }
                  drawingShape = false;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),

              for (var (s1, s2) in widget.shapes) ...[
                Child(shape: s1, color: Colors.blueGrey),
                Child(shape: s2, color: Colors.grey),
                Child(shape: intersect(s1, s2), color: Colors.red),
              ],
              for (Shape s in extraShapes) // todo: this should not fail
                if (s.segments.last.vertices.length > 2)
                  Child(shape: s, color: Colors.white),

              for (var (first, second) in intersections)
                Child(
                  shape: intersect(extraShapes[first], extraShapes[second]),
                  color: Colors.red,
                ),
              Text(
                drawingShape
                    ? "Click to add vertex to the shape"
                    : "Click to intersect shapes",
              ),
              // PolygonLayer(
              //   polygons: [
              //     Polygon(
              //       // borderStrokeWidth: 100,
              //       // borderColor: Colors.red,
              //       points: [
              //         LatLng(60, 20),
              //         LatLng(70, 20),
              //         LatLng(70, 30),
              //         LatLng(60, 30),
              //       ],
              //     ),
              //   ],
              // ),
              // CircleLayer(
              //   circles: [
              //     CircleMarker(
              //       point: LatLng(65, 25),
              //       radius: 10000,
              //       useRadiusInMeter: true,
              //       color: Colors.transparent,
              //       borderColor: Colors.blue,
              //       borderStrokeWidth: 10,
              //     ),
              //   ],
              // ),
            ],
            // PolygonLayer(
            //   polygons: Polygon(
            //     points: [LatLng(40, 30), LatLng(20, 50), LatLng(25, 45)],
            //     color: Colors.blue,
            //   ),
          ),
        ),
      ],
    );
  }
}
