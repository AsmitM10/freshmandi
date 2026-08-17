import 'dart:typed_data';

import 'package:gal/gal.dart';

/// Android/iOS/desktop — saves to the device's photo gallery.
Future<void> saveImageBytes(Uint8List bytes, String fileName) async {
  final hasAccess = await Gal.hasAccess() || await Gal.requestAccess();
  if (!hasAccess) {
    throw Exception('Photo library access is needed to save the invoice.');
  }
  await Gal.putImageBytes(bytes, name: fileName);
}
