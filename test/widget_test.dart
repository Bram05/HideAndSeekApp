import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Map.dart';
import 'dart:io';
import 'dart:convert';
import 'package:jetlag/shape.dart';

void main() async {
  final directory = Directory('tests');
  List<FileSystemEntity> entities = await directory.list().toList();
  final Iterable<File> files = entities.whereType<File>();
  for (var file in files) {
    test(file.path, () async {
      var (shapes, intersections, solutions) = fromJson(
        jsonDecode(await file.readAsString()),
      );
      for (int i = 0; i < intersections.length; i++) {
        Shape result = intersect(
          shapes[intersections[i].$1],
          shapes[intersections[i].$2],
        );
        expect(result, solutions[i]);
      }
    });
  }
}
