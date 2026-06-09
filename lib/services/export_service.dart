import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/note.dart';
import 'file_storage.dart';

/// Exports a [Note] to PDF or TXT. PDF uses the cross-platform `printing`
/// share/print sheet; TXT uses [FileStorage] (share on native, download on web).
class ExportService {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  final FileStorage _storage = FileStorage();

  String _sanitize(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return cleaned.isEmpty ? 'note' : cleaned.replaceAll(RegExp(r'\s+'), '_');
  }

  String _buildText(Note note) {
    final buffer = StringBuffer()
      ..writeln(note.title)
      ..writeln('Catégorie: ${note.category.label}')
      ..writeln('Date: ${_dateFormat.format(note.createdAt)}')
      ..writeln('Durée: ${note.formattedDuration}')
      ..writeln('')
      ..writeln(note.transcript);
    return buffer.toString();
  }

  Future<void> exportAndShareTxt(Note note) async {
    await _storage.exportText('${_sanitize(note.title)}.txt', _buildText(note));
  }

  Future<void> exportAndSharePdf(Note note) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              note.title,
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              _meta('Catégorie', note.category.label),
              pw.SizedBox(width: 24),
              _meta('Date', _dateFormat.format(note.createdAt)),
              pw.SizedBox(width: 24),
              _meta('Durée', note.formattedDuration),
            ],
          ),
          pw.Divider(height: 32),
          pw.Text(
            note.transcript.isEmpty
                ? '(Aucune transcription)'
                : note.transcript,
            style: const pw.TextStyle(fontSize: 12, lineSpacing: 4),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${_sanitize(note.title)}.pdf',
    );
  }

  pw.Widget _meta(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }
}
