import 'package:flutter_riverpod/flutter_riverpod.dart';

enum BrandingMode {
  jpmc,
  myBank,
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

const String jpmcInnovationEconomyText = String.fromEnvironment(
  'jpmc_innovation_economy',
  defaultValue: 'J.P. Morgan Innovation Economy',
);

const String myBankText = String.fromEnvironment(
  'my_bank',
  defaultValue: 'My Bank',
);

String cleanBrandingText(String text, BrandingMode mode) {
  if (mode == BrandingMode.myBank) {
    return text
        .replaceAll('J.P. Morgan Innovation Economy', myBankText)
        .replaceAll('J.P.Morgan', myBankText)
        .replaceAll('J.P. Morgan', myBankText)
        .replaceAll('JPMorgan Chase', myBankText)
        .replaceAll('JPMorgan', myBankText)
        .replaceAll('JPMC Innovation Economy', myBankText)
        .replaceAll('JPMC', myBankText);
  } else {
    return text
        .replaceAll('J.P. Morgan Innovation Economy', jpmcInnovationEconomyText)
        .replaceAll('JPMC Innovation Economy', jpmcInnovationEconomyText);
  }
}

