import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../core/theme/app_theme.dart';
import '../core/utils/app_logger.dart';

/// Encapsulates picking, cropping and (eventually) uploading receipts.
class ReceiptService {
  ReceiptService({ImagePicker? picker, ImageCropper? cropper, Uuid? uuid})
    : _picker = picker ?? ImagePicker(),
      _cropper = cropper ?? ImageCropper(),
      _uuid = uuid ?? const Uuid();

  final ImagePicker _picker;
  final ImageCropper _cropper;
  final Uuid _uuid;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<File?> pickAndCropReceipt(ImageSource source) async {
    AppLogger.info('Opening image picker (${source.name})');
    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );
    if (picked == null) {
      AppLogger.warn('Image picking cancelled by user');
      return null;
    }
    AppLogger.info('Image picked: ${picked.path}');
    final cropped = await _cropper.cropImage(
      sourcePath: picked.path,
      compressFormat: ImageCompressFormat.jpg,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Receipt',
          toolbarColor: AppTheme.deepGreen,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop Receipt'),
      ],
    );
    if (cropped == null) {
      AppLogger.warn('Image crop cancelled by user');
      return null;
    }
    AppLogger.info('Image cropped: ${cropped.path}');
    return File(cropped.path);
  }

  /// Creates trip doc first, then uploads image to Storage.
  /// Backend trigger should OCR/parse/classify and update this trip doc.
  Future<String> uploadAndAnalyze(File imageFile) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw Exception('Please sign in before uploading a receipt.');
    }

    final tripId = 'trip-${_uuid.v4()}';
    final storagePath = 'receipts/$uid/$tripId.jpg';
    final tripDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('trips')
        .doc(tripId);

    // Seed trip doc first to avoid processReceipt NOT_FOUND race.
    final preUploadPayload = {
      'tripId': tripId,
      'uid': uid,
      'status': 'uploading',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    AppLogger.data('Trip pre-upload payload', preUploadPayload);
    await tripDoc.set(preUploadPayload, SetOptions(merge: true));
    AppLogger.info('Trip seeded before upload: users/$uid/trips/$tripId');

    AppLogger.info('Uploading receipt image: $storagePath');

    try {
      final storageRef = _storage.ref(storagePath);
      final uploadTask = await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      AppLogger.info(
        'Storage upload complete bytes=${uploadTask.totalBytes} path=$storagePath',
      );
      final receiptUrl = await storageRef.getDownloadURL();
      AppLogger.info('Storage download URL generated');

      final payload = {
        'status': 'processing',
        'receiptPath': storagePath,
        'receiptUrl': receiptUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      AppLogger.data('Trip pending payload', payload);
      await tripDoc.set(payload, SetOptions(merge: true));
    } catch (error, stackTrace) {
      AppLogger.error('Receipt upload failed', error, stackTrace);
      await tripDoc.set({
        'status': 'failed_upload',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      rethrow;
    }

    AppLogger.info('Trip created as processing: users/$uid/trips/$tripId');
    return tripId;
  }
}
