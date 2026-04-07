import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class InvoicePdfService {
  /// Generates and returns a PDF [Uint8List] from SAP invoice details.
  static Future<Uint8List> generateInvoicePdf(
      Map<String, dynamic> details) async {
    // Load Unicode-capable fonts (fixes "Helvetica has no Unicode support")
    final regular = await PdfGoogleFonts.nunitoRegular();
    final bold = await PdfGoogleFonts.nunitoBold();
    final italic = await PdfGoogleFonts.nunitoItalic();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(
        base: regular,
        bold: bold,
        italic: italic,
      ),
    );

    final lines =
        (details['DocumentLines'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final currency = details['DocCurrency'] ?? 'KSh';
    final docNum = details['DocNum']?.toString() ?? '';
    final cardCode = details['CardCode'] ?? '';
    final cardName = details['CardName'] ?? '';
    final docTotal = details['DocTotal'];
    final docDate = details['DocDate']?.toString() ?? '';
    final vatSum = details['VatSum'];

    // Format date nicely if possible
    String formattedDate = docDate;
    try {
      final parsed = DateTime.parse(docDate.split('T').first);
      formattedDate = DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {}

    final currencyFmt = NumberFormat('#,##0.00');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'KFL KIOSK',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1a237e),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Powered by SAP Business One',
                        style: pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'TAX INVOICE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: const PdfColor.fromInt(0xFF1a237e),
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Invoice #$docNum',
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Date: $formattedDate',
                        style: pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1.5, color: const PdfColor.fromInt(0xFF1a237e)),
              pw.SizedBox(height: 12),

              // ── Bill To ────────────────────────────────────────────────
              pw.Text(
                'BILL TO',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                cardName,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Customer Code: $cardCode',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),

              pw.SizedBox(height: 20),

              // ── Line Items Table ───────────────────────────────────────
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FixedColumnWidth(60),
                  2: const pw.FixedColumnWidth(80),
                  3: const pw.FixedColumnWidth(90),
                },
                children: [
                  // Table header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1a237e),
                    ),
                    children: [
                      _headerCell('Description'),
                      _headerCell('Qty', align: pw.TextAlign.center),
                      _headerCell('Unit Price', align: pw.TextAlign.right),
                      _headerCell('Total', align: pw.TextAlign.right),
                    ],
                  ),
                  // Data rows
                  ...lines.asMap().entries.map((entry) {
                    final i = entry.key;
                    final line = entry.value;
                    final qty = (line['Quantity'] as num?)?.toDouble() ?? 0;
                    final price = (line['Price'] as num?)?.toDouble() ?? 0;
                    final lineTotal = qty * price;
                    final bg = i.isOdd ? PdfColors.grey100 : PdfColors.white;

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        _dataCell(
                          line['ItemDescription'] ?? line['ItemCode'] ?? '-',
                          subText: line['ItemCode'],
                        ),
                        _dataCell('${qty.toInt()}',
                            align: pw.TextAlign.center),
                        _dataCell(currencyFmt.format(price),
                            align: pw.TextAlign.right),
                        _dataCell(currencyFmt.format(lineTotal),
                            align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),

              pw.SizedBox(height: 12),

              // ── Totals ─────────────────────────────────────────────────
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Container(
                  width: 230,
                  child: pw.Column(
                    children: [
                      if (vatSum != null) ...[
                        _summaryRow(
                          'VAT:',
                          '$currency ${currencyFmt.format((vatSum as num).toDouble())}',
                        ),
                        pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                      ],
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            vertical: 6, horizontal: 4),
                        decoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF1a237e),
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'TOTAL DUE:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 12,
                              ),
                            ),
                            pw.Text(
                              '$currency ${currencyFmt.format((docTotal as num?)?.toDouble() ?? 0)}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              pw.Spacer(),

              // ── Footer ─────────────────────────────────────────────────
              pw.Divider(thickness: 0.5, color: PdfColors.grey400),
              pw.SizedBox(height: 4),
              pw.Center(
                child: pw.Text(
                  'This is a computer-generated document. No signature required.',
                  style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  static pw.Widget _headerCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  static pw.Widget _dataCell(String text,
      {pw.TextAlign align = pw.TextAlign.left, String? subText}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Column(
        crossAxisAlignment: align == pw.TextAlign.right
            ? pw.CrossAxisAlignment.end
            : align == pw.TextAlign.center
                ? pw.CrossAxisAlignment.center
                : pw.CrossAxisAlignment.start,
        children: [
          pw.Text(text,
              textAlign: align,
              style: const pw.TextStyle(fontSize: 10)),
          if (subText != null && subText != text)
            pw.Text(
              subText,
              style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }

  static pw.Widget _summaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value,
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
        ],
      ),
    );
  }
}
