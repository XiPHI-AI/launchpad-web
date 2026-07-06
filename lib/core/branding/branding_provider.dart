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

// Active slug provider updated by routing
final activeSlugProvider = StateProvider<String>((ref) => '');

class BankInfo {
  final String bankId;
  final String bankName;
  final String slug;
  BankInfo({required this.bankId, required this.bankName, required this.slug});
}

// Dynamic values loaded on startup from the database
String dynamicMyBankName = 'My Bank';
String dynamicJpmcName = 'J.P. Morgan Innovation Economy';
String dynamicMyBankId = '11111111-1111-1111-1111-111111111111';
String dynamicJpmcId = '22222222-2222-2222-2222-222222222222';

String get myBankText => dynamicMyBankName;
String get jpmcInnovationEconomyText => dynamicJpmcName;

class BankNamesNotifier extends StateNotifier<List<BankInfo>> {
  BankNamesNotifier() : super([]) {
    _loadBanks();
  }

  final _service = ConversationService();

  Future<void> _loadBanks() async {
    try {
      final banksData = await _service.getBanks();
      final List<BankInfo> loaded = [];
      for (final b in banksData) {
        final id = b['bank_id'];
        final name = b['bank_name'];
        final slug = b['slug'] ?? '';
        if (id != null && name != null) {
          loaded.add(BankInfo(bankId: id, bankName: name, slug: slug));
        }
      }
      state = loaded;
      _updateGlobals(loaded, '');
    } catch (e) {
      // Fallback
    }
  }

  void _updateGlobals(List<BankInfo> banks, String currentSlug) {
    if (banks.isEmpty) return;

    // 1. Find JPMC (slug is empty)
    final jpmcBank = banks.firstWhere(
      (b) => b.slug.isEmpty || b.slug == 'jpmc',
      orElse: () => BankInfo(
        bankId: '22222222-2222-2222-2222-222222222222',
        bankName: 'J.P. Morgan Innovation Economy',
        slug: '',
      ),
    );
    dynamicJpmcName = jpmcBank.bankName;
    dynamicJpmcId = jpmcBank.bankId;

    // 2. Find active custom bank matching currentSlug (if any)
    if (currentSlug.isNotEmpty) {
      final match = banks.firstWhere(
        (b) => b.slug == currentSlug,
        orElse: () => BankInfo(
          bankId: '11111111-1111-1111-1111-111111111111',
          bankName: 'My Bank',
          slug: 'mybank',
        ),
      );
      dynamicMyBankName = match.bankName;
      dynamicMyBankId = match.bankId;
    } else {
      // Fallback to default custom bank
      final defaultCustom = banks.firstWhere(
        (b) => b.slug.isNotEmpty && b.slug != 'jpmc',
        orElse: () => BankInfo(
          bankId: '11111111-1111-1111-1111-111111111111',
          bankName: 'My Bank',
          slug: 'mybank',
        ),
      );
      dynamicMyBankName = defaultCustom.bankName;
      dynamicMyBankId = defaultCustom.bankId;
    }
  }

  void setSlug(String slug) {
    _updateGlobals(state, slug);
  }
}

final bankNamesProvider = StateNotifierProvider<BankNamesNotifier, List<BankInfo>>((ref) {
  return BankNamesNotifier();
});

// A provider that listens to both activeSlugProvider and bankNamesProvider and aligns globals
final activeBankAlignerProvider = Provider<BankInfo?>((ref) {
  final slug = ref.watch(activeSlugProvider);
  ref.watch(bankNamesProvider); // Watch bank list to trigger when data loads
  final notifier = ref.watch(bankNamesProvider.notifier);
  notifier.setSlug(slug);
  return null;
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
