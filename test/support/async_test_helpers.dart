/// Attend l'exécution de [action] et retourne l'exception levée, ou `null`
/// si aucune exception n'a été levée (NT-058).
///
/// À utiliser à la place de `expect(() => asyncFn(), throwsA(...))` **non
/// awaité** sur une fonction async : ce dernier ne bloque pas forcément le
/// test avant l'assertion suivante et peut laisser un travail asynchrone en
/// suspens qui se résout pendant le test SUIVANT, avec un message d'échec
/// trompeur attribué à la mauvaise assertion.
///
/// Exemple :
/// ```dart
/// final error = await captureError(() => service.renameWeapon(w, ''));
/// expect(error, isA<WeaponValidationException>());
/// ```
Future<Object?> captureError(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } catch (e) {
    return e;
  }
}
