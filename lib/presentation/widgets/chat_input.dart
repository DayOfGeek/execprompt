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
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../presentation/theme/cyberterm_theme.dart';
import 'image_preview.dart';

class ChatInput extends StatefulWidget {
  final bool enabled;
  final Function(String message, {List<String>? images}) onSend;
  final bool isLoading;
  final VoidCallback? onStopGeneration;
  final TextEditingController? externalController;

  const ChatInput({
    super.key,
    required this.enabled,
    required this.onSend,
    this.isLoading = false,
    this.onStopGeneration,
    this.externalController,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  late TextEditingController _controller;
  final _focusNode = FocusNode();
  final _imagePicker = ImagePicker();
  bool _hasText = false;
  final List<String> _attachedImages = [];
  bool _ownsController = false;
  bool _isPickerLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.externalController != null) {
      _controller = widget.externalController!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }
    _hasText = _controller.text.trim().isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void didUpdateWidget(ChatInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.externalController != oldWidget.externalController) {
      _controller.removeListener(_onTextChanged);
      if (_ownsController) _controller.dispose();
      if (widget.externalController != null) {
        _controller = widget.externalController!;
        _ownsController = false;
      } else {
        _controller = TextEditingController();
        _ownsController = true;
      }
      _hasText = _controller.text.trim().isNotEmpty;
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _canSend => (_hasText || _attachedImages.isNotEmpty) && widget.enabled;

  void _handleSend() {
    final text = _controller.text.trim();
    if (_canSend) {
      HapticFeedback.lightImpact();
      widget.onSend(
        text.isNotEmpty ? text : '(image attached)',
        images: _attachedImages.isNotEmpty ? List.from(_attachedImages) : null,
      );
      _controller.clear();
      setState(() {
        _attachedImages.clear();
      });
      _focusNode.requestFocus();
    }
  }

  Future<void> _handleImagePick() async {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '▸ ATTACH IMAGE',
                style: mono.copyWith(
                  color: colors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(height: 1, color: colors.border),
            ListTile(
              leading: Icon(Icons.photo_library, color: colors.primaryDim),
              title: Text('Gallery', style: mono.copyWith(color: colors.textColor, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: colors.primaryDim),
              title: Text('Camera', style: mono.copyWith(color: colors.textColor, fontSize: 13)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isPickerLoading = true);
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          _attachedImages.add(base64Image);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('> Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickerLoading = false);
    }
  }

  void _removeImage(int index) {
    setState(() {
      _attachedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).cyberTermColors;
    final mono = GoogleFonts.jetBrainsMono();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image preview row
            if (_attachedImages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ImagePreviewRow(
                  images: _attachedImages,
                  onRemove: _removeImage,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Image attach button
                InkWell(
                  onTap: (widget.enabled && !_isPickerLoading) ? _handleImagePick : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: _isPickerLoading
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.primaryDim,
                            ),
                          )
                        : Text(
                            '[+]',
                            style: mono.copyWith(
                              color: widget.enabled ? colors.primaryDim : colors.textDim,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                // Prompt indicator
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    '> ',
                    style: mono.copyWith(
                      color: colors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Input field
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: widget.enabled,
                    style: mono.copyWith(
                      color: colors.textColor,
                      fontSize: 13,
                    ),
                    decoration: InputDecoration(
                      hintText: widget.enabled ? 'Enter command...' : 'Select a model first',
                      hintStyle: mono.copyWith(color: colors.textDim, fontSize: 13),
                      filled: true,
                      fillColor: colors.inputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.primary, width: 1),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(color: colors.border.withOpacity(0.3)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      isDense: true,
                    ),
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: widget.enabled ? (_) => _handleSend() : null,
                  ),
                ),
                const SizedBox(width: 6),
                // Send / Stop button
                if (widget.isLoading)
                  InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      widget.onStopGeneration?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.error),
                        color: colors.error.withOpacity(0.1),
                      ),
                      child: Text(
                        'STOP',
                        style: mono.copyWith(
                          color: colors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                else
                  InkWell(
                    onTap: _canSend ? _handleSend : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _canSend ? colors.primary : colors.border,
                        ),
                        color: _canSend ? colors.primary.withOpacity(0.1) : null,
                      ),
                      child: Text(
                        '[↵]',
                        style: mono.copyWith(
                          color: _canSend ? colors.primary : colors.textDim,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
