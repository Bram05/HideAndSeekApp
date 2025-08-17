import 'dart:convert';
import 'dart:math';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:jetlag/Boundary.dart';
import 'package:jetlag/Location.dart';
import 'package:jetlag/MapAttribution.dart';
import 'package:jetlag/SettingsWidget.dart';
import 'package:jetlag/helper.dart';
import 'package:jetlag/main.dart';
import 'package:jetlag/new_border.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'dart:async';

String getSavesDirectory() {
  return "$documentsdir/saves";
}

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

class Data {
  final String message;
  final int toSkip;
  const Data(this.message, this.toSkip);
}

Future<(Pointer<Void>, int)> getRegions(Data d) async {
  Directory dir = Directory(d.message);
  List<FileSystemEntity> entities = await dir.list().toList();
  Pointer<Pointer<Void>> regions = malloc(entities.length);
  for (int i = 0; i < entities.length; i++) {
    var res = fromJson(
      jsonDecode(await File(entities[i].path).readAsString()),
      d.toSkip,
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

  late bool thermometerInProcess;
  LatLng? thermometerStart;
  late double thermometerDistance, thermometerCurrentDistance;
  late bool thermometerCancel = false;
  void resetThermometer() {
    setState(() {
      thermometerInProcess = false;
      thermometerStart = null;
      thermometerDistance = -1;
      thermometerCurrentDistance = 0;
      thermometerCancel = false;
    });
  }

  @override
  void initState() {
    resetThermometer();
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
    int toSkip = getDeltaFromQuality(await readQuality());
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
        toSkip,
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
    if (widget.renderExtras)
      regions = compute(
        getRegions,
        Data("${getLocationOfRegion(widget.border)}/subareas", toSkip),
      );

    return 3;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
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
        if (!asyncSnapshot.hasData)
          return Text(
            "Loading...",
            style: Theme.of(context).textTheme.headlineMedium,
          );
        return Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (thermometerInProcess)
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      color: Colors.orangeAccent,
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          Text(
                            "Thermometer in progress: ${prettyDistance(thermometerCurrentDistance)} out of ${prettyDistance(thermometerDistance)}",
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 500),
                            child: LinearProgressIndicator(
                              borderRadius: BorderRadius.all(
                                Radius.circular(7),
                              ),
                              minHeight: 7,
                              value:
                                  thermometerCurrentDistance /
                                  thermometerDistance,
                            ),
                          ),
                          FilledButton(
                            onPressed: () async {
                              bool? result = await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text(
                                      "Do you really want to cancel the running thermometer?",
                                    ),
                                    actions: [
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(context, true);
                                        },
                                        child: Text("Yes"),
                                      ),
                                      FilledButton(
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                        child: Text("No"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              if (result == true) thermometerCancel = true;
                            },
                            child: Text("Cancel"),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (widget.renderExtras)
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
                    Shape(
                      shape: boundary,
                      color: Colors.white,
                      focussed: true,
                      centerOfCountry: initialPos,
                    ),
                    // if (originalBoundary != nullptr)
                    //   Shape(
                    //     shape: originalBoundary,
                    //     color: Colors.white,
                    //     focussed: false,
                    //   ),
                    if (widget.renderExtras) LocationMarker(),
                    if (widget.renderExtras)
                      const MapCompass.cupertino(hideIfRotatedNorth: true),
                    if (widget.renderExtras) MapAttribution(),
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

  Future<bool> askQuestion(
    String question,
    Future<Pointer<Void>> Function(bool) handle, {
    bool canIgnore = true,
  }) async {
    bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: canIgnore,
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
    if (result == null) return false;

    Pointer<Void>? out = await showDialog<Pointer<Void>>(
      context: context,
      builder: (context) {
        return FutureBuilder(
          future: handle(result),
          builder: (context, state) {
            if (state.hasError || (state.hasData && state.data == nullptr))
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
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => Navigator.pop(context, state.data),
            );
            return const SizedBox.shrink();
          },
        );
      },
      barrierDismissible: false,
    );
    if (out == null) return false;
    // Pointer<Void> out = await handle(result);
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
    firstQuestion = false;
    return true;
  }

  String prettyDistance(double meters) {
    if (meters < 500) return "${meters.toStringAsFixed(0)}m";
    double d = meters / 1000;
    return "${d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1)}km";
  }

  List<MenuEntry> _getMenus() {
    var questions = [
      (
        "relative",
        [
          (
            "Latitude",
            () {
              return askQuestion(
                "Is hiders latitude higher than yours (above you on the map)?",
                (bool answer) async {
                  return await askLatitudeQuestion(
                    maths.LatitudeQuestion,
                    boundary,
                    lastPosition!.latitude,
                    answer,
                  );
                },
              );
            },
          ),
          (
            "Longitude",
            () {
              return askQuestion(
                "Is hiders longitude higher than yours (to the right of you)?",
                (bool answer) async {
                  return await askLongitudeQuestion(
                    maths.LongitudeQuestion,
                    boundary,
                    lastPosition!.longitude,
                    answer,
                  );
                },
              );
            },
          ),
          (
            "Same area",
            () {
              return askQuestion(
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
        "Thermometer",
        [
          for (double d in [500, 5000, 15000, 50000])
            (
              prettyDistance(d),
              () async {
                setState(() {
                  thermometerInProcess = true;
                  thermometerStart = lastPosition;
                  thermometerDistance = d;
                });
                bool result = await Stream.periodic(Duration(milliseconds: 100))
                    .firstWhere((_) {
                      if (thermometerCancel) throw "_";
                      setState(() {
                        thermometerCurrentDistance = maths.DistanceBetween(
                          lastPositionForCpp(),
                          Struct.create()
                            ..lat = thermometerStart!.latitude
                            ..lon = thermometerStart!.longitude,
                        );
                      });
                      return thermometerCurrentDistance >= thermometerDistance;
                    })
                    .then(
                      (_) {
                        print("finished");
                        return true;
                      },
                      onError: (_) {
                        print("error");
                        return false;
                      },
                    );
                print("Finished: result=$result");
                if (!result) {
                  resetThermometer();
                  return false;
                }
                result = await askQuestion(
                  "Thermometer finished. Did you get closer?",
                  (bool result) async {
                    if (result)
                      return maths.UpdateBoundaryWithClosestToObject(
                        boundary,
                        lastPositionForCpp(),
                        Struct.create()
                          ..lat = thermometerStart!.latitude
                          ..lon = thermometerStart!.longitude,
                      );
                    else
                      return maths.UpdateBoundaryWithClosestToObject(
                        boundary,
                        Struct.create()
                          ..lat = thermometerStart!.latitude
                          ..lon = thermometerStart!.longitude,
                        lastPositionForCpp(),
                      );
                  },
                  canIgnore: false,
                );
                resetThermometer();
                return result;
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
                return askQuestion(
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
          (
            "???",
            () async {
              TextEditingController controller = TextEditingController();
              GlobalKey<FormState> formKey = GlobalKey();
              int? value = await showDialog<int>(
                context: context,
                builder: (context) {
                  void submit() {
                    if (formKey.currentState!.validate())
                      Navigator.pop(context, int.parse(controller.value.text));
                  }

                  return AlertDialog(
                    title: Text("What radius should the circle have?"),
                    content: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 50),
                      child: Form(
                        key: formKey,
                        child: TextFormField(
                          controller: controller,
                          textAlign: TextAlign.end,
                          decoration: InputDecoration(suffix: Text("m")),
                          onFieldSubmitted: (_) {
                            submit();
                          },
                          validator: (String? value) {
                            if (value == null || value.isEmpty)
                              return "Please enter the distance";
                            int? intValue = int.tryParse(value);
                            if (intValue == null ||
                                intValue < 100 ||
                                intValue > 100000)
                              return "Enter a valid number between 100m and 100km";
                            return null;
                          },
                        ),
                      ),
                    ),
                    actions: [
                      FilledButton(
                        onPressed: submit,
                        child: Text("Ask question"),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context, null);
                        },
                        child: Text("Cancel"),
                      ),
                    ],
                  );
                },
              );
              if (value == null) return false;
              return askQuestion(
                "Is hider's location within ${prettyDistance(value.toDouble())} of your current position?",
                (bool answer) async {
                  return askWithinRadiusQuestion(
                    boundary,
                    lastPositionForCpp(),
                    value.toDouble(),
                    answer,
                  );
                },
              );
              return true;
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
              return askQuestion(
                "Is hider's closest museum the same as yours?",
                (bool answer) async {
                  // var museums = jsonDecode(
                  //   await File("downloads/museums.json").readAsString(),
                  // LatLng lastPosition = LatLng(52.0677, 4.35026);
                  var result = await http.post(
                    Uri.parse('https://overpass-api.de/api/interpreter'),
                    body: {
                      "data":
                          '''[out:json][timeout:90];
            nwr['tourism' = 'museum'](around:7000,${lastPosition!.latitude}, ${lastPosition!.longitude});
            out geom;''',
                    },
                  );
                  print("Location is ${lastPosition!}");
                  if (result.statusCode != 200)
                    return Future.error(
                      "Internal error: query for museums failed!",
                    );
                  // await File("out.json").writeAsString(result.body);
                  var (list, n) = convertToList(jsonDecode(result.body));

                  return askClosestMuseumQuestion(
                    boundary,
                    lastPositionForCpp(),
                    list,
                    n,
                    answer,
                    !firstQuestion,
                  );
                },
              );
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
              print("Asking");
              await FilePicker.platform.saveFile(
                dialogTitle: 'Please select an output file:',
                // initialDirectory: "${Directory.current.path}/saves/",
                bytes: utf8.encode(json),
                allowedExtensions: ["json"],
                fileName: ".json",
                type: FileType.custom,
              );
            },
          ),
          MenuEntry(
            label: "Load from json",
            active: true,
            onPressed: () async {
              var result = await FilePicker.platform.pickFiles(
                dialogTitle: "Select file to load",
                initialDirectory: "${Directory.current.path}/saves/",
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
                  getDeltaFromQuality(
                    Quality.full,
                  ), // The loaded file already is of degraded quality
                );
                if (newQuestionsUsed.isNotEmpty)
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
    MenuEntry createEntry(
      (String, Future<bool> Function()) item,
      int i,
      int j,
    ) {
      return MenuEntry(
        label: item.$1,
        onPressed: () async {
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
          bool asked = await () async {
            if (lastPosition == null) {
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text("Error: location not yet determined!"),
                    content: Text(
                      "Cannot ask this question without a location. Please wait until it has been determined",
                    ),
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
              return false;
            }
            return await item.$2();
          }();
          if (asked)
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
              createEntry(questions[i].$2[j], i, j),
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
