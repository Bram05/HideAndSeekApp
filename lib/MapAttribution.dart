import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MapAttribution extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MapAttributionState();
}

class MapAttributionState extends State<MapAttribution> {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.black),
              text: "All map related data from ",
              children: [
                TextSpan(
                  text: "OpenStreetMap",
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () async {
                      if (!await launchUrl(
                        Uri.https("openstreetmap.org", "copyright"),
                        mode: LaunchMode.externalApplication,
                      ))
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("Unable to open license page"),
                              content: Text(
                                "Please go to 'https://www.openstreetmap.org/copyright' yourself",
                              ),
                            );
                          },
                        );
                    },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
