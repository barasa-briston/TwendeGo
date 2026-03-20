import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends ConsumerWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingState = ref.watch(bookingProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: bookingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingState.error != null
              ? Center(child: Text(bookingState.error!))
              : bookingState.bookings.isEmpty
                  ? const Center(child: Text('You have no bookings yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: bookingState.bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookingState.bookings[index];
                        return _BookingCard(booking: booking);
                      },
                    ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final dynamic booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.status == 'CONFIRMED' ? AppColors.success : AppColors.warning;
    final isBus = booking.schedule.vehicle?['vehicle_type']?.toLowerCase().contains('bus') ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, 8),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push('/ticket/${booking.id}'),
          child: Column(
            children: [
              // TOP HALF: Route and Status
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(isBus ? Icons.directions_bus : Icons.airport_shuttle, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    booking.schedule.route.origin.split(',')[0],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8),
                                    child: Icon(Icons.arrow_forward_rounded, size: 16),
                                  ),
                                  Text(
                                    booking.schedule.route.destination.split(',')[0],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                booking.schedule.vehicle?['operator_name'] ?? 'Premium Shuttle',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        // Avatar Placeholder
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.divider,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Status Pill
                    Row(
                      children: [
                        const Text('Status: ', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            booking.status,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // TICKET DIVIDER (Dashed Line Simulator)
              Stack(
                children: [
                  Container(
                    height: 1,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 2, style: BorderStyle.none))),
                    // Note: True dashed line requires custom painter. Using standard divider for now.
                    child: const Divider(thickness: 1, height: 1),
                  ),
                  Positioned(
                    left: -10, top: -10,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle)),
                  ),
                  Positioned(
                    right: -10, top: -10,
                    child: Container(width: 20, height: 20, decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle)),
                  ),
                ],
              ),

              // BOTTOM HALF: Passenger details and QR
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailPair('Passenger', booking.passengerName),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _detailPair('Seat', booking.formattedSeats)),
                              Expanded(child: _detailPair('Time', DateFormat('HH:mm').format(booking.schedule.departureDatetime))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _detailPair('Date', DateFormat('dd MMM yyyy').format(booking.schedule.departureDatetime)),
                          const SizedBox(height: 12),
                          _detailPair('Price', 'KES ${NumberFormat("#,##0").format(booking.amount)}'),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // QR Code Mockup
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 2), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.qr_code_2, size: 70, color: Colors.black),
                          ),
                          const SizedBox(height: 8),
                          const Text('Boarding', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/ticket/${booking.id}'),
                    icon: const Icon(Icons.confirmation_num_outlined, size: 18),
                    label: const Text(
                      'Click here to get your ticket',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailPair(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }
}
