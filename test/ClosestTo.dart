import 'dart:convert';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jetlag/Boundary.dart';
import 'package:jetlag/Maths.dart';
import 'dart:ffi';
import 'package:jetlag/maths_generated_bindings.dart';
import 'package:jetlag/shape.dart';

void main() {
  test("Test closest to museum", () async {
    var museums = jsonDecode(
      await File("downloads/museums.json").readAsString(),
    );
    var (list, n) = convertToList(museums);

    // var result = await http.post(
    //   Uri.parse('https://overpass-api.de/api/interpreter'),
    //   body: {
    //     "data":
    //         '''[out:json][timeout:90];
    //           nwr['tourism' = 'museum'](around:1000,${pos.latitude}, ${pos.longitude});
    //           out geom;''',
    //   },
    // );

    LatLngDart position = Struct.create()
      ..lat = 52.36018057185034
      ..lon = 4.8852546013650695;
    File f = File("newtests/boxAroundRijksmuseum.json");
    File solutionFile = File("newtests/boxAroundRijksmuseumSolution.json");
    File solutionReverseFile = File(
      "newtests/boxAroundRijksmuseumSolutionReverse.json",
    );

    // Updating the boundary clears it so we have to load it twice
    var (boundaries1, _, _, _, _, _, _) = fromJson(
      jsonDecode(await f.readAsString()),
    );
    var (boundaries2, _, _, _, _, _, _) = fromJson(
      jsonDecode(await f.readAsString()),
    );
    assert(boundaries1.length == 1);
    assert(boundaries2.length == 1);
    var (solution, _, _, _, _, _, _) = fromJson(
      jsonDecode(await solutionFile.readAsString()),
    );
    var (solutionRev, _, _, _, _, _, _) = fromJson(
      jsonDecode(await solutionReverseFile.readAsString()),
    );
    assert(solution.length == 1);
    assert(solutionRev.length == 1);
    void test(Pointer<Void> result, Pointer<Void> sol) {
      if (1 != maths.ShapesEqual(result, sol)) {
        // File f = File("out.json");
        // f.writeAsString(jsonEncode(shapeToJson(result)));
        maths.whyUnequal(result, sol);
        assert(false);
      }
    }

    test(
      maths.UpdateBoundaryWithClosests(boundaries1[0], position, list, n, 1, 1),
      solution[0],
    );
    maths.Reverse(solution[0]);
    test(
      maths.UpdateBoundaryWithClosests(boundaries2[0], position, list, n, 0, 1),
      solutionRev[0],
    );
    maths.FreeShape(solution[0]);
    malloc.free(list);
  });
}
