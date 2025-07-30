import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:jetlag/draw_shape.dart';
import 'menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide Size;
import 'package:flutter_map/flutter_map.dart';
import 'package:jetlag/shape.dart';
import 'package:jetlag/renderer.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'Maths.dart';
import 'dart:ffi' hide Size;
import 'Boundary.dart';

class MapWidget extends StatefulWidget {
  final List<Pointer<Void>> shapes;
  const MapWidget({super.key, required this.shapes});
  @override
  State<StatefulWidget> createState() {
    return MapWidgetState();
  }
}

const Size size = Size(10, 10);

class MapWidgetState extends State<MapWidget> {
  bool museums = false;
  bool hittest = false;
  bool drawingCircle = false;
  late ShapeCreator creator;
  bool creatorActive = false;
  LatLng? lastCirclePoint = null;
  bool drewCirclePart = false;
  LatLng circleThirdPoint = LatLng(-1, -1);
  double radius = 200;
  late TileLayer tileLayer;
  List<Pointer<Void>> extraShapes = [];
  int focussedIndex = -1;
  List<(int, int)> intersections = [];
  int firstIntersection = -1;
  List<Pointer<Void>> intended = [];
  final mapController = MapController();
  TextEditingController filenameController = TextEditingController();
  late LatLng initialPos;
  void addShape(Pointer<Void> shape) {
    setState(() {
      extraShapes.add(shape);
      creatorActive = false;
    });
  }

  void newShapeCreator() {
    setState(() {
      creatorActive = true;
      creator = ShapeCreator(key: UniqueKey(), callback: addShape);
    });
  }

