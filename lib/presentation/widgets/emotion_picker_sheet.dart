// lib/presentation/widgets/emotion_picker_sheet.dart
//
// The "under-5-second" check-in. UX principles baked in:
//
//   1. Five emoji buttons sit in the thumb-zone (bottom half of screen).
//   2. A single tap on an emoji is enough — notes/tags are optional.
//   3. Sheet uses showModalBottomSheet with rounded corners — matches
//      the app's calming geometry.

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/models/emotion_entry.dart';

/// Convenience launcher. Returns the resulting EmotionEntry, or null
/// if the user dismissed the sheet without submitting. Pass [initial] to
/// pre-fill the form for editing an existing entry.
Future<EmotionEntry?> showEmotionPickerSheet(
  BuildContext context, {
  EmotionEntry? initial,
}) {
  return showModalBottomSheet<EmotionEntry>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EmotionPickerSheet(initial: initial),
  );
}

class _EmotionPickerSheet extends StatefulWidget {
  final EmotionEntry? initial;
  const _EmotionPickerSheet({this.initial});

  @override
  State<_EmotionPickerSheet> createState() => _EmotionPickerSheetState();
}

class _EmotionPickerSheetState extends State<_EmotionPickerSheet> {
  int? _selectedScore;
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  bool _expanded = false;

  bool get _isEditing => widget.initial != null;

  static const List<_EmojiData> _emojis = [
    _EmojiData(1, '😢', 'Sangat Buruk', AppColors.emotion1),
    _EmojiData(2, '😕', 'Buruk', AppColors.emotion2),
    _EmojiData(3, '😐', 'Biasa', AppColors.emotion3),
    _EmojiData(4, '🙂', 'Baik', AppColors.emotion4),
    _EmojiData(5, '😊', 'Sangat Baik', AppColors.emotion5),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _selectedScore = initial.emotionScore;
      if (initial.tags != null && initial.tags!.isNotEmpty) {
        _tagsController.text = initial.tags!.map((t) => '#$t').join(' ');
      }
      if (initial.notes != null && initial.notes!.isNotEmpty) {
        _notesController.text = initial.notes!;
      }
      _expanded = (initial.tags?.isNotEmpty ?? false) ||
          (initial.notes?.isNotEmpty ?? false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _submit() {
    final score = _selectedScore;
    if (score == null) return;

    final tags = _tagsController.text
        .split(RegExp(r'[\s,]+'))
        .map((t) => t.startsWith('#') ? t.substring(1) : t)
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    Navigator.of(context).pop(
      EmotionEntry(
        emotionScore: score,
        timestamp: widget.initial?.timestamp ?? DateTime.now(),
        tags: tags.isEmpty ? null : tags,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabber(),
            const SizedBox(height: AppSpacing.md),
            Text(
              _isEditing
                  ? 'Ubah catatan ini'
                  : 'Bagaimana perasaanmu sekarang?',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _emojis.map(_emojiButton).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!_expanded)
              TextButton(
                onPressed: () => setState(() => _expanded = true),
                child: const Text('+ Tambah detail (opsional)'),
              )
            else
              _detailFields(),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedScore == null ? null : _submit,
                child: const Text('Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _grabber() => Container(
        height: 4,
        width: 48,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      );

  Widget _emojiButton(_EmojiData data) {
    final selected = _selectedScore == data.score;

    return GestureDetector(
      onTap: () => setState(() => _selectedScore = data.score),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        width: 56,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected
              ? data.color
              : data.color.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color:
                selected ? AppColors.primarySageDeep : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(data.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailFields() {
    return Column(
      children: [
        TextField(
          controller: _tagsController,
          decoration: const InputDecoration(
            hintText: '#kerja #keluarga #tidur',
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _notesController,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Catatan singkat...',
          ),
        ),
      ],
    );
  }
}

class _EmojiData {
  final int score;
  final String emoji;
  final String label;
  final Color color;
  const _EmojiData(this.score, this.emoji, this.label, this.color);
}
