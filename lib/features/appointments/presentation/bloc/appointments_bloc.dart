import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/datasources/appointments_datasource.dart';
import '../../data/models/appointment_model.dart';
import '../../../../core/network/api_client.dart';

// ─── Events ───────────────────────────────────────────────
abstract class AppointmentsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadDoctors extends AppointmentsEvent {}
class LoadMyAppointments extends AppointmentsEvent {}
class LoadDoctorAppointments extends AppointmentsEvent {
  final String? status;
  LoadDoctorAppointments({this.status});
  @override
  List<Object?> get props => [status];
}

class LoadTodayAppointments extends AppointmentsEvent {}

class BookAppointment extends AppointmentsEvent {
  final int doctorId;
  final DateTime date;
  BookAppointment({required this.doctorId, required this.date});
  @override
  List<Object?> get props => [doctorId, date];
}

class UpdateAppointmentStatus extends AppointmentsEvent {
  final int appointmentId;
  final String status;
  final String? notes;
  UpdateAppointmentStatus({required this.appointmentId, required this.status, this.notes});
  @override
  List<Object?> get props => [appointmentId, status];
}

class CancelAppointment extends AppointmentsEvent {
  final int appointmentId;
  CancelAppointment(this.appointmentId);
  @override
  List<Object?> get props => [appointmentId];
}

// ─── States ───────────────────────────────────────────────
abstract class AppointmentsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AppointmentsInitial extends AppointmentsState {}
class AppointmentsLoading extends AppointmentsState {}
class AppointmentsActionLoading extends AppointmentsState {
  final List<AppointmentModel> currentAppointments;
  final List<DoctorListModel> currentDoctors;
  AppointmentsActionLoading({
    this.currentAppointments = const [],
    this.currentDoctors = const [],
  });
}

class DoctorsLoaded extends AppointmentsState {
  final List<DoctorListModel> doctors;
  DoctorsLoaded(this.doctors);
  @override
  List<Object?> get props => [doctors];
}

class AppointmentsLoaded extends AppointmentsState {
  final List<AppointmentModel> appointments;
  AppointmentsLoaded(this.appointments);
  @override
  List<Object?> get props => [appointments];
}

class AppointmentBooked extends AppointmentsState {
  final AppointmentModel appointment;
  AppointmentBooked(this.appointment);
}

class AppointmentUpdated extends AppointmentsState {
  final AppointmentModel appointment;
  AppointmentUpdated(this.appointment);
}

class AppointmentsError extends AppointmentsState {
  final String message;
  AppointmentsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ─── BLoC ─────────────────────────────────────────────────
class AppointmentsBloc extends Bloc<AppointmentsEvent, AppointmentsState> {
  final AppointmentsDatasource _datasource;

  AppointmentsBloc(this._datasource) : super(AppointmentsInitial()) {
    on<LoadDoctors>(_onLoadDoctors);
    on<LoadMyAppointments>(_onLoadMyAppointments);
    on<LoadDoctorAppointments>(_onLoadDoctorAppointments);
    on<LoadTodayAppointments>(_onLoadToday);
    on<BookAppointment>(_onBook);
    on<UpdateAppointmentStatus>(_onUpdateStatus);
    on<CancelAppointment>(_onCancel);
  }

  Future<void> _onLoadDoctors(LoadDoctors e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      final doctors = await _datasource.getDoctors();
      emit(DoctorsLoaded(doctors));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }

  Future<void> _onLoadMyAppointments(LoadMyAppointments e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      final list = await _datasource.getMyAppointments();
      emit(AppointmentsLoaded(list));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }

  Future<void> _onLoadDoctorAppointments(LoadDoctorAppointments e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      final list = await _datasource.getDoctorAppointments(status: e.status);
      emit(AppointmentsLoaded(list));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }

  Future<void> _onLoadToday(LoadTodayAppointments e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsLoading());
    try {
      final list = await _datasource.getTodayAppointments();
      emit(AppointmentsLoaded(list));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }

  Future<void> _onBook(BookAppointment e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsActionLoading());
    try {
      final appt = await _datasource.bookAppointment(
        doctorId: e.doctorId,
        appointmentDate: e.date,
      );
      emit(AppointmentBooked(appt));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }

  Future<void> _onUpdateStatus(UpdateAppointmentStatus e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsActionLoading());
    try {
      final appt = await _datasource.updateStatus(
        appointmentId: e.appointmentId,
        status: e.status,
        doctorNotes: e.notes,
      );
      emit(AppointmentUpdated(appt));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }

  Future<void> _onCancel(CancelAppointment e, Emitter<AppointmentsState> emit) async {
    emit(AppointmentsActionLoading());
    try {
      await _datasource.cancelAppointment(e.appointmentId);
      emit(AppointmentUpdated(AppointmentModel(
        id: e.appointmentId,
        patientId: 0,
        doctorId: 0,
        appointmentDate: DateTime.now(),
        status: 'cancelled',
        createdAt: DateTime.now(),
      )));
    } on Failure catch (f) {
      emit(AppointmentsError(f.message));
    }
  }
}
