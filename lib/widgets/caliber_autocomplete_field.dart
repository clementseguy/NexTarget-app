import 'package:flutter/material.dart';
import '../utils/caliber_autocomplete.dart';

/// Champ libre proposant le référentiel de calibres sans autoremplacement.
class CaliberAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String labelText;
  final bool isRequired;
  final ValueChanged<String>? onChanged;
  final FormFieldSetter<String>? onSaved;
  final ValueChanged<String>? onSelected;

  const CaliberAutocompleteField({
    super.key,
    required this.controller,
    this.focusNode,
    this.labelText = 'Calibre',
    this.isRequired = true,
    this.onChanged,
    this.onSaved,
    this.onSelected,
  });

  @override
  State<CaliberAutocompleteField> createState() =>
      _CaliberAutocompleteFieldState();
}

class _CaliberAutocompleteFieldState extends State<CaliberAutocompleteField> {
  late final FocusNode _ownedFocusNode = FocusNode();

  @override
  void dispose() {
    _ownedFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: widget.focusNode ?? _ownedFocusNode,
      optionsBuilder: (value) => suggestCalibers(value.text),
      fieldViewBuilder: (context, textController, fieldFocus, submit) {
        return TextFormField(
          controller: textController,
          focusNode: fieldFocus,
          decoration: InputDecoration(labelText: widget.labelText),
          validator: widget.isRequired
              ? (value) =>
                  value == null || value.trim().isEmpty ? 'Requis' : null
              : null,
          onChanged: widget.onChanged,
          onSaved: widget.onSaved,
          onFieldSubmitted: (_) => submit(),
        );
      },
      optionsViewBuilder: (context, select, options) {
        final values = options.toList(growable: false);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Theme.of(context).cardColor,
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: values.length,
                itemBuilder: (context, index) => ListTile(
                  dense: true,
                  title: Text(values[index]),
                  onTap: () => select(values[index]),
                ),
              ),
            ),
          ),
        );
      },
      onSelected: (value) {
        widget.onChanged?.call(value);
        widget.onSelected?.call(value);
      },
    );
  }
}
