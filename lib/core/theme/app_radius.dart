/// Dobara border-radius scale. Use these instead of magic numbers
/// for BorderRadius.circular(...) throughout the app.
class AppRadius {
  AppRadius._();

  static const double sm = 8; // small controls, tags
  static const double md = 12; // inputs, chips
  static const double lg = 14; // list items, info panels
  static const double xl = 16; // buttons, product cards
  static const double xxl = 20; // hero banners, modals, profile cards
  static const double pill = 999; // fully-rounded badges, pills, chips
}
