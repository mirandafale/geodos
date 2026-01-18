import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/contact_message.dart';
import 'package:geodos/models/news_item.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/contact_message_service.dart';
import 'package:geodos/services/news_service.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/widgets/app_shell.dart';
import 'package:geodos/widgets/coordinate_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: AppShell(
        title: const Text('Panel de administración'),
        actions: [
          const _AdminModeIndicator(),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: [
            const Tab(icon: Icon(Icons.work_outline), text: 'Proyectos'),
            const Tab(icon: Icon(Icons.article_outlined), text: 'Noticias'),
            const Tab(child: _ContactMessagesTabLabel()),
          ],
        ),
        body: const TabBarView(
          children: [
            _ProjectsTab(),
            _NewsTab(),
            _ContactMessagesTab(),
          ],
        ),
      ),
    );
  }
}

class _ProjectsTab extends StatefulWidget {
  const _ProjectsTab();

  @override
  State<_ProjectsTab> createState() => _ProjectsTabState();
}

class _ProjectsTabState extends State<_ProjectsTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Gestión de proyectos',
            subtitle: 'Administra los proyectos visibles en el visor.',
            action: FilledButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo proyecto'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<Project>>(
                  stream: ProjectService.stream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState(message: 'Cargando proyectos...');
                    }
                    final projects = (snapshot.data ?? [])
                      ..sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
                    if (projects.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.work_outline,
                        title: 'No hay proyectos registrados',
                        message: 'Crea el primer proyecto para mostrarlo en el visor.',
                      );
                    }
                    return ListView.separated(
                      itemCount: projects.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final p = projects[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          title: Text(p.title, style: theme.textTheme.titleMedium),
                          subtitle: Text(
                            '${p.municipality} · ${p.category} · ${p.scope.name.toUpperCase()}',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => _openForm(context, project: p),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                onPressed: () => _deleteProject(p),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProject(Project project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar proyecto'),
        content: Text('¿Seguro que deseas eliminar "${project.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ProjectService.deleteProject(project.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Proyecto "${project.title}" eliminado')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar el proyecto: $e')),
        );
      }
    }
  }

  Future<void> _openForm(BuildContext context, {Project? project}) async {
    final isEditing = project != null;
    final formKey = GlobalKey<FormState>();
    final data = project ?? ProjectService.emptyProject();

    final titleCtrl = TextEditingController(text: data.title);
    final categoryCtrl = TextEditingController(text: data.category);
    final scope = ValueNotifier<ProjectScope>(data.scope);
    final islandCtrl = TextEditingController(text: data.island);
    final municipalityCtrl = TextEditingController(text: data.municipality);
    final yearCtrl = TextEditingController(text: data.year?.toString() ?? '');
    final latCtrl =
        TextEditingController(text: data.lat == 0 ? '' : data.lat.toStringAsFixed(6));
    final lonCtrl =
        TextEditingController(text: data.lon == 0 ? '' : data.lon.toStringAsFixed(6));
    final descCtrl = TextEditingController(text: data.description ?? '');
    final enRedaccion = ValueNotifier<bool>(data.enRedaccion);
    final initialPoint =
        data.lat != 0 && data.lon != 0 ? LatLng(data.lat, data.lon) : null;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar proyecto' : 'Nuevo proyecto'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Título'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: categoryCtrl,
                          decoration: const InputDecoration(labelText: 'Categoría'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<ProjectScope>(
                          valueListenable: scope,
                          builder: (context, value, _) {
                            return DropdownButtonFormField<ProjectScope>(
                              value: value,
                              decoration: const InputDecoration(labelText: 'Ámbito'),
                              items: ProjectScope.values
                                  .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.name.toUpperCase()),
                                      ))
                                  .toList(),
                              onChanged: (v) => scope.value = v ?? ProjectScope.unknown,
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: islandCtrl,
                          decoration: const InputDecoration(labelText: 'Isla'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: municipalityCtrl,
                          decoration: const InputDecoration(labelText: 'Municipio'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: yearCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Año (opcional)'),
                        ),
                        const SizedBox(height: 8),
                        CoordinatePicker(
                          latCtrl: latCtrl,
                          lonCtrl: lonCtrl,
                          initialPoint: initialPoint,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: latCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Latitud',
                            helperText: 'Selecciona el punto en el mapa',
                          ),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Introduce una coordenada válida' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: lonCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Longitud',
                            helperText: 'Selecciona el punto en el mapa',
                          ),
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Introduce una coordenada válida' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(labelText: 'Descripción'),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable: enRedaccion,
                          builder: (context, value, _) {
                            return CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: value,
                              onChanged: (v) => enRedaccion.value = v ?? false,
                              title: const Text('En redacción'),
                              controlAffinity: ListTileControlAffinity.leading,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final projectUpdated = data.copyWith(
                  title: titleCtrl.text.trim(),
                  category: categoryCtrl.text.trim(),
                  scope: scope.value,
                  island: islandCtrl.text.trim(),
                  municipality: municipalityCtrl.text.trim(),
                  year: yearCtrl.text.trim().isEmpty ? null : int.tryParse(yearCtrl.text.trim()),
                  lat: double.parse(latCtrl.text.trim().replaceAll(',', '.')),
                  lon: double.parse(lonCtrl.text.trim().replaceAll(',', '.')),
                  description: descCtrl.text.trim(),
                  enRedaccion: enRedaccion.value,
                  createdAt: data.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                try {
                  if (isEditing) {
                    await ProjectService.updateProject(projectUpdated);
                  } else {
                    await ProjectService.createAdminProject(projectUpdated);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing
                            ? 'Proyecto actualizado'
                            : 'Proyecto creado'),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Guardar cambios' : 'Crear'),
            ),
          ],
        );
      },
    );
  }
}

