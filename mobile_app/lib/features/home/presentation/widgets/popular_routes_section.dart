import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import '../../../../features/trips/presentation/providers/trip_provider.dart';
import '../../../../core/constants/app_colors.dart';

class PopularRoutesSection extends ConsumerWidget {
  const PopularRoutesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Popular Routes',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 24,
            runSpacing: 24,
            alignment: WrapAlignment.center,
            children: [
              RouteCard(
                title: 'Nairobi - Mombasa',
                price: 'KES 2,500',
              ),
              RouteCard(
                title: 'Kampala - Kigali',
                price: 'RWF 35k',
              ),
              RouteCard(
                title: 'Dar es Salaam - Arusha',
                price: 'TSh 60k',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class RouteCard extends ConsumerWidget {
  final String title;
  final String price;

  const RouteCard({super.key, required this.title, required this.price});

  void _onBookNow(BuildContext context, WidgetRef ref) {
    final parts = title.split(' - ');
    if (parts.length == 2) {
      final origin = parts[0].trim();
      final destination = parts[1].trim();
      
      // Trigger search
      ref.read(tripProvider.notifier).searchSchedules(
        origin: origin,
        destination: destination,
      );

      context.go('/search?origin=$origin&destination=$destination');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_bus, color: AppColors.secondary, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                price,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => _onBookNow(context, ref),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Book Now',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
}
