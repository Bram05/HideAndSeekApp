import 'dart:convert';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:jetlag/Plane.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:jetlag/shape.dart';
import 'package:jetlag/ShapeRenderer.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:jetlag/Boundary.dart';
import 'package:vector_math/vector_math.dart' hide Plane, Colors;

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
  // (List<IntersectionData>, Map<(bool, int, int), List<IntersectionOnLine>>)
  List<LatLng> points;
  PointPainter({required this.points, required this.camera});
  @override
  void paint(Canvas canvas, Size size) {
    List<Offset> ps = [];
    for (var data in points) {
      ps.add(camera.latLngToScreenOffset(data));
    }
    canvas.drawPoints(
      ui.PointMode.points,
      ps,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

class LinePainter extends CustomPainter {
  MapCamera camera;
  // (List<IntersectionData>, Map<(bool, int, int), List<IntersectionOnLine>>)
  List<(LatLng, LatLng)> lines;
  LinePainter({required this.lines, required this.camera});
  @override
  void paint(Canvas canvas, Size size) {
    Paint p = Paint()
      ..color = Colors.black
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    for (var data in lines) {
      canvas.drawLine(
        camera.latLngToScreenOffset(data.$1),
        camera.latLngToScreenOffset(data.$2),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

/// A class for consolidating the definition of menu entries.
///
/// This sort of class is not required, but illustrates one way that defining
/// menus could be done.
class MenuEntry {
  const MenuEntry({
    required this.label,
    this.shortcut,
    this.onPressed,
    this.menuChildren,
  }) : assert(
         menuChildren == null || onPressed == null,
         'onPressed is ignored if menuChildren are provided',
       );
  final String label;

  final MenuSerializableShortcut? shortcut;
  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        shortcut: selection.shortcut,
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(
    List<MenuEntry> selections,
  ) {
    final Map<MenuSerializableShortcut, Intent> result =
        <MenuSerializableShortcut, Intent>{};
    for (final MenuEntry selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
      } else {
        if (selection.shortcut != null && selection.onPressed != null) {
          // print("adding shortcut ${selection.shortcut}"); todo: this prints a lot - why?
          result[selection.shortcut!] = VoidCallbackIntent(
            selection.onPressed!,
          );
        }
      }
    }
    return result;
  }
}

class MapWidget extends StatefulWidget {
  final List<(Shape, Shape)> shapes;
  const MapWidget({super.key, required this.shapes});
  @override
  State<StatefulWidget> createState() {
    return MapWidgetState();
  }
}

const Size size = Size(10, 10);

class MapWidgetState extends State<MapWidget> {
  bool drawingShape = false;
  bool museums = false;
  bool hittest = false;
  bool drewCirclePart = false;
  LatLng circleThirdPoint = LatLng(-1, -1);
  late TileLayer tileLayer;
  List<LatLng> points = [];
  List<(LatLng, LatLng)> lines = [];
  List<Shape> extraShapes = [];
  List<Shape> pinks = [];
  int focussedIndex = -1;
  List<(int, int)> intersections = [];
  int firstIntersection = -1;
  List<Shape> intended = [];
  final mapController = MapController();
  TextEditingController filenameController = TextEditingController();
  late LatLng initialPos;
  @override
  void initState() {
    initialPos = LatLng(52.358430, 4.883357);
    tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'www.example.com',
      // tileProvider: CancellableNetworkTileProvider(),
    );

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // if (museums) {
    //                 pinks.add(
    //               await updateBoundary(
    //                 extraShapes.last,
    //                 this,
    //                 mapController.camera,
    //               ),
    //             );
    //
    // }
    pinks.clear();
    lines.clear();
    // points.clear();
    return FutureBuilder<Shape>(
      future: (extraShapes.length > 0 && museums == true
          ? updateBoundary(extraShapes.last, this, mapController.camera)
          : Future(() => Shape(segments: []))),
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) return Text("waiting");

        pinks.add(asyncSnapshot.data!);
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: MenuBar(children: MenuEntry.build(_getMenus())),
                ),
              ],
              //   TextButton(
              //     onPressed: () {
              //       setState(() {
              //         drawingShape = true;
              //         extraShapes.add(
              //           Shape(
              //             segments: [Segment(vertices: [], sides: [])],
              //           ),
              //         );
              //       });
              //     },
              //     child: Text("Start new boundary"),
              //   ),
              //   !hittest
              //       ? TextButton(
              //           onPressed: () {
              //             if (drawingShape) {
              //               print("Stop drawing first!");
              //               return;
              //             }
              //             setState(() {
              //               hittest = true;
              //             });
              //           },
              //           child: Text("Start hittest"),
              //         )
              //       : TextButton(
              //           onPressed: () {
              //             setState(() {
              //               hittest = false;
              //             });
              //           },
              //           child: Text("Stop hittest"),
              //         ),
              //   TextButton(
              //     onPressed: () {
              //       if (!drawingShape || hittest) {
              //         print("Cannot add segment when not drawing a shape!");
              //         return;
              //       }
              //       // extraShapes.last.segments.last.sides.add(
              //       //   StraightEdge(),
              //       // ); // Close the previous shape
              //       setState(() {
              //         extraShapes.last.segments.add(
              //           Segment(vertices: [], sides: []),
              //         );
              //       });
              //     },
              //     child: Text("Add new segment"),
              //   ),
              //   TextButton(
              //     onPressed: () {
              //       setState(() {
              //         extraShapes.clear();
              //         intersections.clear();
              //         firstIntersection = -1;
              //         drawingShape = false;
              //       });
              //     },
              //     child: Text("Clear everything"),
              //   ),
              //   Divider(),
              //   ConstrainedBox(
              //     constraints: BoxConstraints(maxWidth: 100),
              //     child: TextField(
              //       controller: filenameController,
              //       textAlign: TextAlign.center,
              //     ),
              //   ),
              //   TextButton(
              //     onPressed: () {
              //       var tempJson = {};
              //       tempJson["shapes"] = [];
              //
              //       for (Shape s in extraShapes) {
              //         tempJson["shapes"].add(s.toJson());
              //       }
              //
              //       tempJson["intersections"] = [];
              //       for (var (first, second) in intersections) {
              //         tempJson["intersections"].add({
              //           "first": first,
              //           "second": second,
              //           "solution": intersect(
              //             extraShapes[first],
              //             extraShapes[second],
              //           ),
              //         });
              //       }
              //       String json = jsonEncode(tempJson);
              //       print(json);
              //       var file = File("tests/${filenameController.text}.json");
              //       file.writeAsString(json);
              //     },
              //     child: Text("Save extra shapes to disk"),
              //   ),
              //   TextButton(
              //     onPressed: () async {
              //       var file = File("tests/${filenameController.text}.json");
              //       String content = await file.readAsString();
              //       print("File content is $content");
              //       var json = jsonDecode(content);
              //       setState(() {
              //         var (extraShapesNew, intersectsNew, sol) = fromJson(json);
              //         extraShapes = extraShapesNew;
              //         intersections = intersectsNew;
              //         intended = sol;
              //       });
              //
              //       print("Have new shape ${extraShapes.last}");
              //     },
              //     child: Text("Load from json"),
              //   ),
              //
              //   TextButton(
              //     onPressed: () async {
              //       updateBoundary(extraShapes.last);
              //     },
              //     child: Text("Update last created boundary with museums"),
              //   ),
              // ],
            ),
            Expanded(
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
                    initialCenter: initialPos,
                    initialZoom: 7, // 17
                    onMapEvent: (MapEvent e) {
                      setState(() {});
                    },

                    // Tapposition contains screen coordinates, which we do not want
                    onTap: (TapPosition _, LatLng pos) {
                      print("Clicked at position $pos");
                      if (drawingShape) {
                        if (drewCirclePart) {
                          drewCirclePart = false;
                          Offset p1 = mapController.camera.latLngToScreenOffset(
                            extraShapes.last.segments.last.vertices.last,
                          );
                          Offset p2 = mapController.camera.latLngToScreenOffset(
                            circleThirdPoint,
                          );
                          Offset p3 = mapController.camera.latLngToScreenOffset(
                            pos,
                          );
                          Offset delta1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
                          Offset delta1Rotated = Offset(delta1.dy, -delta1.dx);
                          Offset delta1Middle = Offset(
                            (p1.dx + p2.dx) / 2,
                            (p1.dy + p2.dy) / 2,
                          );
                          Offset delta2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);
                          Offset delta2Rotated = Offset(delta2.dy, -delta2.dx);
                          Offset delta2Middle = Offset(
                            (p3.dx + p2.dx) / 2,
                            (p3.dy + p2.dy) / 2,
                          );
                          Line l1 = Line(
                            Vector3(delta1Rotated.dx, delta1Rotated.dy, 0),
                            Vector3(delta1Middle.dx, delta1Middle.dy, 0),
                          );
                          Line l2 = Line(
                            Vector3(delta2Rotated.dx, delta2Rotated.dy, 0),
                            Vector3(delta2Middle.dx, delta2Middle.dy, 0),
                          );
                          Vector3 centre = l1.intersect(l2);
                          assert(close(centre.z, 0));
                          extraShapes.last.segments.last.vertices.add(pos);
                          print('centre: $centre');
                          Offset centreOffset = Offset(centre.x, centre.y);
                          points.add(
                            mapController.camera.screenOffsetToLatLng(
                              centreOffset,
                            ),
                          );
                          extraShapes.last.segments.last.sides.add(
                            CircleEdge(
                              center: mapController.camera.screenOffsetToLatLng(
                                centreOffset,
                              ),
                              plane: Plane(0, 1, 0, 0), //todo:
                              radius: getDistanceAlongSphere(
                                latLngToVec3ForDistance(
                                  mapController.camera.screenOffsetToLatLng(
                                    centreOffset,
                                  ),
                                ),
                                latLngToVec3ForDistance(pos),
                              ),
                              startAngle: 0,
                              sweepAngle: math.pi,
                            ),
                          );
                          print(extraShapes.last.segments.last.sides.last);
                          return;
                        }
                        if (HardwareKeyboard.instance.isShiftPressed) {
                          drewCirclePart = true;
                          circleThirdPoint = pos;
                          return;
                        }

                        setState(() {
                          extraShapes.last.segments.last.vertices.add(pos);
                          // if (extraShapes.last.segments.last.vertices.length > 1) {
                          extraShapes.last.segments.last.sides.add(
                            StraightEdge(),
                          );
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
                    onLongPress: (TapPosition _, LatLng pos) {
                      print("Right click at position $pos");
                      setState(() {
                        if (drawingShape) {
                          if (extraShapes.last.segments.last.vertices.length <=
                              2) {
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
                    tileLayer,
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
                      // if (extraShapes[i].segments.length > 0 &&
                      //     extraShapes[i].segments.last.vertices.length > 2)
                      Child(
                        shape: extraShapes[i],
                        color: Colors.white,
                        focussed: (focussedIndex == i),
                      ),
                    for (
                      int i = 0;
                      i < pinks.length;
                      i++
                    ) // todo: this should not fail
                      // if (extraShapes[i].segments.length > 0 &&
                      //     extraShapes[i].segments.last.vertices.length > 2)
                      Child(
                        shape: pinks[i],
                        color: Colors.pink,
                        focussed: false,
                      ),

                    for (var (first, second) in intersections) ...[
                      Child(
                        shape: intersect(
                          extraShapes[first],
                          extraShapes[second],
                        ),
                        color: Colors.red,
                        focussed: false,
                      ),
                      CustomPaint(
                        painter: PointPainter(
                          points: intersectionPoints(
                            extraShapes[first],
                            extraShapes[second],
                          ).$1.map<LatLng>((el) => el.point).toList(),
                          camera: mapController.camera,
                        ),
                      ),
                    ],
                    if (points.isNotEmpty)
                      CustomPaint(
                        painter: PointPainter(
                          points: points,
                          camera: mapController.camera,
                        ),
                      ),
                    if (lines.isNotEmpty)
                      CustomPaint(
                        painter: LinePainter(
                          lines: lines,
                          camera: mapController.camera,
                        ),
                      ),
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
      },
    );
  }

  ShortcutRegistryEntry? _shortcutsEntry;

  List<MenuEntry> _getMenus() {
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'Debug',
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'Start new boundary',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyB,
              control: true,
            ),
            onPressed: () {
              print("hi there");
              setState(() {
                drawingShape = true;
                extraShapes.add(
                  Shape(
                    segments: [Segment(vertices: [], sides: [])],
                  ),
                );
              });
            },
          ),
          MenuEntry(
            label: 'Add new segment',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              control: true,
            ),
            onPressed: () {
              if (!drawingShape || hittest) {
                print(
                  "Cannot add segment when not drawing a shape or being in a hittest!",
                );
                return;
              }
              // extraShapes.last.segments.last.sides.add(
              //   StraightEdge(),
              // ); // Close the previous shape
              setState(() {
                extraShapes.last.segments.add(Segment(vertices: [], sides: []));
              });
            },
          ),
          MenuEntry(
            label: 'Clear all extra shapes',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyC,
              control: true,
            ),
            onPressed: () {
              setState(() {
                extraShapes.clear();
                intersections.clear();
                museums = false;
                pinks.clear();
                lines.clear();
                points.clear();
                firstIntersection = -1;
                drawingShape = false;
              });
            },
          ),
          MenuEntry(
            label: 'Save extra shapes to json',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              control: true,
            ),
            onPressed: () async {
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
              FilePicker.platform.saveFile(
                dialogTitle: 'Please select an output file:',
                initialDirectory: "${Directory.current.path}/tests/",
                bytes: utf8.encode(json),
                allowedExtensions: ["json"],
                fileName: ".json",
              );
            },
          ),
          MenuEntry(
            label: "Load from json",
            onPressed: () async {
              var result = await FilePicker.platform.pickFiles(
                dialogTitle: "Select file to load",
                initialDirectory: "${Directory.current.path}/tests/",
              );
              if (result == null) {
                print("No file selected");
                return;
              }
              var file = File(result.paths.single!);
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
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyO,
              control: true,
            ),
          ),
          !hittest
              ? MenuEntry(
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyH,
                    control: true,
                  ),
                  label: "Start hittest",
                  onPressed: () {
                    if (drawingShape) {
                      print("Stop drawing first!");
                      return;
                    }
                    setState(() {
                      hittest = true;
                    });
                  },
                )
              : MenuEntry(
                  label: "Stop hittest",
                  shortcut: const SingleActivator(
                    LogicalKeyboardKey.keyH,
                    control: true,
                  ),
                  onPressed: () {
                    setState(() {
                      hittest = false;
                    });
                  },
                ),
          MenuEntry(
            label: "Update last boundary with museum",
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyM,
              control: true,
            ),
            onPressed: () async {
              museums = true;
              pinks.add(
                await updateBoundary(
                  extraShapes.last,
                  this,
                  mapController.camera,
                ),
              );
            },
          ),
        ],
      ),
    ];
    // (Re-)register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application, and update them if they've changed.
    _shortcutsEntry?.dispose();
    // if (ShortcutRegistry.of(context).shortcuts.length > 1) {
    _shortcutsEntry = ShortcutRegistry.of(
      context,
    ).addAll(MenuEntry.shortcuts(result));
    // }
    return result;
  }
}
