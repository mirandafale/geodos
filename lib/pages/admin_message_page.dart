import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/contact_message.dart';
import 'package:geodos/pages/admin_message_detail_page.dart';
import 'package:geodos/services/contact_message_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMessagePage extends StatefulWidget {
  const AdminMessagePage({super.key});

  @override
  State<AdminMessagePage> createState() => _AdminMessagePageState();
}

class _AdminMessagePageState extends State<AdminMessagePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: DefaultTabController(
        length: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _MessagesHeader(),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TabBar(
                labelColor: Brand.primary,
                unselectedLabelColor: Colors.blueGrey.shade400,
                indicatorColor: Brand.primary,
                tabs: const [
                  Tab(text: 'Bandeja'),
                  Tab(text: 'Archivados'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<ContactMessage>>(
                stream: ContactMessageService.getMessages(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const _LoadingState(message: 'Cargando mensajes...');
                  }
                  if (snapshot.hasError) {
                    return const _ErrorState(
                      icon: Icons.cloud_off,
                      title: 'No se pudieron cargar los mensajes',
                      message:
                          'Revisa tu conexión a internet o intenta nuevamente en unos minutos.',
                    );
                  }
                  final messages = snapshot.data ?? [];
                  final inboxMessages =
                      messages.where((message) => !message.isArchived).toList();
                  final archivedMessages =
                      messages.where((message) => message.isArchived).toList();
                  return TabBarView(
                    children: [
                      _MessageListPane(
                        messages: inboxMessages,
                        showGrouping: true,
                        emptyTitle: 'No hay mensajes nuevos',
                        emptyMessage:
                            'Las consultas de contacto aparecerán aquí cuando lleguen.',
                      ),
                      _MessageListPane(
                        messages: archivedMessages,
                        showGrouping: false,
                        emptyTitle: 'Aún no hay mensajes archivados',
                        emptyMessage: 'Los mensajes archivados aparecerán aquí.',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessagesHeader extends StatelessWidget {
  const _MessagesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mensajes de contacto',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Gestiona las consultas enviadas desde el formulario en tiempo real.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blueGrey.shade600,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Brand.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            children: [
              Icon(Icons.mail_outline, size: 18, color: Brand.primary),
              SizedBox(width: 6),
              Text(
                'Panel de lectura',
                style: TextStyle(color: Brand.primary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MessageListPane extends StatelessWidget {
  const _MessageListPane({
    required this.messages,
    required this.showGrouping,
    this.emptyTitle = 'No hay mensajes en la bandeja',
    this.emptyMessage = 'Las consultas de contacto aparecerán aquí cuando lleguen.',
  });

  final List<ContactMessage> messages;
  final bool showGrouping;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _EmptyState(
            icon: Icons.mail_outline,
            title: emptyTitle,
            message: emptyMessage,
          ),
        ),
      );
    }
    final unread = messages.where((message) => !message.isRead).toList();
    final read = messages.where((message) => message.isRead).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (showGrouping && unread.isNotEmpty) ...[
              _GroupHeader(title: 'Nuevos', count: unread.length),
              const SizedBox(height: 8),
              _MessageList(messages: unread),
              const SizedBox(height: 20),
            ],
            if (!showGrouping) ...[
              _MessageList(messages: messages),
            ],
            if (showGrouping && read.isNotEmpty) ...[
              _GroupHeader(title: 'Leídos', count: read.length),
              const SizedBox(height: 8),
              _MessageList(messages: read),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Brand.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(color: Brand.primary, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages});

  final List<ContactMessage> messages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int index = 0; index < messages.length; index++) ...[
          _MessageTile(message: messages[index]),
          if (index < messages.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message});

  final ContactMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlightColor = message.isRead ? Colors.white : Brand.primary.withOpacity(0.05);
    final borderColor = message.isRead ? Colors.grey.shade200 : Brand.primary.withOpacity(0.4);
    return Material(
      color: highlightColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminMessageDetailPage(messageId: message.id),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    message.isRead ? Icons.mail_outline : Icons.mark_email_unread_outlined,
                    size: 20,
                    color: message.isRead ? Colors.blueGrey.shade400 : Brand.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message.name,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    _formatDate(message.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _EmailLink(email: message.email),
                  Text(
                    message.originSection.isEmpty
                        ? 'Origen no definido'
                        : 'Origen: ${message.originSection}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.blueGrey.shade500),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                _excerpt(message.message),
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _excerpt(String text) {
    final trimmed = text.trim();
    if (trimmed.length <= 120) return trimmed;
    return '${trimmed.substring(0, 120)}…';
  }

  static String _formatDate(DateTime? date) {
    if (date == null) return 'Sin fecha';
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }
}

class _EmailLink extends StatelessWidget {
  const _EmailLink({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: email.trim().isEmpty ? null : () => _launchEmail(context, email),
      child: Text(
        email.isEmpty ? 'Sin correo' : email,
        style: TextStyle(
          color: Brand.primary,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final uri = Uri(scheme: 'mailto', path: email.trim());
    final success = await launchUrl(uri, mode: LaunchMode.platformDefault);
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el correo.')),
      );
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.blueGrey.shade300),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.icon, required this.title, required this.message});

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
