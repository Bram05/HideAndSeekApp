import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Map.dart';
import 'package:jetlag/Maths.dart';
import 'dart:io';
import 'dart:convert';
import 'package:jetlag/shape.dart';
import 'dart:ffi' hide Size;
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:ffi/ffi.dart';

void main() async {
  final directory = Directory('tests');
  List<FileSystemEntity> entities = await directory.list().toList();
  final Iterable<File> files = entities.whereType<File>();
  for (var file in files) {
    if (!file.path.endsWith('.json')) continue;

    test(file.path, () async {
      var (shapes, intersections, solutions) = fromJson(
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
  }
}
