import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/app_button.dart';

class PromptInput extends StatefulWidget {
  final String? model;
  final List<String> availableModels;
  final ValueChanged<String>? onModelChanged;
  final ValueChanged<String>? onTextChanged;
  final VoidCallback? onSend;
  final VoidCallback? onClear;
  final bool isSending;
  final int? maxLength;
  final String? hintText;
  final bool autofocus;

  const PromptInput({
    super.key,
    this.model,
    this.availableModels = const [],
    this.onModelChanged,
    this.onTextChanged,
    this.onSend,
    this.onClear,
    this.isSending = false,
    this.maxLength,
    this.hintText,
    this.autofocus = false,
  });

  @override
  State<PromptInput> createState() => _PromptInputState();
}

class _PromptInputState extends State<PromptInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  int _characterCount = 0;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();

    _controller.addListener(_updateCounts);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _updateCounts() {
    final text = _controller.text;
    setState(() {
      _characterCount = text.length;
      _wordCount = text.trim().isEmpty
          ? 0
          : text.trim().split(RegExp(r'\s+')).length;
    });

    widget.onTextChanged?.call(text);
  }

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSend?.call();
  }

  void _handleClear() {
    _controller.clear();
    widget.onClear?.call();
    _focusNode.requestFocus();
  }

  String get _effectiveModel =>
      widget.model ?? widget.availableModels.firstOrNull ?? 'gpt-4';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEmpty = _controller.text.trim().isEmpty;
    final isDisabled = isEmpty || widget.isSending;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildModelSelector(context, theme),
          if (widget.hintText != null) ...[
            const SizedBox(height: 8),
            _buildHint(context, theme),
          ],
          const SizedBox(height: 8),
          _buildInputArea(context, theme, isDisabled),
          const SizedBox(height: 12),
          _buildBottomBar(context, theme, isDisabled),
        ],
      ),
    );
  }

  Widget _buildModelSelector(BuildContext context, ThemeData theme) {
    if (widget.availableModels.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 16,
            color: theme.colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text(
            _effectiveModel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (widget.availableModels.length > 1) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _showModelSelector,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 18,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHint(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        widget.hintText!,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    ThemeData theme,
    bool isDisabled,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: 5,
        maxLength: widget.maxLength,
        autofocus: widget.autofocus,
        enabled: !widget.isSending,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Type your prompt here...',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(12),
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    bool isDisabled,
  ) {
    return Row(
      children: [
        _buildCounts(context, theme),
        const Spacer(),
        if (_controller.text.isNotEmpty && widget.onClear != null) ...[
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: _handleClear,
            tooltip: 'Clear',
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
        ],
        AppButton(
          text: widget.isSending ? 'Sending...' : 'Send',
          variant: AppButtonVariant.primary,
          icon: widget.isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send, size: 18),
          onPressed: isDisabled ? null : _handleSend,
        ),
      ],
    );
  }

  Widget _buildCounts(BuildContext context, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_characterCount chars',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '•',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_wordCount words',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showModelSelector() {
    if (widget.availableModels.length <= 1) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModelSelectorSheet(
        models: widget.availableModels,
        selectedModel: _effectiveModel,
        onSelected: (model) {
          Navigator.pop(context);
          widget.onModelChanged?.call(model);
        },
      ),
    );
  }

  void focus() {
    _focusNode.requestFocus();
  }

  void clear() {
    _controller.clear();
  }

  String get text => _controller.text;
}

class _ModelSelectorSheet extends StatelessWidget {
  final List<String> models;
  final String selectedModel;
  final ValueChanged<String> onSelected;

  const _ModelSelectorSheet({
    super.key,
    required this.models,
    required this.selectedModel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: theme.dividerColor)),
            ),
            child: Center(
              child: Text(
                'Select Model',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: models.length,
              itemBuilder: (context, index) {
                final model = models[index];
                final isSelected = model == selectedModel;

                return ListTile(
                  onTap: () => onSelected(model),
                  selected: isSelected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(
                    Icons.psychology,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  title: Text(
                    model,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                          size: 24,
                        )
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
