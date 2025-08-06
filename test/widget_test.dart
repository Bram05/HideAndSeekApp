import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Maths.dart';
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

    // if (file.path == "newtests/intersectSelfNL.json")
    // if (file.path != "newtests/nl.json")
    // file.path == "newtests/box.json" ||
    // file.path == "newtests/circle.json")
    // continue;
    test(file.path, () async {
      var (shapes, intersections, solutions, _, _, _, _, _) = fromJson(
        jsonDecode(await file.readAsString()),
      );
      for (int i = 0; i < intersections.length; i++) {
        Pointer<Void> result = maths.IntersectShapes(
          shapes[intersections[i].$1],
          shapes[intersections[i].$2],
        );
        if (1 != maths.ShapesEqual(result, solutions[i])) {
          maths.whyUnequal(result, solutions[i]);
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