class _AdminModeIndicator extends StatelessWidget {
  const _AdminModeIndicator();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final email = auth.user?.email ?? 'Usuario administrador';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Modo admin',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  email,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    'Edición habilitada',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewsTab extends StatefulWidget {
  const _NewsTab();

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Noticias',
            subtitle: 'Gestiona publicaciones y actualizaciones.',
            action: FilledButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva noticia'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<NewsItem>>(
                  stream: NewsService.publishedStream(includeDrafts: true),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState(message: 'Cargando noticias...');
                    }
                    final news = snapshot.data ?? [];
                    if (news.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.article_outlined,
                        title: 'Aún no hay noticias',
                        message: 'Publica la primera noticia para la web.',
                      );
                    }
                    return ListView.separated(
                      itemCount: news.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = news[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(item.imageUrl),
                          ),
                          title: Text(item.title),
                          subtitle:
                              Text(item.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                label: Text(item.published ? 'Publicada' : 'Borrador'),
                                backgroundColor: item.published
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                              ),
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => _openForm(context, item: item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                onPressed: () => _deleteNews(item),
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNews(NewsItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar noticia'),
        content: Text('¿Seguro que deseas eliminar "${item.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await NewsService.delete(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Noticia "${item.title}" eliminada')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar la noticia: $e')),
        );
      }
    }
  }

  Future<void> _openForm(BuildContext context, {NewsItem? item}) async {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final bodyCtrl = TextEditingController(text: item?.body ?? '');
    final imageUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');
    final published = ValueNotifier<bool>(item?.published ?? false);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar noticia' : 'Nueva noticia'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleCtrl,
                          decoration: const InputDecoration(labelText: 'Título'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: bodyCtrl,
                          decoration: const InputDecoration(labelText: 'Resumen / cuerpo'),
                          maxLines: 4,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: imageUrlCtrl,
                          decoration: const InputDecoration(labelText: 'URL de imagen'),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable: published,
                          builder: (context, value, _) {
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: value,
                              onChanged: (v) => published.value = v,
                              title: const Text('Publicada'),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final now = DateTime.now();
                final providedImageUrl = imageUrlCtrl.text.trim().isEmpty
                    ? 'https://images.pexels.com/photos/3184465/pexels-photo-3184465.jpeg?auto=compress&cs=tinysrgb&w=1200'
                    : imageUrlCtrl.text.trim();
                final news = NewsItem(
                  id: item?.id ?? '',
                  title: titleCtrl.text.trim(),
                  body: bodyCtrl.text.trim(),
                  summary: bodyCtrl.text.trim(),
                  imageUrl: providedImageUrl,
                  createdAt: item?.createdAt ?? now,
                  updatedAt: now,
                  published: published.value,
                );
                try {
                  if (isEditing) {
                    await NewsService.update(news);
                  } else {
                    await NewsService.create(news);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            isEditing ? 'Noticia actualizada' : 'Noticia creada'),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar la noticia: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Guardar cambios' : 'Crear'),
            ),
          ],
        );
      },
    );
  }
}

class _ContactMessagesTabLabel extends StatelessWidget {
  const _ContactMessagesTabLabel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: ContactMessageService.streamUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.mail_outline),
                if (unreadCount > 0)
                  Positioned(
                    right: -6,
                    top: -4,
                    child: _UnreadBadge(count: unreadCount),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            const Text('Mensajes'),
          ],
        );
      },
    );
  }
}

class _ContactMessagesTab extends StatefulWidget {
  const _ContactMessagesTab();

  @override
  State<_ContactMessagesTab> createState() => _ContactMessagesTabState();
}

class _ContactMessagesTabState extends State<_ContactMessagesTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _SectionHeader(
            title: 'Mensajes de contacto',
            subtitle: 'Gestiona los mensajes enviados desde el formulario.',
            action: SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<ContactMessage>>(
                  stream: ContactMessageService.streamAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState(message: 'Cargando mensajes...');
                    }
                    final messages = snapshot.data ?? [];
                    if (messages.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.mail_outline,
                        title: 'No hay mensajes nuevos',
                        message: 'Las consultas de contacto aparecerán aquí.',
                      );
                    }
                    return ListView.separated(
                      itemCount: messages.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final statusLabel = message.isRead ? 'Leído' : 'Sin leer';
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                          title: Text(message.name, style: Theme.of(context).textTheme.titleMedium),
                          subtitle: Text(
                            '${message.email} · ${_formatDate(context, message.createdAt)}',
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                label: Text(statusLabel),
                                backgroundColor: message.isRead
                                    ? Colors.green.shade100
                                    : Colors.orange.shade100,
                                labelStyle: TextStyle(
                                  color: message.isRead
                                      ? Colors.green.shade800
                                      : Colors.orange.shade800,
                                ),
                              ),
                              if (!message.isRead)
                                TextButton.icon(
                                  onPressed: () async {
                                    await ContactMessageService.markAsRead(message.id);
                                  },
                                  icon: const Icon(Icons.mark_email_read_outlined, size: 18),
                                  label: const Text('Marcar leído'),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return 'Sin fecha';
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatShortDate(date);
    final timeLabel = localizations.formatTimeOfDay(TimeOfDay.fromDateTime(date));
    return '$dateLabel · $timeLabel';
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayValue = count > 9 ? '9+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        displayValue,
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.action,
  });

  final String title;
  final String subtitle;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleLarge?.copyWith(
      color: Brand.ink,
      fontWeight: FontWeight.w700,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: Colors.blueGrey.shade700,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: headingStyle),
              const SizedBox(height: 4),
              Text(subtitle, style: subtitleStyle),
            ],
          ),
        ),
        const SizedBox(width: 16),
        action,
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.primary.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(message, style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}
