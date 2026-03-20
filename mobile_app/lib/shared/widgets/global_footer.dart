import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class GlobalFooter extends StatelessWidget {
  const GlobalFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmall = MediaQuery.of(context).size.width < 800;
    
    return Container(
      color: const Color(0xFFF1F1F1),
      child: Column(
        children: [
          // Upper Footer: Destinations & Offices
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isSmall 
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDestinationsSection(context),
                        const SizedBox(height: 40),
                        _buildOfficesSection(),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _buildDestinationsSection(context)),
                        const SizedBox(width: 48),
                        Expanded(child: _buildOfficesSection()),
                      ],
                    ),
              ),
            ),
          ),
          
          // Lower Footer: Copyright Bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xFFE67E22), // Brand orange from screenshot
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: isSmall
                  ? Column(
                      children: [
                         _buildFooterLinks(context),
                         const SizedBox(height: 12),
                         _buildCopyrightText(),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFooterLinks(context),
                        _buildCopyrightText(),
                      ],
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Destinations',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isVerySmall = constraints.maxWidth < 400;
            return isVerySmall 
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _destinationLink(context, 'Nairobi - Mombasa'),
                    _destinationLink(context, 'Nairobi - Kampala'),
                    _destinationLink(context, 'Nairobi - Daresalaam'),
                    _destinationLink(context, 'Mombasa - Daresalaam'),
                    _destinationLink(context, 'Mombasa - Malaba'),
                    _destinationLink(context, 'Mombasa - Kitale'),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _destinationLink(context, 'Nairobi - Mombasa'),
                          _destinationLink(context, 'Nairobi - Kampala'),
                          _destinationLink(context, 'Nairobi - Daresalaam'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _destinationLink(context, 'Mombasa - Daresalaam'),
                          _destinationLink(context, 'Mombasa - Malaba'),
                          _destinationLink(context, 'Mombasa - Kitale'),
                        ],
                      ),
                    ),
                  ],
                );
          }
        ),
      ],
    );
  }

  Widget _destinationLink(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          final parts = title.split(' - ');
          if (parts.length == 2) {
            context.go('/search?origin=${parts[0]}&destination=${parts[1]}');
          }
        },
        child: Text(
          title,
          style: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildOfficesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Booking Offices',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _officeInfo(
                'Nairobi Office',
                'Ground Floor, Zahra Building\nRiver Rd, Nairobi',
                '+254 799737398'
              ),
            ),
            Expanded(
              child: _officeInfo(
                'Mombasa Office',
                'Aswan Building\nKenyatta Avenue\nMwenbe Tayari',
                ''
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _officeInfo(String name, String address, String contact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
        const SizedBox(height: 4),
        Text(address, style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4)),
        if (contact.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Ticket Management: $contact', style: const TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      ],
    );
  }

  Widget _buildFooterLinks(BuildContext context) {
    return Wrap(
      spacing: 24,
      children: [
        _footerLink(context, 'About Us'),
        _footerLink(context, 'Privacy Policy'),
        _footerLink(context, 'Term & Conditions'),
      ],
    );
  }

  Widget _footerLink(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        if (title == 'About Us') {
          context.go('/about');
        } else if (title == 'Contact Us') {
           context.go('/contact');
        }
        // Others can be added as routes exist
      },
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
      ),
    );
  }

  Widget _buildCopyrightText() {
    return const Text(
      'Copyright © 2026. TwendeGo. All Rights Reserved.',
      style: TextStyle(color: Colors.white, fontSize: 13),
    );
  }
}
