import 'dart:convert';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:jetlag/Boundary.dart';
import 'package:jetlag/choose_boundary.dart';
import 'package:jetlag/draw_shape.dart';
import 'package:jetlag/new_border.dart';
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

class MapWidget extends StatefulWidget {
  final String border;
  final bool renderExtras;
  const MapWidget({
    super.key,
    required this.border,
    required this.renderExtras,
  });
  @override
  State<StatefulWidget> createState() {
    return MapWidgetState();
  }
}

class MapWidgetState extends State<MapWidget> {
  int tileDimension = 256;
  late TileLayer tileLayer;
  Pointer<Void> boundary = nullptr, originalBoundary = nullptr;
  final mapController = MapController();
  int focussed = -1;
  @override
  void initState() {
    tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.HideAndSeek.app',
      tileDimension: tileDimension,
    );
    super.initState();
  }

  void setBoundary(Pointer<Void> newShape) {
    if (originalBoundary == nullptr)
      originalBoundary = boundary;
    else
      maths.FreeShape(boundary);
    boundary = newShape;
  }

  @override
  void dispose() {
    maths.FreeShape(boundary);
    super.dispose();
  }

  late LatLng initialPos;
  late double initialZoom;
  Future<int> initialize(Size size) async {
    if (boundary != nullptr) {
      return 0;
    }

    var file = File("${getLocationOfRegion(widget.border)}/border.json");
    String content = await file.readAsString();
    var json = jsonDecode(content);
    try {
      var (extraShapesNew, intersectsNew, sol, minLat, minLon, maxLat, maxLon) =
          fromJson(json);
      if (extraShapesNew.length != 1) {
        return Future.error(
          "Invalid file: it contained ${extraShapesNew.length} shapes instead of 1",
        );
      }
      boundary = extraShapesNew[0];
      // Pointer<Double> minLat = malloc();
      // Pointer<Double> maxLat = malloc();
      // Pointer<Double> minLon = malloc();
      // Pointer<Double> maxLon = malloc();
      // maths.GetBounds(extraShapesNew[0], minLat, maxLat, minLon, maxLon);
      initialPos = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);
      double log_2(double x) => log(x) / log(2);
      initialZoom = min(
        log_2(
          360 /
              (1.2 *
                  (maxLon - minLon) *
                  (tileDimension.toDouble()) /
                  size.width),
        ),
        log_2(
          170 / // todo: this is wrong
              (1.0 * (maxLat - minLat) * tileDimension / size.height),
        ),
      );
    } catch (e) {
      return Future.error("error: $e");
    }
    return 3;
  }

  Future<(Pointer<Void>, int)> getRegions() async {
    Directory dir = Directory("${getLocationOfRegion(widget.border)}/subareas");
    List<FileSystemEntity> entities = await dir.list().toList();
    Pointer<Pointer<Void>> regions = malloc(entities.length);
    for (int i = 0; i < entities.length; i++) {
      var res = fromJson(
        jsonDecode(await File(entities[i].path).readAsString()),
      ).$1;
      if (res.length != 1) {
        return Future.error(
          "Invalid number of shapes in province: ${res.length}",
        );
      }
      regions[i] = res[0];
    }
    return (regions as Pointer<Void>, entities.length);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    print("Size: $size");
    return FutureBuilder<void>(
      future: initialize(size),
      builder: (context, asyncSnapshot) {
        if (asyncSnapshot.hasError)
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Failed to load: ${asyncSnapshot.error}",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () {
                    context.goNamed("ChooseBoundary");
                  },
                  child: Text("Go back"),
                ),
              ],
            ),
          );
        if (!asyncSnapshot.hasData) return Text("waiting");
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.renderExtras)
                  Expanded(
                    child: MenuBar(children: MenuEntry.build(_getMenus())),
                  ),
              ],
            ),
            Expanded(
              child: MouseRegion(
                child: FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: initialPos,
                    initialZoom: initialZoom,
                  ),
                  children: [
                    tileLayer,
                    Shape(shape: boundary, color: Colors.white, focussed: true),
                    if (originalBoundary != nullptr)
                      Shape(
                        shape: originalBoundary,
                        color: Colors.white,
                        focussed: false,
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  ShortcutRegistryEntry? _shortcutsEntry;

  void askQuestion(String question, Function(bool) handle) async {
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(question),
          children: [
            SimpleDialogOption(
              child: Text("Yes"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
            SimpleDialogOption(
              child: Text("No"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
          ],
        );
      },
    );
    if (result == null) return;
    Pointer<Void> out = await handle(result);
    setState(() {
      setBoundary(out);
    });
    Pointer<Int> segment = malloc();
    Pointer<Int> side = malloc();
    int x = maths.IsValid(boundary, segment, side);
    int seg = segment.value;
    int sid = side.value;
    malloc.free(segment);
    malloc.free(side);
    if (1 != x) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Boundary is invalid"),
            content: Text("Segment = $seg and side = $sid"),
          );
        },
      );
    }
  }

  List<MenuEntry> _getMenus() {
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'Go back',
        onPressed: () {
          context.goNamed("ChooseBoundary");
        },
      ),
      MenuEntry(
        label: 'Save/Load',
        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'Save current state',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              control: true,
            ),
            onPressed: () async {
              var tempJson = {};
              tempJson["shapes"] = [];

              tempJson["shapes"].add(shapeToJson(boundary));
              tempJson["intersections"] = [];
              String json = jsonEncode(tempJson);
              print(json);
              FilePicker.platform.saveFile(
                dialogTitle: 'Please select an output file:',
                initialDirectory: "${Directory.current.path}/saves/",
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
                var (extraShapesNew, intersectsNew, sol, _, _, _, _) = fromJson(
                  json,
                );
                if (extraShapesNew.length != 1) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text("Invalid file"),
                        content: Text("File contains not exactly one boundary"),
                      );
                    },
                  );
                  return;
                }
                setBoundary(extraShapesNew[0]);
              });
            },
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyO,
              control: true,
            ),
          ),
        ],
      ),
      MenuEntry(
        label: "Relative",
        menuChildren: [
          MenuEntry(
            label: "Latitude",
            onPressed: () {
              askQuestion(
                "Is hiders latitude higher than yours (above you on the map)?",
                (bool answer) async {
                  return maths.LatitudeQuestion(
                    boundary,
                    (await getPosition()).lat,
                    answer ? 1 : 0,
                  );
                },
              );
            },
          ),
          MenuEntry(
            label: "Longitude",
            onPressed: () {
              askQuestion(
                "Is hiders longitude higher than yours (to the right of you)?",
                (bool answer) async {
                  return maths.LongitudeQuestion(
                    boundary,
                    (await getPosition()).lon,
                    answer ? 1 : 0,
                  );
                },
              );
            },
          ),
          MenuEntry(
            label: "Same admin area",
            onPressed: () {
              askQuestion(
                "Is the hider in the same administrative area (province,...)?",
                (bool answer) async {
                  var (regions, length) = await getRegions();
                  return maths.AdminAreaQuesiton(
                    boundary,
                    regions,
                    length,
                    await getPosition(),
                    answer ? 1 : 0,
                  );
                },
              );
            },
          ),
        ],
      ),
    ];
    // (Re-)register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application, and update them if they've changed.
    _shortcutsEntry?.dispose();
    if (ShortcutRegistry.of(context).shortcuts.isEmpty) {
      _shortcutsEntry = ShortcutRegistry.of(
        context,
      ).addAll(MenuEntry.shortcuts(result));
    }
    return result;
  }
}
