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


import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../domain/providers/settings_provider.dart';
import '../../domain/providers/database_provider.dart';
import '../../domain/providers/endpoint_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import '../widgets/endpoint_list_section.dart';
import '../widgets/model_configuration_widget.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _ollamaSearchKeyController;
  late TextEditingController _tavilyKeyController;

  @override
  void initState() {
    super.initState();
    _ollamaSearchKeyController = TextEditingController();
    _tavilyKeyController = TextEditingController();
  }

  @override
  void dispose() {
    _ollamaSearchKeyController.dispose();
    _tavilyKeyController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);
    final searchProvider = ref.watch(searchProviderProvider);
    final ollamaSearchKey = ref.watch(ollamaCloudSearchKeyProvider);
    final tavilyKey = ref.watch(tavilyApiKeyProvider);
    final maxResults = ref.watch(searchMaxResultsProvider);
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    if (_ollamaSearchKeyController.text.isEmpty && ollamaSearchKey != null) {
      _ollamaSearchKeyController.text = ollamaSearchKey;
    }
    if (_tavilyKeyController.text.isEmpty && tavilyKey != null) {
      _tavilyKeyController.text = tavilyKey;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '▸ SETTINGS',
          style: mono.copyWith(
            color: colors.primary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ─── THEME ───
          _SectionHeader(title: 'THEME', colors: colors, mono: mono),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: CyberTermTheme.values.map((theme) {
                final isSelected = theme == currentTheme;
                final themeColors = getThemeColors(theme);
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    saveTheme(ref, theme);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? colors.primary.withOpacity(0.1) : null,
                      border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        // Color swatch
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: themeColors.primary,
                            border: Border.all(
                              color: isSelected ? colors.primary : colors.border,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isSelected ? '● ' : '○ ',
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
                                theme.displayName,
                                style: mono.copyWith(
                                  color: isSelected ? colors.primary : colors.textColor,
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              Text(
                                theme.description,
                                style: mono.copyWith(color: colors.textDim, fontSize: 10),
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

          // ─── ENDPOINTS ───
          _SectionHeader(title: 'ENDPOINTS', colors: colors, mono: mono),
          const EndpointListSection(),

          const SizedBox(height: 16),

          // ─── MODEL CONFIG ───
          _SectionHeader(title: 'MODEL CONFIGURATION', colors: colors, mono: mono),
          const ModelConfigurationWidget(),

          const SizedBox(height: 16),

          // ─── WEB SEARCH ───
          _SectionHeader(title: 'WEB SEARCH', colors: colors, mono: mono),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Search Provider', style: mono.copyWith(color: colors.primaryDim, fontSize: 11)),
                const SizedBox(height: 6),
                ...SearchProvider.values.map((provider) {
                  final isSelected = searchProvider == provider;
                  return InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      saveSearchProvider(ref, provider);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text(
                            isSelected ? '● ' : '○ ',
                            style: mono.copyWith(
                              color: isSelected ? colors.primary : colors.textDim,
                              fontSize: 12,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _searchProviderLabel(provider),
                              style: mono.copyWith(
                                color: isSelected ? colors.primary : colors.textColor,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text('Ollama Cloud Search Key', style: mono.copyWith(color: colors.primaryDim, fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: _ollamaSearchKeyController,
                  style: mono.copyWith(color: colors.textColor, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'your-ollama-cloud-api-key',
                    hintStyle: mono.copyWith(color: colors.textDim, fontSize: 12),
                    isDense: true,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Text('Tavily API Key', style: mono.copyWith(color: colors.primaryDim, fontSize: 11)),
                const SizedBox(height: 6),
                TextField(
                  controller: _tavilyKeyController,
                  style: mono.copyWith(color: colors.textColor, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'tvly-xxxxxxxx',
                    hintStyle: mono.copyWith(color: colors.textDim, fontSize: 12),
                    isDense: true,
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Text('Max Results', style: mono.copyWith(color: colors.primaryDim, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: colors.primary,
                          inactiveTrackColor: colors.border,
                          thumbColor: colors.primary,
                          overlayColor: colors.primary.withOpacity(0.15),
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: maxResults.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          onChanged: (v) => saveSearchMaxResults(ref, v.round()),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        '$maxResults',
                        style: mono.copyWith(color: colors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _ollamaSearchKeyController.text = ollamaSearchKey ?? '';
                        _tavilyKeyController.text = tavilyKey ?? '';
                      },
                      child: Text('[RESET]', style: mono.copyWith(fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        final oKey = _ollamaSearchKeyController.text.trim();
                        final tKey = _tavilyKeyController.text.trim();
                        await saveOllamaCloudSearchKey(ref, oKey.isNotEmpty ? oKey : null);
                        await saveTavilyApiKey(ref, tKey.isNotEmpty ? tKey : null);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '> Web search settings saved',
                                style: mono.copyWith(fontSize: 12),
                              ),
                            ),
                          );
                        }
                      },
                      child: Text(
                        '[SAVE]',
                        style: mono.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'ℹ Auto mode uses Ollama Cloud if its search key is set, '
                  'otherwise Tavily. Get a free Tavily key at tavily.com. '
                  'The Ollama Cloud search key is separate from your endpoint API key.',
                  style: mono.copyWith(color: colors.textDim, fontSize: 10),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── DATA MANAGEMENT ───
          _SectionHeader(title: 'DATA MANAGEMENT', colors: colors, mono: mono),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                // Database statistics
                _DatabaseStatsWidget(ref: ref),
                Container(height: 0.5, color: colors.border),
                // Export all
                InkWell(
                  onTap: () => _exportConversations(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Text('> ', style: mono.copyWith(color: colors.primaryDim, fontSize: 12)),
                        Expanded(
                          child: Text(
                            'Export All Conversations',
                            style: mono.copyWith(color: colors.textColor, fontSize: 12),
                          ),
                        ),
                        Text('[JSON]', style: mono.copyWith(color: colors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Import
                InkWell(
                  onTap: () => _importConversations(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Text('> ', style: mono.copyWith(color: colors.primaryDim, fontSize: 12)),
                        Expanded(
                          child: Text(
                            'Import Conversations',
                            style: mono.copyWith(color: colors.textColor, fontSize: 12),
                          ),
                        ),
                        Text('[FILE]', style: mono.copyWith(color: colors.accent, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Clear all
                InkWell(
                  onTap: () => _confirmClearConversations(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.border, width: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Text('! ', style: mono.copyWith(color: colors.error, fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            'Clear All Conversations',
                            style: mono.copyWith(color: colors.error, fontSize: 12),
                          ),
                        ),
                        Text('[DEL]', style: mono.copyWith(color: colors.error, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                // Reset settings
                InkWell(
                  onTap: () => _resetSettings(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Text('! ', style: mono.copyWith(color: colors.textDim, fontSize: 12, fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            'Reset All Settings',
                            style: mono.copyWith(color: colors.textDim, fontSize: 12),
                          ),
                        ),
                        Text('[RST]', style: mono.copyWith(color: colors.textDim, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── LINKS ───
          _SectionHeader(title: 'LINKS', colors: colors, mono: mono),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border.all(color: colors.border),
            ),
            child: Column(
              children: [
                _LinkTile(
                  label: 'DayOfGeek Website',
                  url: 'dayofgeek.com/exec/prompt',
                  colors: colors,
                  mono: mono,
                  onTap: () => _launchUrl('https://dayofgeek.com/exec/prompt/'),
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ─── ABOUT ───
          Center(
            child: Text(
              '▸ ExecPrompt v1.0.0',
              style: mono.copyWith(color: colors.textDim, fontSize: 11),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _searchProviderLabel(SearchProvider provider) {
    switch (provider) {
      case SearchProvider.auto:
        return 'Auto (recommended)';
      case SearchProvider.ollamaCloud:
        return 'Ollama Cloud';
      case SearchProvider.tavily:
        return 'Tavily';
    }
  }

  void _confirmClearConversations(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Conversations'),
        content: const Text('This will permanently delete all conversation history. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () async {
              final db = ref.read(databaseProvider);
              // Delete all conversations (messages cascade)
              await db.delete(db.conversations).go();
              ref.invalidate(conversationsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('> All conversations cleared')),
                );
              }
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _resetSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text('Reset all settings to defaults? Conversations will not be affected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final prefs = ref.read(sharedPreferencesProvider);
              await prefs.clear();
              // Re-read defaults
              ref.invalidate(baseUrlProvider);
              ref.invalidate(temperatureProvider);
              ref.invalidate(topKProvider);
              ref.invalidate(topPProvider);
              ref.invalidate(themeProvider);
              ref.invalidate(searchProviderProvider);
              ref.invalidate(tavilyApiKeyProvider);
              ref.invalidate(searchMaxResultsProvider);
              ref.invalidate(endpointsInitProvider);
              _tavilyKeyController.clear();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('> Settings reset to defaults')),
                );
              }
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportConversations(BuildContext context) async {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    try {
      HapticFeedback.lightImpact();
      final db = ref.read(databaseProvider);
      final data = await db.exportAllData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);

      // Write to temp file and share
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
      final file = File('${dir.path}/execprompt_export_$timestamp.json');
      await file.writeAsString(jsonStr);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ExecPrompt Conversations Export',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('> Export ready', style: mono.copyWith(fontSize: 12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('> Export failed: $e', style: mono.copyWith(fontSize: 12)),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }

  Future<void> _importConversations(BuildContext context) async {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;
      final filePath = result.files.single.path;
      if (filePath == null) return;

      final file = File(filePath);
      final jsonStr = await file.readAsString();
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Validate
      if (data['conversations'] == null) {
        throw const FormatException('Invalid export file: missing conversations key');
      }

      final db = ref.read(databaseProvider);
      final count = await db.importData(data);
      ref.invalidate(conversationsProvider);

      HapticFeedback.mediumImpact();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('> Imported $count conversations', style: mono.copyWith(fontSize: 12)),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('> Import failed: $e', style: mono.copyWith(fontSize: 12)),
            backgroundColor: colors.error,
          ),
        );
      }
    }
  }
}

/// Database statistics display widget
class _DatabaseStatsWidget extends StatefulWidget {
  final WidgetRef ref;
  const _DatabaseStatsWidget({required this.ref});

  @override
  State<_DatabaseStatsWidget> createState() => _DatabaseStatsWidgetState();
}

class _DatabaseStatsWidgetState extends State<_DatabaseStatsWidget> {
  int _convCount = 0;
  int _msgCount = 0;
  String _dbSize = '...';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = widget.ref.read(databaseProvider);
      final convCount = await db.getConversationCount();
      final msgCount = await db.getMessageCount();

      // Get DB file size
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbFolder.path}/execprompt_db.sqlite');
      String dbSize = 'N/A';
      if (await dbFile.exists()) {
        final bytes = await dbFile.length();
        if (bytes >= 1024 * 1024) {
          dbSize = '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
        } else {
          dbSize = '${(bytes / 1024).toStringAsFixed(0)} KB';
        }
      }

      if (mounted) {
        setState(() {
          _convCount = convCount;
          _msgCount = msgCount;
          _dbSize = dbSize;
          _loaded = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _dbSize = 'Error';
          _loaded = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _StatBadge(
            label: 'CONV',
            value: _loaded ? '$_convCount' : '...',
            colors: colors,
            mono: mono,
          ),
          const SizedBox(width: 16),
          _StatBadge(
            label: 'MSGS',
            value: _loaded ? '$_msgCount' : '...',
            colors: colors,
            mono: mono,
          ),
          const SizedBox(width: 16),
          _StatBadge(
            label: 'SIZE',
            value: _dbSize,
            colors: colors,
            mono: mono,
          ),
          const Spacer(),
          InkWell(
            onTap: _loadStats,
            child: Text(
              '[↻]',
              style: mono.copyWith(
                color: colors.textDim,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final CyberTermColors colors;
  final TextStyle mono;

  const _StatBadge({
    required this.label,
    required this.value,
    required this.colors,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: mono.copyWith(
            color: colors.textDim,
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
        Text(
          value,
          style: mono.copyWith(
            color: colors.primary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final CyberTermColors colors;
  final TextStyle mono;

  const _SectionHeader({required this.title, required this.colors, required this.mono});

  @override
  Widget build(BuildContext context) {
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
}

class _LinkTile extends StatelessWidget {
  final String label;
  final String url;
  final CyberTermColors colors;
  final TextStyle mono;
  final VoidCallback onTap;
  final bool isLast;

  const _LinkTile({
    required this.label,
    required this.url,
    required this.colors,
    required this.mono,
    required this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: colors.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Text('> ', style: mono.copyWith(color: colors.primaryDim, fontSize: 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: mono.copyWith(color: colors.textColor, fontSize: 12)),
                  Text(url, style: mono.copyWith(color: colors.textDim, fontSize: 10)),
                ],
              ),
            ),
            Text('↗', style: mono.copyWith(color: colors.textDim, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}


