import 'package:flutter/material.dart';
import 'package:geodos/models/carousel_item.dart';
import 'package:geodos/models/news_item.dart';
import 'package:geodos/models/project.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/carousel_service.dart';
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
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthService>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.work_outline), text: 'Proyectos'),
            Tab(icon: Icon(Icons.view_carousel_outlined), text: 'Carrusel'),
            Tab(icon: Icon(Icons.article_outlined), text: 'Noticias'),
          ],
        ),
        body: const TabBarView(
          children: [
            _ProjectsTab(),
            _CarouselTab(),
            _NewsTab(),
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

class _CarouselTab extends StatefulWidget {
  const _CarouselTab();

  @override
  State<_CarouselTab> createState() => _CarouselTabState();
}

class _CarouselTabState extends State<_CarouselTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionHeader(
            title: 'Carrusel',
            subtitle: 'Destaca contenido clave en la portada.',
            action: FilledButton.icon(
              onPressed: () => _openForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Nuevo slide'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: StreamBuilder<List<CarouselItem>>(
                  stream: CarouselService.streamAll(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const _LoadingState(message: 'Cargando slides...');
                    }
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return const _EmptyState(
                        icon: Icons.view_carousel_outlined,
                        title: 'Aún no hay elementos en el carrusel',
                        message: 'Añade un slide para destacar contenido en la portada.',
                      );
                    }
                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              height: 48,
                              width: 64,
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade200,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.broken_image_outlined, size: 20),
                                  );
                                },
                              ),
                            ),
                          ),
                          title: Text(item.title?.isNotEmpty == true ? item.title! : 'Sin título'),
                          subtitle:
                              Text('Orden: ${item.order}${item.linkUrl == null ? '' : ' · ${item.linkUrl}'}'),
                          trailing: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Activo', style: TextStyle(fontSize: 12)),
                                  Switch(
                                    value: item.isActive,
                                    onChanged: (value) async {
                                      await CarouselService.update(
                                        item.copyWith(isActive: value, updatedAt: DateTime.now()),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              IconButton(
                                tooltip: 'Editar',
                                onPressed: () => _openForm(context, item: item),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Eliminar',
                                onPressed: () => _deleteItem(item),
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

  Future<void> _deleteItem(CarouselItem item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar slide'),
        content: Text('¿Seguro que deseas eliminar el slide "${item.title ?? 'Sin título'}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await CarouselService.delete(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slide eliminado')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar el slide: $e')),
        );
      }
    }
  }

  Future<void> _openForm(BuildContext context, {CarouselItem? item}) async {
    final isEditing = item != null;
    final formKey = GlobalKey<FormState>();
    final titleCtrl = TextEditingController(text: item?.title ?? '');
    final imageUrlCtrl = TextEditingController(text: item?.imageUrl ?? '');
    final linkUrlCtrl = TextEditingController(text: item?.linkUrl ?? '');
    final orderCtrl = TextEditingController(text: item?.order.toString() ?? '0');
    final isActive = ValueNotifier<bool>(item?.isActive ?? true);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Editar slide' : 'Nuevo slide'),
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
                          decoration: const InputDecoration(labelText: 'Título (opcional)'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: imageUrlCtrl,
                          decoration: const InputDecoration(labelText: 'URL de imagen'),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Campo obligatorio' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: linkUrlCtrl,
                          decoration: const InputDecoration(labelText: 'URL de destino (opcional)'),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: orderCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Orden'),
                          validator: (v) =>
                              int.tryParse(v ?? '') == null ? 'Introduce un número válido' : null,
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<bool>(
                          valueListenable: isActive,
                          builder: (context, value, _) {
                            return SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              value: value,
                              onChanged: (v) => isActive.value = v,
                              title: const Text('Activo'),
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
                final updated = CarouselItem(
                  id: item?.id ?? '',
                  title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
                  imageUrl: imageUrlCtrl.text.trim(),
                  linkUrl: linkUrlCtrl.text.trim().isEmpty ? null : linkUrlCtrl.text.trim(),
                  isActive: isActive.value,
                  order: int.parse(orderCtrl.text.trim()),
                  createdAt: item?.createdAt ?? now,
                  updatedAt: now,
                );
                try {
                  if (isEditing) {
                    await CarouselService.update(updated);
                  } else {
                    await CarouselService.create(updated);
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEditing ? 'Slide actualizado' : 'Slide creado'),
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
                  stream: NewsService.stream(),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
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
