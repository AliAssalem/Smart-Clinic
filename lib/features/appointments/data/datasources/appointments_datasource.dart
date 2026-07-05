import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/appointment_model.dart';

class AppointmentsDatasource {
  final ApiClient _apiClient;
  AppointmentsDatasource(this._apiClient);

  Future<List<DoctorListModel>> getDoctors() async {
    try {
      final response = await _apiClient.dio.get('/doctors');
      final list = response.data as List;
      return list.map((e) => DoctorListModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<AppointmentModel> bookAppointment({
    required int doctorId,
    required DateTime appointmentDate,
  }) async {
    try {
      final response = await _apiClient.dio.post('/appointments', data: {
        'doctor_id': doctorId,
        'appointment_date': appointmentDate.toIso8601String(),
      });
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<AppointmentModel>> getMyAppointments() async {
    try {
      final response = await _apiClient.dio.get('/appointments/my');
      final list = response.data as List;
      return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<AppointmentModel>> getDoctorAppointments({String? status}) async {
    try {
      final response = await _apiClient.dio.get(
        '/appointments/doctor',
        queryParameters: status != null ? {'status': status} : null,
      );
      final list = response.data as List;
      return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<List<AppointmentModel>> getTodayAppointments() async {
    try {
      final response = await _apiClient.dio.get('/doctors/me/appointments/today');
      final list = response.data as List;
      return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<AppointmentModel> updateStatus({
    required int appointmentId,
    required String status,
    String? doctorNotes,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/appointments/$appointmentId/status',
        data: {
          'status': status,
          if (doctorNotes != null && doctorNotes.isNotEmpty) 'doctor_notes': doctorNotes,
        },
      );
      return AppointmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    try {
      await _apiClient.dio.delete('/appointments/$appointmentId/cancel');
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}
