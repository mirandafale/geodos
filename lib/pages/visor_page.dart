// visor_page.dart corregido para que compile y funcione con filtros avanzados y visor de proyectos

import 'package:flutter/material.dart';
import 'package:geodos/services/filters_controller.dart';
import 'package:geodos/services/project_service.dart';
import 'package:geodos/widgets/contact_form.dart';
import 'package:geodos/widgets/visor_embed.dart';

class VisorPage extends StatefulWidget {
  const VisorPage({super.key});

  @override
  State<VisorPage> createState() => _VisorPageState();
}

class _VisorPageState extends State<VisorPage> {
  final filters = FiltersController.instance;
  late Future<List<int>> _yearsFuture;
  late Future<List<String>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _yearsFuture = ProjectService.getYears();
    _categoriesFuture = ProjectService.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Proyectos Georreferenciados'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: AnimatedBuilder(
                animation: filters,
                builder: (context, _) {
                  final st = filters.state;
                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      // Campo de búsqueda
                      SizedBox(
                        width: 260,
                        child: TextFormField(
                          decoration: const InputDecoration(
                            labelText: 'Buscar por título',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.search),
                          ),
                          initialValue: st.search,
                          onChanged: filters.setSearch,
                        ),
                      ),

                      // Categoría
                      SizedBox(
                        width: 260,
                        child: FutureBuilder<List<String>>(
                          future: _categoriesFuture,
                          builder: (context, snapshot) {
                            final categories = snapshot.data ?? [];
                            return DropdownButtonFormField<String>(
                              value: st.scope,
                              decoration: const InputDecoration(
                                labelText: 'Categoría',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: 'Todos',
                                  child: Text('Todas'),
                                ),
                                ...categories.map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                              ],
                              onChanged: filters.setScope,
                            );
                          },
                        ),
                      ),

                      // Año
                      SizedBox(
                        width: 160,
                        child: FutureBuilder<List<int>>(
                          future: _yearsFuture,
                          builder: (context, snapshot) {
                            final years = snapshot.data ?? [];
                            return DropdownButtonFormField<int?>(
                              value: st.year,
                              decoration: const InputDecoration(
                                labelText: 'Año',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Todos los años'),
                                ),
                                ...years.map(
                                  (y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(y.toString()),
                                  ),
                                ),
                              ],
                              onChanged: filters.setYear,
                            );
                          },
                        ),
                      ),

                      // Botón de reinicio
                      ElevatedButton.icon(
                        onPressed: filters.reset,
                        icon: const Icon(Icons.clear),
                        label: const Text('Limpiar filtros'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Divider(),

            // Visor de proyectos con filtros aplicados
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: VisorEmbed(startExpanded: true),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                margin: const EdgeInsets.only(top: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '¿Quieres más información?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Completa el formulario y nuestro equipo se pondrá en contacto contigo.',
                      ),
                      SizedBox(height: 16),
                      ContactForm(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
