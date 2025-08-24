import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_theme.dart';

class GlassPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final Widget? floatingActionButton;
  final Widget? bottomBar;
  final bool centerTitle;

  const GlassPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.bottom,
    this.floatingActionButton,
    this.bottomBar,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GlassTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(title, style: GlassTheme.titleLarge),
          centerTitle: centerTitle,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                GlassTheme.isDarkMode ? Brightness.light : Brightness.dark,
          ),
          leading: leading ??
              IconButton(
                icon: Icon(Icons.arrow_back_ios,
                    color: GlassTheme.colors.textPrimary),
                onPressed: () => Navigator.pop(context),
              ),
          actions: actions,
          bottom: bottom,
          flexibleSpace: Container(
            decoration: GlassTheme.backgroundGradient,
          ),
        ),
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: bottomBar,
      ),
    );
  }
}
