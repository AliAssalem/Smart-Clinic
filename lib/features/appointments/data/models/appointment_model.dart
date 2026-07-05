class AppointmentModel {
  final int id;
  final int patientId;
  final int doctorId;
  final DateTime appointmentDate;
  final String status;
  final String? doctorNotes;
  final DateTime createdAt;
  final PatientInfo? patient;
  final DoctorInfo? doctor;

  const AppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    required this.status,
    this.doctorNotes,
    required this.createdAt,
    this.patient,
    this.doctor,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) => AppointmentModel(
        id: json['id'] as int,
        patientId: json['patient_id'] as int,
        doctorId: json['doctor_id'] as int,
        appointmentDate: DateTime.parse(json['appointment_date'] as String),
        status: json['status'] as String,
        doctorNotes: json['doctor_notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        patient: json['patient'] != null
            ? PatientInfo.fromJson(json['patient'] as Map<String, dynamic>)
            : null,
        doctor: json['doctor'] != null
            ? DoctorInfo.fromJson(json['doctor'] as Map<String, dynamic>)
            : null,
      );

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canCancel => isPending || isConfirmed;
}

class PatientInfo {
  final int id;
  final String fullName;
  final String email;
  const PatientInfo({required this.id, required this.fullName, required this.email});
  factory PatientInfo.fromJson(Map<String, dynamic> json) => PatientInfo(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        email: json['email'] as String,
      );
}

class DoctorInfo {
  final int id;
  final double consultationFee;
  final DoctorUser? user;
  final DoctorSpecialty? specialty;
  const DoctorInfo({required this.id, required this.consultationFee, this.user, this.specialty});
  factory DoctorInfo.fromJson(Map<String, dynamic> json) => DoctorInfo(
        id: json['id'] as int,
        consultationFee: double.parse(json['consultation_fee'].toString()),
        user: json['user'] != null ? DoctorUser.fromJson(json['user'] as Map<String, dynamic>) : null,
        specialty: json['specialty'] != null
            ? DoctorSpecialty.fromJson(json['specialty'] as Map<String, dynamic>)
            : null,
      );
}

class DoctorUser {
  final int id;
  final String fullName;
  const DoctorUser({required this.id, required this.fullName});
  factory DoctorUser.fromJson(Map<String, dynamic> json) =>
      DoctorUser(id: json['id'] as int, fullName: json['full_name'] as String);
}

class DoctorSpecialty {
  final String name;
  const DoctorSpecialty({required this.name});
  factory DoctorSpecialty.fromJson(Map<String, dynamic> json) =>
      DoctorSpecialty(name: json['name'] as String);
}

class DoctorListModel {
  final int id;
  final double consultationFee;
  final DoctorUser user;
  final DoctorSpecialty? specialty;

  const DoctorListModel({
    required this.id,
    required this.consultationFee,
    required this.user,
    this.specialty,
  });

  factory DoctorListModel.fromJson(Map<String, dynamic> json) => DoctorListModel(
        id: json['id'] as int,
        consultationFee: double.parse(json['consultation_fee'].toString()),
        user: DoctorUser.fromJson(json['user'] as Map<String, dynamic>),
        specialty: json['specialty'] != null
            ? DoctorSpecialty.fromJson(json['specialty'] as Map<String, dynamic>)
            : null,
      );
}
