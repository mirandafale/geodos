import 'package:flutter/material.dart';
import 'package:geodos/services/consent_service.dart';

class ConsentGate extends StatefulWidget {
  const ConsentGate({super.key, required this.child});

  final Widget child;

  @override
  State<ConsentGate> createState() => _ConsentGateState();
}

class _ConsentGateState extends State<ConsentGate> {
  final ConsentService _consentService = ConsentService();
  late Future<_ConsentStatus> _statusFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _statusFuture = _loadStatus();
  }

  Future<_ConsentStatus> _loadStatus() async {
    final accepted = await _consentService.isAccepted();
    final dismissed = await _consentService.isDismissed();
    return _ConsentStatus(accepted: accepted, dismissed: dismissed);
  }

  Future<void> _handleAccept() async {
    await _consentService.accept();
    setState(_refresh);
  }

  Future<void> _handleDismiss() async {
    await _consentService.dismiss();
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ConsentStatus>(
      future: _statusFuture,
      builder: (context, snapshot) {
        final status = snapshot.data;
        final showBanner = status != null && !status.accepted && !status.dismissed;
        return Stack(
          children: [
            widget.child,
            if (showBanner)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  minimum: const EdgeInsets.all(16),
                  child: _ConsentBanner(
                    onAccept: _handleAccept,
                    onDismiss: _handleDismiss,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ConsentStatus {
  const _ConsentStatus({required this.accepted, required this.dismissed});

  final bool accepted;
  final bool dismissed;
}

class _ConsentBanner extends StatelessWidget {
  const _ConsentBanner({required this.onAccept, required this.onDismiss});

  final Future<void> Function() onAccept;
  final Future<void> Function() onDismiss;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 940),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Wrap(
            spacing: 18,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 520,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uso de datos y privacidad',
                      style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Utilizamos datos técnicos y de contacto para mejorar la experiencia y responder '
                      'a tus solicitudes. Al continuar, aceptas este uso básico de información.',
                      style: textTheme.bodySmall?.copyWith(color: Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/privacy'),
                      child: const Text('Ver política de privacidad'),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Cerrar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: onAccept,
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
