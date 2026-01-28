import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double? size;
  final double? strokeWidth;
  final Color? color;

  const LoadingIndicator({super.key, this.size, this.strokeWidth, this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size ?? 24,
      height: size ?? 24,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? 2,
        valueColor: color != null
            ? AlwaysStoppedAnimation<Color>(color!)
            : null,
      ),
    );
  }
}

class FullScreenLoading extends StatelessWidget {
  final String? message;

  const FullScreenLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const LoadingIndicator(size: 48, strokeWidth: 3),
            if (message != null) ...[
              const SizedBox(height: 24),
              Text(message!, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}

class InlineLoading extends StatelessWidget {
  final String? message;

  const InlineLoading({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const LoadingIndicator(size: 16, strokeWidth: 2),
        if (message != null) ...[
          const SizedBox(width: 12),
          Text(message!, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ],
    );
  }
}

class CardLoading extends StatelessWidget {
  final String title;
  final int itemCount;

  const CardLoading({super.key, this.title = 'Loading', this.itemCount = 3});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(title, style: theme.textTheme.titleLarge),
        ),
        ...List.generate(itemCount, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            height: 100,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }),
      ],
    );
  }
}
