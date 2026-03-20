import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/seat_provider.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import '../../../../shared/widgets/checkout_progress_indicator.dart';
import 'package:intl/intl.dart';

class PassengerDetailsPage extends ConsumerStatefulWidget {
  final String scheduleId;
  final List<String> seatIds;

  const PassengerDetailsPage({super.key, required this.scheduleId, required this.seatIds});

  @override
  ConsumerState<PassengerDetailsPage> createState() => _PassengerDetailsPageState();
}

class _PassengerDetailsPageState extends ConsumerState<PassengerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final tripState = ref.watch(tripProvider);
    if (tripState.schedules.isEmpty) {
      return const Scaffold(
        appBar: GlobalTopNavBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final schedule = tripState.schedules.firstWhere(
      (s) => s.id == widget.scheduleId,
      orElse: () => tripState.schedules.first,
    );
    final seatState = ref.watch(seatProvider(widget.scheduleId));
    
    // Calculate price
    int subtotal = 0;
    for (String id in widget.seatIds) {
      final seatIndex = seatState.seats.indexWhere((s) => s.id == id);
      if (seatIndex != -1) {
        final int row = seatIndex ~/ 4;
        if (row < 2) subtotal += 1500;
        else if (row < 4) subtotal += 1000;
        else subtotal += 800;
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlobalTopNavBar(),
      body: Column(
        children: [
          const CheckoutProgressIndicator(currentStep: 2),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 900;
                
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 40, 
                    vertical: 24,
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPassengerForm(subtotal),
                                const SizedBox(height: 32),
                                _buildSummaryCard(schedule, subtotal, seatState),
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Section: Form
                                Expanded(
                                  flex: 3,
                                  child: _buildPassengerForm(subtotal),
                                ),
                                const SizedBox(width: 48),
                                // Right Section: Summary
                                Expanded(
                                  flex: 2,
                                  child: _buildSummaryCard(schedule, subtotal, seatState),
                                ),
                              ],
                            ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerForm(int subtotal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Passenger Information',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const Text(
          'Please enter the details for the person traveling.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildFormField(
                  'Full Name as per ID', 
                  _nameController, 
                  Icons.person_outline, 
                  'Enter full name',
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          _buildFormField(
                            'Phone Number', 
                            _phoneController, 
                            Icons.phone_outlined, 
                            '+254...',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),
                          _buildFormField(
                            'ID / Passport Number', 
                            _idNumberController, 
                            Icons.badge_outlined, 
                            'Number...',
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            'Phone Number', 
                            _phoneController, 
                            Icons.phone_outlined, 
                            '+254...',
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _buildFormField(
                            'ID / Passport Number', 
                            _idNumberController, 
                            Icons.badge_outlined, 
                            'Number...',
                          ),
                        ),
                      ],
                    );
                  }
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 32),
                const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ensure details match your identification document for a smooth boarding process.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                context.push(
                  Uri(
                    path: '/payment',
                    queryParameters: {
                      'scheduleId': widget.scheduleId,
                      'seatIds': widget.seatIds.join(','),
                      'passengerName': _nameController.text,
                      'passengerPhone': _phoneController.text,
                      'totalAmount': subtotal.toString(),
                    },
                  ).toString(),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'CONTINUE TO PAYMENT',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.0),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, IconData icon, String hint, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: true,
            fillColor: AppColors.background.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.divider)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          validator: (v) => v!.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(dynamic schedule, int subtotal, SeatState seatState) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Booking Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.directions_bus, color: AppColors.accent),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(schedule.vehicle?['operator_name'] ?? 'Premium Operator', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('${schedule.route.origin} to ${schedule.route.destination}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Selected Seats', style: TextStyle(color: AppColors.textSecondary)),
              Text('${widget.seatIds.length} Seat(s)', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: widget.seatIds.map((id) {
              final seat = seatState.seats.isEmpty 
                  ? null 
                  : seatState.seats.firstWhere((s) => s.id == id, orElse: () => seatState.seats.first);
              final seatLabel = seat != null ? seat.seatNumber : id.substring(0, 4);
              return Chip(
                label: Text('Seat $seatLabel', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                backgroundColor: AppColors.background,
                side: BorderSide.none,
                padding: EdgeInsets.zero,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Fare', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                'KES ${NumberFormat('#,##0').format(subtotal)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => context.pop(),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppColors.divider),
            ),
            child: const Text('Change Seats', style: TextStyle(color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

