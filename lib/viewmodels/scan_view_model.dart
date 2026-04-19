import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/utils/app_logger.dart';
import '../services/receipt_service.dart';

class ScanViewModel extends ChangeNotifier {
  ScanViewModel({ReceiptService? receiptService})
    : _service = receiptService ?? ReceiptService();

  final ReceiptService _service;

  File? selectedImage;
  bool isProcessing = false;
  String? errorMessage;
  String? lastTripId;

  bool get canSubmit => selectedImage != null && !isProcessing;

  Future<void> pickImage(ImageSource source) async {
    try {
      AppLogger.info('ScanViewModel.pickImage -> ${source.name}');
      errorMessage = null;
      notifyListeners();
      final result = await _service.pickAndCropReceipt(source);
      if (result != null) {
        selectedImage = result;
        AppLogger.info('Scan image selected successfully');
      } else {
        AppLogger.warn('No image selected/cropped');
      }
      notifyListeners();
    } catch (e, st) {
      AppLogger.error('Scan image picking failed', e, st);
      errorMessage = 'Could not pick image: $e';
      notifyListeners();
    }
  }

  void clear() {
    AppLogger.info('ScanViewModel clear called');
    selectedImage = null;
    errorMessage = null;
    lastTripId = null;
    notifyListeners();
  }

  Future<String?> uploadAndAnalyze() async {
    final image = selectedImage;
    if (image == null) {
      AppLogger.warn('Upload requested with no image selected');
      return null;
    }
    try {
      AppLogger.info('Scan uploadAndAnalyze started');
      isProcessing = true;
      errorMessage = null;
      notifyListeners();
      final id = await _service.uploadAndAnalyze(image);
      lastTripId = id;
      AppLogger.info('Scan upload returned tripId: $id');
      return id;
    } catch (e, st) {
      AppLogger.error('Upload and analyze failed', e, st);
      errorMessage = 'Upload failed: $e';
      return null;
    } finally {
      isProcessing = false;
      notifyListeners();
    }
  }
}
