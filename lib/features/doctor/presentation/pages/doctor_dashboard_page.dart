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

class DoctorDashboardPage extends StatefulWidget {
  const DoctorDashboardPage({super.key});
  @override
  State<DoctorDashboardPage> createState() => _DoctorDashboardPageState();
}

class _DoctorDashboardPageState extends State<DoctorDashboardPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<AppointmentsBloc>().add(LoadTodayAppointments());
  }

  @override
  Widget build(BuildContext context) {
    final user = (context.read<AuthBloc>().state as AuthAuthenticated).user;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _DoctorHomeTab(doctorName: user.fullName),
          _AllAppointmentsTab(),
          _DoctorProfileTab(user: user),
        ],
      ),
      bottomNavigationBar: _DoctorBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          setState(() => _currentIndex = i);
          if (i == 0) context.read<AppointmentsBloc>().add(LoadTodayAppointments());
          if (i == 1) context.read<AppointmentsBloc>().add(LoadDoctorAppointments());
        },
      ),
    );
  }
}

// ─── Home Tab ─────────────────────────────────────────────
class _DoctorHomeTab extends StatelessWidget {
  final String doctorName;
  const _DoctorHomeTab({required this.doctorName});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = now.hour < 12
        ? 'صباح الخير'
        : now.hour < 17
            ? 'مساء الخير'
            : 'مساء النور';

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ClinicHeader(
            title: '$greeting، ${doctorName.replaceAll('د. ', '')}',
            subtitle: DateFormat('EEEE، d MMMM yyyy', 'ar').format(now),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // Stats row
        BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, state) {
            int total = 0, pending = 0, completed = 0;
            if (state is AppointmentsLoaded) {
              total = state.appointments.length;
              pending = state.appointments.where((a) => a.isPending).length;
              completed = state.appointments.where((a) => a.isCompleted).length;
            }
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label: 'مواعيد اليوم',
                        value: '$total',
                        icon: Icons.calendar_today_rounded,
                        color: AppColors.primary,
                        bgColor: AppColors.primarySurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'قيد الانتظار',
                        value: '$pending',
                        icon: Icons.hourglass_empty_rounded,
                        color: AppColors.pending,
                        bgColor: AppColors.warningSurface,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        label: 'مكتملة',
                        value: '$completed',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.completed,
                        bgColor: AppColors.successSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // Today's appointments
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text(
              'مواعيد اليوم',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),

        BlocBuilder<AppointmentsBloc, AppointmentsState>(
          builder: (context, state) {
            if (state is AppointmentsLoading) {
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const ShimmerCard(height: 130),
                    const ShimmerCard(height: 130),
                    const ShimmerCard(height: 130),
                  ]),
                ),
              );
            }
            if (state is AppointmentsLoaded) {
              if (state.appointments.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: EmptyState(
                      icon: Icons.event_available_rounded,
                      title: 'لا توجد مواعيد اليوم',
                      subtitle: 'استرح قليلاً — لا مواعيد مجدولة لهذا اليوم',
                    ),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DoctorAppointmentCard(
                          appointment: state.appointments[i]),
                    ),
                    childCount: state.appointments.length,
                  ),
                ),
              );
            }
            return const SliverToBoxAdapter(child: SizedBox());
          },
        ),
      ],
    );
  }
}

// ─── All Appointments Tab ─────────────────────────────────
class _AllAppointmentsTab extends StatefulWidget {
  @override
  State<_AllAppointmentsTab> createState() => _AllAppointmentsTabState();
}

class _AllAppointmentsTabState extends State<_AllAppointmentsTab> {
  String? _filterStatus;

