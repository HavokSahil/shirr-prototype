import 'package:file_picker/file_picker.dart';

class MediaPicker {
  FilePickerResult? result;
  bool _isValidResult = false;

  MediaPicker();

  Future<void> chooseAudioFile() async {
    result = await FilePicker.platform.pickFiles(type: FileType.audio);
    if (result != null && result!.files.single.path != null) {
      _isValidResult = true;
    } else {
      _isValidResult = false; 
    }
  }

  bool containsValidResult() => _isValidResult;

  String? getFileName() {
    if (_isValidResult) {
      return result!.files.single.name;
    }
    return null;
  }

  String? getFilePath() {
    if (_isValidResult) {
      return result!.files.single.path;
    }
    return null;
  }
}