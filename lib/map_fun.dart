import 'package:flutter_map_compass/flutter_map_compass.dart';
import 'package:go_router/go_router.dart';
import 'package:jetlag/MapAttribution.dart';
import 'package:jetlag/MapFun/circle.dart';
import 'package:jetlag/draw_shape.dart';
import 'package:jetlag/scale.dart';
import 'menu_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapFunWidget extends StatefulWidget {
  const MapFunWidget({super.key});

  @override
  State<StatefulWidget> createState() => MapFunWidgetState();
}

class MapFunWidgetState extends State<MapFunWidget> {
  int tileDimension = 256;
  late TileLayer tileLayer;
  final mapController = MapController();
  late List<(String, Widget)> types;
  Widget? activeWidget;

  @override
  void initState() {
    tileLayer = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.HideAndSeek.app',
      tileDimension: tileDimension,
    );
    super.initState();
    types = [
      ("Circle", CircleWidget()),
      ("Drawing", ShapeCreator(callback: (shape) {})),
    ];
  }

  @override
  void dispose() {
    super.dispose();
  }

  LatLng initialPos = LatLng(50, 5);
  double initialZoom = 6;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(child: MenuBar(children: MenuEntry.build(_getMenus()))),
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
                if (activeWidget != null) activeWidget!,
                MapAttribution(),
                MapCompass.cupertino(hideIfRotatedNorth: true),
                ScaleWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<MenuEntry> _getMenus() {
    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'Go back',
        onPressed: () {
          context.goNamed("ChooseBoundary");
        },
        active: true,
      ),
      for (var (name, widget) in types)
        MenuEntry(
          label: name,
          onPressed: () {
            setState(() {
              activeWidget = widget;
            });
          },
        ),
      MenuEntry(
        label: "Nothing",
        onPressed: () {
          setState(() {
            activeWidget = null;
          });
        },
      ),
    ];
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
