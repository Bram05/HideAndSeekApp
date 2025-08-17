import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Maths.dart';
import 'package:jetlag/SettingsWidget.dart';
import 'dart:io';
import 'dart:convert';
import 'package:jetlag/shape.dart';
import 'dart:ffi' hide Size;

void main() async {
  final directory = Directory('newtests');
  List<FileSystemEntity> entities = await directory.list().toList();
  final Iterable<File> files = entities.whereType<File>();
  for (var file in files) {
    if (!file.path.endsWith('.json')) continue;

    if (file.path == "newtests/sharingASide.json")
      continue; // This one is not reliable because the sides may be equal as doubles but not necessarily as high precision Doubles (i.e. it fails when precision is set too high
    // if (file.path != "newtests/nl.json")
    // file.path == "newtests/box.json" ||
    // file.path == "newtests/circle.json")
    // continue;
    test(file.path, () async {
      var (shapes, intersections, solutions, _, _, _, _, _) = fromJson(
        jsonDecode(await file.readAsString()),
        getDeltaFromQuality(Quality.full),
      );
      for (int i = 0; i < intersections.length; i++) {
        Pointer<Void> result = maths.IntersectShapes(
          shapes[intersections[i].$1],
          shapes[intersections[i].$2],
        );
        if (1 != maths.ShapesEqual(result, solutions[i])) {
          maths.whyUnequal(result, solutions[i]);
          File f = File("${file.path}.res");
          f.writeAsString(jsonEncode(toJson(result, [])));
          assert(false);
        }
        maths.FreeShape(result);
      }
      for (var shape in shapes) maths.FreeShape(shape);
    });
    // tearDownAll(() async {
    //   maths.DestroyEverything();
    //   await Future.delayed(const Duration(seconds: 5), () {
    //     print("Quitting");
    //   });
    // });
  }
}
