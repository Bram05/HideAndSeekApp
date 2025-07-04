import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/shape.dart';
import 'package:jetlag/ShapeRenderer.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:ui' as ui;

(List<Shape>, List<(int, int)>, List<Shape>) fromJson(
  Map<String, dynamic> json,
) {
  List<Shape> extraShapes = [];
  List<(int, int)> intersections = [];
  List<Shape> solutions = [];
  for (var shape in json["shapes"]) {
    extraShapes.add(Shape.fromJson(shape));
  }
  for (var intersection in json["intersections"]) {
    intersections.add((intersection["first"], intersection["second"]));
    solutions.add(Shape.fromJson(intersection["solution"]));
  }

  return (extraShapes, intersections, solutions);
}

class PointPainter extends CustomPainter {
  MapCamera camera;
  (List<IntersectionData>, Map<(bool, int, int), List<IntersectionOnLine>>)
  points;
  PointPainter({required this.points, required this.camera});
  @override
  void paint(Canvas canvas, Size size) {
    List<Offset> ps = [];
    for (var data in points.$1) {
      ps.add(camera.latLngToScreenOffset(data.point));
    }
    canvas.drawPoints(
      ui.PointMode.points,
      ps,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class MapWidget extends StatefulWidget {
  List<(Shape, Shape)> shapes;
  MapWidget({super.key, required this.shapes});
  @override
  State<StatefulWidget> createState() {
    return MapWidgetState();
  }
}

const Size size = Size(1000, 1000);

class MapWidgetState extends State<MapWidget> {
  bool drawingShape = false;
  bool hittest = false;
  List<Shape> extraShapes = [];
  int focussedIndex = -1;
  List<(int, int)> intersections = [];
  int firstIntersection = -1;
  List<Shape> intended = [];
  final mapController = MapController();
  TextEditingController filenameController = TextEditingController();
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
            !hittest
                ? TextButton(
                    onPressed: () {
                      if (drawingShape) {
                        print("Stop drawing first!");
                        return;
                      }
                      setState(() {
                        hittest = true;
                      });
                    },
                    child: Text("Start hittest"),
                  )
                : TextButton(
                    onPressed: () {
                      setState(() {
                        hittest = false;
                      });
                    },
                    child: Text("Stop hittest"),
                  ),
            TextButton(
              onPressed: () {
                if (!drawingShape || hittest) {
                  print("Cannot add segment when not drawing a shape!");
                  return;
                }
                // extraShapes.last.segments.last.sides.add(
                //   StraightEdge(),
                // ); // Close the previous shape
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
            Divider(),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 100),
              child: TextField(
                controller: filenameController,
                textAlign: TextAlign.center,
              ),
            ),
            TextButton(
              onPressed: () {
                var tempJson = {};
                tempJson["shapes"] = [];

                for (Shape s in extraShapes) {
                  tempJson["shapes"].add(s.toJson());
                }

                tempJson["intersections"] = [];
                for (var (first, second) in intersections) {
                  tempJson["intersections"].add({
                    "first": first,
                    "second": second,
                    "solution": intersect(
                      extraShapes[first],
                      extraShapes[second],
                    ),
                  });
                }
                String json = jsonEncode(tempJson);
                print(json);
                var file = File("tests/${filenameController.text}.json");
                file.writeAsString(json);
              },
              child: Text("Save extra shapes to disk"),
            ),
            TextButton(
              onPressed: () async {
                var file = File("tests/${filenameController.text}.json");
                String content = await file.readAsString();
                print("File content is $content");
                var json = jsonDecode(content);
                setState(() {
                  var (extraShapesNew, intersectsNew, sol) = fromJson(json);
                  extraShapes = extraShapesNew;
                  intersections = intersectsNew;
                  intended = sol;
                });

                print("Have new shape ${extraShapes.last}");
              },
              child: Text("Load from json"),
            ),
          ],
        ),
        ConstrainedBox(
          constraints: BoxConstraints.loose(size),
          child: MouseRegion(
            onHover: (PointerHoverEvent e) {
              setState(() {
                if (hittest) {
                  for (int i = 0; i < extraShapes.length; i++) {
                    if (extraShapes[i].hit(
                      mapController.camera.screenOffsetToLatLng(
                        e.localPosition,
                      ),
                    )) {
                      focussedIndex = i;
                      return;
                    }
                    focussedIndex = -1;
                  }
                }
              });
            },
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(50.5, 1.5),
                initialZoom: 7,
                onMapEvent: (MapEvent e) {
                  print("Got map event $e");
                  setState(() {});
                },

                // Tapposition contains screen coordinates, which we do not want
                onTap: (TapPosition _, LatLng pos) {
                  print("Clicked at position $pos");
                  if (drawingShape) {
                    setState(() {
                      extraShapes.last.segments.last.vertices.add(pos);
                      // if (extraShapes.last.segments.last.vertices.length > 1) {
                      extraShapes.last.segments.last.sides.add(StraightEdge());
                      // }
                    });
                  } else {
                    print("hit?");
                    for (int i = extraShapes.length - 1; i >= 0; i--) {
                      if (extraShapes[i].hit(pos)) {
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
                },
                onSecondaryTap: (TapPosition _, LatLng pos) {
                  print("Right click at position $pos");
                  setState(() {
                    if (drawingShape) {
                      if (extraShapes.last.segments.last.vertices.length <= 2) {
                        extraShapes.removeLast();
                      } else {
                        // extraShapes.last.segments.last.sides.add(StraightEdge());
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
                  Child(shape: s1, color: Colors.blueGrey, focussed: false),
                  Child(shape: s2, color: Colors.grey, focussed: false),
                  Child(
                    shape: intersect(s1, s2),
                    color: Colors.red,
                    focussed: false,
                  ),
                ],
                for (
                  int i = 0;
                  i < extraShapes.length;
                  i++
                ) // todo: this should not fail
                  if (extraShapes[i].segments.last.vertices.length > 2)
                    Child(
                      shape: extraShapes[i],
                      color: Colors.white,
                      focussed: (focussedIndex == i),
                    ),

                for (var (first, second) in intersections) ...[
                  Child(
                    shape: intersect(extraShapes[first], extraShapes[second]),
                    color: Colors.red,
                    focussed: false,
                  ),
                  CustomPaint(
                    painter: PointPainter(
                      points: intersectionPoints(
                        extraShapes[first],
                        extraShapes[second],
                      ),
                      camera: mapController.camera,
                    ),
                  ),
                ],
                // for (Shape shape in intended)
                //   Child(shape: shape, color: Colors.blue, focussed: false),
                Text(
                  drawingShape
                      ? "Click to add vertex to the shape"
                      : "Click to intersect shapes",
                  style: TextStyle(fontSize: 25, color: Colors.black),
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
        ),
      ],
    );
  }
}
