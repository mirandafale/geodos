// lib/pages/admin_dashboard_page.dart
import 'package:flutter/material.dart';
import 'package:geodos/services/auth_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showInfo(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = AuthService.instance;
    final email = auth.user?.email ?? '—';
    final isAdmin = auth.isAdmin;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de control'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(114),
          child: Column(
            children: [
              // Banner “Modo Administrador”
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isAdmin
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isAdmin
                          ? Colors.green.withOpacity(0.35)
                          : Colors.orange.withOpacity(0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isAdmin ? Icons.admin_panel_settings : Icons.lock_outline,
                        color: isAdmin ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isAdmin ? 'MODO ADMINISTRADOR' : 'SESIÓN SIN ROL ADMIN',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Usuario: $email',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await AuthService.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushReplacementNamed(context, '/');
                        },
                        child: const Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                ),
              ),

              // Tabs con contraste claro
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.primary.withOpacity(0.12),
                    ),
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.8),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.folder_open),
                        text: 'Proyectos',
                      ),
                      Tab(
                        icon: Icon(Icons.article),
                        text: 'Noticias',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _ProjectsTab(onInfo: _showInfo),
          _NewsTab(onInfo: _showInfo),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final idx = _tabController.index;
          if (idx == 0) {
            _showInfo('Acción: Nuevo proyecto (conectar a tu CRUD real)');
          } else {
            _showInfo('Acción: Nueva noticia (conectar a tu CRUD real)');
          }
        },
        icon: const Icon(Icons.add),
        label: AnimatedBuilder(
          animation: _tabController,
          builder: (_, __) => Text(_tabController.index == 0 ? 'Nuevo proyecto' : 'Nueva noticia'),
        ),
      ),
    );
  }
}

class _ProjectsTab extends StatelessWidget {
  final void Function(String) onInfo;
  const _ProjectsTab({required this.onInfo});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gestión de Proyectos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aquí irá el CRUD real de proyectos. Ahora mismo dejamos el panel estable (solo UX) para no romper tu visor ni tu carrusel.',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onInfo('Pendiente: conectar a ProjectService real'),
          icon: const Icon(Icons.build),
          label: const Text('Conectar CRUD de Proyectos'),
        ),
      ],
    );
  }
}

class _NewsTab extends StatelessWidget {
  final void Function(String) onInfo;
  const _NewsTab({required this.onInfo});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Gestión de Noticias',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        const Text(
          'Aquí irá el CRUD real de noticias. Mantendremos la UI profesional y luego la conectamos a tu NewsService existente (el que ya alimenta el carrusel).',
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => onInfo('Pendiente: conectar a NewsService real'),
          icon: const Icon(Icons.build),
          label: const Text('Conectar CRUD de Noticias'),
        ),
      ],
    );
  }
}
