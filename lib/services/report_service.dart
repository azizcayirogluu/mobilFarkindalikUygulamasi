import 'package:cloud_functions/cloud_functions.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class ReportService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');


  // PDF ve Diğer servisler korunuyor...
  Future<void> sistemRaporuOlustur() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(build: (context) => [pw.Text("SISTEM OZETI")]));
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
    } catch (e) { debugPrint("PDF Rapor hatası: $e"); }
  }

  Future<bool> olayBildir({required String baslik, required String detay, required String konum}) async {
    try {
      await _functions.httpsCallable('submitReport').call({'baslik': baslik, 'detay': detay, 'konum': konum});
      return true;
    } catch (e) { return false; }
  }
}
