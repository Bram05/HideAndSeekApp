import 'dart:convert';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/Boundary.dart';
import 'package:jetlag/Location.dart';
import 'package:jetlag/helper.dart';
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
  final String? debug;
  final bool renderExtras;
  const MapWidget({
    super.key,
    required this.border,
    required this.renderExtras,
    this.debug,
  });
  @override
  State<StatefulWidget> createState() {
    return MapWidgetState();
  }
}

Future<(Pointer<Void>, int)> getRegions(String message) async {
  Directory dir = Directory("${getLocationOfRegion(message)}/subareas");
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

class MapWidgetState extends State<MapWidget> {
  int tileDimension = 256;
  late TileLayer tileLayer;
  Pointer<Void> boundary = nullptr, originalBoundary = nullptr;
  final mapController = MapController();
  int focussed = -1;
  bool firstQuestion = true;
  late Future<(Pointer<Void>, int)> regions;
  List<List<bool>>? questionsUsed;

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
    // regions = getRegions(widget.border);
    // var (shapes, _, _, _, _, _, _) = fromJson(
    //   jsonDecode(
    //     await File("newtests/boxAroundRijksmuseum.json").readAsString(),
    //   ),
    // );
    // initialPos = LatLng(52.360181, 4.8852546);
    // initialZoom = 15;
    // boundary = shapes[0];
    // return 3;

    var file = File("${getLocationOfRegion(widget.border)}/border.json");
    String content = await file.readAsString();
    var json = jsonDecode(content);
    try {
      var (
        extraShapesNew,
        intersectsNew,
        sol,
        minLat,
        minLon,
        maxLat,
        maxLon,
        _,
      ) = fromJson(
        json,
      );
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
    regions = compute(getRegions, widget.border);

    return 3;
  }

  @override
  Widget build(BuildContext context) {
    print("Boundary = $boundary");
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
                    // if (originalBoundary != nullptr)
                    //   Shape(
                    //     shape: originalBoundary,
                    //     color: Colors.white,
                    //     focussed: false,
                    //   ),
                    LocationMarker(),
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

    print("Here");
    Pointer<Void>? out = await showDialog<Pointer<Void>>(
      context: context,
      builder: (context) {
        print("Building dialog");
        return FutureBuilder(
          future: handle(result),
          builder: (context, state) {
            print("Building within");
            if (state.hasError)
              return AlertDialog(
                scrollable: true,
                title: Text("Something went wrong"),
                content: Text(state.error.toString()),
                actions: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text("Close"),
                  ),
                ],
              );
            if (!state.hasData)
              return AlertDialog(
                title: Text("Loading..."),
                content: Text("Please wait"),
              );
            Navigator.pop(context, state.data);
            return Text('...');
          },
        );
      },
      barrierDismissible: false,
    );
    // Pointer<Void> out = await handle(result);
    setState(() {
      setBoundary(out!);
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
    firstQuestion = false;
  }

  String prettyDistance(double meters) {
    if (meters < 500) return "${meters.toStringAsFixed(0)}  m";
    double d = meters / 1000;
    return "${d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1)} km";
  }

  List<MenuEntry> _getMenus() {
    var questions = [
      (
        "relative",
        [
          (
            "Latitude",
            () {
              askQuestion(
                "Is hiders latitude higher than yours (above you on the map)?",
                (bool answer) async {
                  return await askLatitudeQuestion(
                    maths.LatitudeQuestion,
                    boundary,
                    lastPosition.latitude,
                    answer,
                  );
                },
              );
            },
          ),
          (
            "Longitude",
            () {
              askQuestion(
                "Is hiders longitude higher than yours (to the right of you)?",
                (bool answer) async {
                  return await askLongitudeQuestion(
                    maths.LongitudeQuestion,
                    boundary,
                    lastPosition.longitude,
                    answer,
                  );
                },
              );
            },
          ),
          (
            "Same area",
            () {
              askQuestion(
                "Is the hider in the same administrative area (province,...)?",
                (bool answer) async {
                  return await regions.then(
                    (value) {
                      return askAdminAreaQuestion(
                        boundary,
                        value.$1,
                        value.$2,
                        lastPositionForCpp(),
                        answer,
                      );
                    },
                    onError: (error) {
                      return Future.error(error);
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      (
        "Radius",
        [
          for (double r in [100, 500, 1000, 10000, 20000, 50000, 100000])
            (
              prettyDistance(r),
              () {
                askQuestion(
                  "Is hider's location within ${prettyDistance(r)} of your current position?",
                  (bool answer) async {
                    return askWithinRadiusQuestion(
                      boundary,
                      lastPositionForCpp(),
                      r,
                      answer,
                    );
                  },
                );
              },
            ),
        ],
      ),
      (
        "Precision",
        [
          (
            "museums",
            () async {
              askQuestion("Is hider's closest museum the same as yours?", (
                bool answer,
              ) async {
                // var museums = jsonDecode(
                //   await File("downloads/museums.json").readAsString(),
                LatLng lastPosition = LatLng(52.0677, 4.35026);
                var result = await http.post(
                  Uri.parse('https://overpass-api.de/api/interpreter'),
                  body: {
                    "data":
                        '''[out:json][timeout:90];
            nwr['tourism' = 'museum'](around:7000,${lastPosition.latitude}, ${lastPosition.longitude});
            out geom;''',
                  },
                );
                if (result.statusCode != 200)
                  return Future.error(
                    "Internal error: query for museums failed!",
                  );
                await File("out.json").writeAsString(result.body);
                var (list, n) = convertToList(jsonDecode(result.body));

                return askClosestMuseumQuestion(
                  boundary,
                  // lastPositionForCpp(),
                  Struct.create()
                    ..lat = lastPosition.latitude
                    ..lon = lastPosition.longitude,
                  list,
                  n,
                  answer,
                  !firstQuestion,
                );
              });
            },
          ),
        ],
      ),
    ];
    questionsUsed ??= [
      for (var cat in questions) [for (var _ in cat.$2) false],
    ];
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'Go back',
        onPressed: () {
          context.goNamed("ChooseBoundary");
        },
        active: true,
      ),
      MenuEntry(
        label: 'Save/Load',

        menuChildren: <MenuEntry>[
          MenuEntry(
            label: 'Save current state',
            active: true,
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyS,
              control: true,
            ),
            onPressed: () async {
              var tempJson = toJson(boundary, questionsUsed!);
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
            active: true,
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
                var (
                  extraShapesNew,
                  intersectsNew,
                  sol,
                  _,
                  _,
                  _,
                  _,
                  newQuestionsUsed,
                ) = fromJson(
                  json,
                );
                questionsUsed = newQuestionsUsed;
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
    ];
    MenuEntry creatEntry((String, VoidCallback) item, int i, int j) {
      return MenuEntry(
        label: item.$1,
        onPressed: () {
          if (questionsUsed![i][j]) {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("Cannot ask this question"),
                  content: Text("Every question can only be asked once"),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text("Close"),
                    ),
                  ],
                );
              },
            );
            return;
          }
          item.$2();
          setState(() {
            questionsUsed![i][j] = true;
          });
        },
        active: !(questionsUsed![i][j]),
      );
    }

    for (int i = 0; i < questions.length; i++) {
      result.add(
        MenuEntry(
          label: questions[i].$1,
          menuChildren: [
            for (int j = 0; j < questions[i].$2.length; j++)
              creatEntry(questions[i].$2[j], i, j),
          ],
        ),
      );
    }
    // (Re-)register the shortcuts with the ShortcutRegistry so that they are
    // available to the entire application, and update them if they've changed.
    // _shortcutsEntry?.dispose();
    // if (ShortcutRegistry.of(context).shortcuts.isEmpty) {
    //   _shortcutsEntry = ShortcutRegistry.of(
    //     context,
    //   ).addAll(MenuEntry.shortcuts(result));
    // }
    return result;
  }
}
