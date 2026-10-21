import 'dart:io';

import 'package:cross_file/cross_file.dart';

/// Deletes a recording the participant discarded. Missing files are fine.
Future<void> deleteRecording(XFile file) async {
  try {
    await File(file.path).delete();
  } on PathNotFoundException {
    // Already gone.
  }
}
