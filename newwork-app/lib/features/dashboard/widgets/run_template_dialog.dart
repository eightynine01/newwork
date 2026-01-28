import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/template.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';

class RunTemplateDialog extends ConsumerStatefulWidget {
  final Template template;

  const RunTemplateDialog({
    super.key,
    required this.template,
  });

  @override
  ConsumerState<RunTemplateDialog> createState() => _RunTemplateDialogState();
}

class _RunTemplateDialogState extends ConsumerState<RunTemplateDialog> {
  final Map<String, TextEditingController> _variableControllers = {};
  final Map<String, String> _variableValues = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _extractVariables();
  }

  @override
  void dispose() {
    for (var controller in _variableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// Extract {{variable}} placeholders from template
  List<String> _extractVariables() {
    final pattern = RegExp(r'\{\{(\w+)\}\}');
    final matches = pattern.allMatches(widget.template.systemPrompt);
    final variables = matches.map((m) => m.group(1)!).toSet().toList();
    for (var variable in variables) {
      _variableControllers[variable] = TextEditingController();
    }
    return variables;
  }

  /// Substitute variables into prompt
  String _getRenderedPrompt() {
    String prompt = widget.template.systemPrompt;
    _variableValues.forEach((key, value) {
      if (value.isNotEmpty) {
        prompt = prompt.replaceAll('{{$key}}', value);
      }
    });
    return prompt;
  }

  Future<void> _runTemplate() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await ref.read(templatesProvider.notifier).runTemplate(
            widget.template.id,
            variables: _variableValues.isEmpty ? null : _variableValues,
          );

      if (mounted) {
        Navigator.pop(context, result);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Template executed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to run template: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final variables = _variableControllers.keys.toList();
    final renderedPrompt = _getRenderedPrompt();

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.play_circle_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Run Template',
              style: theme.textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 700,
        height: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Template info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.template.isPublic
                            ? Icons.public
                            : Icons.workspaces_outline,
                        size: 16,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.template.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Used ${widget.template.usageCount} times',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  if (widget.template.description != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        widget.template.description!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withOpacity(0.9),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Variables section
            if (variables.isNotEmpty) ...[
              Text(
                'Fill in variables',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: variables.length,
                    itemBuilder: (context, index) {
                      final variable = variables[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppInput(
                          label: variable,
                          controller: _variableControllers[variable],
                          helperText: 'Value for {{$variable}}',
                          onChanged: (value) {
                            setState(() {
                              _variableValues[variable] = value.trim();
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Preview section
            Text(
              'Rendered Prompt',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    renderedPrompt,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        AppButton(
          text: 'Cancel',
          variant: AppButtonVariant.text,
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        AppButton(
          text: 'Run Template',
          onPressed: _isSubmitting ? null : _runTemplate,
          isLoading: _isSubmitting,
          icon: const Icon(Icons.play_arrow),
        ),
      ],
    );
  }
}
