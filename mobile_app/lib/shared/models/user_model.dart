class UserModel {
  final String id;
  final String phoneNumber;
  final String username;
  final String role;
  final String? fullName;
  final String? email;
  final String? dob;
  final String? gender;

  UserModel({
    required this.id,
    required this.phoneNumber,
    required this.username,
    required this.role,
    this.fullName,
    this.email,
    this.dob,
    this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      phoneNumber: json['phone_number'],
      username: json['username'],
      role: json['role'],
      fullName: json['full_name'],
      email: json['email'],
      dob: json['dob'],
      gender: json['gender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phone_number': phoneNumber,
      'username': username,
      'role': role,
      'full_name': fullName,
      'email': email,
      'dob': dob,
      'gender': gender,
    };
  }
}
