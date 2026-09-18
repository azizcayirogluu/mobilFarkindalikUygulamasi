import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart';

class ReportService {
  Future<void> sistemRaporuOlustur() async {
    try {
      final pdf = pw.Document();
      pdf.addPage(pw.MultiPage(build: (context) => [pw.Text("SISTEM OZETI")]));
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint("PDF Rapor hatası: $e");
    }
  }
}
