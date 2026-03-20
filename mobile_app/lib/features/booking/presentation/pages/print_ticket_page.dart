import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import '../../../../shared/widgets/global_footer.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/booking_provider.dart';

class PrintTicketPage extends ConsumerStatefulWidget {
  const PrintTicketPage({super.key});

  @override
  ConsumerState<PrintTicketPage> createState() => _PrintTicketPageState();
}

class _PrintTicketPageState extends ConsumerState<PrintTicketPage> {
  final TextEditingController _refController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController(text: '+254');

  @override
  void dispose() {
    _refController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  void _retrieveTicket() {
    final refStr = _refController.text.trim().toUpperCase();
    final phoneStr = _phoneController.text.trim();
    final bookingState = ref.read(bookingProvider);
    
    // Search in local state
    try {
      final booking = bookingState.bookings.firstWhere(
        (b) => (refStr.isNotEmpty && (b.bookingReference.toUpperCase() == refStr || b.id == refStr)) ||
               (phoneStr.isNotEmpty && b.passengerPhone == phoneStr),
      );
      context.push('/ticket/${booking.id}');
    } catch (e) {
      final searchVal = refStr.isNotEmpty ? refStr : phoneStr;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No booking found with "$searchVal"'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlobalTopNavBar(isTransparent: true),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/homepage_bg.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.black.withOpacity(0.5),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 120),
                  child: Center(
                    child: DefaultTabController(
                      length: 2,
                      child: Column(
                        children: [
                          _buildTicketContainer(context),
                        ],
                      ),
                    ),
                  ),
                ),
                const GlobalFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketContainer(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Stack(
        children: [
          // Background Ticket Shape
          ClipPath(
            clipper: TicketClipper(),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.all(48),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Print Ticket',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Please enter your seat confirmation details to retrieve your ticket.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const TabBar(
                      indicatorColor: AppColors.primary,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: Colors.white70,
                      tabs: [
                        Tab(text: 'By Reference'),
                        Tab(text: 'By Phone'),
                      ],
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 180,
                      child: TabBarView(
                        children: [
                          _buildReferenceForm(),
                          _buildPhoneForm(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _retrieveTicket,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Retrieve Ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'Check your confirmation SMS for the ID/Reference.',
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Booking ID / Reference', style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 12),
        TextField(
          controller: _refController,
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('e.g. TWG-123456', Icons.confirmation_number),
          onSubmitted: (_) => _retrieveTicket(),
        ),
      ],
    );
  }

  Widget _buildPhoneForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Code', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('+254', null),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Phone Number', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Mobile No', Icons.phone),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text('Ticket No (Optional)', style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          style: const TextStyle(color: Colors.white),
          decoration: _inputDecoration('Enter Ticket No', Icons.qr_code),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint, IconData? icon) {
    return InputDecoration(
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }
}

class TicketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    const double radius = 20;
    
    path.lineTo(0, size.height / 2 - radius);
    path.arcToPoint(Offset(radius, size.height / 2), radius: const Radius.circular(radius), clockwise: true);
    path.arcToPoint(Offset(0, size.height / 2 + radius), radius: const Radius.circular(radius), clockwise: true);
    
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    
    path.lineTo(size.width, size.height / 2 + radius);
    path.arcToPoint(Offset(size.width - radius, size.height / 2), radius: const Radius.circular(radius), clockwise: true);
    path.arcToPoint(Offset(size.width, size.height / 2 - radius), radius: const Radius.circular(radius), clockwise: true);
    
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
