import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../shared/models/booking_model.dart';

class TicketPdfService {
  static Future<void> generateAndPrintTicket(BookingModel booking) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final departureDt = booking.schedule.departureDatetime;
    final timeStr = DateFormat('hh:mm a').format(departureDt).toUpperCase();
    final dateStr = DateFormat("d'TH' MMM yyyy").format(departureDt).toUpperCase();
    final origin = booking.schedule.route.origin.toUpperCase();
    final destination = booking.schedule.route.destination.toUpperCase();
    final passengerName = booking.passengerName;
    final bookingRef = booking.bookingReference.toUpperCase();
    final seatNum = booking.formattedSeats;
    final journey = '$origin - $destination EXPRESS';
    final qrData = '$bookingRef|$passengerName|$seatNum|${departureDt.toIso8601String()}';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Theme(
            data: pw.ThemeData.withFont(
              base: font,
              bold: boldFont,
            ),
            child: pw.Column(
              children: [
              // Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFD4AF37),
                  borderRadius: pw.BorderRadius.only(
                    topLeft: pw.Radius.circular(8),
                    topRight: pw.Radius.circular(8),
                  ),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _pdfHeaderColumn('COMPANY', 'TWENDEGO EXPRESS'),
                    _pdfHeaderColumn('SOURCE', origin),
                    _pdfHeaderColumn('DESTINATION', destination, align: pw.CrossAxisAlignment.end),
                  ],
                ),
              ),

              // Body
              pw.Container(
                padding: const pw.EdgeInsets.all(28),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfDetailBlock('BOOKING REF:', bookingRef, large: true),
                        pw.SizedBox(height: 24),
                        _pdfDetailBlock('TICKET NO:', 'TWG${bookingRef.substring(0, 9)}'),
                        pw.SizedBox(height: 24),
                        _pdfDetailBlock('SEAT NO', seatNum, large: true),
                      ],
                    ),
                    pw.SizedBox(width: 48),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _pdfDetailBlock('PASSENGER', passengerName),
                          pw.SizedBox(height: 24),
                          _pdfDetailBlock('DEPARTURE', '$timeStr\n$dateStr', large: true),
                          pw.SizedBox(height: 24),
                          _pdfDetailBlock('JOURNEY:', journey),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 32),
                    pw.BarcodeWidget(
                      data: qrData,
                      barcode: pw.Barcode.qrCode(),
                      width: 100,
                      height: 100,
                    ),
                  ],
                ),
              ),

              // Footer
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: pw.Row(
                  children: [
                    pw.Text('TwendeGo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColor.fromInt(0xFFD4AF37))),
                    pw.Spacer(),
                    pw.Text(
                      '*Be present before 30 minutes of departure time at boarding point\n-Powered By TwendeGo-',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
                      textAlign: pw.TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        },
      ),
    );

    try {
      final pdfBytes = await pdf.save();
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'Ticket_${booking.bookingReference}.pdf',
      );
    } catch (e) {
      print('PDF Generation Error: $e');
      // If layoutPdf fails, try sharePdf
      try {
        await Printing.sharePdf(
          bytes: await pdf.save(),
          filename: 'Ticket_${booking.bookingReference}.pdf',
        );
      } catch (shareErr) {
        print('PDF Share Error: $shareErr');
      }
    }
  }

  static pw.Widget _pdfHeaderColumn(String label, String value, {pw.CrossAxisAlignment align = pw.CrossAxisAlignment.start}) {
    return pw.Column(
      crossAxisAlignment: align,
      children: [
        pw.Text(label, style: const pw.TextStyle(color: PdfColors.black, fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(color: PdfColors.black, fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _pdfDetailBlock(String label, String value, {bool large = false}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: large ? 14 : 10, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
