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
import '../../data/models/endpoint.dart';
import '../../domain/providers/endpoint_provider.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import '../screens/endpoint_config_screen.dart';

/// Settings section that lists configured endpoints and provides
/// add/edit/delete actions. Replaces the old CONNECTION section.
class EndpointListSection extends ConsumerWidget {
  const EndpointListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final endpoints = ref.watch(endpointsProvider);
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          // Endpoint list
          if (endpoints.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'No endpoints configured',
                    style: mono.copyWith(color: colors.textDim, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add an endpoint to connect to an AI provider',
                    style: mono.copyWith(color: colors.textDim, fontSize: 10),
                  ),
                ],
              ),
            )
          else
            ...endpoints.map((endpoint) => _EndpointTile(
                  endpoint: endpoint,
                  isLast: endpoint == endpoints.last,
                )),
          // Add button
          InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EndpointConfigScreen(),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  top: endpoints.isNotEmpty
                      ? BorderSide(color: colors.border, width: 0.5)
                      : BorderSide.none,
                ),
              ),
              child: Center(
                child: Text(
                  '[+ ADD ENDPOINT]',
                  style: mono.copyWith(
                    color: colors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointTile extends ConsumerWidget {
  final Endpoint endpoint;
  final bool isLast;

  const _EndpointTile({required this.endpoint, required this.isLast});

  String _typeLabel(EndpointType type) {
    switch (type) {
      case EndpointType.ollama:
        return 'Ollama';
      case EndpointType.openai:
        return 'OpenAI';
      case EndpointType.anthropic:
        return 'Anthropic';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    final modelCount = endpoint.selectedModels.length;
    final host = Uri.tryParse(endpoint.baseUrl)?.host ?? endpoint.baseUrl;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EndpointConfigScreen(endpoint: endpoint),
          ),
        );
      },
      onLongPress: () => _showMenu(context, ref),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: endpoint.isActive
              ? colors.primary.withOpacity(0.05)
              : null,
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(color: colors.border, width: 0.5),
                ),
        ),
        child: Row(
          children: [
            // Status indicator
            Text(
              endpoint.isActive ? '● ' : '○ ',
              style: mono.copyWith(
                color: endpoint.isActive ? colors.primary : colors.textDim,
                fontSize: 12,
              ),
            ),
            // Endpoint info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    endpoint.name,
                    style: mono.copyWith(
                      color: endpoint.isActive
                          ? colors.primary
                          : colors.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$host • ${_typeLabel(endpoint.type)} • '
                    '$modelCount model${modelCount == 1 ? '' : 's'}',
                    style: mono.copyWith(
                      color: colors.textDim,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            // More menu
            GestureDetector(
              onTap: () => _showMenu(context, ref),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  '[⋮]',
                  style: mono.copyWith(
                    color: colors.textDim,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        color: colors.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MenuAction(
              label: 'Edit',
              icon: '▸',
              colors: colors,
              mono: mono,
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        EndpointConfigScreen(endpoint: endpoint),
                  ),
                );
              },
            ),
            _MenuAction(
              label: endpoint.isActive ? 'Disable' : 'Enable',
              icon: endpoint.isActive ? '○' : '●',
              colors: colors,
              mono: mono,
              onTap: () {
                Navigator.pop(ctx);
                ref.read(endpointsProvider.notifier).toggleEndpoint(
                      endpoint.id,
                      isActive: !endpoint.isActive,
                    );
              },
            ),
            _MenuAction(
              label: 'Delete',
              icon: '✕',
              colors: colors,
              mono: mono,
              isDestructive: true,
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).cyberTermColors;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Endpoint'),
        content: Text(
            'Delete "${endpoint.name}"? This will remove the endpoint and its API key.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () {
              ref
                  .read(endpointsProvider.notifier)
                  .deleteEndpoint(endpoint.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _MenuAction extends StatelessWidget {
  final String label;
  final String icon;
  final CyberTermColors colors;
  final TextStyle mono;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuAction({
    required this.label,
    required this.icon,
    required this.colors,
    required this.mono,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? colors.error : colors.textColor;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Text('$icon ', style: mono.copyWith(color: color, fontSize: 14)),
            Text(label, style: mono.copyWith(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
