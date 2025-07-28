import 'dart:ffi';
import 'maths_generated_bindings.dart';
import 'package:ffi/ffi.dart';
import 'Maths.dart';

class LatLngDartStorage implements Finalizable {
  static final _finalizer = NativeFinalizer(
    (latlng) => latlng.free(),
  );
  Pointer<LatLngDart> data;
  LatLngDartStorage(double lat, double lon)
    : data = malloc()
        ..ref.lat = lat
        ..ref.lon = lon;
	{
	    _finalizer.attach(wrapper, connection, detach: wrapper);
	}

  void free() {
    malloc.free(data);
  }
}
