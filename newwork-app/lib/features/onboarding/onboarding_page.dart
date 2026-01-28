import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/providers/onboarding_provider.dart';
import 'widgets/mode_selection_card.dart';
import 'widgets/host_setup_form.dart';
import 'widgets/client_setup_form.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    // Check if onboarding is already completed
    if (onboardingState.isCompleted) {
      // Navigate to dashboard
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/dashboard');
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, theme),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildCurrentStep(),
              ),
            ),
            _buildBottomBar(context, theme, onboardingState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.code,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OpenWork',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Setup your workspace',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              _showSkipDialog(context);
            },
            child: Text(
              'Skip',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    final onboardingState = ref.watch(onboardingStateProvider);

    switch (onboardingState.currentStep) {
      case 0:
        return _buildModeSelectionStep();
      case 1:
        return _buildSetupStep();
      case 2:
        return _buildCompletionStep();
      default:
        return _buildModeSelectionStep();
    }
  }

  Widget _buildModeSelectionStep() {
    final onboardingState = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Choose Your Mode',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Select how you want to use OpenWork',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          ModeSelectionCard(
            mode: OnboardingMode.host,
            isSelected: onboardingState.selectedMode == OnboardingMode.host,
            onTap: () => notifier.selectMode(OnboardingMode.host),
            title: 'Host Mode',
            description:
                'Run OpenWork locally with full control over workspaces, files, and configurations.',
            icon: Icons.computer,
          ),
          const SizedBox(height: 16),
          ModeSelectionCard(
            mode: OnboardingMode.client,
            isSelected: onboardingState.selectedMode == OnboardingMode.client,
            onTap: () => notifier.selectMode(OnboardingMode.client),
            title: 'Client Mode',
            description:
                'Connect to a remote OpenWork server for cloud-based workflows and collaboration.',
            icon: Icons.cloud,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupStep() {
    final onboardingState = ref.watch(onboardingStateProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    switch (onboardingState.selectedMode) {
      case OnboardingMode.host:
        return HostSetupForm(
          initialWorkspaceName: onboardingState.workspaceName,
          initialWorkspacePath: onboardingState.workspacePath,
          initialPreset:
              onboardingState.selectedPreset ?? WorkspacePreset.starter,
          onBack: () => notifier.previousStep(),
          onComplete: _handleHostSetupComplete,
        );

      case OnboardingMode.client:
        return ClientSetupForm(
          initialUrl: onboardingState.clientUrl,
          onBack: () => notifier.previousStep(),
          onComplete: _handleClientSetupComplete,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Future<bool> _handleHostSetupComplete({
    required String workspaceName,
    required String workspacePath,
    required WorkspacePreset preset,
  }) async {
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.createWorkspace(
      workspaceName: workspaceName,
      workspacePath: workspacePath,
      preset: preset,
    );
    if (success) {
      await notifier.completeOnboarding();
      if (mounted) {
        context.go('/dashboard');
      }
    }
    return success;
  }

  Future<bool> _handleClientSetupComplete(String url) async {
    final notifier = ref.read(onboardingProvider.notifier);
    final success = await notifier.connectToServer(url);
    if (success) {
      await notifier.completeOnboarding();
      if (mounted) {
        context.go('/dashboard');
      }
    }
    return success;
  }

  Widget _buildCompletionStep() {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Setup Complete!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'You\'re all set to start using OpenWork',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.go('/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Go to Dashboard',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    ThemeData theme,
    OnboardingState state,
  ) {
    final notifier = ref.read(onboardingProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildProgressIndicator(theme, state),
          if (state.currentStep == 0 && state.canProceedToSetup) ...[
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => notifier.nextStep(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeData theme, OnboardingState state) {
    final steps = ['Mode', 'Setup', 'Complete'];
    final currentStep = state.currentStep;

    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  if (index > 0)
                    Expanded(
                        child:
                            _buildProgressLine(theme, isActive || isCompleted)),
                  _buildProgressDot(
                    theme,
                    isActive,
                    isCompleted,
                    index + 1,
                  ),
                  if (index < steps.length - 1)
                    Expanded(
                        child:
                            _buildProgressLine(theme, isActive || isCompleted)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                steps[index],
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isActive || isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildProgressLine(ThemeData theme, bool isActive) {
    return Container(
      height: 2,
      color: isActive ? theme.colorScheme.primary : theme.dividerColor,
    );
  }

  Widget _buildProgressDot(
    ThemeData theme,
    bool isActive,
    bool isCompleted,
    int stepNumber,
  ) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isActive
            ? theme.colorScheme.primary
            : isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                size: 18,
                color: theme.colorScheme.onPrimary,
              )
            : Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: isActive
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _showSkipDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
          'You can complete onboarding later from the settings. Some features may be limited until setup is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/dashboard');
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

// Provider to get the onboarding state
final onboardingStateProvider = Provider<OnboardingState>((ref) {
  return ref.watch(onboardingProvider);
});
