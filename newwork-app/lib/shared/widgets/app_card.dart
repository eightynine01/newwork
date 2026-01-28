import 'package:flutter/material.dart';

enum AppCardVariant { elevated, outlined, filled }

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Widget? title;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.elevated,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.title,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget cardChild = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || (actions != null && actions!.isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    DefaultTextStyle(
                      style:
                          theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ) ??
                          const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                      child: title!,
                    ),
                  if (actions != null) ...actions!,
                ],
              ),
            ),
          child,
        ],
      ),
    );

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius ?? 12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          child: Container(decoration: _getDecoration(theme), child: cardChild),
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(ThemeData theme) {
    switch (variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: backgroundColor ?? theme.cardTheme.color,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        );

      case AppCardVariant.outlined:
        return BoxDecoration(
          color: backgroundColor ?? theme.cardTheme.color,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
          border: Border.all(color: theme.dividerColor, width: 1),
        );

      case AppCardVariant.filled:
        return BoxDecoration(
          color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius ?? 12),
        );
    }
  }
}
