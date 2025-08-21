import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'map.dart';
import 'settings_widget.dart';
import 'main.dart';
import 'new_border.dart';

String beautify(String countryName) {
  return countryName.replaceAll("_", " ");
}

String uglify(String countryName) {
  return countryName.replaceAll(" ", "_");
}

class ChooseBoundary extends StatefulWidget {
  const ChooseBoundary({super.key});
  @override
  State<StatefulWidget> createState() {
    return ChooseBoundaryState();
  }
}

String getCountriesDirectory() {
  return "$documentsdir/countries";
}

class ChooseBoundaryState extends State<ChooseBoundary> {
  Future<List<String>> getBorders() async {
    await setAppDir();
    Directory f = Directory(getCountriesDirectory());
    if (!await f.exists()) await f.create(recursive: true);
    f = Directory(getSavesDirectory());
    if (!await f.exists()) await f.create(recursive: true);

    Directory dir = Directory(getCountriesDirectory());
    return dir
        .list()
        .map(
          (file) =>
              beautify(file.path.toString().replaceFirst("${dir.path}/", "")),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getBorders(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        return SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 20),
                Text(
                  "Where do you want to play?",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.center,
                  spacing: 20,
                  children: [
                    if (snapshot.hasError)
                      Text(
                        "Something went wrong (${snapshot.error}), please try again.",
                      )
                    else if (!snapshot.hasData)
                      Text("Loading ...")
                    else
                      for (var item in snapshot.data!)
                        ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 400),
                          child: Card(
                            child: ListTile(
                              // minVerticalPadding: 20,
                              minLeadingWidth: 20,
                              title: Center(
                                child: Text(
                                  beautify(item),
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              onTap: () {
                                context.goNamed(
                                  "Map",
                                  pathParameters: {"path": item},
                                );
                              },
                              onLongPress: () async {
                                bool? result = await showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text(
                                        "Are you sure you want to delete the region '$item'?",
                                      ),
                                      // actionsAlignment:
                                      //     MainAxisAlignment.spaceAround,
                                      actions: [
                                        FilledButton(
                                          child: Text("Yes"),
                                          onPressed: () {
                                            Navigator.pop(context, true);
                                          },
                                        ),
                                        FilledButton(
                                          child: Text("No"),
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                                if (result == true) {
                                  setState(() {
                                    Directory(
                                      getLocationOfRegion(item),
                                    ).deleteSync(recursive: true);
                                  });
                                }
                              },
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(10),
                                  ),
                                  child: Image.file(
                                    File(
                                      "${getLocationOfRegion(item)}/image.jpeg",
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
                FilledButton(
                  onPressed: () {
                    context.goNamed("CreateBoundary");
                  },
                  child: Text("Add your own"),
                ),
                FilledButton(
                  onPressed: () {
                    context.goNamed("MapFun");
                  },
                  child: Text("Have some fun on the map"),
                ),
                FilledButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return SettingsWidget();
                      },
                    );
                  },
                  child: Text("Settings"),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}
