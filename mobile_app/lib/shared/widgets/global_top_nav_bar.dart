import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';

class GlobalTopNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isTransparent;

  const GlobalTopNavBar({super.key, this.isTransparent = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final double width = MediaQuery.of(context).size.width;
    final bool isMobile = width < 1100;
    
    return Container(
      decoration: BoxDecoration(
        color: isTransparent ? Colors.transparent : Colors.white,
        boxShadow: isTransparent ? [] : [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 20 : 40, 
            vertical: 8
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Logo Area (Clickable to Home)
              _buildLogo(context),
              
              // Navigation Area
              if (isMobile) 
                _buildMobileMenu(context, ref, user)
              else 
                _buildDesktopMenu(context, ref, user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context) {
    return InkWell(
      onTap: () => context.go('/home'),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_bus, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          const Text(
            'TwendeGo',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMenu(BuildContext context, WidgetRef ref, dynamic user) {
    String dashboardRoute = '/home';
    if (user != null) {
      if (user.role == 'OPERATOR') dashboardRoute = '/operator-dashboard';
      else if (user.role == 'ADMIN') dashboardRoute = '/admin-dashboard';
    }

    return Row(
      children: [
        _navLink(context, 'Home', '/home'),
        _navLink(context, 'About Us', '/about'),
        _navLink(context, 'Contact Us', '/contact'),
        _navLink(context, 'Print Ticket', '/print-ticket'),
        if (user != null) ...[
          _navLink(context, 'My Bookings', '/my-bookings'),
          if (user.role == 'OPERATOR') _navLink(context, 'Dashboard', '/operator-dashboard'),
          if (user.role == 'ADMIN') _navLink(context, 'Verifications', '/admin/pending-verifications'),
          _logoutButton(context, ref),
        ] else
          _navLink(context, 'Sign In / Register', '/login'),
      ],
    );
  }

  Widget _logoutButton(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton.icon(
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          context.go('/login');
        },
        icon: Icon(Icons.logout, size: 18, color: isTransparent ? Colors.white : Colors.black87),
        label: Text(
          'Logout',
          style: TextStyle(
            fontWeight: FontWeight.w600, 
            fontSize: 16,
            color: isTransparent ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildMobileMenu(BuildContext context, WidgetRef ref, dynamic user) {
    return PopupMenuButton<String>(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.apps, color: AppColors.primary, size: 28),
      ),
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) async {
        if (value == 'logout') {
          await ref.read(authProvider.notifier).logout();
          context.go('/login');
        } else if (value.isNotEmpty) {
          context.go(value);
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('Home', '/home', Icons.home),
        _buildPopupItem('About Us', '/about', Icons.info),
        _buildPopupItem('Contact Us', '/contact', Icons.contact_support),
        _buildPopupItem('Print Ticket', '/print-ticket', Icons.print),
        if (user != null) ...[
          _buildPopupItem('My Bookings', '/my-bookings', Icons.history),
          if (user.role == 'OPERATOR') 
            _buildPopupItem('Dashboard', '/operator-dashboard', Icons.dashboard),
          if (user.role == 'ADMIN')
            _buildPopupItem('Verifications', '/admin/pending-verifications', Icons.verified_user),
          _buildPopupItem('Logout', 'logout', Icons.logout),
        ] else
          _buildPopupItem('Sign In / Register', '/login', Icons.person),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String title, String route, IconData icon) {
    return PopupMenuItem<String>(
      value: route,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navLink(BuildContext context, String title, [String? route]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: () {
          if (route != null) context.go(route);
        },
        style: TextButton.styleFrom(
          foregroundColor: isTransparent ? Colors.white : Colors.black87,
        ),
        child: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);
}
