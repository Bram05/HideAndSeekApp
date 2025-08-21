import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'maths.dart';
import 'maths_generated_bindings.dart';

class LatitudeQuestion {
  final int id;
  final Pointer<Void> shape;
  final double lat;
  final int answer;
  const LatitudeQuestion(this.id, this.shape, this.lat, this.answer);
}

class LongitudeQuestion {
  final int id;
  final Pointer<Void> shape;
  final double lon;
  final int answer;
  const LongitudeQuestion(this.id, this.shape, this.lon, this.answer);
}

class AdminAreaQuestion {
  final int id;
  final Pointer<Void> shape;
  final Pointer<Void> regions;
  final int length;
  final LatLngDart position;
  final int answer;
  const AdminAreaQuestion(
    this.id,
    this.shape,
    this.regions,
    this.length,
    this.position,
    this.answer,
  );
}

class ClosestMuseumQuestion {
  final int id;
  final Pointer<Void> boundary;
  final LatLngDart position;
  final Pointer<LatLngDart> museums;
  final int numMuseums;
  final int answer;
  final int deleteFirst;
  const ClosestMuseumQuestion(
    this.id,
    this.boundary,
    this.position,
    this.museums,
    this.numMuseums,
    this.answer,
    this.deleteFirst,
  );
}

class WithinRadiusQuestion {
  final int id;
  final Pointer<Void> boundary;
  final LatLngDart centre;
  final double radius;
  final int answer;
  const WithinRadiusQuestion(
    this.id,
    this.boundary,
    this.centre,
    this.radius,
    this.answer,
  );
}

class QuestionResponse {
  final int id;
  final Pointer<Void> shape;
  const QuestionResponse(this.id, this.shape);
}

Future<Pointer<Void>> askLatitudeQuestion(
  Pointer<Void> Function(Pointer<Void>, double, int) func,
  Pointer<Void> boundary,
  double lat,
  bool ans,
) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextQuestionRequestId++;
  final LatitudeQuestion request = LatitudeQuestion(
    requestId,
    // func,
    boundary,
    lat,
    ans ? 1 : 0,
  );
  final Completer<Pointer<Void>> completer = Completer<Pointer<Void>>();
  _questionRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

Future<Pointer<Void>> askLongitudeQuestion(
  Pointer<Void> Function(Pointer<Void>, double, int) func,
  Pointer<Void> boundary,
  double lon,
  bool ans,
) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextQuestionRequestId++;
  final LongitudeQuestion request = LongitudeQuestion(
    requestId,
    // func,
    boundary,
    lon,
    ans ? 1 : 0,
  );
  final Completer<Pointer<Void>> completer = Completer<Pointer<Void>>();
  _questionRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

Future<Pointer<Void>> askAdminAreaQuestion(
  Pointer<Void> boundary,
  Pointer<Void> regions,
  int length,
  LatLngDart position,
  bool ans,
) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextQuestionRequestId++;
  final AdminAreaQuestion request = AdminAreaQuestion(
    requestId,
    boundary,
    regions,
    length,
    position,
    ans ? 1 : 0,
  );
  final Completer<Pointer<Void>> completer = Completer<Pointer<Void>>();
  _questionRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

Future<Pointer<Void>> askWithinRadiusQuestion(
  Pointer<Void> boundary,
  LatLngDart centre,
  double radius,
  bool ans,
) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextQuestionRequestId++;
  final WithinRadiusQuestion request = WithinRadiusQuestion(
    requestId,
    boundary,
    centre,
    radius,
    ans ? 1 : 0,
  );
  final Completer<Pointer<Void>> completer = Completer<Pointer<Void>>();
  _questionRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

Future<Pointer<Void>> askClosestMuseumQuestion(
  Pointer<Void> boundary,
  LatLngDart position,
  Pointer<LatLngDart> museums,
  int numMuseums,
  bool answer,
  bool deleteFirst,
) async {
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextQuestionRequestId++;
  final ClosestMuseumQuestion request = ClosestMuseumQuestion(
    requestId,
    boundary,
    position,
    museums,
    numMuseums,
    answer ? 1 : 0,
    deleteFirst ? 1 : 0,
  );
  final Completer<Pointer<Void>> completer = Completer<Pointer<Void>>();
  _questionRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

int _nextQuestionRequestId = 0;

/// Mapping from [_SumRequest] `id`s to the completers corresponding to the correct future of the pending request.
final Map<int, Completer<Pointer<Void>>> _questionRequests =
    <int, Completer<Pointer<Void>>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is QuestionResponse) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<Pointer<Void>> completer = _questionRequests[data.id]!;
        _questionRequests.remove(data.id);
        completer.complete(data.shape);
        return;
      }
      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) async {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // On the helper isolate listen to requests and respond to them.
        if (data is LatitudeQuestion) {
          final Pointer<Void> result = maths.LatitudeQuestion(
            data.shape,
            data.lat,
            data.answer,
          );
          final QuestionResponse response = QuestionResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        if (data is LongitudeQuestion) {
          final Pointer<Void> result = maths.LongitudeQuestion(
            data.shape,
            data.lon,
            data.answer,
          );
          final QuestionResponse response = QuestionResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        if (data is AdminAreaQuestion) {
          final Pointer<Void> result = maths.AdminAreaQuesiton(
            data.shape,
            data.regions,
            data.length,
            data.position,
            data.answer,
          );
          final QuestionResponse response = QuestionResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        if (data is ClosestMuseumQuestion) {
          final Pointer<Void> result = maths.UpdateBoundaryWithClosests(
            data.boundary,
            data.position,
            data.museums,
            data.numMuseums,
            data.answer,
            data.deleteFirst,
          );
          final QuestionResponse response = QuestionResponse(data.id, result);
          sendPort.send(response);
          return;
        }
        if (data is WithinRadiusQuestion) {
          final Pointer<Void> result = maths.WithinRadiusQuestion(
            data.boundary,
            data.centre,
            data.radius,
            data.answer,
          );
          final QuestionResponse response = QuestionResponse(data.id, result);
          sendPort.send(response);
          return;
        }

        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();
