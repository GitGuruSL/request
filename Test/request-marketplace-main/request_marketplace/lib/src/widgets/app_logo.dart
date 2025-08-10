import 'package:flutter/material.dart';

/// Centralized app logo widget for consistent branding across the app
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 80.0,
    this.showShadow = true,
    this.borderRadius,
  });

  /// Predefined logo sizes for different use cases
  const AppLogo.small({
    super.key,
    this.showShadow = true,
    this.borderRadius,
  }) : size = 40.0;

  const AppLogo.medium({
    super.key,
    this.showShadow = true,
    this.borderRadius,
  }) : size = 60.0;

  const AppLogo.large({
    super.key,
    this.showShadow = true,
    this.borderRadius,
  }) : size = 100.0;

  const AppLogo.splash({
    super.key,
    this.showShadow = true,
    this.borderRadius,
  }) : size = 120.0;

  final double size;
  final bool showShadow;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? (size * 0.2);
    
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow ? [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: size * 0.15,
            offset: Offset(0, size * 0.06),
          ),
        ] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          'assets/icons/app_icon.png',
          height: size,
          width: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // Fallback gradient logo with app icon
            return Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6750A4),
                    Color(0xFF9575CD),
                  ],
                ),
                borderRadius: BorderRadius.circular(radius),
              ),
              child: Icon(
                Icons.shopping_bag_rounded,
                color: Colors.white,
                size: size * 0.5,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Logo with text for branding purposes
class AppLogoWithText extends StatelessWidget {
  const AppLogoWithText({
    super.key,
    this.logoSize = 80.0,
    this.spacing = 16.0,
    this.textStyle,
    this.showShadow = true,
  });

  final double logoSize;
  final double spacing;
  final TextStyle? textStyle;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = theme.textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.onSurface,
    ) ?? const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Color(0xFF1D1B20),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          showShadow: showShadow,
        ),
        SizedBox(height: spacing),
        Text(
          'Request',
          style: textStyle ?? defaultTextStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Horizontal logo with text layout
class AppLogoHorizontal extends StatelessWidget {
  const AppLogoHorizontal({
    super.key,
    this.logoSize = 40.0,
    this.spacing = 12.0,
    this.textStyle,
    this.showShadow = true,
  });

  final double logoSize;
  final double spacing;
  final TextStyle? textStyle;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultTextStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    ) ?? const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1D1B20),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppLogo(
          size: logoSize,
          showShadow: showShadow,
        ),
        SizedBox(width: spacing),
        Text(
          'Request',
          style: textStyle ?? defaultTextStyle,
        ),
      ],
    );
  }
}
