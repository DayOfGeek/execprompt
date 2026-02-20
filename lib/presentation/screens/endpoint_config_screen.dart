// ExecPrompt - AI LLM Mobile Client
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/endpoint.dart';
import '../../data/models/model_info.dart';
import '../../data/services/api_adapter.dart';
import '../../domain/providers/endpoint_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';

/// Full-page form screen for adding or editing an endpoint.
///
/// When [endpoint] is null the screen opens in "Add" mode;
/// when provided it opens in "Edit" mode with fields pre-populated.
class EndpointConfigScreen extends ConsumerStatefulWidget {
  final Endpoint? endpoint;
  const EndpointConfigScreen({super.key, this.endpoint});

  @override
  ConsumerState<EndpointConfigScreen> createState() =>
      _EndpointConfigScreenState();
}

class _EndpointConfigScreenState extends ConsumerState<EndpointConfigScreen> {
  static const _uuid = Uuid();

  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _apiKeyController;
  EndpointType _type = EndpointType.ollama;

  bool _isEdit = false;
  String _endpointId = '';

  // Connection test state
  _ConnectionStatus _connectionStatus = _ConnectionStatus.idle;
  String _connectionMessage = '';

  // Models state
  bool _isLoadingModels = false;
  List<ModelInfo> _availableModels = [];
  Set<String> _selectedModelIds = {};
  String _modelSearchQuery = '';

  // Save state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final ep = widget.endpoint;
    _isEdit = ep != null;
    _endpointId = ep?.id ?? _uuid.v4();
    _nameController = TextEditingController(text: ep?.name ?? '');
    _urlController = TextEditingController(text: ep?.baseUrl ?? '');
    _apiKeyController = TextEditingController(text: ep?.apiKey ?? '');
    _type = ep?.type ?? EndpointType.ollama;
    _selectedModelIds = Set<String>.from(ep?.selectedModels ?? []);

