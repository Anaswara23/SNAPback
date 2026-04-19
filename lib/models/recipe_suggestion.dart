/// A nutritious recipe suggestion derived from items the user just bought
/// (and tilted toward their cultural preferences).
class RecipeSuggestion {
  const RecipeSuggestion({
    required this.title,
    required this.description,
    required this.usesItems,
    required this.cuisine,
    required this.prepTimeMinutes,
    required this.healthScore,
    this.steps = const <String>[],
  });

  /// Short recipe name, e.g. "Strawberry yogurt parfait".
  final String title;

  /// 1–2 sentence overview of the dish + why it's nutritious.
  final String description;

  /// Items from the trip that this recipe actually uses.
  final List<String> usesItems;

  /// Cuisine tag (e.g. "Mediterranean", "South Asian", "American").
  final String cuisine;

  /// Approximate prep + cook time.
  final int prepTimeMinutes;

  /// Self-reported nutrition score, 1–5 (5 = healthiest).
  final int healthScore;

  /// Optional concise prep steps (3–5 bullets).
  final List<String> steps;

  factory RecipeSuggestion.fromCloud(Map<String, dynamic> json) {
    return RecipeSuggestion(
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      usesItems: ((json['usesItems'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      cuisine: (json['cuisine'] ?? '').toString(),
      prepTimeMinutes: ((json['prepTimeMinutes'] as num?) ?? 20).toInt(),
      healthScore:
          ((json['healthScore'] as num?)?.toInt() ?? 4).clamp(1, 5),
      steps: ((json['steps'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}
