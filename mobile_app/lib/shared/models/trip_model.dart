class RouteModel {
  final String id;
  final String origin;
  final String destination;
  final double? distanceKm;
  final String? estimatedDuration;

  RouteModel({
    required this.id,
    required this.origin,
    required this.destination,
    this.distanceKm,
    this.estimatedDuration,
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: json['id']?.toString() ?? '',
      origin: json['origin']?.toString() ?? 'Unknown',
      destination: json['destination']?.toString() ?? 'Unknown',
      distanceKm: json['distance_km'] != null ? double.tryParse(json['distance_km'].toString()) : null,
      estimatedDuration: json['estimated_duration']?.toString(),
    );
  }
}

class ScheduleModel {
  final String id;
  final RouteModel route;
  final Map<String, dynamic>? vehicle;
  final DateTime departureDatetime;
  final DateTime arrivalEstimate;
  final double fare;
  final String status;
  final int availableSeatsCount;

  ScheduleModel({
    required this.id,
    required this.route,
    this.vehicle,
    required this.departureDatetime,
    required this.arrivalEstimate,
    required this.fare,
    required this.status,
    required this.availableSeatsCount,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id']?.toString() ?? '',
      route: RouteModel.fromJson(json['route'] ?? {}),
      vehicle: json['vehicle'],
      departureDatetime: DateTime.tryParse(json['departure_datetime']?.toString() ?? '') ?? DateTime.now(),
      arrivalEstimate: DateTime.tryParse(json['arrival_estimate']?.toString() ?? '') ?? DateTime.now(),
      fare: double.tryParse(json['fare']?.toString() ?? '0') ?? 0.0,
      status: json['status']?.toString() ?? 'UNKNOWN',
      availableSeatsCount: int.tryParse(json['available_seats_count']?.toString() ?? '0') ?? 0,
    );
  }
}
