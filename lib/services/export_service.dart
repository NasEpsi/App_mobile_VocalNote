import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/note.dart';
import 'file_storage.dart';

/// Exports a [Note] to a nicely formatted PDF or TXT. PDF uses the
/// cross-platform `printing` share/print sheet; TXT uses [FileStorage]
/// (share on native, download on web).
class ExportService {
  final DateFormat _dateFormat = DateFormat('dd MMMM yyyy à HH:mm', 'fr_FR');
  final FileStorage _storage = FileStorage();

  static const int _brandColor = 0xFF6C8EF5;

  String _sanitize(String name) {
    final cleaned = name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    return cleaned.isEmpty ? 'note' : cleaned.replaceAll(RegExp(r'\s+'), '_');
  }

  String _safeDate(DateTime date) {
    try {
      return _dateFormat.format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  // --- TXT ---

  String _buildText(Note note, String folderName) {
    const line = '========================================';
    const thin = '----------------------------------------';
    final buffer = StringBuffer()
      ..writeln(line)
      ..writeln('  VOXNOTE')
      ..writeln('  ${note.title}')
      ..writeln(line)
      ..writeln('')
      ..writeln('Dossier : $folderName')
      ..writeln('Date    : ${_safeDate(note.createdAt)}')
      ..writeln('Durée   : ${note.formattedDuration}')
      ..writeln('')
      ..writeln(thin)
      ..writeln('TRANSCRIPTION')
      ..writeln(thin)
      ..writeln('')
      ..writeln(note.transcript.isEmpty
          ? '(Aucune transcription)'
          : note.transcript);
    return buffer.toString();
  }

  Future<void> exportAndShareTxt(Note note, {String? folderName}) async {
    await _storage.exportText(
      '${_sanitize(note.title)}.txt',
      _buildText(note, folderName ?? 'Aucun dossier'),
    );
  }

  // --- PDF ---

  Future<void> exportAndSharePdf(
    Note note, {
    String? folderName,
    int? folderColorValue,
  }) async {
    final accent = PdfColor.fromInt(folderColorValue ?? _brandColor);
    final folder = folderName ?? 'Aucun dossier';

    final fonts = await _loadFonts();
    final doc = pw.Document(
      theme: pw.ThemeData.withFont(
        base: fonts.regular,
        bold: fonts.bold,
        italic: fonts.italic,
      ),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.zero,
        footer: (context) => _footer(context, accent),
        build: (context) => [
          _banner(note, accent),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(40, 24, 40, 24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    _metaCard('DOSSIER', folder, accent, withDot: true),
                    pw.SizedBox(width: 12),
                    _metaCard('DATE', _safeDate(note.createdAt), accent),
                    pw.SizedBox(width: 12),
                    _metaCard('DURÉE', note.formattedDuration, accent),
                  ],
                ),
                pw.SizedBox(height: 24),
                _sectionTitle('Transcription', accent),
                pw.SizedBox(height: 10),
                pw.Text(
                  note.transcript.isEmpty
                      ? 'Aucune transcription'
                      : note.transcript,
                  textAlign: pw.TextAlign.justify,
                  style: pw.TextStyle(
                    fontSize: 11.5,
                    lineSpacing: 5,
                    color: PdfColor.fromInt(0xFF333947),
                    fontStyle: note.transcript.isEmpty
                        ? pw.FontStyle.italic
                        : pw.FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${_sanitize(note.title)}.pdf',
    );
  }

  pw.Widget _banner(Note note, PdfColor accent) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.fromLTRB(40, 36, 40, 32),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [accent, PdfColor.fromInt(0xFFB57BEE)],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                width: 18,
                height: 18,
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'VOXNOTE',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            note.title,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 26,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaCard(
    String label,
    String value,
    PdfColor accent, {
    bool withDot = false,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: pw.BoxDecoration(
          color: PdfColor.fromInt(0xFFF6F7FB),
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                letterSpacing: 1,
                color: PdfColor.fromInt(0xFF9AA0AE),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                if (withDot) ...[
                  pw.Container(
                    width: 8,
                    height: 8,
                    decoration: pw.BoxDecoration(
                      color: accent,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.SizedBox(width: 6),
                ],
                pw.Text(
                  value,
                  style: pw.TextStyle(
                    fontSize: 11,
                    color: PdfColor.fromInt(0xFF1F2330),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _sectionTitle(String title, PdfColor accent) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(width: 4, height: 16, color: accent),
        pw.SizedBox(width: 8),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF1F2330),
          ),
        ),
      ],
    );
  }

  pw.Widget _footer(pw.Context context, PdfColor accent) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(40, 0, 40, 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Généré avec Voxnote',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF9AA0AE),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromInt(0xFF9AA0AE),
            ),
          ),
        ],
      ),
    );
  }

  Future<_PdfFonts> _loadFonts() async {
    try {
      return _PdfFonts(
        regular: await PdfGoogleFonts.nunitoRegular(),
        bold: await PdfGoogleFonts.nunitoBold(),
        italic: await PdfGoogleFonts.nunitoItalic(),
      );
    } catch (_) {
      return _PdfFonts(
        regular: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
        italic: pw.Font.helveticaOblique(),
      );
    }
  }
}

class _PdfFonts {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;

  _PdfFonts({
    required this.regular,
    required this.bold,
    required this.italic,
  });
}
