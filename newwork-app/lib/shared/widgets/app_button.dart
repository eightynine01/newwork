import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, text, danger, success }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isDisabled;
  final Widget? icon;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.isFullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveDisabled = isDisabled || isLoading;

    Widget buttonContent() {
      if (isLoading) {
        return const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }

      if (icon != null) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [icon!, const SizedBox(width: 8), Text(text)],
        );
      }

      return Text(text);
    }

    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? Size(double.infinity, 48) : null,
          ),
          child: buttonContent(),
        );

      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            side: BorderSide(color: theme.colorScheme.primary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? Size(double.infinity, 48) : null,
          ),
          child: buttonContent(),
        );

      case AppButtonVariant.text:
        return TextButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: isFullWidth ? Size(double.infinity, 48) : null,
          ),
          child: buttonContent(),
        );

      case AppButtonVariant.danger:
        return ElevatedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? Size(double.infinity, 48) : null,
          ),
          child: buttonContent(),
        );

      case AppButtonVariant.success:
        return ElevatedButton(
          onPressed: effectiveDisabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: isFullWidth ? Size(double.infinity, 48) : null,
          ),
          child: buttonContent(),
        );
    }
  }
}
