import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'package:geodos/widgets/app_drawer.dart';
import 'package:geodos/pages/login_admin_page.dart';


class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.title,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.showPrimaryNavigation = true,
  });

  final Widget body;
  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showPrimaryNavigation;

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final isWide = MediaQuery.of(context).size.width >= 980;
    final adminAction = IconButton(
      icon: const Icon(Icons.admin_panel_settings_outlined),
      tooltip: 'Acceso admin',
      onPressed: () => Navigator.of(context).pushNamed('/login'),
    );
    final navigationActions = <Widget>[
      if (showPrimaryNavigation && isWide) ...[
        _PrimaryNavAction(label: 'Servicios', route: '/services'),
        _PrimaryNavAction(label: 'Proyectos', route: '/visor'),
        _PrimaryNavAction(label: 'Quiénes somos', route: '/about'),
        _PrimaryNavAction(label: 'Blog', route: '/blog'),
      ],
    ];
    final mergedActions = <Widget>[
      ...navigationActions,
      if (actions != null) ...actions!,
      adminAction,
    ];
    final titleWidget = title ?? const Text('GEODOS');

    return Scaffold(
      drawer: AppDrawer(
        onAdminAccess: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const LoginAdminPage(),
            ),
          );
        },
      ),
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
        title: InkWell(
          onTap: () => Navigator.of(context).pushNamed('/'),
          child: titleWidget,
        ),
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

class _PrimaryNavAction extends StatelessWidget {
  const _PrimaryNavAction({required this.label, required this.route});

  final String label;
  final String route;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: TextButton(
        onPressed: () => Navigator.of(context).pushNamed(route),
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          textStyle: MaterialStateProperty.all(baseStyle),
          foregroundColor: MaterialStateProperty.resolveWith(
            (states) {
              if (states.contains(MaterialState.hovered) || states.contains(MaterialState.focused)) {
                return Colors.white;
              }
              return Colors.white.withOpacity(0.92);
            },
          ),
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Brand.secondary.withOpacity(0.28);
            }
            if (states.contains(MaterialState.hovered) || states.contains(MaterialState.focused)) {
              return Brand.secondary.withOpacity(0.22);
            }
            return Colors.transparent;
          }),
          overlayColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Brand.secondary.withOpacity(0.3);
            }
            if (states.contains(MaterialState.hovered)) {
              return Brand.secondary.withOpacity(0.22);
            }
            return Colors.transparent;
          }),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
