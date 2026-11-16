enum ProtocolFollowed { yes, partially, no }

/// Qualification facultative d'un exercice pendant une session.
class ExerciseExecution {
  final bool? performed;
  final ProtocolFollowed? protocolFollowed;
  final String? comment;

  const ExerciseExecution({
    this.performed,
    this.protocolFollowed,
    this.comment,
  });

  Map<String, dynamic> toMap() => {
        'performed': performed,
        'protocolFollowed': protocolFollowed?.name,
        'comment': _normalizedComment(comment),
      };

  factory ExerciseExecution.fromMap(Map<String, dynamic> map) {
    final rawProtocol = map['protocolFollowed'];
    ProtocolFollowed? protocolFollowed;
    if (rawProtocol is String) {
      for (final value in ProtocolFollowed.values) {
        if (value.name == rawProtocol) protocolFollowed = value;
      }
    }
    return ExerciseExecution(
      performed: map['performed'] is bool ? map['performed'] as bool : null,
      protocolFollowed: protocolFollowed,
      comment: _normalizedComment(
        map['comment'] is String ? map['comment'] as String : null,
      ),
    );
  }

  static String? _normalizedComment(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}
