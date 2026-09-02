import 'package:flutter/material.dart';
import '../services/weapon_service.dart';
import '../utils/weapon_autocomplete.dart';

/// Champ de saisie de l'arme réutilisé partout où une session est créée ou
/// modifiée (formulaire de session, wizard de conversion) — NT-009.
///
/// Propose, pendant la frappe, les noms du râtelier correspondants (casse
/// ignorée) sans jamais écraser ni bloquer la saisie libre de l'utilisateur :
/// aucune complétion automatique n'est appliquée, seule une sélection
/// explicite d'une suggestion remplit le champ.
class WeaponAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final WeaponService? weaponService;

  const WeaponAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'Arme',
    this.validator,
    this.onChanged,
    this.weaponService,
  });

  @override
  State<WeaponAutocompleteField> createState() => _WeaponAutocompleteFieldState();
}

class _WeaponAutocompleteFieldState extends State<WeaponAutocompleteField> {
  late final WeaponService _service = widget.weaponService ?? WeaponService();
  final FocusNode _focusNode = FocusNode();
  List<String> _rackNames = const [];

  @override
  void initState() {
    super.initState();
    _loadRackNames();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadRackNames() async {
    try {
      final weapons = await _service.listAll();
      if (!mounted) return;
      setState(() => _rackNames = weapons.map((w) => w.name).toList());
    } catch (_) {
      // Le râtelier reste une simple aide : une erreur de chargement ne doit
      // jamais bloquer la saisie libre du champ arme.
    }
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: widget.controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue value) => suggestWeaponNames(value.text, _rackNames),
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: widget.labelText),
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (_) => onFieldSubmitted(),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final opts = options.toList();
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            color: Theme.of(context).cardColor,
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220, minWidth: 220),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: opts.length,
                itemBuilder: (context, index) {
                  final opt = opts[index];
                  return ListTile(
                    dense: true,
                    title: Text(opt),
                    onTap: () => onSelected(opt),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
