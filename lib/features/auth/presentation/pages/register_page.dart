import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../bloc/auth_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../../features/appointments/data/datasources/appointments_datasource.dart';
import '../../../../features/appointments/data/models/appointment_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _feeCtrl = TextEditingController();
  bool _obscure = true;
  String _role = 'patient';
  int? _selectedSpecialtyId;
  List<DoctorSpecialty> _specialties = [];
  bool _loadingSpecialties = false;

  @override
  void initState() {
    super.initState();
    _loadSpecialties();
  }

  Future<void> _loadSpecialties() async {
    setState(() => _loadingSpecialties = true);
    try {
      // Will be injected properly via DI in production
    } catch (_) {}
    setState(() => _loadingSpecialties = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_role == 'doctor' && _selectedSpecialtyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار التخصص')),
      );
      return;
    }
    context.read<AuthBloc>().add(AuthRegisterRequested(
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          role: _role,
          specialtyId: _role == 'doctor' ? _selectedSpecialtyId : null,
          consultationFee:
              _role == 'doctor' ? double.tryParse(_feeCtrl.text) : null,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            state.user.isDoctor
                ? context.go('/doctor/dashboard')
                : context.go('/patient/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),
                  // Back
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'إنشاء حساب جديد',
                    style: GoogleFonts.cairo(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'انضم إلى العيادة الذكية اليوم',
                    style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 28),

                  // Role Selector
                  _RoleSelector(
                    selected: _role,
                    onChanged: (r) => setState(() => _role = r),
                  ),
                  const SizedBox(height: 20),

                  ClinicTextField(
                    controller: _nameCtrl,
                    label: 'الاسم الكامل',
                    prefixIcon: Icons.person_outline_rounded,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 14),

                  ClinicTextField(
                    controller: _emailCtrl,
                    label: 'البريد الإلكتروني',
                    hint: 'example@email.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'البريد مطلوب';
                      if (!v.contains('@')) return 'بريد غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  ClinicTextField(
                    controller: _passCtrl,
                    label: 'كلمة المرور',
                    prefixIcon: Icons.lock_outline_rounded,
                    obscureText: _obscure,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                      if (v.length < 8) return '8 أحرف على الأقل';
                      return null;
                    },
                  ),

                  // Doctor-only fields
                  if (_role == 'doctor') ...[
                    const SizedBox(height: 14),
                    ClinicTextField(
                      controller: _feeCtrl,
                      label: 'سعر الكشفية (﷼)',
                      prefixIcon: Icons.monetization_on_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (_role != 'doctor') return null;
                        if (v == null || v.isEmpty) return 'سعر الكشفية مطلوب';
                        if (double.tryParse(v) == null) return 'رقم غير صالح';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _SpecialtyDropdown(
                      selectedId: _selectedSpecialtyId,
                      onChanged: (id) => setState(() => _selectedSpecialtyId = id),
                    ),
                  ],

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: state is AuthLoading ? null : _submit,
                      child: state is AuthLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text('إنشاء الحساب'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب؟ ',
                        style: GoogleFonts.cairo(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/login'),
                        child: Text(
                          'تسجيل الدخول',
                          style: GoogleFonts.cairo(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoleSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _RoleSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _RoleTab(
            label: 'مريض',
            icon: Icons.personal_injury_outlined,
            isSelected: selected == 'patient',
            onTap: () => onChanged('patient'),
          ),
          _RoleTab(
            label: 'طبيب',
            icon: Icons.medical_services_outlined,
            isSelected: selected == 'doctor',
            onTap: () => onChanged('doctor'),
          ),
        ],
      ),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  const _RoleTab(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpecialtyDropdown extends StatefulWidget {
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  const _SpecialtyDropdown({this.selectedId, required this.onChanged});

  @override
  State<_SpecialtyDropdown> createState() => _SpecialtyDropdownState();
}

class _SpecialtyDropdownState extends State<_SpecialtyDropdown> {
  // Hardcoded for now; in production fetch from API
  final _items = const [
    {'id': 1, 'name': 'أطفال'},
    {'id': 2, 'name': 'قلبية'},
    {'id': 3, 'name': 'أسنان'},
    {'id': 4, 'name': 'عيون'},
    {'id': 5, 'name': 'عامة'},
  ];

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: widget.selectedId,
      decoration: InputDecoration(
        labelText: 'التخصص',
        prefixIcon: const Icon(Icons.category_outlined, size: 20),
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      hint: Text(
        'اختر التخصص',
        style: GoogleFonts.cairo(color: AppColors.textHint, fontSize: 14),
      ),
      items: _items
          .map((s) => DropdownMenuItem<int>(
                value: s['id'] as int,
                child: Text(
                  s['name'] as String,
                  style: GoogleFonts.cairo(fontSize: 14),
                ),
              ))
          .toList(),
      onChanged: widget.onChanged,
    );
  }
}
