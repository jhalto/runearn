import 'package:flutter/material.dart';

class TransactionTagsField extends StatefulWidget {
  const TransactionTagsField({
    required this.tags,
    required this.onChanged,
    super.key,
  });

  final List<String> tags;
  final ValueChanged<List<String>> onChanged;

  @override
  State<TransactionTagsField> createState() => _TransactionTagsFieldState();
}

class _TransactionTagsFieldState extends State<TransactionTagsField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(String raw) {
    final tag = raw.trim().toLowerCase().replaceFirst(RegExp(r'^#+'), '');
    if (tag.isEmpty) return;
    if (!widget.tags.contains(tag)) {
      widget.onChanged(List.unmodifiable([...widget.tags, tag]));
    }
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Tags (optional)',
        helperText: 'Press Enter after each tag',
        prefixIcon: Icon(Icons.sell_outlined),
        border: OutlineInputBorder(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final tag in widget.tags)
                    InputChip(
                      label: Text('#$tag'),
                      onDeleted: () => widget.onChanged(
                        widget.tags.where((item) => item != tag).toList(),
                      ),
                    ),
                ],
              ),
            ),
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.done,
            onSubmitted: _add,
            decoration: const InputDecoration(
              hintText: 'e.g. office, family, tax',
              border: InputBorder.none,
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }
}
