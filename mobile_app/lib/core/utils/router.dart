import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/signup_page.dart';
import '../../features/trips/presentation/pages/search_results_page.dart';
import '../../features/trips/presentation/pages/trip_detail_page.dart';
import '../../features/booking/presentation/pages/seat_selection_page.dart';
import '../../features/booking/presentation/pages/passenger_details_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/booking/presentation/pages/my_bookings_page.dart';
import '../../features/booking/presentation/pages/ticket_detail_page.dart';
import '../../features/operator/presentation/pages/operator_dashboard.dart';
import '../../features/home/presentation/pages/about_us_page.dart';
import '../../features/home/presentation/pages/contact_us_page.dart';
import '../../features/booking/presentation/pages/print_ticket_page.dart';
import '../../features/admin/presentation/pages/admin_pending_verifications_page.dart';
import '../../features/auth/presentation/pages/profile_page.dart';
import '../../features/auth/presentation/pages/notifications_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: RouterRefreshNotifier(ref), 
    redirect: (context, state) {
      // Don't redirect while auth is still initializing (loading profile from token)
      if (authState.isLoading) return null;

      final isLoggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/signup';
      final isSplashing = state.matchedLocation == '/splash';

      if (authState.user == null) {
        // Not logged in. Let them stay on public pages.
        if (isLoggingIn || isSplashing || state.matchedLocation == '/onboarding' || state.matchedLocation == '/home' || state.matchedLocation == '/about' || state.matchedLocation == '/contact' || state.matchedLocation == '/search') {
          return isSplashing ? '/home' : null;
        }
        return '/login';
      }

      if (isLoggingIn || isSplashing) return '/home';

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final origin = state.uri.queryParameters['origin'];
          final destination = state.uri.queryParameters['destination'];
          final date = state.uri.queryParameters['date'];
          final int passengers = int.tryParse(state.uri.queryParameters['passengers'] ?? '1') ?? 1;
          return SearchResultsPage(origin: origin, destination: destination, date: date, passengers: passengers);
        },
      ),
      GoRoute(
        path: '/trip-detail/:id',
        builder: (context, state) {
          final int passengers = int.tryParse(state.uri.queryParameters['passengers'] ?? '1') ?? 1;
          return TripDetailPage(scheduleId: state.pathParameters['id']!, passengers: passengers);
        },
      ),
      GoRoute(
        path: '/seat-selection/:id',
        builder: (context, state) {
          final int passengers = int.tryParse(state.uri.queryParameters['passengers'] ?? '1') ?? 1;
          return SeatSelectionPage(scheduleId: state.pathParameters['id']!, passengers: passengers);
        },
      ),
      GoRoute(
        path: '/passenger-details/:id',
        builder: (context, state) {
          final seats = state.uri.queryParameters['seats']?.split(',') ?? [];
          return PassengerDetailsPage(scheduleId: state.pathParameters['id']!, seatIds: seats);
        },
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => PaymentPage(data: state.uri.queryParameters),
      ),
      GoRoute(
        path: '/my-bookings',
        builder: (context, state) => const MyBookingsPage(),
      ),
      GoRoute(
        path: '/ticket/:id',
        builder: (context, state) => TicketDetailPage(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/operator-dashboard',
        builder: (context, state) => const OperatorDashboard(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AboutUsPage(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactUsPage(),
      ),
      GoRoute(
        path: '/print-ticket',
        builder: (context, state) => const PrintTicketPage(),
      ),
      GoRoute(
        path: '/admin/pending-verifications',
        builder: (context, state) => const AdminPendingVerificationsPage(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
    ],
  );
});

class RouterRefreshNotifier extends ChangeNotifier {
  RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (_, __) => notifyListeners());
  }
}
