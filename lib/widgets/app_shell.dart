import 'package:flutter/material.dart';
import 'package:geodos/brand/brand.dart';
import 'app_drawer.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.body,
    this.title = 'GEODOS',
    this.titleWidget,
    this.actions,
    this.bottom,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.backgroundColor,
    this.extendBodyBehindAppBar = false,
    this.centerTitle = false,
    this.useDrawer = true,
    this.bodyPadding,
  });

  final Widget body;
  final String title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? backgroundColor;
  final bool extendBodyBehindAppBar;
  final bool centerTitle;
  final bool useDrawer;
  final EdgeInsetsGeometry? bodyPadding;

  @override
  Widget build(BuildContext context) {
    final defaultTitleStyle = Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        );

    final content = bodyPadding != null
        ? Padding(padding: bodyPadding!, child: body)
        : body;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      drawer: useDrawer ? const AppDrawer() : null,
      appBar: AppBar(
        title: titleWidget ?? Text(title, style: defaultTitleStyle),
        centerTitle: centerTitle,
        actions: actions,
        bottom: bottom,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace:
            Container(decoration: const BoxDecoration(gradient: Brand.appBarGradient)),
      ),
      body: content,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
