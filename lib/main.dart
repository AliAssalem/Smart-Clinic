import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/datasources/auth_datasource.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/appointments/data/datasources/appointments_datasource.dart';
import 'features/appointments/presentation/bloc/appointments_bloc.dart';
import 'app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  final storage = SecureStorageService();
  final apiClient = ApiClient(storage);
  final authDatasource = AuthDatasource(apiClient, storage);
  final appointmentsDatasource = AppointmentsDatasource(apiClient);

  runApp(SmartClinicApp(
    authDatasource: authDatasource,
    appointmentsDatasource: appointmentsDatasource,
  ));
}

class SmartClinicApp extends StatelessWidget {
  final AuthDatasource authDatasource;
  final AppointmentsDatasource appointmentsDatasource;

  const SmartClinicApp({
    super.key,
    required this.authDatasource,
    required this.appointmentsDatasource,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authDatasource),
        ),
        BlocProvider<AppointmentsBloc>(
          create: (_) => AppointmentsBloc(appointmentsDatasource),
        ),
      ],
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = AppRouter.router(authBloc);

          return MaterialApp.router(
            title: 'Smart Clinic',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: router,
            builder: (context, child) {
              return Directionality(
                textDirection: TextDirection.rtl,
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