    // Pre-fill default URL for new endpoints
    if (!_isEdit) {
      _urlController.text = _defaultUrl(_type);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  String _defaultUrl(EndpointType type) {
    switch (type) {
      case EndpointType.ollama:
        return 'http://localhost:11434';
      case EndpointType.openai:
        return 'https://api.openai.com';
      case EndpointType.anthropic:
        return 'https://api.anthropic.com';
    }
  }

  String _urlHint(EndpointType type) {
    switch (type) {
      case EndpointType.ollama:
        return 'e.g. http://10.0.2.2:11434';
      case EndpointType.openai:
        return 'e.g. https://openrouter.ai/api';
      case EndpointType.anthropic:
        return 'https://api.anthropic.com';
    }
  }

  String _defaultName(EndpointType type) {
    switch (type) {
      case EndpointType.ollama:
        return 'Ollama';
      case EndpointType.openai:
        return 'OpenAI';
      case EndpointType.anthropic:
        return 'Anthropic';
    }
  }

  String _typeLabel(EndpointType type) {
    switch (type) {
      case EndpointType.ollama:
        return 'Ollama';
      case EndpointType.openai:
        return 'OpenAI Compatible';
      case EndpointType.anthropic:
        return 'Anthropic';
    }
  }

  String _typeHint(EndpointType type) {
    switch (type) {
      case EndpointType.ollama:
        return 'Local or remote Ollama server';
      case EndpointType.openai:
        return 'OpenAI, OpenRouter, Groq, Together, etc.';
      case EndpointType.anthropic:
        return 'Anthropic Claude API';
    }
  }

  ApiAdapter _buildAdapter() {
    final url = _urlController.text.trim();
    final key = _apiKeyController.text.trim();
    switch (_type) {
      case EndpointType.ollama:
        return ref.read(adapterForEndpointProvider(Endpoint(
          id: _endpointId,
          name: _nameController.text.trim(),
          baseUrl: url,
          type: _type,
          selectedModels: [],
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          apiKey: key.isNotEmpty ? key : null,
        )));
      case EndpointType.openai:
        return ref.read(adapterForEndpointProvider(Endpoint(
          id: _endpointId,
          name: _nameController.text.trim(),
          baseUrl: url,
          type: _type,
          selectedModels: [],
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          apiKey: key.isNotEmpty ? key : null,
        )));
      case EndpointType.anthropic:
        return ref.read(adapterForEndpointProvider(Endpoint(
          id: _endpointId,
          name: _nameController.text.trim(),
          baseUrl: url,
          type: _type,
          selectedModels: [],
          sortOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          apiKey: key.isNotEmpty ? key : null,
        )));
    }
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _connectionStatus = _ConnectionStatus.error;
        _connectionMessage = 'Server URL is required';
      });
      return;
    }

    setState(() {
      _connectionStatus = _ConnectionStatus.checking;
      _connectionMessage = '';
    });

    try {
      final adapter = _buildAdapter();
      final result = await adapter.testConnection();
      if (mounted) {
        setState(() {
          _connectionStatus = _ConnectionStatus.connected;
          _connectionMessage = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionStatus = _ConnectionStatus.error;
          _connectionMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _loadModels() async {
    setState(() {
      _isLoadingModels = true;
      _availableModels = [];
    });

    try {
      final adapter = _buildAdapter();
      final models = await adapter.listModels();
      if (mounted) {
        setState(() {
          _availableModels = models;
          _isLoadingModels = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingModels = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('> Failed to load models: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('> Name is required')),
      );
      return;
    }
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('> Server URL is required')),
      );
      return;
    }
    if (_selectedModelIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('> Select at least one model')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final apiKey = _apiKeyController.text.trim();
      final now = DateTime.now();
      final endpoint = Endpoint(
        id: _endpointId,
        name: name,
        baseUrl: url,
        type: _type,
        selectedModels: _selectedModelIds.toList(),
        sortOrder: widget.endpoint?.sortOrder ?? 999,
        isActive: widget.endpoint?.isActive ?? true,
        createdAt: widget.endpoint?.createdAt ?? now,
        updatedAt: now,
        apiKey: apiKey.isNotEmpty ? apiKey : null,
      );

      final notifier = ref.read(endpointsProvider.notifier);
      if (_isEdit) {
        await notifier.updateEndpoint(endpoint);
      } else {
        await notifier.addEndpoint(endpoint);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? '> Endpoint updated' : '> Endpoint added',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('> Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit ? '▸ EDIT ENDPOINT' : '▸ ADD ENDPOINT',
          style: mono.copyWith(
            color: colors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: Text(
              _isSaving ? '...' : '[SAVE]',
              style: mono.copyWith(
                color: _isSaving ? colors.textDim : colors.primary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ─── PROVIDER TYPE ───
          _buildSectionHeader('PROVIDER TYPE', colors, mono),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: EndpointType.values.map((type) {
                final isSelected = type == _type;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _type = type;
                      // Auto-fill defaults when switching type on new endpoints
                      if (!_isEdit) {
                        _urlController.text = _defaultUrl(type);
                        if (_nameController.text.isEmpty ||
                            EndpointType.values.any(
                                (t) => _nameController.text == _defaultName(t))) {
                          _nameController.text = _defaultName(type);
                        }
                      }
                    });
                    // Clear models when switching type
                    _availableModels = [];
                    _selectedModelIds = {};
                    _connectionStatus = _ConnectionStatus.idle;
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.1)
                          : null,
                      border: type != EndpointType.values.last
                          ? Border(
                              bottom: BorderSide(
                                  color: colors.border, width: 0.5))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Text(
                          isSelected ? '● ' : '○ ',
                          style: mono.copyWith(
                            color: isSelected
                                ? colors.primary
                                : colors.textDim,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _typeLabel(type),
                                style: mono.copyWith(
                                  color: isSelected
                                      ? colors.primary
                                      : colors.textColor,
                                  fontSize: 12,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Text(
                                _typeHint(type),
                                style: mono.copyWith(
                                    color: colors.textDim, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // ─── ENDPOINT DETAILS ───
          _buildSectionHeader('ENDPOINT DETAILS', colors, mono),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Name',
                    style: mono.copyWith(
                        color: colors.primaryDim, fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  style:
                      mono.copyWith(color: colors.textColor, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'e.g. My Ollama, OpenRouter',
                    hintStyle:
                        mono.copyWith(color: colors.textDim, fontSize: 12),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                Text('Server URL',
                    style: mono.copyWith(
                        color: colors.primaryDim, fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: _urlController,
                  style:
                      mono.copyWith(color: colors.textColor, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: _urlHint(_type),
                    hintStyle:
                        mono.copyWith(color: colors.textDim, fontSize: 12),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                Text(
                  _type == EndpointType.ollama
                      ? 'API Key (optional)'
                      : 'API Key',
                  style: mono.copyWith(
                      color: colors.primaryDim, fontSize: 11),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _apiKeyController,
                  style:
                      mono.copyWith(color: colors.textColor, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: _type == EndpointType.anthropic
                        ? 'sk-ant-...'
                        : 'sk-...',
                    hintStyle:
                        mono.copyWith(color: colors.textDim, fontSize: 12),
                    isDense: true,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),

                // Connection test
                Row(
                  children: [
                    FilledButton(
                      onPressed: _connectionStatus == _ConnectionStatus.checking
                          ? null
                          : _testConnection,
                      child: Text(
                        '[TEST CONNECTION]',
                        style: mono.copyWith(
                            fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: _buildConnectionStatus(colors, mono)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── MODELS ───
          _buildSectionHeader('MODELS', colors, mono),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                // Fetch models button & search
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          FilledButton(
                            onPressed: _isLoadingModels ? null : _loadModels,
                            child: Text(
                              _isLoadingModels
                                  ? '[LOADING...]'
                                  : '[FETCH MODELS]',
                              style: mono.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_availableModels.isNotEmpty)
                            Text(
                              '${_availableModels.length} available, '
                              '${_selectedModelIds.length} selected',
                              style: mono.copyWith(
                                  color: colors.textDim, fontSize: 10),
                            ),
                        ],
                      ),
                      if (_availableModels.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        TextField(
                          style: mono.copyWith(
                              color: colors.textColor, fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Search models...',
                            hintStyle: mono.copyWith(
                                color: colors.textDim, fontSize: 12),
                            isDense: true,
                            prefixText: '> ',
                            prefixStyle: mono.copyWith(
                                color: colors.primaryDim, fontSize: 12),
                          ),
                          onChanged: (v) =>
                              setState(() => _modelSearchQuery = v),
                        ),
                      ],
                    ],
                  ),
                ),

                // Model list
                if (_isLoadingModels)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                              strokeWidth: 1.5, color: colors.primaryDim),
                        ),
                        const SizedBox(width: 8),
                        Text('Fetching models...',
                            style: mono.copyWith(
                                color: colors.textDim, fontSize: 11)),
                      ],
                    ),
                  )
                else if (_availableModels.isNotEmpty)
                  ..._buildModelList(colors, mono),

                // Show selected models that weren't fetched (edit mode)
                if (_selectedModelIds.isNotEmpty &&
                    _availableModels.isEmpty &&
                    !_isLoadingModels)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected models:',
                          style: mono.copyWith(
                              color: colors.primaryDim, fontSize: 11),
                        ),
                        const SizedBox(height: 4),
                        ..._selectedModelIds.map((id) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '● $id',
                                style: mono.copyWith(
                                    color: colors.primary, fontSize: 11),
                              ),
                            )),
                        const SizedBox(height: 8),
                        Text(
                          'Fetch models to modify selection',
                          style: mono.copyWith(
                              color: colors.textDim, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, CyberTermColors colors, TextStyle mono) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 4),
      child: Text(
        '── $title ──',
        style: mono.copyWith(
          color: colors.primaryDim,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildConnectionStatus(CyberTermColors colors, TextStyle mono) {
    switch (_connectionStatus) {
      case _ConnectionStatus.idle:
        return const SizedBox.shrink();
      case _ConnectionStatus.checking:
        return Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: colors.primaryDim),
            ),
            const SizedBox(width: 8),
            Text('Testing...',
                style: mono.copyWith(color: colors.textDim, fontSize: 11)),
          ],
        );
      case _ConnectionStatus.connected:
        return Row(
          children: [
            Container(width: 8, height: 8, color: const Color(0xFF33FF33)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _connectionMessage,
                style: mono.copyWith(
                    color: const Color(0xFF33FF33), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      case _ConnectionStatus.error:
        return Row(
          children: [
            Container(width: 8, height: 8, color: colors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _connectionMessage,
                style: mono.copyWith(color: colors.error, fontSize: 11),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        );
    }
  }

  List<Widget> _buildModelList(CyberTermColors colors, TextStyle mono) {
    final query = _modelSearchQuery.toLowerCase();
    final filtered = query.isEmpty
        ? _availableModels
        : _availableModels
            .where((m) =>
                m.id.toLowerCase().contains(query) ||
                m.displayName.toLowerCase().contains(query))
            .toList();

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'No models match "$_modelSearchQuery"',
            style: mono.copyWith(color: colors.textDim, fontSize: 11),
          ),
        ),
      ];
    }

    // Select/deselect all visible
    return [
      Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            final allVisible = filtered.map((m) => m.id).toSet();
            setState(() {
              if (allVisible.every(_selectedModelIds.contains)) {
                _selectedModelIds.removeAll(allVisible);
              } else {
                _selectedModelIds.addAll(allVisible);
              }
            });
          },
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              filtered.every((m) => _selectedModelIds.contains(m.id))
                  ? '[DESELECT ALL]'
                  : '[SELECT ALL]',
              style: mono.copyWith(
                color: colors.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      // Model tiles
      ...filtered.map((model) {
        final isSelected = _selectedModelIds.contains(model.id);
        return InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              if (isSelected) {
                _selectedModelIds.remove(model.id);
              } else {
                _selectedModelIds.add(model.id);
              }
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? colors.primary.withValues(alpha: 0.08)
                  : null,
              border: Border(
                top: BorderSide(color: colors.border, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Text(
                  isSelected ? '☑ ' : '☐ ',
                  style: mono.copyWith(
                    color: isSelected ? colors.primary : colors.textDim,
                    fontSize: 12,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        model.displayName,
                        style: mono.copyWith(
                          color: isSelected
                              ? colors.primary
                              : colors.textColor,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (model.parameterSize != null ||
                          model.family != null)
                        Text(
                          [
                            if (model.parameterSize != null)
                              model.parameterSize,
                            if (model.family != null) model.family,
                            if (model.quantizationLevel != null)
                              model.quantizationLevel,
                          ].join(' • '),
                          style: mono.copyWith(
                              color: colors.textDim, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    ];
  }
}

enum _ConnectionStatus { idle, checking, connected, error }
