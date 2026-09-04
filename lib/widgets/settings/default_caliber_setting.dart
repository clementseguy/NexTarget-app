import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../caliber_autocomplete_field.dart';

class DefaultCaliberSetting extends StatefulWidget {
  const DefaultCaliberSetting({super.key});

  @override
  State<DefaultCaliberSetting> createState() => _DefaultCaliberSettingState();
}

class _DefaultCaliberSettingState extends State<DefaultCaliberSetting> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<SettingsProvider>().defaultCaliber ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveSelection(String value) async {
    await context.read<SettingsProvider>().updateDefaultCaliber(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calibre par défaut: $value')),
    );
  }

  Future<void> _clear() async {
    _controller.clear();
    await context.read<SettingsProvider>().updateDefaultCaliber(null);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Préférence calibre effacée')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: CaliberAutocompleteField(
            controller: _controller,
            labelText: 'Calibre par défaut',
            isRequired: false,
            onSelected: _saveSelection,
          ),
        ),
        IconButton(
          tooltip: 'Aucun calibre par défaut',
          onPressed: _clear,
          icon: const Icon(Icons.clear),
        ),
      ],
    );
  }
}
