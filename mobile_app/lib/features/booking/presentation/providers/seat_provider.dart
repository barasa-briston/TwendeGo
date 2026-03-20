import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/models/seat_model.dart';

final seatProvider = StateNotifierProvider.family<SeatNotifier, SeatState, String>((ref, scheduleId) {
  return SeatNotifier(scheduleId);
});

class SeatState {
  final List<SeatModel> seats;
  final bool isLoading;
  final String? error;
  final List<String> selectedSeatIds;

  SeatState({this.seats = const [], this.isLoading = false, this.error, this.selectedSeatIds = const []});

  SeatState copyWith({List<SeatModel>? seats, bool? isLoading, String? error, List<String>? selectedSeatIds}) {
    return SeatState(
      seats: seats ?? this.seats,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedSeatIds: selectedSeatIds ?? this.selectedSeatIds,
    );
  }
}

class SeatNotifier extends StateNotifier<SeatState> {
  final String scheduleId;
  final _api = ApiClient();

  SeatNotifier(this.scheduleId) : super(SeatState()) {
    fetchSeats();
  }

  Future<void> fetchSeats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get(
        ApiEndpoints.seats,
        queryParameters: {'schedule_id': scheduleId},
      );
      
      final List data = response.data;
      final seats = data.map((e) => SeatModel.fromJson(e)).toList();
      
      state = state.copyWith(seats: seats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to fetch seats.');
    }
  }

  void toggleSeat(String seatId, {int maxSeats = 1}) {
    final selected = List<String>.from(state.selectedSeatIds);
    if (selected.contains(seatId)) {
      selected.remove(seatId);
    } else {
      if (selected.length < maxSeats) {
        selected.add(seatId); 
      }
    }
    state = state.copyWith(selectedSeatIds: selected);
  }
}
