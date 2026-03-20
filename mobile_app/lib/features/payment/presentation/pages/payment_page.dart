import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../booking/presentation/providers/seat_provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../trips/presentation/providers/trip_provider.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import '../../../../shared/widgets/checkout_progress_indicator.dart';
import 'package:intl/intl.dart';

class PaymentPage extends ConsumerStatefulWidget {
  final Map<String, String> data;

  const PaymentPage({super.key, required this.data});

  @override
  ConsumerState<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends ConsumerState<PaymentPage> {
  bool _isLoading = false;
  final TextEditingController _transactionCodeController = TextEditingController();
  final _api = ApiClient();

  Future<void> _initiatePayment() async {
    if (_transactionCodeController.text.isEmpty) {
      // Validate before STK push
    }
    setState(() => _isLoading = true);
    try {
      final bookingRes = await _api.dio.post(ApiEndpoints.bookings, data: {
        'schedule': widget.data['scheduleId'],
        'seats': widget.data['seatIds']?.split(','),
        'passenger_name': widget.data['passengerName'],
        'passenger_phone': widget.data['passengerPhone'],
        'amount': widget.data['totalAmount'],
        if (_transactionCodeController.text.isNotEmpty) 'transaction_code': _transactionCodeController.text,
      });
      
      final bookingId = bookingRes.data['id'];
      
      if (_transactionCodeController.text.isNotEmpty) {
        if (mounted) {
          _showSuccessDialog(
            'Code Submitted ✅',
            'Your M-Pesa code "${_transactionCodeController.text}" has been recorded. An admin will verify and confirm your booking shortly. You can track your booking under "My Bookings".',
            bookingId: bookingId,
          );
        }
        return;
      }
      
      await _api.dio.post(ApiEndpoints.stkPush, data: {
        'booking_id': bookingId,
        'phone_number': widget.data['passengerPhone']?.replaceAll('+', ''),
      });
      
      if (mounted) {
        _showSuccessDialog(
          'Payment Initiated', 
          'Please check your phone for the M-Pesa STK Push prompt and enter your PIN.',
          bookingId: bookingId,
        );
      }
    } on DioException catch (e) {
      String errorMessage = 'Payment failed. Please try again.';
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map) {
          // Extract the first field error from the response
          final firstError = data.values.first;
          if (firstError is List && firstError.isNotEmpty) {
            errorMessage = firstError.first.toString();
          } else if (firstError is String) {
            errorMessage = firstError;
          } else {
            errorMessage = 'Server error (${e.response!.statusCode}). Please try again.';
          }
        } else if (data is String) {
          errorMessage = data;
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An unexpected error occurred: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String title, String message, {String? bookingId}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
        content: Text(message),
        actions: [
          if (bookingId != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/ticket/$bookingId');
              },
              child: const Text('VIEW TICKET', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
            child: const Text('GO HOME'),
          ),
        ],
      ),
    );
  }

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
      (s) => s.id == widget.data['scheduleId'],
      orElse: () => tripState.schedules.first,
    );
    final int subtotal = int.tryParse(widget.data['totalAmount'] ?? '0') ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 1000;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const GlobalTopNavBar(),
          body: Column(
            children: [
              CheckoutProgressIndicator(currentStep: 3),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40, vertical: 24),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: isMobile 
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFinalSummary(schedule, subtotal),
                              const SizedBox(height: 32),
                              _buildPaymentOptions(),
                            ],
                          )
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: _buildPaymentOptions()),
                              const SizedBox(width: 48),
                              Expanded(flex: 2, child: _buildFinalSummary(schedule, subtotal)),
                            ],
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Methods',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
        ),
        const Text(
          'Securely pay for your seat via M-Pesa.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32),
        
        // Option 1: STK Push Card
        _buildPaymentCard(
          type: 'Automatic M-Pesa STK Push',
          description: 'Receive a prompt directly on your phone to enter your PIN.',
          child: ElevatedButton(
            onPressed: _isLoading ? null : _initiatePayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('SEND M-PESA STK PUSH', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Option 2: Manual Code
        _buildPaymentCard(
          type: 'Manual Transaction Code',
          description: 'If you paid via Till/Paybill manually, enter the transaction code here.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _transactionCodeController,
                decoration: InputDecoration(
                  hintText: 'e.g. QFE2XZ9Y1',
                  prefixIcon: const Icon(Icons.receipt_long, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.background.withOpacity(0.5),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.divider)),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('SUBMIT CODE', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentCard({String? logoUrl, required String type, required String description, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (type.contains('M-Pesa')) 
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                   decoration: BoxDecoration(color: const Color(0xFF4CAF50), borderRadius: BorderRadius.circular(4)),
                   child: const Text('M-PESA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                 ),
              const SizedBox(width: 12),
              Text(type, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildFinalSummary(dynamic schedule, int subtotal) {
    final seatState = ref.watch(seatProvider(widget.data['scheduleId']!));
    final seatIds = widget.data['seatIds']?.split(',') ?? [];
    final seatLabels = seatIds.map((id) {
      if (seatState.seats.isEmpty) return id.substring(0, 4);
      final seat = seatState.seats.firstWhere((s) => s.id == id, orElse: () => seatState.seats.first);
      return seat.seatNumber;
    }).join(', ');

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
          const Text('Final Summary', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          const SizedBox(height: 24),
          _summaryLine('Passenger', widget.data['passengerName'] ?? ''),
          _summaryLine('Phone', widget.data['passengerPhone'] ?? ''),
          const Divider(height: 32),
          _summaryLine('Bus', schedule.vehicle?['operator_name'] ?? 'Premium'),
          _summaryLine('Seats', seatLabels),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Total to Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
              Text(
                'KES ${NumberFormat('#,##0').format(subtotal)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF4CAF50)),
              ),
            ],
          ),
          const SizedBox(height: 32),
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: Colors.green),
              SizedBox(width: 8),
              Text('Security encrypted payment', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}

