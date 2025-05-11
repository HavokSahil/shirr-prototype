import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<Uint8List?> captureSnapshot(GlobalKey repaintKey, {double pixelRatio = 3.0}) async {
  // Get the Render Repaint Boundary
  try {
    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    // Save the Image
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  } catch(e) {
    return null;
  }
}

Future<(bool, String?)> saveSnapshotToStorage(Uint8List bytes) async {
    try {
      if (Platform.isAndroid) {
        var result = await Permission.storage.request();
        if (result.isGranted) return (false, null);
      }
      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/snapshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(path);
      await file.writeAsBytes(bytes);

      return (true, path);
    } catch (err) {
      return (false, null);
    }
}