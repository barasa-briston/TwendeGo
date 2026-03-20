import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/models/booking_model.dart';

final bookingProvider = StateNotifierProvider<BookingNotifier, BookingState>((ref) {
  return BookingNotifier();
});

class BookingState {
  final List<BookingModel> bookings;
  final bool isLoading;
  final String? error;

  BookingState({this.bookings = const [], this.isLoading = false, this.error});

  BookingState copyWith({List<BookingModel>? bookings, bool? isLoading, String? error}) {
    return BookingState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class BookingNotifier extends StateNotifier<BookingState> {
  final _api = ApiClient();

  BookingNotifier() : super(BookingState()) {
    fetchMyBookings();
  }

  Future<void> fetchMyBookings() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get(ApiEndpoints.myBookings);
      final List data = response.data;
      final bookings = data.map((e) => BookingModel.fromJson(e)).toList();
      state = state.copyWith(bookings: bookings, isLoading: false);
    } catch (e, stack) {
      print('Error fetching bookings: $e');
      print(stack);
      state = state.copyWith(isLoading: false, error: 'Failed to fetch bookings.');
    }
  }
}
