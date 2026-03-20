class SeatModel {
  final String id;
  final String seatNumber;
  final bool isAvailable;
  final String? seatType; // e.g., 'WINDOW', 'AISLE'

  SeatModel({
    required this.id,
    required this.seatNumber,
    required this.isAvailable,
    this.seatType,
  });

  factory SeatModel.fromJson(Map<String, dynamic> json) {
    return SeatModel(
      id: json['id']?.toString() ?? '',
      seatNumber: json['seat_number']?.toString() ?? '?',
      isAvailable: json['is_available'] == true || json['is_booked'] == false,
      seatType: json['seat_type']?.toString(),
    );
  }
}
