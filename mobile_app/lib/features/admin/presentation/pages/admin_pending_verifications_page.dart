import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';

final _pendingBookingsProvider = FutureProvider<List<dynamic>>((ref) async {
  final api = ApiClient();
  final res = await api.dio.get(ApiEndpoints.adminPendingVerifications);
  return res.data as List;
});

class AdminPendingVerificationsPage extends ConsumerWidget {
  const AdminPendingVerificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(_pendingBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GlobalTopNavBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF5B2D8E),
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pending Payment Verifications',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Review and approve bookings submitted with manual M-Pesa transaction codes.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: pendingAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                    const SizedBox(height: 16),
                    Text('Failed to load: $e', textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.refresh(_pendingBookingsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green, size: 64),
                        SizedBox(height: 16),
                        Text('No pending verifications!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('All bookings have been reviewed.', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.refresh(_pendingBookingsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final b = bookings[index];
                      return _buildBookingCard(context, ref, b);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, WidgetRef ref, Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF5B2D8E).withOpacity(0.08),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF5B2D8E), size: 20),
                const SizedBox(width: 12),
                Text(
                  b['booking_reference'] ?? 'N/A',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                ),
                const Spacer(),
                _statusBadge('PENDING VERIFICATION', Colors.orange),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _infoCell('Passenger', b['passenger_name'] ?? 'N/A')),
                    Expanded(child: _infoCell('Phone', b['passenger_phone'] ?? 'N/A')),
                    Expanded(child: _infoCell('Amount', 'KES ${b['amount'] ?? '0'}')),
                  ],
                ),
                const SizedBox(height: 16),
                // Transaction Code - highlighted
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.money, color: Colors.amber, size: 22),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('M-Pesa Transaction Code', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            b['transaction_code'] ?? 'No code provided',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _handleAction(context, ref, b['id'], 'reject'),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('REJECT'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleAction(context, ref, b['id'], 'approve'),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('APPROVE & CONFIRM BOOKING'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCell(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.4))),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Future<void> _handleAction(BuildContext context, WidgetRef ref, String bookingId, String action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(action == 'approve' ? 'Confirm Approval' : 'Confirm Rejection'),
        content: Text(action == 'approve'
            ? 'This will confirm the booking and allow the passenger to access their ticket.'
            : 'This will cancel the booking. This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: Text(action == 'approve' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Capture these before async gap
    final messenger = ScaffoldMessenger.of(context);

    try {
      final api = ApiClient();
      final res = await api.dio.post(
        ApiEndpoints.adminApproveBooking(bookingId),
        data: {'action': action},
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(res.data['message'] ?? 'Done'),
          backgroundColor: action == 'approve' ? Colors.green : Colors.redAccent,
        ),
      );
      // ignore: unused_result
      ref.refresh(_pendingBookingsProvider);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }
}
