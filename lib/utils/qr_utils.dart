import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrUtils {
  // Genera un ID sicuro per il QR code utilizzando un hash
  static String generateSecureQrId(String studentId, String salt) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dataToHash = '$studentId:$timestamp:$salt';
    final bytes = utf8.encode(dataToHash);
    final digest = sha256.convert(bytes);
    return 'stu_${digest.toString().substring(0, 12)}';
  }

  // Genera un salt random
  static String generateRandomSalt() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  // Crea un widget QR
  static Widget createQrWidget(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      backgroundColor: Colors.white,
      padding: const EdgeInsets.all(10),
      embeddedImage: const AssetImage('assets/logo.png'),
      embeddedImageStyle: const QrEmbeddedImageStyle(
        size: Size(40, 40),
      ),
    );
  }

  // Genera dati per il PDF della card
  static Map<String, dynamic> generateCardData(
      String studentId,
      String firstName,
      String lastName,
      String className,
      String school,
      String qrCodeId,
      ) {
    return {
      'studentId': studentId,
      'firstName': firstName,
      'lastName': lastName,
      'className': className,
      'school': school,
      'qrCodeId': qrCodeId,
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}