import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../shared/models/trip_model.dart';

final tripProvider = StateNotifierProvider<TripNotifier, TripState>((ref) {
  return TripNotifier();
});

class TripState {
  final List<ScheduleModel> schedules;
  final bool isLoading;
  final String? error;

  TripState({this.schedules = const [], this.isLoading = false, this.error});

  TripState copyWith({List<ScheduleModel>? schedules, bool? isLoading, String? error}) {
    return TripState(
      schedules: schedules ?? this.schedules,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class TripNotifier extends StateNotifier<TripState> {
  final _api = ApiClient();

  TripNotifier() : super(TripState());

  Future<void> searchSchedules({String? origin, String? destination, String? date}) async {
    print('searchSchedules called with param: origin=$origin, destination=$destination, date=$date');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _api.dio.get(
        ApiEndpoints.schedules,
        queryParameters: {
          if (origin != null) 'origin': origin,
          if (destination != null) 'destination': destination,
          if (date != null) 'date': date,
        },
      );
      print('API Response Status: ${response.statusCode}');
      print('API Response Data: ${response.data}');
      
      final List data = response.data;
      final schedules = data.map((e) => ScheduleModel.fromJson(e)).toList();
      print('Parsed ${schedules.length} schedules successfully.');
      
      state = state.copyWith(schedules: schedules, isLoading: false);
    } catch (e, stacktrace) {
      print('Error parsing schedules: $e');
      print(stacktrace);
      state = state.copyWith(isLoading: false, error: 'Failed to fetch schedules.');
    }
  }
}
