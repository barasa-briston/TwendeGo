import 'package:flutter/foundation.dart';

class ApiEndpoints {
  static const String baseUrl = kIsWeb 
      ? 'http://localhost:8080/api'
      : 'http://172.20.136.115:8080/api';
  
  // Auth
  static const String register = '/auth/register/';
  static const String login = '/auth/login/';
  static const String profile = '/auth/profile/';
  
  // Routes & Trips
  static const String routes = '/routes/';
  static const String schedules = '/schedules/';
  static const String seats = '/seats/';
  
  // Bookings
  static const String bookings = '/bookings/';
  static const String myBookings = '/bookings/my/';
  
  // Payments
  static const String stkPush = '/payments/mpesa/stk-push/';
  static String paymentStatus(String checkoutRequestId) =>
      '/payments/status/$checkoutRequestId/';

  // Operator Management
  static const String operatorVehicles = '/operator/vehicles/';
  static const String operatorRoutes = '/operator/routes/';
  static const String operatorSchedules = '/operator/schedules/';

  // Admin Management
  static const String adminPendingVerifications = '/admin/pending-verifications/';
  static String adminApproveBooking(String bookingId) => '/admin/bookings/$bookingId/approve/';
}
