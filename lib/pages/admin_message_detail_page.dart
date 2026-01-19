import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/models/contact_message.dart';
import 'package:geodos/services/auth_service.dart';
import 'package:geodos/services/contact_message_service.dart';
import 'package:geodos/widgets/app_shell.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminMessageDetailPage extends StatelessWidget {
  const AdminMessageDetailPage({super.key, required this.messageId});

  final String messageId;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: const Text('Detalle del mensaje'),
      body: StreamBuilder<ContactMessage?>(
        stream: ContactMessageService.streamMessage(messageId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState(message: 'Cargando mensaje...');
          }
          if (snapshot.hasError) {
            return const _ErrorState(
              title: 'No se pudo cargar el mensaje',
              message: 'Intenta nuevamente en unos minutos.',
            );
          }
          final message = snapshot.data;
          if (message == null) {
            return const _ErrorState(
              title: 'Mensaje no disponible',
              message: 'El mensaje ya no está disponible o fue eliminado.',
            );
          }
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _MessageHeader(message: message),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DetailRow(
                                label: 'Nombre',
                                value: message.name,
                              ),
                              _DetailRow(
                                label: 'Email',
                                valueWidget: _EmailLink(email: message.email),
                              ),
                              _DetailRow(
                                label: 'Fecha',
                                value: _formatDate(message.createdAt),
                              ),
                              _DetailRow(
                                label: 'Origen',
                                value: message.originSection.isEmpty
                                    ? 'Sin definir'
                                    : message.originSection,
                              ),
                              _DetailRow(
                                label: 'Source',
                                value: message.source.isEmpty ? 'Sin definir' : message.source,
                              ),
                              if (message.company.isNotEmpty)
                                _DetailRow(label: 'Empresa', value: message.company),
                              if (message.projectType.isNotEmpty)
                                _DetailRow(label: 'Tipo de proyecto', value: message.projectType),
                              const SizedBox(height: 12),
                              Text(
                                'Mensaje',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Brand.mist,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Text(
                                  message.message,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.blueGrey.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _ActionBar(message: message),
              ],
            ),
          );
        },
      ),
    );
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

class _MessageHeader extends StatelessWidget {
  const _MessageHeader({required this.message});

  final ContactMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.name,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                message.email,
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade600),
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            _StatusChip(
              label: message.isRead ? 'Leído' : 'Nuevo',
              color: message.isRead ? Colors.green : Colors.orange,
            ),
            if (message.isArchived)
              const _StatusChip(label: 'Archivado', color: Brand.primary),
          ],
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.blueGrey.shade600,
                  ),
            ),
          ),
          Expanded(
            child: valueWidget ??
                Text(
                  value ?? '',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
          ),
        ],
      ),
    );
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
        style: const TextStyle(
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

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.message});

  final ContactMessage message;

  @override
  Widget build(BuildContext context) {
    final isAdmin = AuthService.instance.isAdmin;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        if (!message.isRead)
          FilledButton.icon(
            onPressed: isAdmin ? () => _markAsRead(context, message.id) : null,
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('Marcar como leído'),
          ),
        OutlinedButton.icon(
          onPressed: !message.isArchived && isAdmin
              ? () => _archiveMessage(context, message.id)
              : null,
          icon: const Icon(Icons.archive_outlined),
          label: Text(message.isArchived ? 'Archivado' : 'Archivar mensaje'),
        ),
        TextButton.icon(
          onPressed: isAdmin ? () => _confirmDelete(context, message.id) : null,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }

  Future<void> _markAsRead(BuildContext context, String messageId) async {
    try {
      await ContactMessageService.markAsRead(messageId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje marcado como leído.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo marcar como leído: $error')),
      );
    }
  }

  Future<void> _archiveMessage(BuildContext context, String messageId) async {
    try {
      await ContactMessageService.archiveMessage(messageId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje archivado.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo archivar el mensaje: $error')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar mensaje'),
        content: const Text(
          '¿Seguro que deseas eliminar este mensaje? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ContactMessageService.deleteMessage(messageId);
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mensaje eliminado.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo eliminar el mensaje: $error')),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.blueGrey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
