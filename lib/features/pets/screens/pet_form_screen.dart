import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/pets_provider.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../shared/models/pet.dart';
import '../../../core/theme/app_theme.dart';

class PetFormScreen extends ConsumerStatefulWidget {
  final String? petId;
  const PetFormScreen({super.key, this.petId});

  @override
  ConsumerState<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends ConsumerState<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _raza = TextEditingController();
  final _edad = TextEditingController();
  final _fechaNacimiento = TextEditingController();
  final _peso = TextEditingController();
  String _especie = 'Perro';
  String? _sexo;
  Pet? _loadedPet;
  bool _saving = false;
  bool _loading = false;

  static const _especies = ['Perro', 'Gato', 'Ave', 'Conejo', 'Hamster', 'Otro'];

  bool get _isEdit => widget.petId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pet = await ref.read(petRepositoryProvider).get(widget.petId!);
      _loadedPet = pet;
      _nombre.text = pet.nombre;

      final loadedEsp = pet.especie.trim();
      _especie = _especies.firstWhere(
        (e) => e.toLowerCase() == loadedEsp.toLowerCase(),
        orElse: () => _especies.firstWhere(
          (e) => loadedEsp.toLowerCase().contains(e.toLowerCase()),
          orElse: () => 'Otro',
        ),
      );
      _raza.text = pet.raza ?? '';
      _edad.text = pet.edad ?? '';
      _fechaNacimiento.text = (pet.fechaNacimiento != null &&
              pet.fechaNacimiento != '0000-00-00' &&
              pet.fechaNacimiento!.isNotEmpty)
          ? pet.fechaNacimiento!
          : '';
      _peso.text = pet.peso != null && pet.peso! > 0 ? pet.peso.toString() : '';

      if (pet.sexo != null && pet.sexo!.trim().isNotEmpty) {
        final s = pet.sexo!.trim().toLowerCase();
        if (s == 'm' || s.startsWith('mach')) {
          _sexo = 'Macho';
        } else if (s == 'f' || s == 'h' || s.startsWith('hemb')) {
          _sexo = 'Hembra';
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos cargar los datos de la mascota. Por favor intenta nuevamente.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _raza.dispose();
    _edad.dispose();
    _fechaNacimiento.dispose();
    _peso.dispose();
    super.dispose();
  }

  Future<void> _selectFechaNacimiento() async {
    final now = DateTime.now();
    DateTime initial = now;
    if (_fechaNacimiento.text.trim().isNotEmpty) {
      initial = DateTime.tryParse(_fechaNacimiento.text.trim()) ?? now;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Seleccionar fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked != null) {
      final formatted =
          "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      setState(() => _fechaNacimiento.text = formatted);
    }
  }

  Future<void> _submit(bool canEditAll) async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);

    // Si es cliente editando, preserva los valores clínicos originales de la mascota
    final pet = Pet(
      id: widget.petId ?? '',
      nombre: _nombre.text.trim(),
      especie: canEditAll ? _especie : (_loadedPet?.especie ?? _especie),
      raza: canEditAll
          ? (_raza.text.trim().isEmpty ? null : _raza.text.trim())
          : _loadedPet?.raza,
      edad: canEditAll
          ? (_edad.text.trim().isEmpty ? null : _edad.text.trim())
          : _loadedPet?.edad,
      fechaNacimiento: canEditAll
          ? (_fechaNacimiento.text.trim().isEmpty ? null : _fechaNacimiento.text.trim())
          : _loadedPet?.fechaNacimiento,
      sexo: canEditAll ? _sexo : _loadedPet?.sexo,
      peso: canEditAll ? double.tryParse(_peso.text.trim()) : _loadedPet?.peso,
      foto: _loadedPet?.foto,
    );

    try {
      final repo = ref.read(petRepositoryProvider);
      if (_isEdit) {
        await repo.update(widget.petId!, pet);
      } else {
        await repo.create(pet);
      }
      ref.invalidate(petsListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(_isEdit ? 'Mascota actualizada con éxito' : 'Mascota creada con éxito'),
              ],
            ),
            backgroundColor: AppTheme.tertiary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/pets');
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No pudimos guardar los cambios. Por favor verifica los datos e intenta nuevamente.'),
            backgroundColor: AppTheme.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = ref.watch(authProvider);
    final isCliente = (auth.role ?? 'CLIENTE').toUpperCase() == 'CLIENTE';
    final canEditAll = !_isEdit || !isCliente;

