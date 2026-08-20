import '../../../l10n/gen/app_localizations.dart';

/// The three catalog categories (Figma spec section G/C). Fixed set — the
/// design does not support arbitrary/admin-defined categories.
enum ItemCategory { indianVegetables, fruits, exoticVegetables }

extension ItemCategoryX on ItemCategory {
  /// The exact value stored in `items.category` — matches the DB check
  /// constraint in the items-catalog migration.
  String get dbValue {
    switch (this) {
      case ItemCategory.indianVegetables:
        return 'indian_vegetables';
      case ItemCategory.fruits:
        return 'fruits';
      case ItemCategory.exoticVegetables:
        return 'exotic_vegetables';
    }
  }

  /// English category chip/card label — only used as a non-visual
  /// fallback (e.g. logging); screens should call [localizedLabel]
  /// instead so the label follows the selected app language.
  String get label {
    switch (this) {
      case ItemCategory.indianVegetables:
        return 'Indian Vegetables';
      case ItemCategory.fruits:
        return 'Fruits';
      case ItemCategory.exoticVegetables:
        return 'Exotic Veg';
    }
  }

  /// Category chip/card label text in the current app language. This is
  /// UI copy (a fixed set of 3 category names FreshMandi itself defines),
  /// not database content, so — unlike item names — it's in scope for
  /// localization.
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case ItemCategory.indianVegetables:
        return l10n.categoryIndianVegetables;
      case ItemCategory.fruits:
        return l10n.categoryFruits;
      case ItemCategory.exoticVegetables:
        return l10n.categoryExoticVeg;
    }
  }
}

extension ItemCategoryParsing on String {
  /// Matches by keyword rather than exact string equality. The live
  /// catalog (manually entered/imported, ~193 rows) stores human-readable
  /// values like "Indian Vegetables" rather than the snake_case
  /// (`indian_vegetables`) the original schema's CHECK constraint
  /// specified — an exact-match parse silently misfiled every single row
  /// into the default category. Keyword matching tolerates whatever
  /// casing/spacing variation the data actually has ("Fruits",
  /// "FRUITS", "fruit", etc.) without needing it to be pixel-perfect.
  ItemCategory toItemCategory() {
    final normalized = trim().toLowerCase();
    if (normalized.contains('fruit')) return ItemCategory.fruits;
    if (normalized.contains('exotic')) return ItemCategory.exoticVegetables;
    return ItemCategory.indianVegetables;
  }
}