  final _filters = [
    {'label': 'الكل', 'value': null},
    {'label': 'انتظار', 'value': 'pending'},
    {'label': 'مؤكد', 'value': 'confirmed'},
    {'label': 'مكتمل', 'value': 'completed'},
    {'label': 'ملغي', 'value': 'cancelled'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClinicHeader(title: 'جميع المواعيد', subtitle: 'إدارة مواعيد مرضاك'),
        // Filter chips
        SizedBox(
          height: 52,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: _filters.length,
            itemBuilder: (ctx, i) {
              final f = _filters[i];
              final selected = _filterStatus == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _filterStatus = f['value'] as String?);
                    context.read<AppointmentsBloc>().add(
                          LoadDoctorAppointments(status: _filterStatus),
                        );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    child: Text(
                      f['label'] as String,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: BlocBuilder<AppointmentsBloc, AppointmentsState>(
            builder: (context, state) {
              if (state is AppointmentsLoading) {
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: 4,
                  itemBuilder: (_, __) => const ShimmerCard(height: 130),
                );
              }
              if (state is AppointmentsLoaded) {
                if (state.appointments.isEmpty) {
                  return EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'لا توجد مواعيد',
                    subtitle: 'لا توجد مواعيد مطابقة للفلتر المحدد',
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  itemCount: state.appointments.length,
                  itemBuilder: (ctx, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoctorAppointmentCard(
                        appointment: state.appointments[i]),
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

// ─── Doctor Appointment Card ──────────────────────────────
class _DoctorAppointmentCard extends StatelessWidget {
  final AppointmentModel appointment;
  const _DoctorAppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primarySurface,
                      child: Text(
                        (appointment.patient?.fullName ?? 'م')[0],
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.patient?.fullName ?? 'مريض',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            appointment.patient?.email ?? '',
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(appointment.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('d MMM - hh:mm a').format(appointment.appointmentDate),
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Action buttons
          if (!appointment.isCompleted && !appointment.isCancelled) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (appointment.isPending)
                    Expanded(
                      child: _ActionBtn(
                        label: 'تأكيد',
                        icon: Icons.check_circle_outline_rounded,
                        color: AppColors.confirmed,
                        onTap: () => _updateStatus(context, 'confirmed'),
                      ),
                    ),
                  if (appointment.isPending) const SizedBox(width: 8),
                  if (appointment.isConfirmed)
                    Expanded(
                      child: _ActionBtn(
                        label: 'إتمام الكشف',
                        icon: Icons.medical_services_outlined,
                        color: AppColors.completed,
                        onTap: () => _showNotesSheet(context),
                      ),
                    ),
                  if (appointment.isConfirmed) const SizedBox(width: 8),
                  Expanded(
                    child: _ActionBtn(
                      label: 'إلغاء',
                      icon: Icons.cancel_outlined,
                      color: AppColors.error,
                      onTap: () => _updateStatus(context, 'cancelled'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (appointment.doctorNotes != null) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
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
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
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

  void _updateStatus(BuildContext context, String status) {
    context.read<AppointmentsBloc>().add(UpdateAppointmentStatus(
          appointmentId: appointment.id,
          status: status,
        ));
  }

  void _showNotesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AppointmentsBloc>(),
        child: _NotesSheet(appointmentId: appointment.id),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesSheet extends StatefulWidget {
  final int appointmentId;
  const _NotesSheet({required this.appointmentId});

  @override
  State<_NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<_NotesSheet> {
  final _notesCtrl = TextEditingController();

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppointmentsBloc, AppointmentsState>(
      listener: (context, state) {
        if (state is AppointmentUpdated) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم إتمام الكشف بنجاح',
                  style: GoogleFonts.cairo()),
              backgroundColor: AppColors.success,
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
              'إتمام الكشف',
              style: GoogleFonts.cairo(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'أضف ملاحظاتك الطبية للمريض',
              style: GoogleFonts.cairo(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 5,
              style: GoogleFonts.cairo(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'الوصفة الطبية والملاحظات...',
                hintStyle: GoogleFonts.cairo(
                    color: AppColors.textHint, fontSize: 13),
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.border, width: 1.2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                            context.read<AppointmentsBloc>().add(
                                  UpdateAppointmentStatus(
                                    appointmentId: widget.appointmentId,
                                    status: 'completed',
                                    notes: _notesCtrl.text.trim(),
                                  ),
                                );
                          },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.completed),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline_rounded,
                                  size: 18),
                              const SizedBox(width: 8),
                              Text('إتمام الكشف',
                                  style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.w700)),
                            ],
                          ),
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

// ─── Doctor Profile Tab ───────────────────────────────────
class _DoctorProfileTab extends StatelessWidget {
  final dynamic user;
  const _DoctorProfileTab({required this.user});

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
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              child: Text(
                                user.fullName.isNotEmpty
                                    ? user.fullName
                                        .replaceAll('د. ', '')[0]
                                        .toUpperCase()
                                    : 'د',
                                style: GoogleFonts.cairo(
                                  fontSize: 34,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.medical_services_rounded,
                                    size: 14,
                                    color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          user.fullName,
                          style: GoogleFonts.cairo(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user.email,
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: Colors.white70),
                        ),
                        if (user.doctor?.specialty != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user.doctor!.specialty!.name,
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              if (user.doctor != null) ...[
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.accentSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_outlined,
                            color: AppColors.accent, size: 24),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'سعر الكشفية',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            Text(
                              '${user.doctor!.consultationFee.toStringAsFixed(0)} ﷼',
                              style: GoogleFonts.cairo(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _ProfileMenuItem(
                icon: Icons.lock_outline_rounded,
                label: 'تغيير كلمة المرور',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.schedule_rounded,
                label: 'ساعات الدوام',
                onTap: () {},
              ),
              _ProfileMenuItem(
                icon: Icons.help_outline_rounded,
                label: 'المساعدة',
                onTap: () {},
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                      context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    label: Text('تسجيل الخروج',
                        style: GoogleFonts.cairo(color: AppColors.error)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: AppColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

class _DoctorBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _DoctorBottomNav(
      {required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': Icons.dashboard_rounded, 'label': 'لوحة التحكم'},
      {'icon': Icons.calendar_month_rounded, 'label': 'المواعيد'},
      {'icon': Icons.person_rounded, 'label': 'حسابي'},
    ];
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
              (i) {
                final item = items[i];
                final selected = currentIndex == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primarySurface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          color: selected
                              ? AppColors.primary
                              : AppColors.textHint,
                          size: 22,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['label'] as String,
                          style: GoogleFonts.cairo(
                            fontSize: 10,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
