import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:mensa_scolastica/models/student.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class QrGenerator {
  // Genera un ID sicuro per il QR code
  static String generateSecureQrId(String studentId, String salt) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final dataToHash = '$studentId:$timestamp:$salt';
    final bytes = utf8.encode(dataToHash);
    final digest = sha256.convert(bytes);
    return 'stu_${digest.toString().substring(0, 12)}';
  }

  // Widget per visualizzare un QR code con dati dello studente
  static Widget buildQrCardWidget(Student student, {double size = 200}) {
    final GlobalKey qrKey = GlobalKey();

    return RepaintBoundary(
      key: qrKey,
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${student.firstName} ${student.lastName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Classe ${student.className} - ${student.school}',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              QrImageView(
                data: student.qrCodeId,
                version: QrVersions.auto,
                size: size,
                backgroundColor: Colors.white,
                padding: const EdgeInsets.all(10),
                embeddedImage: const AssetImage('assets/logo.png'),
                embeddedImageStyle: const QrEmbeddedImageStyle(
                  size: Size(40, 40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${student.qrCodeId}',
                style: const TextStyle(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Cattura il widget QR come immagine
  static Future<Uint8List?> captureQrWidgetAsImage(GlobalKey qrKey) async {
    try {
      RenderRepaintBoundary boundary = qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  // Genera un PDF per un singolo studente
  static Future<Uint8List> generateStudentQrPdf(Student student) async {
    final pdf = pw.Document();

    // Carica il logo (se esiste)
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Logo non trovato, continua senza
    }

    // Genera il QR code per il PDF
    final qrImage = await QrPainter(
      data: student.qrCodeId,
      version: QrVersions.auto,
      color: const Color(0xFF000000),
      emptyColor: const Color(0xFFFFFFFF),
      gapless: true,
    ).toImageData(200);

    // Aggiungi la pagina al PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                if (logoImage != null)
                  pw.Container(
                    height: 60,
                    child: pw.Image(logoImage),
                  ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Carta Mensa Scolastica',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${student.firstName} ${student.lastName}',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Classe ${student.className} - ${student.school}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  width: 220,
                  height: 220,
                  child: pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'ID: ${student.qrCodeId}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(width: 1, color: PdfColors.black),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Text(
                    'Questa carta è personale e deve essere conservata con cura.\nPresentala ogni giorno per registrare il pasto.',
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  // Genera un PDF per più studenti (max 4 per pagina)
  static Future<Uint8List> generateMultipleStudentQrPdf(List<Student> students) async {
    final pdf = pw.Document();

    // Carica il logo (se esiste)
    pw.MemoryImage? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      // Logo non trovato, continua senza
    }

    // Processa gli studenti in gruppi di 4
    for (var i = 0; i < students.length; i += 4) {
      final pageStudents = students.skip(i).take(4).toList();

      final List<pw.Widget> qrCodes = [];

      for (var student in pageStudents) {
        // Genera il QR code
        final qrImage = await QrPainter(
          data: student.qrCodeId,
          version: QrVersions.auto,
          color: const Color(0xFF000000),
          emptyColor: const Color(0xFFFFFFFF),
          gapless: true,
        ).toImageData(150);

        qrCodes.add(
          pw.Container(
            margin: const pw.EdgeInsets.all(10),
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5),
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  '${student.firstName} ${student.lastName}',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  'Classe ${student.className}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: 150,
                  height: 150,
                  child: pw.Image(pw.MemoryImage(qrImage!.buffer.asUint8List())),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'ID: ${student.qrCodeId}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
            ),
          ),
        );
      }

      // Crea la pagina con i QR code
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 40,
                        child: pw.Image(logoImage),
                      ),
                    pw.SizedBox(width: 10),
                    pw.Text(
                      'Carte Mensa Scolastica',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Generato il ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Expanded(
                  child: pw.Wrap(
                    children: qrCodes,
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // Stampa un PDF
  static Future<void> printPdf(Uint8List pdfBytes, String title) async {
    await Printing.layoutPdf(
      onLayout: (format) => pdfBytes,
      name: title,
    );
  }

  // Salva un PDF e lo condividi
  static Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Carta Mensa QR Code');
    } catch (e) {
      print('Errore durante la condivisione: $e');
    }
  }
}