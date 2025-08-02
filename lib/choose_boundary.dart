import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:jetlag/new_border.dart';
import 'package:screenshot/screenshot.dart';

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

class ChooseBoundaryState extends State<ChooseBoundary> {
  Future<List<String>> getBorders() async {
    Directory dir = Directory("countries");
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
        return Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              Text(
                "Choose the area to play in",
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
                    Text("Something went wrong, please try again.")
                  else if (!snapshot.hasData)
                    Text("Loading ...")
                  else
                    for (var item in snapshot.data!)
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 500),
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
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                                child: Image.file(
                                  File("countries/${uglify(item)}/image.jpeg"),
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
              TextButton(
                onPressed: () {
                  context.goNamed(
                    "Map",
                    pathParameters: {"path": "Europees_Nederland"},
                  );
                },
                child: Text("Go directly to Netherlands"),
              ),
            ],
          ),
        );
      },
    );
  }
}
