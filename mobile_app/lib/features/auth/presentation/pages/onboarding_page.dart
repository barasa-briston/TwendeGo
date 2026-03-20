import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = [
    OnboardingItem(
      title: 'Search routes easily',
      description: 'Find the best intercity shuttle routes with a few taps.',
      icon: Icons.search,
      color: const Color(0xFFFFC107),
    ),
    OnboardingItem(
      title: 'Choose your seat',
      description: 'Pick your favorite seat from our interactive seat map.',
      icon: Icons.event_seat,
      color: const Color(0xFFFF9800),
    ),
    OnboardingItem(
      title: 'Pay with M-Pesa',
      description: 'Secure and fast payments directly from your phone.',
      icon: Icons.account_balance_wallet,
      color: const Color(0xFF4CAF50),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Definitive color to avoid potential null
    final primaryColor = AppColors.primary ?? const Color(0xFFFFC107);
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decorations
          Positioned(
            top: -100,
            right: -100,
            child: _buildBackgroundCircle(250, primaryColor.withOpacity(0.1)),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: _buildBackgroundCircle(200, primaryColor.withOpacity(0.05)),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _items.length,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      return OnboardingContent(item: _items[index]);
                    },
                  ),
                ),
                
                // Bottom Navigation
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: Color(0xFF6C757D),
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      
                      // Progress Indicators
                      Row(
                        children: List.generate(
                          _items.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentPage == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index 
                                  ? primaryColor 
                                  : primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      
                      // Next/Start Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage < _items.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOutQuint,
                            );
                          } else {
                            context.go('/home');
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(_currentPage == _items.length - 1 ? 16 : 12),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            _currentPage == _items.length - 1 ? Icons.check : Icons.arrow_forward_ios,
                            color: Colors.white,
                            size: _currentPage == _items.length - 1 ? 28 : 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final OnboardingItem item;

  const OnboardingContent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final itemColor = item.color ?? const Color(0xFFFFC107);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: itemColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: itemColor.withOpacity(0.2),
                      blurRadius: 30,
                      spreadRadius: 5,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  size: 70,
                  color: itemColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 60),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212529),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6C757D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingItem({
    required this.title, 
    required this.description, 
    required this.icon,
    required this.color,
  });
}
