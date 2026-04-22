import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

class ModelService {
  // Make sure this path exactly matches your assets configuration in pubspec.yaml
  static const String modelPath = 'Assets/models/visioncare_model.tflite';
  static const int inputSize = 224; // VisionCare model typically uses 224x224

  late Interpreter _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      // Close any existing interpreter to prevent memory leaks
      try {
        _interpreter.close();
      } catch (e) {
        // Ignore if interpreter wasn't initialized
      }

      final appDir = await getApplicationDocumentsDirectory();
      final modelFile = File('${appDir.path}/visioncare_model.tflite');

      if (!await modelFile.exists()) {
        print("Model file doesn't exist, copying from assets...");
        try {
          final modelData = await rootBundle.load(modelPath);
          await modelFile.writeAsBytes(modelData.buffer.asUint8List());
          print("Model file copied successfully: ${modelFile.path}");
          print("Model file size: ${await modelFile.length()} bytes");
        } catch (e) {
          print("Error copying model file: $e");
          rethrow;
        }
      } else {
        print("Using existing model file: ${modelFile.path}");
        print("Model file size: ${await modelFile.length()} bytes");
      }

      // Try loading directly from assets first
      try {
        print("Attempting to load model from assets...");
        final interpreterOptions = InterpreterOptions()..threads = 2;
        _interpreter =
            await Interpreter.fromAsset(modelPath, options: interpreterOptions);
        _isInitialized = true;
        print("Model loaded from assets successfully");
      } catch (assetError) {
        print("Failed to load from assets: $assetError");

        // Fall back to loading from file
        try {
          print("Attempting to load model from file...");
          final interpreterOptions = InterpreterOptions()..threads = 2;
          _interpreter = Interpreter.fromFile(modelFile,
              options: interpreterOptions);
          _isInitialized = true;
          print("Model loaded from file successfully");
        } catch (fileError) {
          print("Failed to load from file: $fileError");
          rethrow;
        }
      }

      // Print model details for debugging
      if (_isInitialized) {
        try {
          // Get input and output tensor details
          final inputTensor = _interpreter.getInputTensor(0);
          final outputTensor = _interpreter.getOutputTensor(0);

          print("Input tensor shape: ${inputTensor.shape}");
          print("Input tensor type: ${inputTensor.type}");
          print("Output tensor shape: ${outputTensor.shape}");
          print("Output tensor type: ${outputTensor.type}");
        } catch (e) {
          print("Error getting tensor info: $e");
        }
      }
    } catch (e, stackTrace) {
      print("Error initializing model: $e");
      print("Stack trace: $stackTrace");
      _isInitialized = false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> detectDisease(File imageFile) async {
    try {
      if (!_isInitialized) {
        await initialize();
        if (!_isInitialized) {
          throw Exception("Model failed to initialize");
        }
      }

      // Load and process the image
      final imageBytes = await imageFile.readAsBytes();
      var image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception("Failed to decode image");
      }

      print("Original image size: ${image.width}x${image.height}");

      // Resize image to match model input size
      var resizedImage =
          img.copyResize(image, width: inputSize, height: inputSize);
      print("Resized image to: ${resizedImage.width}x${resizedImage.height}");

      // Get input and output tensor shapes
      final inputShape = _interpreter.getInputTensor(0).shape;
      final outputShape = _interpreter.getOutputTensor(0).shape;

      print("Model expects input shape: $inputShape");
      print("Model provides output shape: $outputShape");

      // Prepare input data as a flat list first
      List<double> flatInputData = [];

      // Fill with normalized pixel values
      for (int y = 0; y < inputSize; y++) {
        for (int x = 0; x < inputSize; x++) {
          final pixel = resizedImage.getPixel(x, y);
          flatInputData.add(pixel.r / 255.0);
          flatInputData.add(pixel.g / 255.0);
          flatInputData.add(pixel.b / 255.0);
        }
      }

      // Reshape according to input shape
      List<dynamic> inputData;
      if (inputShape.length == 4) {
        // For [1, height, width, 3] format
        inputData = [
          flatInputData.reshape([inputSize, inputSize, 3])
        ];
      } else {
        // Fallback
        inputData = flatInputData.reshape(inputShape);
      }

      // Create output buffer with the correct shape
      List<dynamic> outputBuffer;
      if (outputShape.length == 2) {
        // For [1, 4] format
        outputBuffer = [List<double>.filled(outputShape[1], 0.0)];
      } else {
        outputBuffer =
            List<double>.filled(outputShape.reduce((a, b) => a * b), 0.0);
      }

      // Run inference with properly typed buffers
      print("Running inference...");
      _interpreter.run(inputData, outputBuffer);

      // Print all output values for debugging
      print("Inference complete. Raw output: $outputBuffer");
      if (outputShape.length == 2) {
        for (int i = 0; i < outputShape[1]; i++) {
          print("Class $i confidence: ${outputBuffer[0][i]}");
        }
      }

      // Process results
      String predictedDisease = "Healthy";
      double confidence = 0.0;

      // Find the class with highest confidence
      var maxIdx = 0;
      var maxVal = 0.0;

      if (outputShape.length == 2) {
        // For [1, 4] format
        maxVal = (outputBuffer[0][0] as num).toDouble();
        for (int i = 1; i < outputShape[1]; i++) {
          double val = (outputBuffer[0][i] as num).toDouble();
          if (val > maxVal) {
            maxVal = val;
            maxIdx = i;
          }
        }
      } else {
        maxVal = (outputBuffer[0] as num).toDouble();
        for (int i = 1; i < outputBuffer.length; i++) {
          double val = (outputBuffer[i] as num).toDouble();
          if (val > maxVal) {
            maxVal = val;
            maxIdx = i;
          }
        }
      }

      confidence = maxVal;

      // Apply confidence threshold of 0.3
      if (confidence >= 0.3) {
        // Map index to disease name - FIXED ORDER BASED ON MODEL OUTPUT
        if (maxIdx == 0) {
          predictedDisease = "Common Rust";
        } else if (maxIdx == 1) {
          predictedDisease = "Gray Leaf Spot";
        } else if (maxIdx == 2) {
          predictedDisease = "Healthy";
        } else if (maxIdx == 3) {
          predictedDisease = "Northern Leaf Blight";
        }
      } else {
        predictedDisease = "Unknown (Low Confidence)";
      }

      print("Predicted class index: $maxIdx with confidence: $confidence");
      print("Predicted disease: $predictedDisease");

      return {
        'disease': predictedDisease,
        'confidence': confidence,
        'detections': [],
      };
    } catch (e, stackTrace) {
      print("Error in detectDisease: $e");
      print("Stack trace: $stackTrace");
      rethrow;
    }
  }

  void dispose() {
    if (_isInitialized) {
      _interpreter.close();
    }
  }
}
