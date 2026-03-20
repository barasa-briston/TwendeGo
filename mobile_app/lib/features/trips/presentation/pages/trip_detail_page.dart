import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/trip_provider.dart';
import '../../../booking/presentation/providers/seat_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import '../../../../shared/widgets/checkout_progress_indicator.dart';
import 'package:intl/intl.dart';

class TripDetailPage extends ConsumerWidget {
  final String scheduleId;
  final int passengers;

  const TripDetailPage({super.key, required this.scheduleId, this.passengers = 1});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripState = ref.watch(tripProvider);
    if (tripState.schedules.isEmpty) {
      return const Scaffold(
        appBar: GlobalTopNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final schedule = tripState.schedules.firstWhere(
      (s) => s.id == scheduleId,
      orElse: () => tripState.schedules.first,
    );
    final seatState = ref.watch(seatProvider(scheduleId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlobalTopNavBar(),
      body: seatState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const CheckoutProgressIndicator(currentStep: 1),
                Expanded(
                  child: _buildResponsiveContent(context, ref, schedule, seatState),
                ),
              ],
            ),
    );
  }

  Widget _buildSeatMapSection(BuildContext context, WidgetRef ref, dynamic schedule, SeatState state, {bool isMobile = false}) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSeatLegend(),
          const Divider(height: 1),
          if (isMobile)
            Padding(
              padding: const EdgeInsets.all(20),
              child: _buildSeatGrid(context, ref, schedule, state, isMobile: true),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: _buildSeatGrid(context, ref, schedule, state),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSeatGrid(BuildContext context, WidgetRef ref, dynamic schedule, SeatState state, {bool isMobile = false}) {
    return Center(
      child: Container(
        width: isMobile ? double.infinity : 400,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Front of bus (Driver)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.sports_motorsports_outlined, size: 40, color: AppColors.textSecondary.withOpacity(0.5)),
              ],
            ),
            const SizedBox(height: 40),
            // Seat Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
              ),
              itemCount: state.seats.length + (state.seats.length ~/ 4),
              itemBuilder: (context, index) {
                if (index % 5 == 2) return const SizedBox.shrink(); // Aisle

                final seatIndex = index - (index ~/ 5);
                if (seatIndex >= state.seats.length) return const SizedBox.shrink();

                final seat = state.seats[seatIndex];
                final isSelected = state.selectedSeatIds.contains(seat.id);
                final notifier = ref.read(seatProvider(scheduleId).notifier);

                return InkWell(
                  onTap: seat.isAvailable ? () => notifier.toggleSeat(seat.id, maxSeats: passengers) : null,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: !seat.isAvailable
                          ? AppColors.divider
                          : isSelected
                              ? AppColors.primary
                              : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !seat.isAvailable
                            ? AppColors.divider
                            : isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        seat.seatNumber,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isMobile ? 14 : 16,
                          color: !seat.isAvailable
                              ? AppColors.textSecondary
                              : isSelected
                                  ? Colors.black
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeatLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _legendDot(Colors.green, 'Business: KES 1,000'),
              const SizedBox(width: 24),
              _legendDot(Colors.blue, 'Normal: KES 800'),
              const SizedBox(width: 24),
              _legendDot(AppColors.primary, 'VIP: KES 1,500'),
            ],
          ),
          Row(
            children: [
              _legendBox(Colors.white, 'Available Seat', AppColors.textPrimary.withOpacity(0.3)),
              const SizedBox(width: 24),
              _legendBox(AppColors.primary, 'Selected seats', AppColors.primary),
              const SizedBox(width: 24),
              _legendBox(AppColors.divider, 'Booked seats', AppColors.divider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _legendBox(Color color, String label, Color border) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: border, width: 2)),
          child: const Center(child: Text('S', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black45))),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildSummaryPanel(BuildContext context, dynamic schedule, SeatState state) {
    final subtotal = schedule.fare * state.selectedSeatIds.length;
    
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trip Interface', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Booking Summary', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: -1.0)),
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryDropdown('Pick Point', '${schedule.route.origin} CBD Terminal', Icons.location_on_outlined),
                const SizedBox(height: 24),
                _buildSummaryDropdown('Drop Point', '${schedule.route.destination} Main Stage', Icons.flag_outlined),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 24),
                const Text('Selected Seats', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                Text(
                  state.selectedSeatIds.isEmpty ? 'None selected' : '${state.selectedSeatIds.length} of $passengers Seat(s)',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (state.selectedSeatIds.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.selectedSeatIds.map((id) {
                      final seat = state.seats.firstWhere((s) => s.id == id);
                      return Chip(
                        label: Text(seat.seatNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        side: const BorderSide(color: AppColors.primary),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 40),
          
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black, // Dark mode checkout area
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Fare', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text('KES ${NumberFormat('#,##0').format(subtotal)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.selectedSeatIds.length == passengers
                        ? () => context.push('/passenger-details/${schedule.id}?seats=${state.selectedSeatIds.join(",")}')
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      state.selectedSeatIds.length == passengers ? 'CONTINUE TO DETAILS' : 'PLEASE SELECT SEATS',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent(BuildContext context, WidgetRef ref, dynamic schedule, SeatState state) {
    final bool isDesktop = MediaQuery.of(context).size.width > 800;
    
    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Interactive Seat Map
          Expanded(
            flex: 3,
            child: _buildSeatMapSection(context, ref, schedule, state),
          ),
          // Right Side: Checkout Summary Panel
          Container(width: 1, color: AppColors.divider),
          Expanded(
            flex: 2,
            child: _buildSummaryPanel(context, schedule, state),
          ),
        ],
      );
    }

    // Mobile Layout fallback
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSummaryPanel(context, schedule, state),
          _buildSeatMapSection(context, ref, schedule, state, isMobile: true),
        ],
      ),
    );
  }

  Widget _buildSummaryDropdown(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.textSecondary),
              const SizedBox(width: 12),
              Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold))),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.textSecondary),
            ],
          ),
        ),
      ],
    );
  }
}