  @override
  void initState() {
    initialPos = LatLng(51.438721966613016, 4.9261581923893);
    tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'www.example.com',
    );
    super.initState();
  }

  Future<int> initialize() async {
    if (extraShapes.isNotEmpty) {
      return 0;
    }
    var file = File("countries/Europees_Nederland.json");
    String content = await file.readAsString();
    var json = jsonDecode(content);
    var (extraShapesNew, intersectsNew, sol) = fromJson(json);
    extraShapes = extraShapesNew;
    intersections = intersectsNew;
    // extraShapes.addAll(sol);
    // intended = sol;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    // print("Rendering
    return FutureBuilder<void>(
      future: initialize(),
      // future: (extraShapes.isNotEmpty && museums == true
      //     ? updateBoundary(extraShapes.last, true)
      //     : Future(() => Pointer<Void>.fromAddress(0))),
      builder: (context, asyncSnapshot) {
        if (!asyncSnapshot.hasData) return Text("waiting");
        // if (asyncSnapshot.data as Pointer<Void> != Pointer.fromAddress(0)) {
        //   print("TODO:");
        //   // museums = false;
        //   // extraShapes.add(asyncSnapshot.data as Pointer<Void>);
        // }

        // pinks.add(asyncSnapshot.data!);
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
                  // setState(() {
                  // maths.FreeShape(extraShapes.last);
                  // LatLng p = mapController.camera.screenOffsetToLatLng(
                  //   e.localPosition,
                  // );
                  // Pointer<LatLngDart> ek = malloc<LatLngDart>()
                  //   ..ref.lat = p.latitude
                  //   ..ref.lon = p.longitude;
                  // extraShapes.last = maths.AddCircle(ek, radius);
                  // malloc.free(ek);
                  // if (hittest) {
                  //   for (int i = 0; i < extraShapes.length; i++) {
                  //     if (1 ==
                  //         maths.hit(
                  //           extraShapes[i],
                  //           latLngToLatLngDart(
                  //             mapController.camera.screenOffsetToLatLng(
                  //               e.localPosition,
                  //             ),
                  //           ),
                  //         )) {
                  //       focussedIndex = i;
                  //       return;
                  //     }
                  //     focussedIndex = -1;
                  //   }
                  // }
                  // });
                },
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialPos,
                    initialZoom: 14, // 17
                    onMapEvent: (MapEvent e) {
                      setState(() {});
                    },

                    // Tapposition contains screen coordinates, which we do not want
                    onTap: (TapPosition _, LatLng pos) {
                      // print("Clicked at position $pos");
                      // return;
                      // if (drawingCircle) {
                      //   if (lastCirclePoint != null) {
                      //     Vector3 centre = latLngToVec3(lastCirclePoint!);
                      //     Vector3 now = latLngToVec3(pos);
                      //     lastCirclePoint = null;
                      //     drawingCircle = false;
                      //     print("adding cirlc");
                      //     print("Centre is ${vec3ToLatLng(centre)}");
                      //     var (p, _, _) = Plane.fromCircle(
                      //       vec3ToLatLng(centre),
                      //       getDistanceAlongSphere(centre, now),
                      //       true,
                      //     );
                      //     print("LIES INSIDE: ${p.liesInside(now)}");
                      //     points.add(vec3ToLatLng(now));
                      //     points.add(
                      //       vec3ToLatLng(
                      //         (centre - (now - centre)).normalized(),
                      //       ),
                      //     );
                      //     extraShapes.add(
                      //       Shape(
                      //         segments: [
                      //           Segment(
                      //             vertices: [
                      //               now,
                      //               (centre - (now - centre)).normalized(),
                      //             ],
                      //             sides: [
                      //               CircleEdge(
                      //                 center: vec3ToLatLng(centre),
                      //                 radius: getDistanceAlongSphere(
                      //                   centre,
                      //                   now,
                      //                 ),
                      //                 startAngle: 0,
                      //                 sweepAngle: math.pi,
                      //                 plane: p,
                      //               ),
                      //               StraightEdge(),
                      //             ],
                      //           ),
                      //         ],
                      //       ),
                      //     );
                      //     print(
                      //       extraShapes.last.segments.last.sides[0].getPlane(
                      //         now,
                      //         centre - (now - centre),
                      //       ),
                      //     );
                      //     setState(() {});
                      //     return;
                      //   } else {
                      //     lastCirclePoint = pos;
                      //     return;
                      //   }
                      // }
                      // if (drawingShape) {
                      //   if (drewCirclePart) {
                      //     drewCirclePart = false;
                      //     Offset p1 = mapController.camera.latLngToScreenOffset(
                      //       vec3ToLatLng(
                      //         extraShapes.last.segments.last.vertices.last,
                      //       ),
                      //     );
                      //     Offset p2 = mapController.camera.latLngToScreenOffset(
                      //       circleThirdPoint,
                      //     );
                      //     Offset p3 = mapController.camera.latLngToScreenOffset(
                      //       pos,
                      //     );
                      //     Offset delta1 = Offset(p1.dx - p2.dx, p1.dy - p2.dy);
                      //     Offset delta1Rotated = Offset(delta1.dy, -delta1.dx);
                      //     Offset delta1Middle = Offset(
                      //       (p1.dx + p2.dx) / 2,
                      //       (p1.dy + p2.dy) / 2,
                      //     );
                      //     Offset delta2 = Offset(p3.dx - p2.dx, p3.dy - p2.dy);
                      //     Offset delta2Rotated = Offset(delta2.dy, -delta2.dx);
                      //     Offset delta2Middle = Offset(
                      //       (p3.dx + p2.dx) / 2,
                      //       (p3.dy + p2.dy) / 2,
                      //     );
                      //     Line l1 = Line(
                      //       Vector3(delta1Rotated.dx, delta1Rotated.dy, 0),
                      //       Vector3(delta1Middle.dx, delta1Middle.dy, 0),
                      //     );
                      //     Line l2 = Line(
                      //       Vector3(delta2Rotated.dx, delta2Rotated.dy, 0),
                      //       Vector3(delta2Middle.dx, delta2Middle.dy, 0),
                      //     );
                      //     Vector3 centre = l1.intersect(l2);
                      //     assert(close(centre.z, 0));
                      //     extraShapes.last.segments.last.vertices.add(
                      //       latLngToVec3(pos),
                      //     );
                      //     print('centre: $centre');
                      //     Offset centreOffset = Offset(centre.x, centre.y);
                      //     // points.add(
                      //     //   mapController.camera.screenOffsetToLatLng(
                      //     //     centreOffset,
                      //     //   ),
                      //     // );
                      //     extraShapes.last.segments.last.sides.add(
                      //       CircleEdge(
                      //         center: mapController.camera.screenOffsetToLatLng(
                      //           centreOffset,
                      //         ),
                      //         plane: Plane(0, 1, 0, 0), //todo:
                      //         radius: getDistanceAlongSphere(
                      //           latLngToVec3(
                      //             mapController.camera.screenOffsetToLatLng(
                      //               centreOffset,
                      //             ),
                      //           ),
                      //           latLngToVec3(pos),
                      //         ),
                      //         startAngle: 0,
                      //         sweepAngle: math.pi,
                      //       ),
                      //     );
                      //     print(extraShapes.last.segments.last.sides.last);
                      //     return;
                      //   }
                      //   if (HardwareKeyboard.instance.isShiftPressed) {
                      //     drewCirclePart = true;
                      //     circleThirdPoint = pos;
                      //     return;
                      //   }
                      //
                      //   setState(() {
                      //     extraShapes.last.segments.last.vertices.add(
                      //       latLngToVec3(pos),
                      //     );
                      //     // if (extraShapes.last.segments.last.vertices.length > 1) {
                      //     extraShapes.last.segments.last.sides.add(
                      //       StraightEdge(),
                      //     );
                      //     // }
                      //   });
                      // } else {
                      //   print("hit?");
                      //   // todo: =----------------------------change to extrashapes
                      //   for (int i = widget.shapes.length - 1; i >= 0; i--) {
                      //     if (widget.shapes[i].hit(latLngToVec3(pos), this)) {
                      //       print("hit index $i");
                      //       // if (firstIntersection == -1) {
                      //       //   firstIntersection = i;
                      //       //   return;
                      //       // } else {
                      //       // setState(() {
                      //       //   intersections.add((firstIntersection, i));
                      //       //   firstIntersection = -1;
                      //       //   print(
                      //       //     "Now seeing ${intersections.length} intersections",
                      //       //   );
                      //       // });
                      //       // return;
                      //       // }
                      //     }
                      //   }
                      //   print("Did not intersect anything");
                      // }
                    },
                    onLongPress: (TapPosition _, LatLng pos) {
                      // print("Right click at position $pos");
                      // setState(() {
                      //   if (drawingShape) {
                      //     if (extraShapes.last.segments.last.vertices.length <=
                      //         2) {
                      //       extraShapes.removeLast();
                      //     } else {
                      //       // extraShapes.last.segments.last.sides.add(StraightEdge());
                      //     }
                      //   }
                      //   drawingShape = false;
                      // });
                    },
                  ),
                  children: [
                    tileLayer,
                    if (creatorActive) creator,
                    for (var s in widget.shapes) ...[
                      Shape(shape: s, color: Colors.blueGrey, focussed: false),
                      // Child(shape: s2, color: Colors.grey, focussed: false),
                      // Child(
                      //   shape: intersect(s1, s2, this),
                      //   color: Colors.red,
                      //   focussed: false,
                      // ),
                    ],
                    for (
                      int i = 0;
                      i < extraShapes.length;
                      i++
                    ) // todo: this should not fail
                      // if (extraShapes[i].segments.length > 0 &&
                      //     extraShapes[i].segments.last.vertices.length > 2)
                      Shape(
                        shape: extraShapes[i],
                        color: Colors.white,
                        focussed: (focussedIndex == i),
                      ),
                    for (var (first, second) in intersections) ...[
                      Shape(
                        shape: maths.IntersectShapes(
                          extraShapes[first],
                          extraShapes[second],
                        ),
                        color: Colors.red,
                        focussed: false,
                      ),
                    ],
                    // CustomPaint(
                    //   painter: PointPainter(
                    //     points:
                    //         intersectionPoints(
                    //               extraShapes[first],
                    //               extraShapes[second],
                    //             ).$1
                    //             .map<LatLng>((el) => vec3ToLatLng(el.point))
                    //             .toList(),
                    //     camera: mapController.camera,
                    //   ),
                    // ),
                    // ],
                    // if (points.isNotEmpty)
                    //   CustomPaint(
                    //     painter: PointPainter(
                    //       points: points,
                    //       camera: mapController.camera,
                    //     ),
                    //   ),
                    // if (lines.isNotEmpty)
                    //   CustomPaint(
                    //     painter: LinePainter(
                    //       lines: lines,
                    //       camera: mapController.camera,
                    //     ),
                    //   ),
                    // // for (Shape shape in intended)
                    // //   Child(shape: shape, color: Colors.blue, focussed: false),
                    // Text(
                    //   drawingShape
                    //       ? "Click to add vertex to the shape"
                    //       : "Click to intersect shapes",
                    //   style: TextStyle(fontSize: 25, color: Colors.black),
                    // ),
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
              newShapeCreator();
              // print("hi there");
              // setState(() {
              //   drawingShape = true;
              //   extraShapes.add(
              //     Shape(
              //       segments: [Segment(vertices: [], sides: [])],
              //     ),
              //   );
              // });
            },
          ),
          // MenuEntry(
          //   label: 'Add new segment',
          //   shortcut: const SingleActivator(
          //     LogicalKeyboardKey.keyN,
          //     control: true,
          //   ),
          //   onPressed: () {
          //     // if (!drawingShape || hittest) {
          //     //   print(
          //     //     "Cannot add segment when not drawing a shape or being in a hittest!",
          //     //   );
          //     //   return;
          //     // }
          //     // extraShapes.last.segments.last.sides.add(
          //     //   StraightEdge(),
          //     // ); // Close the previous shape
          //     // setState(() {
          //     //   extraShapes.last.segments.add(Segment(vertices: [], sides: []));
          //     // });
          //   },
          // ),
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
                firstIntersection = -1;
                // drawingShape = false;
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

              for (Pointer<Void> s in extraShapes) {
                print("Converting shape to json");
                tempJson["shapes"].add(shapeToJson(s));
              }

              tempJson["intersections"] = [];
              for (var (first, second) in intersections) {
                tempJson["intersections"].add({
                  "first": first,
                  "second": second,
                  "solution": shapeToJson(
                    maths.IntersectShapes(
                      extraShapes[first],
                      extraShapes[second],
                    ),
                  ),
                });
              }
              String json = jsonEncode(tempJson);
              print(json);
              FilePicker.platform.saveFile(
                dialogTitle: 'Please select an output file:',
                initialDirectory: "${Directory.current.path}/newtests/",
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
                initialDirectory: "${Directory.current.path}/newtests/",
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

              print("Added ${extraShapes.length} new things");
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
                    // if (drawingShape) {
                    //   print("Stop drawing first!");
                    //   return;
                    // }
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
            label: "Add circle",
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyK,
              control: true,
            ),
            onPressed: () async {
              drawingCircle = true;
            },
          ),
          MenuEntry(
            label: "Update last boundary with museum",
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyM,
              control: true,
            ),
            onPressed: () async {
              // museums = true;
              if (extraShapes.isEmpty) return;
              Pointer<Void> boundary = extraShapes.removeLast();
              extraShapes.add(await updateBoundary(boundary, true));
              setState(() {});
              // pinks.add(
              //   await updateBoundary(
              //     extraShapes.last,
              //     this,
              //     mapController.camera,
              //   ),
              // );
            },
          ),
          MenuEntry(
            label: "Increase radius",
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyD,
              control: false,
            ),
            onPressed: () async {
              setState(() {
                radius *= 1.1;
              });
            },
          ),
          MenuEntry(
            label: "Decrease radius",
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyF,
              control: false,
            ),
            onPressed: () async {
              setState(() {
                radius *= 0.9;
              });
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
