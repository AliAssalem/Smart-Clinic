import 'dart:convert';

class UserModel {
  final int id;
  final String fullName;
  final String email;
  final String role;
  final DoctorModel? doctor;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.doctor,
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        doctor: json['doctor'] != null
            ? DoctorModel.fromJson(json['doctor'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        if (doctor != null) 'doctor': doctor!.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory UserModel.fromJsonString(String jsonString) =>
      UserModel.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}

class DoctorModel {
  final int id;
  final double consultationFee;
  final SpecialtyModel? specialty;

  const DoctorModel({
    required this.id,
    required this.consultationFee,
    this.specialty,
  });

  factory DoctorModel.fromJson(Map<String, dynamic> json) => DoctorModel(
        id: json['id'] as int,
        consultationFee: double.parse(json['consultation_fee'].toString()),
        specialty: json['specialty'] != null
            ? SpecialtyModel.fromJson(json['specialty'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'consultation_fee': consultationFee,
        if (specialty != null) 'specialty': specialty!.toJson(),
      };
}

class SpecialtyModel {
  final int id;
  final String name;

  const SpecialtyModel({required this.id, required this.name});

  factory SpecialtyModel.fromJson(Map<String, dynamic> json) => SpecialtyModel(
        id: json['id'] as int,
        name: json['name'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class AuthResponseModel {
  final String message;
  final String accessToken;
  final UserModel user;

  const AuthResponseModel({
    required this.message,
    required this.accessToken,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) => AuthResponseModel(
        message: json['message'] as String,
        accessToken: json['access_token'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}
