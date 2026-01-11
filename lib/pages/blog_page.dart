import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/news_item.dart';
import 'package:geodos/pages/news_detail_page.dart';
import 'package:geodos/services/news_service.dart';
import 'package:geodos/widgets/app_shell.dart';
import 'package:geodos/widgets/news_card.dart';

class BlogPage extends StatelessWidget {
  const BlogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppShell(
      title: const Text('Blog / Actualidad'),
      body: Container(
        color: Brand.mist,
        child: StreamBuilder<List<NewsItem>>(
          stream: NewsService.publishedStream(),
          builder: (context, snapshot) {
            final posts = snapshot.data ?? [];
            final isLoading = snapshot.connectionState == ConnectionState.waiting;
            final showFeatured = posts.isNotEmpty && !isLoading && !snapshot.hasError;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1150),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actualidad GEODOS',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Brand.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Conoce las últimas noticias, proyectos e iniciativas relacionadas con la '
                        'consultoría ambiental y territorial.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (showFeatured) ...[
                        _FeaturedPlaceholder(textTheme: theme.textTheme),
                        const SizedBox(height: 24),
                      ],
                      if (snapshot.hasError)
                        _InfoState(
                          icon: Icons.info_outline,
                          title: 'No se pudieron cargar las noticias',
                          message:
                              'Estamos trabajando para restablecer la sección. Inténtalo de nuevo más tarde.',
                        )
                      else if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (posts.isEmpty)
                        _InfoState(
                          icon: Icons.article_outlined,
                          title: 'Aún no hay noticias publicadas',
                          message:
                              'Cuando tengamos novedades, las verás aquí. Vuelve pronto para conocer '
                              'la actualidad de GEODOS.',
                        )
                      else
                        _NewsGrid(
                          items: posts,
                          onSelect: (item) => _openDetail(context, item),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, NewsItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => NewsDetailPage(item: item)),
    );
  }
}

class _FeaturedPlaceholder extends StatelessWidget {
  const _FeaturedPlaceholder({required this.textTheme});

  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.star_border, color: Brand.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Espacio reservado para artículos destacados.',
              style: textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsGrid extends StatelessWidget {
  const _NewsGrid({required this.items, required this.onSelect});

  final List<NewsItem> items;
  final ValueChanged<NewsItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100 ? 3 : (width >= 760 ? 2 : 1);
        const spacing = 24.0;
        final itemWidth = (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: NewsCard(
                    item: item,
                    onTap: () => onSelect(item),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _InfoState extends StatelessWidget {
  const _InfoState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: Brand.primary.withOpacity(0.7)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
