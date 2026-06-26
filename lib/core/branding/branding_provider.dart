import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BrandingMode {
  jpmc,
  myBanker,
}

class BrandingNotifier extends StateNotifier<BrandingMode> {
  BrandingNotifier() : super(BrandingMode.jpmc);

  void setBranding(BrandingMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}

final brandingProvider = StateNotifierProvider<BrandingNotifier, BrandingMode>((ref) {
  return BrandingNotifier();
});

String cleanBrandingText(String text, BrandingMode mode) {
  if (mode == BrandingMode.myBanker) {
    return text
        .replaceAll('J.P. Morgan Innovation Economy', 'My Banker')
        .replaceAll('J.P.Morgan', 'My Banker')
        .replaceAll('J.P. Morgan', 'My Banker')
        .replaceAll('JPMorgan Chase', 'My Banker')
        .replaceAll('JPMorgan', 'My Banker')
        .replaceAll('JPMC Innovation Economy', 'My Banker')
        .replaceAll('JPMC', 'My Banker');
  }
  return text;
}
