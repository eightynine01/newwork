import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/ai_provider.dart';
import '../../../data/providers/dashboard_providers.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

class ModelPickerDialog extends ConsumerStatefulWidget {
  final String? currentModelId;
  final bool showSetAsDefaultButton;

  const ModelPickerDialog({
    super.key,
    this.currentModelId,
    this.showSetAsDefaultButton = true,
  });

  @override
  ConsumerState<ModelPickerDialog> createState() => _ModelPickerDialogState();
}

class _ModelPickerDialogState extends ConsumerState<ModelPickerDialog> {
  String _searchQuery = '';
  String? _selectedProviderId;
  String? _selectedModelId;

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.currentModelId;
  }

  @override
  Widget build(BuildContext context) {
    final providersState = ref.watch(providersProvider);
    final providers = providersState.providers;

    // Filter providers based on search
    List<AIProvider> filteredProviders = providers.where((provider) {
      final providerModels = providersState.getModelsForProvider(provider.id);
      return providerModels.any((model) =>
          model.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          provider.name.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    // Get models for selected provider
    List<AIModel> displayModels = _selectedProviderId != null
        ? providersState.getModelsForProvider(_selectedProviderId!)
        : [];

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildSearchBar(context),
            Expanded(
              child: _buildContent(
                  context, providersState, filteredProviders, displayModels),
            ),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.psychology,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select Model',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search models...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProvidersState providersState,
    List<AIProvider> filteredProviders,
    List<AIModel> displayModels,
  ) {
    if (providersState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (providersState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load models',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              providersState.error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_selectedProviderId == null) {
      return _buildProvidersList(context, filteredProviders);
    } else {
      return _buildModelsList(context, displayModels, providersState);
    }
  }

  Widget _buildProvidersList(BuildContext context, List<AIProvider> providers) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No providers found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: providers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final provider = providers[index];
        final providerModels =
            ref.read(providersProvider).getModelsForProvider(provider.id);

        return AppCard(
          onTap: () {
            setState(() {
              _selectedProviderId = provider.id;
            });
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_tree,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (provider.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        provider.description!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${providerModels.length} models',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModelsList(
    BuildContext context,
    List<AIModel> models,
    ProvidersState providersState,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _selectedProviderId = null;
                  });
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _searchQuery.isEmpty ? 'All Models' : 'Search Results',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${models.length} models',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (models.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No models found',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: models.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final model = models[index];
                final isSelected = _selectedModelId == model.id;

                return AppCard(
                  variant: isSelected
                      ? AppCardVariant.outlined
                      : AppCardVariant.elevated,
                  backgroundColor: isSelected
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withOpacity(0.3)
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      model.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ..._buildCapabilityBadges(context, model),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  model.providerName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                                if (model.description != null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    model.description!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Radio<String>(
                            value: model.id,
                            groupValue: _selectedModelId,
                            onChanged: (value) {
                              setState(() {
                                _selectedModelId = value;
                              });
                            },
                          ),
                        ],
                      ),
                      if (model.cost != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              model.cost!['free'] == true
                                  ? Icons.check_circle
                                  : Icons.payments_outlined,
                              size: 16,
                              color: model.cost!['free'] == true
                                  ? Colors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              model.cost!['free'] == true ? 'Free' : 'Paid',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: model.cost!['free'] == true
                                        ? Colors.green
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  List<Widget> _buildCapabilityBadges(BuildContext context, AIModel model) {
    List<Widget> badges = [];

    if (model.capabilities.any((c) => c == ModelCapability.reasoning)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Reasoning',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.purple,
            ),
          ),
        ),
      );
    }

    if (model.capabilities.any((c) => c == ModelCapability.vision)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Vision',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.blue,
            ),
          ),
        ),
      );
    }

    if (model.capabilities.any((c) => c == ModelCapability.tools)) {
      badges.add(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Tools',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.orange,
            ),
          ),
        ),
      );
    }

    return badges;
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedModelId != null
                  ? () {
                      Navigator.pop(context, _selectedModelId);
                    }
                  : null,
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
    );
  }
}
