import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import './Results.dart';
import '../database/database_helper.dart';
import '../vision_classifier.dart';

class Scan extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  const Scan({super.key, this.patientName, this.patientId});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  static const int _maxSelectedImages = 5;
  List<File> _selectedImages = [];
  int _selectedImageIndex = 0;
  bool get _hasSelection => _selectedImages.isNotEmpty;
  final VisionClassifier _visionClassifier = VisionClassifier();
  bool _isProcessing = false;
  late AnimationController _animationController;
  late Animation<double> _scanAnimation;
  
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;

  // Eye detection variables
  late FaceDetector _faceDetector;
  bool _isDetecting = false;
  bool _eyeDetected = false;
  bool _canProcess = true;

  @override
  void initState() {
    super.initState();
    _initializeModel();
    _initializeDetector();
    _setupCamera();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _animationController.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _animationController.forward();
        }
      });
  }

  void _initializeDetector() {
    final options = FaceDetectorOptions(
      enableLandmarks: true,
      enableClassification: true,
      performanceMode: FaceDetectorMode.fast,
    );
    _faceDetector = FaceDetector(options: options);
  }

  Future<void> _setupCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
          imageFormatGroup: Platform.isAndroid
              ? ImageFormatGroup.yuv420
              : ImageFormatGroup.bgra8888,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
          _startImageStream();
        }
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startImageStream() {
    if (_cameraController == null) return;
    
    _cameraController!.startImageStream((CameraImage image) {
      if (_isProcessing || !_canProcess || _hasSelection) return;
      
      _processCameraImage(image);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isDetecting || !_canProcess) return;
    _isDetecting = true;

    try {
      bool eyeInFrame = false;

      // STEP 1: Try Face/Eye Detection (for distance shots)
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage != null) {
        final faces = await _faceDetector.processImage(inputImage);
        if (faces.isNotEmpty) {
          for (Face face in faces) {
            final leftEye = face.landmarks[FaceLandmarkType.leftEye];
            final rightEye = face.landmarks[FaceLandmarkType.rightEye];
            if (leftEye != null || rightEye != null) {
              eyeInFrame = true;
              break;
            }
          }
        }
      }

      // STEP 2: Fallback to Retina/Close-up Detection (for macro shots)
      if (!eyeInFrame) {
        eyeInFrame = _isRetinaLike(image);
      }

      if (mounted && _eyeDetected != eyeInFrame) {
        setState(() {
          _eyeDetected = eyeInFrame;
        });
      }
    } catch (e) {
      debugPrint('Error detecting eyes: $e');
    } finally {
      _isDetecting = false;
    }
  }

  /// Strict retinal structure check for live feed.
  /// Synchronized with the logic in VisionClassifier.isValidRetinaStructure.
  bool _isRetinaLike(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;
      final Uint8List bytes = image.planes[0].bytes; // Y Plane (Luminance)

      // We focus on the central area of the frame
      int startY = height ~/ 4;
      int endY = 3 * height ~/ 4;
      int startX = width ~/ 4;
      int endX = 3 * width ~/ 4;

      int totalY = 0;
      int maxY = 0;
      int sampleCount = 0;
      int complexity = 0;

      // Analyzing structure and intensity
      for (int y = startY; y < endY; y += 10) {
        for (int x = startX; x < endX; x += 10) {
          int index = y * width + x;
          if (index < bytes.length) {
            int val = bytes[index];
            totalY += val;
            if (val > maxY) maxY = val;
            
            // Check complexity (gradient/edges) to detect vessel-like patterns
            if (x > startX && y > startY) {
              int prevX = bytes[index - 10];
              int prevY = bytes[index - (width * 10)];
              int diff = (val - prevX).abs() + (val - prevY).abs();
              if (diff > 15) complexity++;
            }
            sampleCount++;
          }
        }
      }

      if (sampleCount == 0) return false;
      double avgY = totalY / sampleCount;

      // --- STRICT VALIDATION (Same as VisionClassifier) ---
      
      // 1. Optic Disc / Localized Highlight Check
      bool hasOpticDisc = maxY > (avgY * 1.3) && maxY > 120;
      
      // 2. Retinal Texture / Vessel Complexity Check
      // We scale the threshold based on the number of samples
      bool hasRetinalTexture = complexity > (sampleCount * 0.05);

      // 3. Dynamic Range Check
      bool hasDynamicRange = (maxY - avgY) > 30;

      // Only return true if it meets all "Eye-like" structural criteria
      return hasOpticDisc && hasRetinalTexture && hasDynamicRange;
    } catch (e) {
      return false;
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (_cameraController == null) return null;

    final sensorOrientation = _cameras![0].sensorOrientation;
    final InputImageRotation? rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final InputImageFormat? format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || (Platform.isAndroid && format != InputImageFormat.yuv420) || (Platform.isIOS && format != InputImageFormat.bgra8888)) return null;

    if (image.planes.length != 1 && Platform.isIOS) return null;
    if (image.planes.length != 3 && Platform.isAndroid) return null;

    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final InputImageMetadata metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: rotation,
      format: format,
      bytesPerRow: image.planes[0].bytesPerRow,
    );

    return InputImage.fromBytes(bytes: bytes, metadata: metadata);
  }

  @override
  void dispose() {
    _canProcess = false;
    _faceDetector.close();
    _animationController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeModel() async {
    await _visionClassifier.loadModel();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _selectedImages = [File(file.path)];
        _selectedImageIndex = 0;
      });
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _processImage() async {
    if (!_hasSelection) return;

    try {
      setState(() {
        _isProcessing = true;
      });
      _animationController.forward();

      // Artificial delay to show the scanning animation
      await Future.delayed(const Duration(seconds: 3));

      // 1. Process with model using aggregated multi-image inference.
      final result = _aggregatePrediction(_selectedImages);
      final String disease = result["disease"] ?? "Unknown";
      final double confidence = result["confidence"] ?? 0.0;
      final bool isValid = result["isValid"] ?? false;

      // STRICT VALIDATION: Check if there is at least one valid retina image.
      if (!isValid || disease == "INVALID_OBJECT") {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
          _animationController.stop();
          
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0B2239),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
                  SizedBox(width: 10),
                  Text("Invalid Image", style: TextStyle(color: Colors.white)),
                ],
              ),
              content: const Text(
                "The system determined that the selected image(s) are not valid retinas. Please ensure you select clear, well-lit retina photos.",
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK", style: TextStyle(color: Color(0xFF5ED3F2), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
        return;
      }

      final dbHelper = DatabaseHelper();
      final File approvedImage = result["approvedImage"] as File;
      final imagePath = await dbHelper.saveImage(approvedImage);
      
      // 2. Save to database
      await dbHelper.insertDiagnosis(
        disease, 
        imagePath,
        confidence,
        patientName: widget.patientName,
        patientId: widget.patientId,
      );

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });
      _animationController.stop();

      // 3. Show Results as a modal bottom sheet (keeps Scan context alive)
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final height = MediaQuery.of(context).size.height * 0.88;
          return SizedBox(
            height: height,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF011627),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: ResultsContent(
                disease: disease,
                date: DateFormat('MMMM dd, yyyy').format(DateTime.now()),
                imagePath: imagePath,
                confidence: confidence,
                patientName: widget.patientName,
                patientId: widget.patientId,
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        _animationController.stop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _aggregatePrediction(List<File> imageFiles) {
    final Map<String, double> scoreSums = {};
    final Map<String, List<double>> scoreLists = {};
    final Map<String, File> bestImages = {};
    final Map<String, double> bestImageConfidences = {};
    int validCount = 0;

    for (final file in imageFiles) {
      final result = _visionClassifier.predict(file);
      final bool isValid = result["isValid"] ?? false;
      final String disease = result["disease"] ?? "INVALID_OBJECT";
      final double confidence = result["confidence"] ?? 0.0;

      if (!isValid || disease == "INVALID_OBJECT") {
        continue;
      }

      scoreSums[disease] = (scoreSums[disease] ?? 0.0) + confidence;
      scoreLists.putIfAbsent(disease, () => []).add(confidence);
      if (confidence > (bestImageConfidences[disease] ?? -1.0)) {
        bestImageConfidences[disease] = confidence;
        bestImages[disease] = file;
      }
      validCount++;
    }

    if (validCount == 0) {
      return {
        "disease": "INVALID_OBJECT",
        "confidence": 0.0,
        "isValid": false,
      };
    }

    final bestEntry = scoreSums.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final bestLabel = bestEntry.key;
    final bestConfidences = scoreLists[bestLabel]!;
    final averageConfidence = bestConfidences.reduce((a, b) => a + b) / bestConfidences.length;

    return {
      "disease": bestLabel,
      "confidence": averageConfidence,
      "approvedImage": bestImages[bestLabel],
      "isValid": true,
    };
  }

  Future<void> _pickImageFromGallery() async {
    if (_selectedImages.length >= _maxSelectedImages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can only select up to 5 images.')),
        );
      }
      return;
    }

    try {
      final List<XFile>? pickedFiles = await _picker.pickMultiImage(
        maxWidth: 4000,
        maxHeight: 4000,
      );

      if (pickedFiles != null && pickedFiles.isNotEmpty && mounted) {
        final newFiles = pickedFiles.map((file) => File(file.path)).toList();
        final combined = List<File>.from(_selectedImages)..addAll(newFiles);
        if (combined.length > _maxSelectedImages) {
          final allowed = combined.sublist(0, _maxSelectedImages);
          setState(() {
            _selectedImages = allowed;
            if (_selectedImageIndex >= _selectedImages.length) {
              _selectedImageIndex = 0;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only the first 5 images were added.')),
          );
        } else {
          setState(() {
            _selectedImages = combined;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF011627),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Image/Camera Box
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Center(
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B2239),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10, width: 1),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Image or Camera Preview
                              _hasSelection
                                  ? Image.file(_selectedImages[_selectedImageIndex], fit: BoxFit.cover)
                                  : _isCameraInitialized && _cameraController != null
                                      ? FittedBox(
                                          fit: BoxFit.cover,
                                          child: SizedBox(
                                            width: _cameraController!.value.previewSize?.height ?? 1,
                                            height: _cameraController!.value.previewSize?.width ?? 1,
                                            child: CameraPreview(_cameraController!),
                                          ),
                                        )
                                      : const Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(color: Color(0xFF5ED3F2)),
                                              SizedBox(height: 16),
                                              Text(
                                                "Initializing camera...",
                                                style: TextStyle(color: Colors.white54, fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                              
                              // Grid Overlay
                              if (!_hasSelection) _buildGridOverlay(),

                              // No Eye Detected Overlay
                              if (!_hasSelection && _isCameraInitialized && !_eyeDetected && !_isProcessing)
                                Container(
                                  color: Colors.black26,
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.visibility_off, color: Colors.white, size: 20),
                                          SizedBox(width: 8),
                                          Text(
                                            "No eye detected",
                                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Scanning Animation Line
                              if (_isProcessing && _hasSelection)
                                AnimatedBuilder(
                                  animation: _scanAnimation,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: constraints.maxHeight * _scanAnimation.value,
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF5ED3F2).withOpacity(0.8),
                                              blurRadius: 10,
                                              spreadRadius: 2,
                                            )
                                          ],
                                          color: const Color(0xFF5ED3F2),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                              // Processing Overlay
                              if (_isProcessing)
                                Container(
                                  color: Colors.black45,
                                  child: const Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: Color(0xFF5ED3F2)),
                                        SizedBox(height: 20),
                                        Text(
                                          "Scanning retina...",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            shadows: [Shadow(blurRadius: 10, color: Colors.black, offset: Offset(2, 2))],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                ),
              ),

              const SizedBox(height: 30),

              if (_hasSelection)
                _buildSelectedImagesPreview(),

              const SizedBox(height: 20),

              // Action Buttons
              if (!_isProcessing)
                Column(
                  children: [
                    if (_hasSelection)
                      _buildMainButton(
                        icon: Icons.analytics_outlined,
                        label: "PROCEED TO SCAN",
                        color: const Color(0xFF5ED3F2),
                        onTap: _processImage,
                      )
                    else
                      _buildMainButton(
                        icon: Icons.camera_alt,
                        label: "CAPTURE",
                        color: _eyeDetected ? const Color(0xFF5ED3F2) : Colors.grey,
                        onTap: _eyeDetected ? _takePicture : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please position the camera to detect an eye."),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildSecondaryButton(
                            icon: Icons.photo_library,
                            label: 'pick_from_gallery'.tr(),
                            onTap: _pickImageFromGallery,
                          ),
                        ),
                        if (_hasSelection) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSecondaryButton(
                              icon: Icons.camera_alt,
                              label: 'Retake',
                              onTap: () {
                                setState(() {
                                  _selectedImages.clear();
                                  _selectedImageIndex = 0;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Vertical lines
            Positioned(
              left: constraints.maxWidth / 3,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white30),
            ),
            Positioned(
              left: 2 * constraints.maxWidth / 3,
              top: 0,
              bottom: 0,
              child: Container(width: 1, color: Colors.white30),
            ),
            // Horizontal lines
            Positioned(
              top: constraints.maxHeight / 3,
              left: 0,
              right: 0,
              child: Container(height: 1, color: Colors.white30),
            ),
            Positioned(
              top: 2 * constraints.maxHeight / 3,
              left: 0,
              right: 0,
              child: Container(height: 1, color: Colors.white30),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectedImagesPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            'Selected ${_selectedImages.length}/$_maxSelectedImages images',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final bool isSelected = index == _selectedImageIndex;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedImageIndex = index;
                  });
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF5ED3F2) : Colors.white24,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: Image.file(
                    _selectedImages[index],
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 5,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0B2239),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white10),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
