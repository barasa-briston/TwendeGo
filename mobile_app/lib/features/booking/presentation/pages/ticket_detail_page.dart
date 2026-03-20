import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/booking_model.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/ticket_pdf_service.dart';

class TicketDetailPage extends ConsumerWidget {
  final String bookingId;

  const TicketDetailPage({super.key, required this.bookingId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);
    
    if (bookingState.isLoading) {
      return const Scaffold(
        appBar: GlobalTopNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final booking = bookingState.bookings.cast<BookingModel?>().firstWhere(
      (b) => b?.id == bookingId, 
      orElse: () => null
    );

    if (booking == null) {
      return Scaffold(
        appBar: const GlobalTopNavBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Booking not found.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      );
    }
    final isWide = MediaQuery.of(context).size.width > 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F5),
      appBar: const GlobalTopNavBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              children: [
                _buildETicketCard(context, booking, isWide),
                const SizedBox(height: 24),
                _buildActionButtons(context, booking),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildETicketCard(BuildContext context, BookingModel booking, bool isWide) {
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gold Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: const BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: isWide 
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _headerColumn('COMPANY', 'TWENDEGO EXPRESS'),
                    const SizedBox(width: 40),
                    _headerColumn('SOURCE', origin),
                    const Spacer(),
                    _headerColumn('DESTINATION', destination, align: CrossAxisAlignment.end),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headerColumn('COMPANY', 'TWENDEGO EXPRESS'),
                        const Icon(Icons.directions_bus, size: 24, color: Colors.black),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _headerColumn('SOURCE', origin),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                        _headerColumn('DESTINATION', destination, align: CrossAxisAlignment.end),
                      ],
                    ),
                  ],
                ),
          ),

          // Main Body
          Padding(
            padding: const EdgeInsets.all(28),
            child: isWide
                ? _buildWideBody(bookingRef, seatNum, passengerName, timeStr, dateStr, journey, qrData)
                : _buildNarrowBody(bookingRef, seatNum, passengerName, timeStr, dateStr, journey, qrData),
          ),

          // Dashed separator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: List.generate(60, (i) => Expanded(
                child: Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: i.isOdd ? Colors.transparent : const Color(0xFFDDDDDD),
                ),
              )),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo placeholder
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.directions_bus, color: AppColors.primary, size: 22),
                      const SizedBox(width: 6),
                      const Text('TwendeGo', style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.5,
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    '*Be present before 30 minutes of departure time at boarding point\n-Powered By TwendeGo-',
                    style: TextStyle(fontSize: 11, color: Color(0xFF888888)),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBody(String bookingRef, String seatNum, String passengerName,
      String timeStr, String dateStr, String journey, String qrData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left column – Booking Ref & Seat
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailBlock('BOOKING REF:', bookingRef, large: true),
            const SizedBox(height: 24),
            _detailBlock('TICKET NO:', 'TWG${bookingRef.substring(0, 9)}'),
            const SizedBox(height: 24),
            _detailBlock('SEAT NO', seatNum, large: true, seatStyle: true),
          ],
        ),
        const SizedBox(width: 48),
        // Middle column – Passenger & Departure
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailBlock('PASSENGER', passengerName),
              const SizedBox(height: 24),
              _detailBlock('DEPARTURE', '$timeStr\n$dateStr', large: true, isMultiLine: true),
              const SizedBox(height: 24),
              _detailBlock('JOURNEY:', journey),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right column – QR Code
        QrImageView(
          data: qrData,
          version: QrVersions.auto,
          size: 140,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildNarrowBody(String bookingRef, String seatNum, String passengerName,
      String timeStr, String dateStr, String journey, String qrData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 140,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        _detailBlock('BOOKING REF:', bookingRef, large: true),
        const SizedBox(height: 16),
        _detailBlock('TICKET NO:', 'TWG${bookingRef.substring(0, 9)}'),
        const SizedBox(height: 16),
        _detailBlock('PASSENGER', passengerName),
        const SizedBox(height: 16),
        _detailBlock('DEPARTURE', '$timeStr\n$dateStr', large: true, isMultiLine: true),
        const SizedBox(height: 16),
        _detailBlock('SEAT NO', seatNum, large: true, seatStyle: true),
        const SizedBox(height: 16),
        _detailBlock('JOURNEY:', journey),
      ],
    );
  }

  Widget _headerColumn(String label, String value, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label, style: const TextStyle(
          color: Colors.black,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        )),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        )),
      ],
    );
  }

  Widget _detailBlock(String label, String value, {bool large = false, bool seatStyle = false, bool isMultiLine = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(
          color: Color(0xFF888888),
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        )),
        const SizedBox(height: 4),
        if (isMultiLine)
          ...value.split('\n').asMap().entries.map((entry) => Text(
            entry.value,
            style: TextStyle(
              fontSize: entry.key == 0 ? 26 : 14,
              fontWeight: entry.key == 0 ? FontWeight.w900 : FontWeight.w600,
              color: Colors.black87,
              height: 1.2,
            ),
          ))
        else
          Text(
            value,
            style: TextStyle(
              fontSize: seatStyle ? 40 : (large ? 18 : 14),
              fontWeight: FontWeight.w900,
              color: seatStyle ? const Color(0xFF5B2D8E) : Colors.black87,
              letterSpacing: seatStyle ? -1.0 : 0.3,
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, BookingModel booking) {
    final bool isSmall = MediaQuery.of(context).size.width < 500;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 0 : 20),
      child: isSmall 
        ? Column(
            children: [
              _downloadButton(booking),
              const SizedBox(height: 12),
              _copyButton(context, booking),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _copyButton(context, booking),
              const SizedBox(width: 16),
              _downloadButton(booking),
            ],
          ),
    );
  }

  Widget _copyButton(BuildContext context, BookingModel booking) {
    return OutlinedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Copying booking reference...'), backgroundColor: AppColors.primary),
        );
        Clipboard.setData(ClipboardData(text: booking.bookingReference));
      },
      icon: const Icon(Icons.copy),
      label: const Text('Copy Ref'),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF5B2D8E),
        side: const BorderSide(color: Color(0xFF5B2D8E)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(160, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _downloadButton(BookingModel booking) {
    return ElevatedButton.icon(
      onPressed: () => TicketPdfService.generateAndPrintTicket(booking),
      icon: const Icon(Icons.download_outlined),
      label: const Text('Download Ticket'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF5B2D8E),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        minimumSize: const Size(180, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
