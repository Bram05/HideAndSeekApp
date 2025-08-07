import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class SettingsWidget extends StatefulWidget {
  const SettingsWidget({super.key});

  @override
  State<StatefulWidget> createState() => SettingsWidgetState();
}

enum Quality { poor, medium, good, full }

int getDeltaFromQuality(Quality q) {
  switch (q) {
    case Quality.poor:
      return 30;
    case Quality.medium:
      return 10;
    case Quality.good:
      return 5;
    case Quality.full:
      return 1;
  }
}

Quality? toQuality(int value) {
  for (Quality q in Quality.values) {
    if (q.index == value) return q;
  }
  return null;
}

Quality? toQualityString(String value) {
  for (Quality q in Quality.values) {
    if (q.name == value) return q;
  }
  return null;
}

Future<String> getSettingsFile() async {
  String s = "${(await getApplicationDocumentsDirectory()).path}/settings.txt";
  print("Settings file: $s");
  return s;
}

Future<File> openSettings() async {
  File f = File(await getSettingsFile());
  if (!await f.exists()) await f.create(recursive: true);
  return f;
}

Future<Quality> readQuality() async {
  File f = await openSettings();

  Quality? q = toQualityString(await f.readAsString());
  if (q == null) return Quality.medium;
  return q;
}

Future<void> writeQuality(Quality q) async {
  File f = await openSettings();

  f.writeAsString(q.name);
}

class SettingsWidgetState extends State<SettingsWidget> {
  Quality? quality = null;

  @override
  void deactivate() async {
    if (quality != null) await writeQuality(quality!);
    super.deactivate();
  }

  Future<int> setQuality() async {
    if (quality != null) return Future.value(3);
    quality = await readQuality();
    print("Complete");
    return Future.value(3);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: setQuality(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Text("Failed to load settings: ${snap.error}");
        }
        if (!snap.hasData) return Text("Loading settings ...");

        return LayoutBuilder(
          builder: (context, constraints) {
            double widthMargin = min(
              max(40, (constraints.maxWidth - 800) / 2),
              200,
            );
            double heightMargin = min(
              max(40, (constraints.maxHeight - 150) / 2),
              100,
            );
            return Card(
              margin: EdgeInsets.symmetric(
                horizontal: widthMargin,
                vertical: heightMargin,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      "Settings",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Table(
                      columnWidths: const {1: FractionColumnWidth(0.75)},
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle, // center the text
                      children: [
                        TableRow(
                          children: [
                            Text(
                              "Quality of the map",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            SliderTheme(
                              data: SliderThemeData(year2023: false),
                              child: Slider(
                                value: quality!.index.toDouble(),
                                min: 0,
                                max: Quality.values.length - 1,
                                divisions: Quality.values.length - 1,
                                label: quality!.name,
                                onChanged: (double value) {
                                  setState(() {
                                    quality = toQuality(value.toInt())!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
