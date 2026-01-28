import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/storage_provider.dart';
import '../repositories/api_client.dart';
import '../../features/onboarding/widgets/mode_selection_card.dart';
import '../../features/onboarding/widgets/host_setup_form.dart';
import 'dashboard_providers.dart'; // Import providers from dashboard_providers

// Storage keys
const String _keyOnboardingCompleted = 'onboarding_completed';
const String _keySelectedMode = 'onboarding_mode';
const String _keyWorkspacePath = 'onboarding_workspace_path';
const String _keyWorkspaceName = 'onboarding_workspace_name';
const String _keyClientUrl = 'onboarding_client_url';

// Onboarding state
class OnboardingState {
  final int currentStep;
  final OnboardingMode? selectedMode;
  final String? workspaceName;
  final String? workspacePath;
  final WorkspacePreset? selectedPreset;
  final String? clientUrl;
  final bool isLoading;
  final String? error;
  final bool isCompleted;

  const OnboardingState({
    this.currentStep = 0,
    this.selectedMode,
    this.workspaceName,
    this.workspacePath,
    this.selectedPreset,
    this.clientUrl,
    this.isLoading = false,
    this.error,
    this.isCompleted = false,
  });

  OnboardingState copyWith({
    int? currentStep,
    OnboardingMode? selectedMode,
    String? workspaceName,
    String? workspacePath,
    WorkspacePreset? selectedPreset,
    String? clientUrl,
    bool? isLoading,
    String? error,
    bool? isCompleted,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      selectedMode: selectedMode ?? this.selectedMode,
      workspaceName: workspaceName ?? this.workspaceName,
      workspacePath: workspacePath ?? this.workspacePath,
      selectedPreset: selectedPreset ?? this.selectedPreset,
      clientUrl: clientUrl ?? this.clientUrl,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  bool get canProceedToSetup => selectedMode != null;
  bool get canProceedToComplete {
    if (selectedMode == OnboardingMode.host) {
      return workspaceName != null &&
          workspacePath != null &&
          workspaceName!.isNotEmpty &&
          workspacePath!.isNotEmpty;
    } else if (selectedMode == OnboardingMode.client) {
      return clientUrl != null && clientUrl!.isNotEmpty;
    }
    return false;
  }
}

// Onboarding notifier
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final StorageProvider _storage;
  final ApiClient _apiClient;

  OnboardingNotifier(this._storage, this._apiClient)
      : super(const OnboardingState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      await _storage.init();

      final isCompleted = _storage.getBool(_keyOnboardingCompleted) ?? false;
      final modeStr = _storage.getString(_keySelectedMode);
      final workspaceName = _storage.getString(_keyWorkspaceName);
      final workspacePath = _storage.getString(_keyWorkspacePath);
      final clientUrl = _storage.getString(_keyClientUrl);

      OnboardingMode? selectedMode;
      if (modeStr == 'host') {
        selectedMode = OnboardingMode.host;
      } else if (modeStr == 'client') {
        selectedMode = OnboardingMode.client;
      }

      state = state.copyWith(
        isCompleted: isCompleted,
        selectedMode: selectedMode,
        workspaceName: workspaceName,
        workspacePath: workspacePath,
        clientUrl: clientUrl,
        currentStep: isCompleted ? 2 : 0,
      );
    } catch (e) {
      // Keep default state if loading fails
    }
  }

  void selectMode(OnboardingMode mode) {
    state = state.copyWith(
      selectedMode: mode,
      error: null,
    );
  }

  void setWorkspaceName(String name) {
    state = state.copyWith(workspaceName: name);
  }

  void setWorkspacePath(String path) {
    state = state.copyWith(workspacePath: path);
  }

  void setSelectedPreset(WorkspacePreset preset) {
    state = state.copyWith(selectedPreset: preset);
  }

  void setClientUrl(String url) {
    state = state.copyWith(clientUrl: url, error: null);
  }

  void goToStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setError(String error) {
    state = state.copyWith(error: error, isLoading: false);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<bool> createWorkspace({
    required String workspaceName,
    required String workspacePath,
    required WorkspacePreset preset,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Create workspace via API
      final workspace = await _apiClient.createWorkspace(
        name: workspaceName,
        path: workspacePath,
        description: _getPresetDescription(preset),
      );

      // Set as active workspace
      await _apiClient.setActiveWorkspace(workspace.id);

      // Save to storage
      await _storage.setString(_keyWorkspaceName, workspaceName);
      await _storage.setString(_keyWorkspacePath, workspacePath);

      state = state.copyWith(
        workspaceName: workspaceName,
        workspacePath: workspacePath,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to create workspace: $e',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> connectToServer(String url) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // TODO: Implement actual connection test
      // For now, simulate connection
      await Future.delayed(const Duration(seconds: 1));

      // Save to storage
      await _storage.setString(_keyClientUrl, url);

      state = state.copyWith(
        clientUrl: url,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to connect to server: $e',
        isLoading: false,
      );
      return false;
    }
  }

  Future<bool> completeOnboarding() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Save mode to storage
      await _storage.setBool(_keyOnboardingCompleted, true);
      await _storage.setString(
        _keySelectedMode,
        state.selectedMode?.name ?? '',
      );

      state = state.copyWith(
        isCompleted: true,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to complete onboarding: $e',
        isLoading: false,
      );
      return false;
    }
  }

  Future<void> resetOnboarding() async {
    await _storage.remove(_keyOnboardingCompleted);
    await _storage.remove(_keySelectedMode);
    await _storage.remove(_keyWorkspaceName);
    await _storage.remove(_keyWorkspacePath);
    await _storage.remove(_keyClientUrl);

    state = const OnboardingState();
  }

  String _getPresetDescription(WorkspacePreset preset) {
    switch (preset) {
      case WorkspacePreset.starter:
        return 'Starter preset with essential features enabled';
      case WorkspacePreset.automation:
        return 'Automation preset optimized for workflows and CI/CD';
      case WorkspacePreset.minimal:
        return 'Minimal preset with only core functionality';
    }
  }
}

// Onboarding provider
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final storage = ref.watch(storageProvider);
  final apiClient = ref.watch(apiClientProvider);
  return OnboardingNotifier(storage, apiClient);
});
