import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../../core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/trips/presentation/providers/trip_provider.dart';
import '../../../../shared/widgets/global_top_nav_bar.dart';
import '../widgets/hero_search_bar.dart';
import '../widgets/advantages_section.dart';
import '../widgets/popular_routes_section.dart';
import '../widgets/info_carousel_banner.dart';
import '../../../../shared/widgets/global_footer.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlobalTopNavBar(isTransparent: true),
      body: Stack(
        children: [
          // Fixed Immersive Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/homepage_bg.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Subtle Dark Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          // Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Seamless Long-Distance\nTravel across East Africa',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 32),
                        HeroSearchBar(),
                        SizedBox(height: 48),
                        InfoCarouselBanner(),
                        SizedBox(height: 48),
                        PopularRoutesSection(),
                        SizedBox(height: 48),
                        AdvantagesSection(),
                        SizedBox(height: 48),
                        _DiscountCampaignBanner(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  const GlobalFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0: context.go('/home'); break;
            case 1: context.push('/my-bookings'); break;
            case 2: context.push('/notifications'); break;
            case 3: context.push('/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.confirmation_num), label: 'Bookings'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _DiscountCampaignBanner extends ConsumerWidget {
  const _DiscountCampaignBanner();

    final bool isNarrow = MediaQuery.of(context).size.width < 600;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
        child: Container(
          padding: EdgeInsets.all(isNarrow ? 16 : 24),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20)],
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.0),
          ),
          child: isNarrow 
            ? Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer, color: Colors.black, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Discount Campaign!',
                          style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get 10% off on your first booking.',
                    style: TextStyle(color: Colors.black87, fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(tripProvider.notifier).searchSchedules();
                      context.go('/search');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(Icons.local_offer, color: Colors.black, size: 40),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Discount Campaign!',
                          style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Get 10% off on your first booking.',
                          style: TextStyle(color: Colors.black87, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(tripProvider.notifier).searchSchedules();
                      context.go('/search');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(100, 40),
                    ),
                    child: const Text('Book Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
        ),
      ),
    );
}
