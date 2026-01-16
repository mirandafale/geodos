import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/widgets/app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
  });

  final Widget body;
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final adminAction = IconButton(
      icon: const Icon(Icons.admin_panel_settings_outlined),
      tooltip: 'Acceso admin',
      onPressed: () => Navigator.of(context).pushNamed('/login'),
    );
    final mergedActions = <Widget>[
      if (actions != null) ...actions!,
      adminAction,
    ];

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        leadingWidth: canPop ? 96 : 56,
        leading: Builder(
          builder: (context) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (canPop)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ],
            );
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: Brand.appBarGradient),
        ),
        title: title ?? const Text('GEODOS'),
        titleSpacing: 12,
        centerTitle: false,
        actions: mergedActions,
        bottom: bottom,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
