import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'map.dart';
import 'choose_boundary.dart';
import 'country.dart';
import 'new_border_widget.dart';
import 'package:screenshot/screenshot.dart';
import 'package:go_router/go_router.dart';

String getLocationOfRegion(String name) {
  return "${getCountriesDirectory()}/${uglify(name)}";
}

class NewBorder extends StatefulWidget {
  const NewBorder({super.key});

  @override
  State<StatefulWidget> createState() {
    return NewBorderState();
  }
}

class NewBorderState extends State<NewBorder> {
  @override
  @override
  void initState() {
    super.initState();
  }

  Future<String> storeImage(String name) async {
    ScreenshotController c = ScreenshotController();
    try {
      Uint8List res = await c.captureFromWidget(
        MediaQuery(
          data: MediaQueryData(size: Size(1080, 920)),
          child: MapWidget(border: name, renderExtras: false),
        ),
        delay: Duration(seconds: 5),
        targetSize: Size(1080, 920),
      );
      File f = File("${getLocationOfRegion(name)}/image.jpeg");
      f.writeAsBytes(res);
      return "";
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<int>> getProvinces(
    String generalName,
    Map<String, dynamic>? json,
  ) async {
    json ??= await getRequest(name: generalName);
    List<int> out = [];
    for (var member in json["members"]) {
      if (member["type"] == "relation" && member["role"] == "subarea") {
        out.add(member["ref"]);
      }
    }

    return out;
  }

  int state = 0;
  String text = "";
  (String, String) error = ("?", "?");
  Future<void> create(
    String generalName,
    String borderName,
    Function(void Function()) stateChange,
  ) async {
    Directory dir = Directory(getLocationOfRegion(generalName));
    print("Creating!!");
    Future<bool> addSingleAction(
      Future<void> Function() func,
      String name,
    ) async {
      stateChange(() {
        text += "$name ...";
      });
      try {
        await func();
        stateChange(() {
          text += "Done!\n";
        });
        return true;
      } catch (e) {
        stateChange(() {
          state = -1;
          error = (name, e.toString());
        });
        return false;
      }
    }

    if (await dir.exists()) {
      stateChange(() {
        state = -1;
        error = ("initialisation", "This country already exists");
      });
      return;
    }
    await dir.create();
    Directory("${dir.path}/subareas").create();

    Map<String, dynamic> borderNameJson = {};
    if (!await addSingleAction(() async {
      borderNameJson = await download(
        "${dir.path}/border.json",
        name: borderName,
      );
    }, "Downloading border"))
      return;
    List<int> out = [];
    try {
      out = await getProvinces(
        generalName,
        generalName == borderName ? borderNameJson : null,
      );
    } catch (e) {
      stateChange(() {
        state = -1;
        error = ("getting all subareas", e.toString());
      });
      return;
    }
    for (int i = 0; i < out.length; i++) {
      Map<String, dynamic> json = {};
      String name = "?";
      try {
        json = await getRequest(ref: out[i]);
        name = json["tags"]["name"].toString();
      } catch (e) {
        stateChange(() {
          state = -1;
          error = ("getting name for subarea $i", e.toString());
        });
        return;
      }
      if (!await addSingleAction(
        () => parseAndStoreBoundary(json, "${dir.path}/subareas/$name.json"),
        "Downloading subarea $name (${i + 1}/${out.length})",
      ))
        return;
    }
    if (!await addSingleAction(
      () => storeImage(generalName),
      "Generating image",
    ))
      return;
    imageCache.clear();

    stateChange(() {
      text += "All Done";
      state = 1;
    });
  }

  bool running = false;
  @override
  Widget build(BuildContext context) {
    void onSuccess() {
      context.goNamed("ChooseBoundary");
    }

    void onClick(String generalName, String borderName) async {
      print(
        "Downloading region with generalName $generalName and borderName $borderName",
      );
      state = 0;
      text = "";
      error = ("?", "?");
      running = false;
      await showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              if (!running) create(generalName, borderName, setState);
              running = true;
              if (state == 0)
                return AlertDialog(
                  title: Text("Adding country ..."),
                  content: Text(text.isEmpty ? "Please wait" : text),
                );
              if (state == 1) {
                return AlertDialog(
                  title: Text("Finished adding country"),
                  content: Text(text),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSuccess();
                      },
                      child: Text("Go back"),
                    ),
                  ],
                );
              }
              if (state == -1) {
                Directory(
                  getLocationOfRegion(generalName),
                ).deleteSync(recursive: true);
                return AlertDialog(
                  title: Text("Something went wrong during ${error.$1}"),
                  content: Text(error.$2),
                  actions: [
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text("Close"),
                    ),
                  ],
                );
              }
              return AlertDialog(title: Text("Something went very wrong :("));
            },
          );
        },
        barrierDismissible: false,
      );
    }

    return NewBorderWidget(onClick: onClick);
  }
}
