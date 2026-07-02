import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/conversation_service.dart';

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

// Dynamic values loaded on startup from the database
String dynamicMyBankName = 'My Bank';
String dynamicJpmcName = 'J.P. Morgan Innovation Economy';
String get myBankText => dynamicMyBankName;
String get jpmcInnovationEconomyText => dynamicJpmcName;

class BankNamesNotifier extends StateNotifier<Map<String, String>> {
  BankNamesNotifier() : super({
    '11111111-1111-1111-1111-111111111111': 'My Bank',
    '22222222-2222-2222-2222-222222222222': 'J.P. Morgan Innovation Economy',
  }) {
    _loadBankNames();
  }

  final _service = ConversationService();

  Future<void> _loadBankNames() async {
    try {
      final banks = await _service.getBanks();
      for (final b in banks) {
        final id = b['bank_id'];
        final name = b['bank_name'];
        if (id == '11111111-1111-1111-1111-111111111111' && name != null) {
          dynamicMyBankName = name;
        } else if (id == '22222222-2222-2222-2222-222222222222' && name != null) {
          dynamicJpmcName = name;
        }
      }
      state = {
        '11111111-1111-1111-1111-111111111111': dynamicMyBankName,
        '22222222-2222-2222-2222-222222222222': dynamicJpmcName,
      };
    } catch (e) {
      // Fallback
    }
  }
}

final bankNamesProvider = StateNotifierProvider<BankNamesNotifier, Map<String, String>>((ref) {
  return BankNamesNotifier();
});

String cleanBrandingText(String text, BrandingMode mode) {
  if (mode == BrandingMode.myBank) {
    return text
        .replaceAll('J.P. Morgan Innovation Economy', dynamicMyBankName)
        .replaceAll('J.P.Morgan', dynamicMyBankName)
        .replaceAll('J.P. Morgan', dynamicMyBankName)
        .replaceAll('JPMorgan Chase', dynamicMyBankName)
        .replaceAll('JPMorgan', dynamicMyBankName)
        .replaceAll('JPMC Innovation Economy', dynamicMyBankName)
        .replaceAll('JPMC', dynamicMyBankName);
  } else {
    return text
        .replaceAll('J.P. Morgan Innovation Economy', dynamicJpmcName)
        .replaceAll('JPMC Innovation Economy', dynamicJpmcName);
  }
}
