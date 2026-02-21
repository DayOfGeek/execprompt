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

/// A widget that displays an image preview with a remove button.
/// Supports both base64-encoded images and file paths.
class ImagePreview extends StatelessWidget {
  final String imageData;
  final VoidCallback? onRemove;
  final double size;

  const ImagePreview({
    super.key,
    required this.imageData,
    this.onRemove,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildImage(context),
        ),
        if (onRemove != null)
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    // If it's a base64 string
    if (_isBase64(imageData)) {
      try {
        final bytes = base64Decode(imageData);
        return Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(context),
        );
      } catch (_) {
        return _buildErrorPlaceholder(context);
      }
    }

    // If it's a file path
    final file = File(imageData);
    if (file.existsSync()) {
      return Image.file(
        file,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(context),
      );
    }

    return _buildErrorPlaceholder(context);
  }

  Widget _buildErrorPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.broken_image,
        color: Theme.of(context).colorScheme.onErrorContainer,
      ),
    );
  }

  bool _isBase64(String data) {
    try {
      // Quick heuristic: base64 strings don't contain path separators
      if (data.contains('/') && data.length < 200) return false;
      return data.length > 100; // base64 images are always long
    } catch (_) {
      return false;
    }
  }
}

/// A horizontal scrollable row of image previews for the chat input area.
class ImagePreviewRow extends StatelessWidget {
  final List<String> images;
  final Function(int) onRemove;

  const ImagePreviewRow({
    super.key,
    required this.images,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ImagePreview(
            imageData: images[index],
            onRemove: () => onRemove(index),
          );
        },
      ),
    );
  }
}
