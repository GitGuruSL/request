import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_theme.dart';

class GlassPage extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final PreferredSizeWidget? bottom;
  final Widget? bottomBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Color? appBarBackgroundColor;

  const GlassPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.centerTitle = false,
    this.bottom,
    this.bottomBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.appBarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(title),
        centerTitle: centerTitle,
        backgroundColor: appBarBackgroundColor ?? Colors.transparent,
        elevation: 0,
        foregroundColor: GlassTheme.colors.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness:
              GlassTheme.isDarkMode ? Brightness.light : Brightness.dark,
          statusBarBrightness:
              GlassTheme.isDarkMode ? Brightness.dark : Brightness.light,
          systemNavigationBarColor:
              GlassTheme.isDarkMode ? const Color(0xFF121212) : Colors.white,
          systemNavigationBarIconBrightness:
              GlassTheme.isDarkMode ? Brightness.light : Brightness.dark,
        ),
        actions: actions,
        leading: leading,
        bottom: bottom,
      ),
      body: GlassTheme.backgroundContainer(
        child: SafeArea(
          top: true,
          child: body,
        ),
      ),
      bottomNavigationBar: bottomBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
