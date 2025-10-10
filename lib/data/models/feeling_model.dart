// lib/data/models/feeling_model.dart
enum Feeling {
  terrible,
  bad,
  neutral,
  good,
  great,
}

extension FeelingExtension on Feeling {
  String get displayName {
    switch (this) {
      case Feeling.terrible:
        return 'Terrible';
      case Feeling.bad:
        return 'Mal';
      case Feeling.neutral:
        return 'Regular';
      case Feeling.good:
        return 'Bien';
      case Feeling.great:
        return 'Genial';
    }
  }

  String get emoji {
    switch (this) {
      case Feeling.terrible:
        return '😣';
      case Feeling.bad:
        return '😔';
      case Feeling.neutral:
        return '😐';
      case Feeling.good:
        return '😊';
      case Feeling.great:
        return '😄';
    }
  }

  int get value {
    switch (this) {
      case Feeling.terrible:
        return 1;
      case Feeling.bad:
        return 2;
      case Feeling.neutral:
        return 3;
      case Feeling.good:
        return 4;
      case Feeling.great:
        return 5;
    }
  }
}