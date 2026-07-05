import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../appointments/presentation/bloc/appointments_bloc.dart';
import '../../../appointments/data/models/appointment_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});
  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AppointmentsBloc>().add(LoadDoctors());
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(userName: user.fullName),
          _DoctorsTab(),
          _AppointmentsTab(),
          _ProfileTab(user: user),
        ],
      ),
      bottomNavigationBar: _ClinicBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 1) context.read<AppointmentsBloc>().add(LoadDoctors());
          if (i == 2) context.read<AppointmentsBloc>().add(LoadMyAppointments());
        },
        items: const [
          _NavItem(icon: Icons.home_rounded, label: 'الرئيسية'),
          _NavItem(icon: Icons.people_alt_rounded, label: 'الأطباء'),
          _NavItem(icon: Icons.calendar_month_rounded, label: 'مواعيدي'),
          _NavItem(icon: Icons.person_rounded, label: 'حسابي'),
        ],
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String userName;
  const _HomeTab({required this.userName});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ClinicHeader(
            title: 'مرحباً، ${userName.split(' ').first} 👋',
            subtitle: 'كيف يمكننا مساعدتك اليوم؟',
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Quick actions
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ماذا تريد أن تفعل؟',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_circle_outline_rounded,
                        label: 'حجز موعد',
                        color: AppColors.primary,
                        bg: AppColors.primarySurface,
                        onTap: () {
                          context.read<AppointmentsBloc>().add(LoadDoctors());
                          // Switch to doctors tab
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.history_rounded,
                        label: 'سجل المواعيد',
                        color: AppColors.accent,
                        bg: AppColors.accentSurface,
                        onTap: () {
                          context.read<AppointmentsBloc>().add(LoadMyAppointments());
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Upcoming appointments
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المواعيد القادمة',
                    style: GoogleFonts.cairo(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () {
                    context.read<AppointmentsBloc>().add(LoadMyAppointments());
                  },
                  child: Text('عرض الكل',
                      style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),

        BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, state) {
            if (state is AppointmentsLoading) {
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const ShimmerCard(height: 90),
                    const ShimmerCard(height: 90),
                  ]),
                ),
              );
            }
            if (state is AppointmentsLoaded) {
              final upcoming = state.appointments
                  .where((a) => a.isPending || a.isConfirmed)
                  .take(3)
                  .toList();
              if (upcoming.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: _EmptyAppointmentsCard(),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AppointmentCard(appointment: upcoming[i], showCancel: true),
                    ),
                    childCount: upcoming.length,
                  ),
                ),
              );
            }
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: _EmptyAppointmentsCard(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── Doctors Tab ──────────────────────────────────────────
class _DoctorsTab extends StatefulWidget {
  @override
  State<_DoctorsTab> createState() => _DoctorsTabState();
}

class _DoctorsTabState extends State<_DoctorsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClinicHeader(
          title: 'الأطباء المتاحون',
          subtitle: 'اختر طبيبك واحجز موعدك',
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: GoogleFonts.cairo(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'ابحث عن طبيب أو تخصص...',
              hintStyle: GoogleFonts.cairo(color: AppColors.textHint, fontSize: 14),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) {
              if (state is AppointmentsLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 5,
                  itemBuilder: (_, __) => const ShimmerCard(height: 110),
                );
              }
              if (state is DoctorsLoaded) {
                final filtered = _search.isEmpty
                    ? state.doctors
                    : state.doctors.where((d) {
                  final nameMatch = d.user.fullName.toLowerCase().contains(_search.toLowerCase());
                  final specialtyMatch = d.specialty?.name.toLowerCase().contains(_search.toLowerCase()) ?? false;
                  return nameMatch || specialtyMatch;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'لا يوجد أطباء',
                    subtitle: 'لم يتم العثور على أطباء مطابقين للبحث',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoctorCard(doctor: filtered[i]),
                  ),
                );
              }
              if (state is AppointmentsError) {
                return EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'خطأ في التحميل',
                  subtitle: state.message,
                  actionLabel: 'إعادة المحاولة',
                  onAction: () =>
                      context.read<AppointmentsBloc>().add(LoadDoctors()),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

// ─── Appointments Tab ─────────────────────────────────────
class _AppointmentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClinicHeader(title: 'مواعيدي', subtitle: 'جميع مواعيدك في مكان واحد'),
        Expanded(
          child: BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) {
              if (state is AppointmentsLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: 4,
                  itemBuilder: (_, __) => const ShimmerCard(height: 100),
                );
              }
              if (state is AppointmentsLoaded) {
                if (state.appointments.isEmpty) {
                  return EmptyState(
                    icon: Icons.calendar_today_outlined,
                    title: 'لا توجد مواعيد',
                    subtitle: 'احجز موعدك الأول مع أحد أطبائنا',
                    actionLabel: 'احجز الآن',
                    onAction: () =>
                        context.read<AppointmentsBloc>().add(LoadDoctors()),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  itemCount: state.appointments.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AppointmentCard(
                        appointment: state.appointments[i], showCancel: true),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }
}

// ─── Profile Tab ──────────────────────────────────────────
class _ProfileTab extends StatelessWidget {
  final dynamic user;
  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: AppColors.headerGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 42,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : 'م',
                            style: GoogleFonts.cairo(
                                fontSize: 32,
                                color: Colors.white,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: GoogleFonts.cairo(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        Text(
                          user.email,
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'مريض',
                            style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _ProfileMenuItem(
                icon: Icons.person_outline_rounded,
                label: 'معلومات الحساب',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'تغيير كلمة المرور',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.notifications_outlined,
                label: 'الإشعارات',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'المساعدة والدعم',
                onTap: () {},
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                    label: Text(
                      'تسجيل الخروج',
                      style: GoogleFonts.cairo(color: AppColors.error),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;
  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.bg,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final DoctorListModel doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primarySurface,
            child: Text(
              doctor.user.fullName.isNotEmpty
                  ? doctor.user.fullName.replaceAll('د. ', '')[0]
                  : 'د',
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.user.fullName,
                  style: GoogleFonts.cairo(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                if (doctor.specialty != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      doctor.specialty!.name,
                      style: GoogleFonts.cairo(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  '${doctor.consultationFee.toStringAsFixed(0)} ﷼ / كشفية',
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showBookingSheet(context, doctor),
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child:
                Text('احجز', style: GoogleFonts.cairo(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showBookingSheet(BuildContext ctx, DoctorListModel doctor) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: ctx.read<AppointmentsBloc>(),
        child: _BookingSheet(doctor: doctor),
      ),
    );
  }
}

class _BookingSheet extends StatefulWidget {
  final DoctorListModel doctor;
  const _BookingSheet({required this.doctor});

  @override
  State<_BookingSheet> createState() => _BookingSheetState();
}

class _BookingSheetState extends State<_BookingSheet> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentsBloc, AppointmentsState>(
      listener: (context, state) {
        if (state is AppointmentBooked) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم حجز الموعد بنجاح!',
                  style: GoogleFonts.cairo()),
              backgroundColor: AppColors.success,
            ),
          );
        } else if (state is AppointmentsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message, style: GoogleFonts.cairo()),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'حجز موعد',
              style: GoogleFonts.cairo(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'مع ${widget.doctor.user.fullName}',
              style: GoogleFonts.cairo(
                  fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),

            // Date picker
            GestureDetector(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 90)),
                  builder: (ctx, child) => Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primary,
                      ),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDate == null
                          ? 'اختر التاريخ'
                          : DateFormat('EEEE، d MMMM yyyy', 'ar')
                              .format(_selectedDate!),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: _selectedDate == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time picker
            GestureDetector(
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) setState(() => _selectedTime = time);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppColors.primary, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      _selectedTime == null
                          ? 'اختر الوقت'
                          : _selectedTime!.format(context),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        color: _selectedTime == null
                            ? AppColors.textHint
                            : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            BlocBuilder<AppointmentsBloc, AppointmentsState>(
              builder: (context, state) {
                final loading = state is AppointmentsActionLoading;
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : () {
                            if (_selectedDate == null || _selectedTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('يرجى اختيار التاريخ والوقت')),
                              );
                              return;
                            }
                            final dt = DateTime(
                              _selectedDate!.year,
                              _selectedDate!.month,
                              _selectedDate!.day,
                              _selectedTime!.hour,
                              _selectedTime!.minute,
                            );
                            context.read<AppointmentsBloc>().add(
                                  BookAppointment(
                                      doctorId: widget.doctor.id, date: dt),
                                );
                          },
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text('تأكيد الحجز'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  final bool showCancel;
  const _AppointmentCard(
      {required this.appointment, this.showCancel = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services_outlined,
                    color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment.doctor?.user?.fullName ?? 'طبيب',
                      style: GoogleFonts.cairo(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    Text(
                      appointment.doctor?.specialty?.name ?? '',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              StatusBadge(appointment.status),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('d MMM yyyy', 'ar').format(appointment.appointmentDate),
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                DateFormat('hh:mm a').format(appointment.appointmentDate),
                style: GoogleFonts.cairo(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const Spacer(),
              if (showCancel && appointment.canCancel)
                GestureDetector(
                  onTap: () {
                    context
                        .read<AppointmentsBloc>()
                        .add(CancelAppointment(appointment.id));
                  },
                  child: Text(
                    'إلغاء',
                    style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          if (appointment.doctorNotes != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.successSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.note_alt_outlined,
                      size: 14, color: AppColors.completed),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      appointment.doctorNotes!,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyAppointmentsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              color: AppColors.primary, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('لا توجد مواعيد قادمة',
                    style: GoogleFonts.cairo(
                        fontWeight: FontWeight.w700, color: AppColors.primary)),
                Text('احجز موعدك الأول مع أحد أطبائنا المتخصصين',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.primary.withOpacity(0.7))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileMenuItem(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        title: Text(label,
            style: GoogleFonts.cairo(
                fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right_rounded,
            color: AppColors.textHint),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

class _ClinicBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;
  const _ClinicBottomNav(
      {required this.currentIndex,
      required this.onTap,
      required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (i) => _NavTile(
                item: items[i],
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _NavTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;
  const _NavTile(
      {required this.item, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              color: isSelected ? AppColors.primary : AppColors.textHint,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: GoogleFonts.cairo(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w400,
                color: isSelected ? AppColors.primary : AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
