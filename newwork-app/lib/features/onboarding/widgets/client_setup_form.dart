import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_input.dart';
import '../../../shared/widgets/app_card.dart';

enum ConnectionStatus { idle, testing, success, error }

class ClientSetupForm extends ConsumerStatefulWidget {
  final String? initialUrl;
  final VoidCallback onBack;
  final Future<bool> Function(String url) onComplete;

  const ClientSetupForm({
    super.key,
    this.initialUrl,
    required this.onBack,
    required this.onComplete,
  });

  @override
  ConsumerState<ClientSetupForm> createState() => _ClientSetupFormState();
}

class _ClientSetupFormState extends ConsumerState<ClientSetupForm> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();

  ConnectionStatus _connectionStatus = ConnectionStatus.idle;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _urlController.text = widget.initialUrl ?? '';
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _connectionStatus = ConnectionStatus.testing;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      // TODO: Implement actual connection test using API client
      // For now, simulate a connection test
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.success;
          _successMessage = 'Successfully connected to OpenCode server!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = ConnectionStatus.error;
          _errorMessage = 'Failed to connect: $e';
        });
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final url = _urlController.text.trim();

    try {
      final success = await widget.onComplete(url);
      if (mounted && !success) {
        setState(() {
          _errorMessage = 'Failed to complete setup. Please try again.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            title: const Text('Connect to OpenCode Server'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter the URL of your OpenCode server to connect as a client.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 20),
                AppInput(
                  label: 'Server URL',
                  hint: 'e.g., http://localhost:8000',
                  controller: _urlController,
                  isRequired: true,
                  inputType: AppInputType.text,
                  errorText: _errorMessage,
                  helperText: 'Include http:// or https://',
                ),
                const SizedBox(height: 16),
                AppButton(
                  text: 'Test Connection',
                  variant: AppButtonVariant.secondary,
                  icon: _buildConnectionIcon(),
                  onPressed: _connectionStatus == ConnectionStatus.testing
                      ? null
                      : _testConnection,
                  isLoading: _connectionStatus == ConnectionStatus.testing,
                ),
                if (_successMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _successMessage!,
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            title: const Text('Connection Information'),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoItem(
                  context,
                  Icons.info_outline,
                  'What is OpenCode Server?',
                  'OpenCode Server is the backend that handles AI sessions, workspace management, and tool execution.',
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                  context,
                  Icons.cloud_outlined,
                  'Local vs Remote',
                  'Connect to a local server for development or a remote server for cloud-based workflows.',
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                  context,
                  Icons.security,
                  'Connection Security',
                  'For production, always use HTTPS. Local development can use HTTP.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  text: 'Back',
                  variant: AppButtonVariant.secondary,
                  onPressed: widget.onBack,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppButton(
                  text: 'Connect',
                  variant: AppButtonVariant.primary,
                  onPressed: _connectionStatus == ConnectionStatus.success
                      ? _handleSubmit
                      : null,
                  isDisabled: _connectionStatus != ConnectionStatus.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget? _buildConnectionIcon() {
    switch (_connectionStatus) {
      case ConnectionStatus.idle:
        return const Icon(Icons.wifi_find);
      case ConnectionStatus.testing:
        return null; // Loading indicator shown instead
      case ConnectionStatus.success:
        return const Icon(Icons.check_circle);
      case ConnectionStatus.error:
        return const Icon(Icons.error);
    }
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
