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
  late Future<bool> _acceptedFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    _acceptedFuture = _consentService.isAccepted();
  }

  Future<void> _handleAccept() async {
    await _consentService.accept();
    setState(_refresh);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _acceptedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Material(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.data == true) {
          return widget.child;
        }

        return WillPopScope(
          onWillPop: () async => false,
          child: Stack(
            children: [
              AbsorbPointer(absorbing: true, child: widget.child),
              const ModalBarrier(dismissible: false, color: Colors.black54),
              _ConsentDialog(onAccept: _handleAccept),
            ],
          ),
        );
      },
    );
  }
}

class _ConsentDialog extends StatefulWidget {
  const _ConsentDialog({required this.onAccept});

  final Future<void> Function() onAccept;

  @override
  State<_ConsentDialog> createState() => _ConsentDialogState();
}

class _ConsentDialogState extends State<_ConsentDialog> {
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  bool _saving = false;

  bool get _canSubmit => _termsAccepted && _privacyAccepted && !_saving;

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }
    setState(() {
      _saving = true;
    });
    await widget.onAccept();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 640;
        final content = ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: constraints.maxHeight * 0.9,
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(isMobile ? 24 : 16),
            clipBehavior: Clip.antiAlias,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Consentimiento de uso y protección de datos',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Para continuar necesitas aceptar los términos de uso y la política de privacidad. '
                    'Esta aceptación se guarda para futuras visitas.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  CheckboxListTile(
                    value: _termsAccepted,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                              _termsAccepted = value ?? false;
                            }),
                    title: const Text('Acepto los Términos de uso'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: _privacyAccepted,
                    onChanged: _saving
                        ? null
                        : (value) => setState(() {
                              _privacyAccepted = value ?? false;
                            }),
                    title: const Text(
                      'Acepto la Política de privacidad y tratamiento de datos',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _canSubmit ? _submit : null,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Aceptar y continuar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (isMobile) {
          return Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              minimum: const EdgeInsets.all(16),
              child: content,
            ),
          );
        }

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: content,
          ),
        );
      },
    );
  }
}
