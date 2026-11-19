import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_provider.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '¡Buenos días! ☀️';
    if (hour < 19) return '¡Buenas tardes! 🌤️';
    return '¡Buenas noches! 🌙';
  }

  Color _getRoleColor(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return AppTheme.accent;
      case 'VETERINARIO':
        return AppTheme.tertiary;
      case 'EMPLEADO':
        return AppTheme.primary;
      case 'CLIENTE':
      default:
        return AppTheme.secondary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings_rounded;
      case 'VETERINARIO':
        return Icons.medical_services_rounded;
      case 'EMPLEADO':
        return Icons.badge_rounded;
      case 'CLIENTE':
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.role ?? 'CLIENTE';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roleColor = _getRoleColor(role);

    final cards = <_DashModule>[
      _DashModule(
        title: 'Mascotas',
        subtitle: 'Fichas y pacientes',
        icon: Icons.pets_rounded,
        gradient: const [Color(0xFF10B981), Color(0xFF06B6D4)],
        route: '/pets',
        roles: ['ADMIN', 'VETERINARIO', 'CLIENTE'],
        isAvailable: true,
      ),
      _DashModule(
        title: 'Citas',
        subtitle: 'Agenda y reservas',
        icon: Icons.calendar_month_rounded,
        gradient: const [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        route: null,
        roles: ['ADMIN', 'VETERINARIO', 'EMPLEADO', 'CLIENTE'],
        isAvailable: false,
      ),
      _DashModule(
        title: 'Vacunas',
        subtitle: 'Control de dosis',
        icon: Icons.vaccines_rounded,
        gradient: const [Color(0xFFEC4899), Color(0xFFF43F5E)],
        route: null,
        roles: ['ADMIN', 'VETERINARIO', 'CLIENTE'],
        isAvailable: false,
      ),
      _DashModule(
        title: 'Productos',
        subtitle: 'Inventario y stock',
        icon: Icons.inventory_2_rounded,
        gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        route: null,
        roles: ['ADMIN', 'EMPLEADO'],
        isAvailable: false,
      ),
      _DashModule(
        title: 'Ventas',
        subtitle: 'Facturación directa',
        icon: Icons.point_of_sale_rounded,
        gradient: const [Color(0xFF0EA5E9), Color(0xFF0284C7)],
        route: null,
        roles: ['ADMIN', 'EMPLEADO'],
        isAvailable: false,
      ),
      _DashModule(
        title: 'Reportes',
        subtitle: 'Métricas e ingresos',
        icon: Icons.bar_chart_rounded,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        route: null,
        roles: ['ADMIN', 'VETERINARIO'],
        isAvailable: false,
      ),
    ].where((c) => c.roles.contains(role.toUpperCase())).toList();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'VetCare Mobile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),

                    // Role Badge & Logout
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: roleColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: roleColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_getRoleIcon(role), size: 14, color: roleColor),
                              const SizedBox(width: 6),
                              Text(
                                role,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: roleColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            foregroundColor: AppTheme.rose,
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 20),
                          tooltip: 'Cerrar sesión',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Cerrar sesión'),
                                content: const Text('¿Seguro que deseas cerrar sesión?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  FilledButton(
                                    style: FilledButton.styleFrom(backgroundColor: AppTheme.rose),
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Cerrar sesión'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await ref.read(authProvider.notifier).logout();
                              if (context.mounted) context.go('/login');
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Hero Welcome Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF6366F1), Color(0xFF06B6D4)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🐾 BIENVENIDO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Cuidado y atención veterinaria',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Accede al historial de tus pacientes y servicios en un toque.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.medical_information_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Modules Section Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Servicios y Accesos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      '${cards.length} disponibles',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grid of Modules
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.95,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = cards[index];
                    return _ModuleCard(module: item, isDark: isDark);
                  },
                  childCount: cards.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashModule {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final String? route;
  final List<String> roles;
  final bool isAvailable;

  _DashModule({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.roles,
    required this.isAvailable,
  });
}

class _ModuleCard extends StatelessWidget {
  final _DashModule module;
  final bool isDark;

  const _ModuleCard({required this.module, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (module.route != null) {
            context.go(module.route!);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text('${module.title} se habilitará en la próxima actualización.')),
                  ],
                ),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.cardDark : AppTheme.cardLight,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top Icon & Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: module.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: module.gradient.first.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(module.icon, color: Colors.white, size: 26),
                    ),
                    if (module.isAvailable)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.tertiary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Activo',
                          style: TextStyle(
                            color: AppTheme.tertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Pronto',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),

                // Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      module.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
