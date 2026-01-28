import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppInputType { text, multiline, password, email, number, search }

class AppInput extends StatelessWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final AppInputType inputType;
  final bool isReadOnly;
  final bool isRequired;
  final int? maxLines;
  final int? maxLength;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;
  final EdgeInsetsGeometry? contentPadding;

  const AppInput({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.onClear,
    this.prefixIcon,
    this.suffixIcon,
    this.inputType = AppInputType.text,
    this.isReadOnly = false,
    this.isRequired = false,
    this.maxLines,
    this.maxLength,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
    this.contentPadding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveController =
        controller ?? TextEditingController(text: initialValue);
    final theme = Theme.of(context);

    InputDecoration decoration() {
      return InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon:
            suffixIcon ??
            (controller?.text.isNotEmpty == true && onClear != null
                ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
                : null),
        errorText: errorText,
        helperText: helperText,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        counterText: maxLength != null
            ? '${controller?.text.length ?? 0}/$maxLength'
            : null,
      );
    }

    switch (inputType) {
      case AppInputType.multiline:
        return TextField(
          controller: effectiveController,
          onChanged: onChanged,
          readOnly: isReadOnly,
          maxLines: maxLines ?? 5,
          maxLength: maxLength,
          decoration: decoration(),
          keyboardType: keyboardType ?? TextInputType.multiline,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
        );

      case AppInputType.password:
        return TextField(
          controller: effectiveController,
          onChanged: onChanged,
          readOnly: isReadOnly,
          obscureText: true,
          maxLength: maxLength,
          decoration: decoration(),
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
        );

      case AppInputType.email:
        return TextField(
          controller: effectiveController,
          onChanged: onChanged,
          readOnly: isReadOnly,
          maxLength: maxLength,
          decoration: decoration(),
          keyboardType: TextInputType.emailAddress,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
        );

      case AppInputType.number:
        return TextField(
          controller: effectiveController,
          onChanged: onChanged,
          readOnly: isReadOnly,
          maxLength: maxLength,
          decoration: decoration(),
          keyboardType: TextInputType.number,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
        );

      case AppInputType.search:
        return TextField(
          controller: effectiveController,
          onChanged: onChanged,
          readOnly: isReadOnly,
          maxLength: maxLength,
          decoration: decoration(),
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
        );

      case AppInputType.text:
      default:
        return TextField(
          controller: effectiveController,
          onChanged: onChanged,
          readOnly: isReadOnly,
          maxLength: maxLength,
          decoration: decoration(),
          keyboardType: keyboardType ?? TextInputType.text,
          inputFormatters: inputFormatters,
          focusNode: focusNode,
          autofocus: autofocus,
        );
    }
  }
}
