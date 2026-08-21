import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class VisionClassifier {
  Interpreter? _interpreter;

  final List<String> _labels = [
    'Normal',
    'Mild',
    'Severe'
  ];

  Future<void> loadModel() async {
    try {
      final options = InterpreterOptions()..threads = 4;
      _interpreter = await Interpreter.fromAsset(
        'Assets/models/visioncare_model.tflite',
        options: options,
      );
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  /// STRICT STRUCTURAL VALIDATOR
  /// Validates based on RNFL patterns and Optic Disc presence.
  /// Works for both Camera and Gallery images.
  bool isValidRetinaStructure(File imageFile) {
    try {
      final bytes = imageFile.readAsBytesSync();
      final image = img.decodeImage(bytes);
      if (image == null) return false;

      // Analyze in 128x128 grayscale to focus on structure
      final sample = img.copyResize(image, width: 128, height: 128);
      List<int> grays = [];
      int maxG = 0;
      double avgG = 0;

      for (int y = 0; y < 128; y++) {
        for (int x = 0; x < 128; x++) {
          final p = sample.getPixel(x, y);
          int g = (0.299 * p.r + 0.587 * p.g + 0.114 * p.b).round();
          grays.add(g);
          if (g > maxG) maxG = g;
          avgG += g;
        }
      }
      avgG /= 16384;

      // 1. Complexity Check (Detects RNFL vessels and nerve patterns)
      // Walls/furniture/skin are too smooth (low complexity)
      int complexity = 0;
      for (int i = 1; i < 127; i++) {
        for (int j = 1; j < 127; j++) {
          int idx = i * 128 + j;
          int diff = (grays[idx] - grays[idx - 1]).abs() + (grays[idx] - grays[idx - 128]).abs();
          if (diff > 12) complexity++; 
        }
      }

      // 2. Optic Disc Presence
      // A valid retina MUST have a localized area of high intensity (maxG) 
      // relative to the average intensity.
      bool hasOpticDisc = maxG > (avgG * 1.3) && maxG > 100;
      
      // 3. RNFL Pattern Density
      // Retinas have a specific range of "complexity" due to vessels.
      // Too low = wall/skin. Too high = random noise.
      bool hasRetinalTexture = complexity > 600 && complexity < 5000;

      // 4. Dynamic Range Check
      bool hasDynamicRange = (maxG - avgG) > 40;

      // VALID_RETINA if it has the central structural marks (Disc + RNFL Texture)
      return hasOpticDisc && hasRetinalTexture && hasDynamicRange;
    } catch (e) {
      return false;
    }
  }

  Uint8List _preprocess(File imageFile) {
    final imageBytes = imageFile.readAsBytesSync();
    final decodedImage = img.decodeImage(imageBytes)!;
    final inputShape = _interpreter!.getInputTensor(0).shape;
    final int inputSize = inputShape[1]; 
    final resizedImage = img.copyResize(decodedImage, width: inputSize, height: inputSize);

    final buffer = Float32List(inputSize * inputSize * 3);
    var index = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        final pixel = resizedImage.getPixel(x, y);
        buffer[index++] = pixel.r / 255.0;
        buffer[index++] = pixel.g / 255.0;
        buffer[index++] = pixel.b / 255.0;
      }
    }
    return buffer.buffer.asUint8List();
  }

  Map<String, dynamic> predict(File imageFile) {
    if (_interpreter == null) return {"disease": "Error", "confidence": 0.0, "isValid": false};

    // STEP 1: STRICT STRUCTURAL VALIDATION
    if (!isValidRetinaStructure(imageFile)) {
      return {
        "disease": "INVALID_OBJECT",
        "confidence": 0.0,
        "isValid": false
      };
    }

    // STEP 2: AI INFERENCE
    var input = _preprocess(imageFile);
    final outputShape = _interpreter!.getOutputTensor(0).shape;
    final int numClasses = outputShape[1];
    var output = List.filled(numClasses, 0.0).reshape([1, numClasses]);
    _interpreter!.run(input, output);

    int maxIndex = 0;
    double maxScore = -1;
    for (int i = 0; i < numClasses; i++) {
      if (output[0][i] > maxScore) {
        maxScore = output[0][i];
        maxIndex = i;
      }
    }

    // STEP 3: STRICT CONFIDENCE (90%)
    if (maxScore < 0.90) {
      return {
        "disease": "INVALID_OBJECT",
        "confidence": maxScore,
        "isValid": false
      };
    }

    String label = "Unknown";
    if (numClasses == 5) {
      if (maxIndex == 2) {
        label = _labels[0]; // Normal
      } else if (maxIndex == 0 || maxIndex == 1) label = _labels[1]; // Mild
      else if (maxIndex == 3 || maxIndex == 4) label = _labels[2]; // Severe
    } else {
      label = maxIndex < _labels.length ? _labels[maxIndex] : "Unknown";
    }

    return {
      "disease": label,
      "confidence": maxScore,
      "isValid": true
    };
  }
}
