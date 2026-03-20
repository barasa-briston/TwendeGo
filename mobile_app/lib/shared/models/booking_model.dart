import 'trip_model.dart';
import 'seat_model.dart';

class BookingModel {
  final String id;
  final ScheduleModel schedule;
  final List<String> seatIds;
  final List<SeatModel>? seatsDetail;
  final String passengerName;
  final String passengerPhone;
  final String status;
  final double amount;
  final String bookingReference;
  final String? transactionCode;
  final DateTime createdAt;

  BookingModel({
    required this.id,
    required this.schedule,
    required this.seatIds,
    this.seatsDetail,
    required this.passengerName,
    required this.passengerPhone,
    required this.status,
    required this.amount,
    required this.bookingReference,
    this.transactionCode,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    try {
      final scheduleData = json['schedule_detail'];
      final List<dynamic>? seatsData = json['seats_detail'];
      final seatsDetail = seatsData?.map((s) => SeatModel.fromJson(s)).toList();

      return BookingModel(
        id: json['id']?.toString() ?? '',
        schedule: scheduleData != null && scheduleData is Map<String, dynamic>
            ? ScheduleModel.fromJson(scheduleData)
            : _dummySchedule(json['schedule']?.toString() ?? ''),
        seatIds: (json['seats'] as List<dynamic>?)?.map((s) => s.toString()).toList() ?? [],
        seatsDetail: seatsDetail,
        passengerName: json['passenger_name']?.toString() ?? 'Unknown',
        passengerPhone: json['passenger_phone']?.toString() ?? '',
        status: json['status']?.toString() ?? 'UNKNOWN',
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
        bookingReference: json['booking_reference']?.toString() ?? 'REF-?',
        transactionCode: json['transaction_code']?.toString(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
    } catch (e) {
      // If parsing fails for one booking, return a minimal valid object to avoid crashing the list
      return BookingModel(
        id: json['id']?.toString() ?? 'error',
        schedule: _dummySchedule('error'),
        seatIds: [],
        passengerName: 'Parsing Error',
        passengerPhone: '',
        status: 'ERROR',
        amount: 0,
        bookingReference: 'ERROR',
        createdAt: DateTime.now(),
      );
    }
  }

  static ScheduleModel _dummySchedule(String id) {
    return ScheduleModel(
      id: id,
      route: RouteModel(id: '', origin: 'Unknown', destination: 'Unknown'),
      departureDatetime: DateTime.now(),
      arrivalEstimate: DateTime.now(),
      fare: 0,
      status: 'UNKNOWN',
      availableSeatsCount: 0,
    );
  }

  String get formattedSeats {
    if (seatsDetail != null && seatsDetail!.isNotEmpty) {
      return seatsDetail!.map((s) => s.seatNumber).join(', ');
    }
    if (seatIds.isNotEmpty) {
      return seatIds.join(', ');
    }
    return 'None';
  }
}
