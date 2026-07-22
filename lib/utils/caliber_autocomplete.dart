import '../config/app_config.dart';

String _norm(String s) {
  var t = s.trim().toLowerCase();
  t = t.replaceAll('×', 'x');
  t = t.replaceAll(RegExp(r'[().]'), '');
  t = t.replaceAll('mm', '');
  t = t.replaceAll(RegExp(r'\s+'), '');
  return t;
}

List<String> _configuredCalibers() {
  try {
    return AppConfig.I.calibers;
  } catch (_) {
    return const [
      '.22 LR',
      '.32 S&W Long',
      '9mm (9x19)',
      '.38 Special',
      '.357 Magnum',
      '.380 ACP',
      '.40 S&W',
      '.45 ACP',
      'Autre',
    ];
  }
}

List<String> normalizedCaliberOptions() {
  final byNorm = <String, String>{};
  for (final caliber in _configuredCalibers()) {
    final trimmed = caliber.trim();
    if (trimmed.isEmpty) continue;
    byNorm.putIfAbsent(_norm(trimmed), () => trimmed);
  }
  return List.unmodifiable(byNorm.values);
}

class CaliberAutocompleteResult {
  final String? autoReplacement;
  final List<String> suggestions;
  CaliberAutocompleteResult({this.autoReplacement, required this.suggestions});
}

CaliberAutocompleteResult suggestFor(String input) {
  final list = normalizedCaliberOptions();
  final normIn = _norm(input);
  if (normIn.isEmpty) {
    return CaliberAutocompleteResult(
        autoReplacement: null, suggestions: const []);
  }
  final matches = <String>[];
  for (final c in list) {
    final n = _norm(c);
    if (n.contains(normIn)) matches.add(c);
    if (n == normIn) {
      return CaliberAutocompleteResult(
          autoReplacement: c, suggestions: const []);
    }
  }
  if (matches.length == 1) {
    return CaliberAutocompleteResult(
        autoReplacement: matches.first, suggestions: const []);
  }
  return CaliberAutocompleteResult(autoReplacement: null, suggestions: matches);
}

String canonicalizeCaliber(String? input) {
  final value = (input ?? '').trim();
  if (value.isEmpty) return '';

  final exactNorm = _norm(value);
  for (final caliber in normalizedCaliberOptions()) {
    if (_norm(caliber) == exactNorm) return caliber;
  }

  final suggested = suggestFor(value).autoReplacement;
  return suggested ?? value;
}

String pickInitialCaliber({String? existing, String? defaultCaliber}) {
  final e = canonicalizeCaliber(existing);
  if (e.isNotEmpty) return e;
  final d = canonicalizeCaliber(defaultCaliber);
  return d;
}