    final (emoji, colors) = PetSpeciesHelper.getStyle(_especie);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'Editar Mascota' : 'Nueva Mascota')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/pets'),
        ),
        title: Text(_isEdit ? 'Editar Mascota' : 'Nueva Mascota'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
            physics: const BouncingScrollPhysics(),
            children: [
              // Live Avatar Preview Card with Pet Photo or Species Emoji
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _loadedPet?.fullImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                _loadedPet!.fullImageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Text(emoji, style: const TextStyle(fontSize: 30)),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(emoji, style: const TextStyle(fontSize: 30)),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _nombre.text.trim().isEmpty
                                ? (_isEdit ? 'Mascota' : 'Nombre de la mascota')
                                : _nombre.text.trim(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_especie${_raza.text.trim().isNotEmpty ? ' · ${_raza.text.trim()}' : ''}',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Cliente Notification Banner (restringe edición de campos médicos)
              if (_isEdit && isCliente) ...[
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Como propietario puedes actualizar el nombre de tu mascota. Las características clínicas (especie, raza, sexo y peso) son administradas por tu veterinario.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Section 1: Identificación
              _SectionHeader(title: 'Identificación', icon: Icons.badge_outlined, isDark: isDark),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nombre,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'Nombre de la mascota *',
                  prefixIcon: Icon(Icons.pets_outlined),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _especie,
                decoration: InputDecoration(
                  labelText: 'Especie *',
                  prefixIcon: const Icon(Icons.category_outlined),
                  enabled: canEditAll,
                ),
                items: _especies
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: canEditAll
                    ? (v) {
                        if (v != null) setState(() => _especie = v);
                      }
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _raza,
                enabled: canEditAll,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Raza',
                  prefixIcon: const Icon(Icons.fingerprint_rounded),
                  helperText: !canEditAll ? 'Solo modificable por veterinarios' : null,
                ),
              ),

              const SizedBox(height: 26),

              // Section 2: Características Físicas
              _SectionHeader(title: 'Características Físicas', icon: Icons.health_and_safety_outlined, isDark: isDark),
              const SizedBox(height: 12),

              // Sex Selection Chips
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sexo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _SexChoiceButton(
                          title: 'Macho',
                          icon: Icons.male_rounded,
                          color: const Color(0xFF0284C7),
                          isSelected: _sexo == 'Macho',
                          isEnabled: canEditAll,
                          onTap: canEditAll
                              ? () => setState(() => _sexo = _sexo == 'Macho' ? null : 'Macho')
                              : () {},
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SexChoiceButton(
                          title: 'Hembra',
                          icon: Icons.female_rounded,
                          color: const Color(0xFFDB2777),
                          isSelected: _sexo == 'Hembra',
                          isEnabled: canEditAll,
                          onTap: canEditAll
                              ? () => setState(() => _sexo = _sexo == 'Hembra' ? null : 'Hembra')
                              : () {},
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _edad,
                enabled: canEditAll,
                decoration: InputDecoration(
                  labelText: 'Edad (ej: 2 años)',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  helperText: !canEditAll ? 'Solo modificable por veterinarios' : null,
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _fechaNacimiento,
                readOnly: true,
                enabled: canEditAll,
                onTap: canEditAll ? _selectFechaNacimiento : null,
                decoration: InputDecoration(
                  labelText: 'Fecha de nacimiento',
                  prefixIcon: const Icon(Icons.calendar_month_outlined),
                  suffixIcon: canEditAll && _fechaNacimiento.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _fechaNacimiento.clear()),
                        )
                      : const Icon(Icons.edit_calendar_rounded, size: 20),
                  helperText: !canEditAll ? 'Solo modificable por veterinarios' : null,
                ),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _peso,
                enabled: canEditAll,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Peso aproximado (kg)',
                  prefixIcon: const Icon(Icons.scale_outlined),
                  suffixText: 'kg',
                  helperText: !canEditAll ? 'Solo modificable por veterinarios' : null,
                ),
              ),

              const SizedBox(height: 32),

              // Submit Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: FilledButton(
                  onPressed: _saving ? null : () => _submit(canEditAll),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(_isEdit ? Icons.check_circle_rounded : Icons.save_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(_isEdit ? 'Guardar Cambios' : 'Registrar Mascota'),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const _SectionHeader({required this.title, required this.icon, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _SexChoiceButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final bool isDark;

  const _SexChoiceButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.isEnabled = true,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.65,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.12)
                  : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 20, color: isSelected ? color : const Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? color : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
