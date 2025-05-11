// import 'dart:async';
// import 'dart:io';
// import 'dart:isolate';
// import 'dart:typed_data';

// import 'package:flutter/foundation.dart';
// import 'package:flutter_sound/flutter_sound.dart';
// import 'package:shirr/services/audio_decoder.dart';

// class MediaController {
//   final FlutterSoundPlayer _player = FlutterSoundPlayer();
//   final StreamController<Uint8List> _streamController = StreamController<Uint8List>();
//   Isolate? _streamIsolate;
//   ReceivePort? _receivePort;
//   SendPort? _sendPort;

//   File? _file;
//   String? _decodedFile;
//   int _fileLength = 0;

//   int _sampleRate = 44100;
//   int _channels = 2;
//   int _bitsPerSample = 16;
//   int _headerSize = 44;

//   bool _isPlaying = false;
//   bool _isPaused = false;
//   Duration _playbackPosition = Duration.zero;

//   MediaController() {
//     _player.openPlayer();
//     _player.setSubscriptionDuration(const Duration(milliseconds: 200));
//     _player.onProgress?.listen((progress) {
//       _playbackPosition = progress.position;
//     });
//   }

//   static List<double> convertUint8ToDouble(Uint8List bytes) {
//     final sampleCount = bytes.length ~/ 2;
//     final byteData = ByteData.sublistView(bytes);
//     return List.generate(sampleCount, (i) {
//       final sample = byteData.getInt16(i * 2, Endian.little);
//       return sample / 32768.0;
//     });
//   }

//   Future<bool> loadAudio(String path) async {
//     _decodedFile = await AudioDecoder.convertToWav(path);
//     if (_decodedFile == null || _decodedFile!.isEmpty) return false;

//     _file = File(_decodedFile!);
//     _fileLength = await _file!.length();

//     final header = await _file!.openRead(0, 44).first;
//     if (header.length >= 44) _parseWavHeader(Uint8List.fromList(header));

//     return true;
//   }

//   void _parseWavHeader(Uint8List header) {
//     final byteData = ByteData.sublistView(header);
//     _channels = byteData.getInt16(22, Endian.little);
//     _sampleRate = byteData.getInt32(24, Endian.little);
//     _bitsPerSample = byteData.getInt16(34, Endian.little);
//     _headerSize = 44; // May adjust if you support extended headers
//   }

//   Future<void> play() async {
//     if (_isPlaying && !_isPaused) return;
//     if (_file == null || _fileLength <= _headerSize) return;

//     _streamController.addStream(_streamWavFromIsolate());

//     await _player.startPlayerFromStream(
//       codec: Codec.pcm16,
//       numChannels: _channels,
//       sampleRate: _sampleRate,
//     );

//     _isPlaying = true;
//     _isPaused = false;

//     _streamController.stream.listen(
//       (chunk) => _player.feedUint8FromStream(chunk),
//       onDone: stop,
//       onError: (e) => stop(),
//       cancelOnError: true,
//     );
//   }

//   Future<void> pause() async {
//     if (_isPlaying && !_isPaused) {
//       await _player.pausePlayer();
//       _isPaused = true;
//     }
//   }

//   Future<void> resume() async {
//     if (_isPlaying && _isPaused) {
//       await _player.resumePlayer();
//       _isPaused = false;
//     }
//   }

//   Future<void> stop() async {
//     await _player.stopPlayer();
//     await _streamController.close();
//     _isPlaying = false;
//     _isPaused = false;

//     _receivePort?.close();
//     _streamIsolate?.kill(priority: Isolate.immediate);
//     _streamIsolate = null;
//     _receivePort = null;
//     _sendPort = null;
//   }

//   Future<void> restart() async {
//     await stop();
//     await loadAudio(_decodedFile!);
//     await play();
//   }

//   Future<void> seek(Duration position) async {
//     await _player.seekToPlayer(position);
//     _playbackPosition = position;
//   }

//   Duration getPlaybackPosition() => _playbackPosition;

//   /// Isolated WAV streaming function
//   Stream<Uint8List> _streamWavFromIsolate() async* {
//     _receivePort = ReceivePort();
//     _streamIsolate = await Isolate.spawn(_wavIsolateEntry, {
//       'sendPort': _receivePort!.sendPort,
//       'path': _file!.path,
//       'startOffset': _headerSize,
//     });

//     final controller = StreamController<Uint8List>();

//     _receivePort!.listen((message) {
//       if (message is Uint8List) {
//         controller.add(message);
//       } else if (message == 'done') {
//         controller.close();
//       }
//     });

//     yield* controller.stream;
//   }

//   static Future<void> _wavIsolateEntry(Map<String, dynamic> args) async {
//     final SendPort sendPort = args['sendPort'];
//     final String path = args['path'];
//     final int startOffset = args['startOffset'];

//     final file = File(path);
//     final stream = file.openRead(startOffset);

//     await for (final chunk in stream) {
//       sendPort.send(Uint8List.fromList(chunk));
//     }

//     sendPort.send('done');
//   }

//   Future<void> dispose() async {
//     await stop();
//     await _player.closePlayer();
//   }
// }
