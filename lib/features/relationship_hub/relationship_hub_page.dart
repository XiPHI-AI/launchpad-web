import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'dart:html' as html;
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/conversation_service.dart';
import '../../theme/app_theme.dart';
import '../voice/voice_page.dart';
import '../../services/notification_service.dart';
import '../../shared/widgets/hub_nav_bar.dart';
import '../../shared/widgets/no_transition_page_route.dart';
import '../../shared/widgets/prospect_id_provider.dart';
import '../../services/prospect_storage.dart';
import '../../shared/widgets/typewriter_reveal.dart';
import '../banker/banker_crm_page.dart';
import '../../core/branding/branding_provider.dart';

class _GuideMessage {
  final bool isUser;
  final String text;
  final bool isMarkdown;
  final bool animate;

  const _GuideMessage({
    required this.isUser,
    required this.text,
    this.isMarkdown = false,
    this.animate = false,
  });
}

class RelationshipHubPage extends ConsumerStatefulWidget {
  final String? prospectId;
  final String? mode;
  final Map<String, dynamic> dynamicVariables;

  const RelationshipHubPage({
    super.key,
    this.prospectId,
    this.mode,
    this.dynamicVariables = const {},
  });

  @override
  ConsumerState<RelationshipHubPage> createState() => _RelationshipHubPageState();
}

class _RelationshipHubPageState extends ConsumerState<RelationshipHubPage> {
  final ConversationService _service = ConversationService();
  ProspectInitResult? _prospect;
  bool _loading = false;
  List<ProductPublic> _products = [];
  bool _loadingProducts = false;
  bool _chatExpanded = false;
  bool _inDirectMessagingMode = false;
  final FocusNode _chatFocusNode = FocusNode();


  @override
  void dispose() {
    _chatFocusNode.dispose();
    super.dispose();
  }

  static const _defaultCompany = 'Prospectz.ai';
  static const _defaultFounder = 'Profile';

  @override
  void initState() {
    super.initState();
    if (widget.prospectId != null) {
      final cachedProspect = ProspectCache.get(widget.prospectId!);
      if (cachedProspect != null) {
        _prospect = cachedProspect;
        _loading = false;
      } else {
        _loading = true;
      }
      final cachedProducts = ProductCache.get(widget.prospectId!);
      if (cachedProducts != null) {
        _products = cachedProducts;
        _loadingProducts = false;
      } else {
        _loadingProducts = true;
      }
    }
    _hydrateProspect();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    if (widget.mode == 'banker') {
      setState(() {
        _products = [];
        _loadingProducts = false;
      });
      return;
    }
    if (widget.prospectId != null && ProductCache.get(widget.prospectId!) == null) {
      setState(() => _loadingProducts = true);
    }
    try {
      final products = await _service.listProducts(prospectId: widget.prospectId);
      if (widget.prospectId != null) {
        ProductCache.set(widget.prospectId!, products);
      }
      if (mounted) setState(() => _products = products);
    } catch (e) {
      debugPrint('Error fetching products: $e');
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _hydrateProspect() async {
    if (widget.prospectId == null) return;
    if (widget.mode == 'banker') {
      final String name = widget.prospectId ?? 'Aster';
      final branding = ref.read(brandingProvider);
      setState(() {
        _prospect = ProspectInitResult(
          prospectId: widget.prospectId ?? 'aster',
          stageBucket: 'super_agent',
          agentDisplayName: cleanBrandingText('your JPMC AI Advisor', branding),
          conversationPhase: name.toLowerCase() == 'aster' ? 5 : 2,
          isReturning: true,
          email: '${widget.prospectId ?? "aster"}@example.com',
          fullName: '$name Founder',
          companyName: name,
          companyStage: 'seed',
          industry: 'Technology',
          incorporated: true,
        );
        _loading = false;
      });
      return;
    }
    if (ProspectCache.get(widget.prospectId!) == null) {
      setState(() => _loading = true);
    }
    try {
      final prospect = await _service.getProspect(widget.prospectId!);
      ProspectCache.set(widget.prospectId!, prospect);
      if (!mounted) return;
      setState(() => _prospect = prospect);
    } catch (_) {
      if (!mounted) return;
      setState(() => _prospect = null);
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _companyName =>
      _prospect?.companyName ??
      widget.dynamicVariables['companyName']?.toString() ??
      _defaultCompany;

  String get _founderName =>
      _prospect?.fullName ??
      widget.dynamicVariables['userName']?.toString() ??
      _defaultFounder;

  String get _userEmail =>
      _prospect?.email ??
      widget.dynamicVariables['userEmail']?.toString() ??
      '';

  String get _bankerName {
    if (_prospect != null && _prospect!.bankerId == null) {
      return 'No Banker Assigned';
    }
    return _prospect?.bankerName ?? 'Sarah Chen';
  }

  String get _bankerPosition {
    if (_prospect != null && _prospect!.bankerId == null) {
      return 'Unassigned';
    }
    return _prospect?.bankerPosition ?? 'Innovation Banking';
  }


  void _onMessageTap() {
    setState(() {
      _chatExpanded = true;
      _inDirectMessagingMode = true;
    });
    _chatFocusNode.requestFocus();
  }


  String get _industry =>
      _prospect?.industry ??
      widget.dynamicVariables['industry']?.toString() ??
      'Innovation Economy';

  List<String> get _priorities {
    final selected = _prospect?.selectedPrioritiesJson ??
        (widget.dynamicVariables['selectedPriorities'] as Map?)
            ?.map((key, value) => MapEntry(key.toString(), value == true)) ??
        const <String, bool>{};
    final enabled = selected.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
    return enabled.isEmpty
        ? const [
            'Payments & operations',
            'Credit & lending',
            'International expansion',
          ]
        : enabled;
  }

  String get _stageLabel {
    const map = {
      'pre_seed': 'Pre-seed',
      'seed': 'Seed',
      'series_a': 'Series A',
      'series_b_plus': 'Series B+',
      'revenue_generating_no_vc': 'Revenue-generating, no VC',
    };
    final raw =
        _prospect?.companyStage ?? widget.dynamicVariables['stage']?.toString();
    return map[raw] ?? 'Founder workspace';
  }

  String get _initials {
    final source = _founderName.trim().isNotEmpty ? _founderName : _companyName;
    if (source == 'Profile') return 'U';
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty
        ? 'AL'
        : parts.map((part) => part[0].toUpperCase()).join();
  }

  void _showProfileModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => ProspectProfileModal(
        prospectId: widget.prospectId,
        founderName: _founderName,
        companyName: _companyName,
        initials: _initials,
        stageBucket: _prospect?.stageBucket,
      ),
    );
  }

  Future<void> _handleLogout() async {
    ProspectCache.clear();
    ProductCache.clear();
    await ProspectStorage().clearProspectId();
    if (!mounted) return;
    context.go('/');
  }

  void _showProductModal(BuildContext context, ProductPublic product) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1180;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => _ProductDetailModal(
          product: product,
          prospectId: widget.prospectId,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ProductDetailModal(
          product: product,
          prospectId: widget.prospectId,
        ),
      );
    }
  }

  void _showLearningModal(BuildContext context, String title) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1180;
    if (isDesktop) {
      showDialog(
        context: context,
        builder: (_) => _LearningMaterialModal(
          title: title,
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _LearningMaterialModal(
          title: title,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1180;
    final isMobile = screenWidth < 768;
    final isSmallScreen = !isDesktop;

    final mainContent = _loading
        ? const Center(child: CircularProgressIndicator())
        : isDesktop
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mode != 'banker')
                    _NotificationsSection(
                      bankerName: _bankerName,
                      bankerPosition: _bankerPosition,
                    ),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _HubMainColumn(
                            companyName: _companyName,
                            founderName: _founderName,
                            industry: _industry,
                            stageLabel: _stageLabel,
                            priorities: _priorities,
                            prospectId: widget.prospectId,
                            email: _userEmail,
                            onTapProduct: _showProductModal,
                            onTapLearning: _showLearningModal,
                            products: _products,
                            bankerName: _bankerName,
                            bankerPosition: _bankerPosition,
                            onMessageTap: _onMessageTap,
                            mode: widget.mode,
                            onUnassignBanker: () => _hydrateProspect(),
                          ),
                        ),
                        SizedBox(
                          width: 404,
                          child: _AiGuidePanel(
                            prospectId: widget.prospectId,
                            founderName: _founderName,
                            companyName: _companyName,
                            industry: _industry,
                            stageLabel: _stageLabel,
                            priorities: _priorities,
                            bankerName: _bankerName,
                            focusNode: _chatFocusNode,
                            inDirectMessagingMode: _inDirectMessagingMode,
                            onBackToNova: () {
                              setState(() {
                                _inDirectMessagingMode = false;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : _HubMainColumn(
                companyName: _companyName,
                founderName: _founderName,
                industry: _industry,
                stageLabel: _stageLabel,
                priorities: _priorities,
                prospectId: widget.prospectId,
                email: _userEmail,
                products: _products,
                trailingPanel: null, // Chat is shown in floating bottom sheet instead!
                onTapProduct: _showProductModal,
                onTapLearning: _showLearningModal,
                bankerName: _bankerName,
                bankerPosition: _bankerPosition,
                onMessageTap: _onMessageTap,
                mode: widget.mode,
                onUnassignBanker: () => _hydrateProspect(),
              );

    final scaffold = Scaffold(
      backgroundColor: const Color(0xFFFAF7F0),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                HubNavBar(
                  companyName: widget.mode == 'banker' ? 'Sarah Chen' : _companyName,
                  initials: widget.mode == 'banker' ? 'SC' : _initials,
                  founderName: widget.mode == 'banker' ? 'Sarah Chen' : _founderName,
                  activeLabel: 'Relationship Hub',
                  isHubEnabled: true,
                  isBankerView: widget.mode == 'banker',
                  onProfileTap: () => _showProfileModal(context),
                  onLogout: _handleLogout,
                  onInteractionsTap: () {
                    final pid = widget.prospectId;
                    final path = pid != null ? '/stages?p=$pid' : '/stages';
                    context.go(path);
                  },
                ),
                Expanded(
                  child: mainContent,
                ),
              ],
            ),
            if (isSmallScreen && !_loading) ...[
              // Dimmed backdrop
              if (_chatExpanded)
                GestureDetector(
                  onTap: () => setState(() => _chatExpanded = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              // Floating Action Bubble
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                bottom: _chatExpanded ? -100 : 24,
                right: 24,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => setState(() => _chatExpanded = true),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppThemeTokens.modalHeader,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
              // Sliding bottom sheet modal overlay
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.fastOutSlowIn,
                left: 0,
                right: 0,
                bottom: _chatExpanded ? 0 : -MediaQuery.of(context).size.height,
                height: MediaQuery.of(context).size.height * 0.85,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => _chatExpanded = false),
                        onVerticalDragEnd: (details) {
                          if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                            setState(() => _chatExpanded = false);
                          }
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD1D5DB),
                                borderRadius: BorderRadius.circular(2.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: _AiGuidePanel(
                          prospectId: widget.prospectId,
                          founderName: _founderName,
                          companyName: _companyName,
                          industry: _industry,
                          stageLabel: _stageLabel,
                          priorities: _priorities,
                          onClose: () => setState(() => _chatExpanded = false),
                          bankerName: _bankerName,
                          focusNode: _chatFocusNode,
                          inDirectMessagingMode: _inDirectMessagingMode,
                          onBackToNova: () {
                            setState(() {
                              _inDirectMessagingMode = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return ProspectIdProvider(
      prospectId: widget.prospectId,
      child: scaffold,
    );
  }
}


CrmProspect getProspectForNotification(NotificationItem item, List<CrmProspect> prospects) {
  if (prospects.isEmpty) {
    return CrmProspect(
      id: 'default',
      name: "123's",
      email: '',
      sector: 'Fintech',
      stage: 'Seed',
      status: 'In conversation',
      profileProgress: 0.45,
      docsReceivedText: '0/2 received',
      docsReceivedCount: 0,
      docsTotalCount: 2,
      materialsReadText: '0 / 1',
      materialsReadSub: '1 unread',
      lastActive: 'Today',
      avatarText: '1',
      avatarBg: Colors.blue,
      avatarFg: Colors.white,
      founderName: 'Gil',
      stageBucket: 'super_agent',
      phoneNumber: '',
      headcount: '',
      incorporated: true,
      priorities: const [],
      docs: const [],
      education: const [],
      activity: const [],
      notes: '',
    );
  }
  // Use prospectSlot directly — reliable with real API data.
  return prospects[item.prospectSlot % prospects.length];
}

NotificationItem localizeNotification(
  NotificationItem item,
  String bankerName, {
  bool isBanker = false,
  String? prospectName,
  String? founderName,
}) {
  final String pName = prospectName ?? 'Prospect';
  final String fName = founderName ?? 'Founder';
  final String bName = bankerName;
  final String bFirstName = bankerName.split(' ').first;

  if (isBanker) {
    // 1. Swap titles and messages
    String title = item.title;
    if (title.contains('added by Sarah')) {
      title = 'New guide shared with $pName';
    } else if (title.contains('Sarah reviewed')) {
      title = '$fName reviewed your guide';
    }

    String message = item.message;
    message = message
        .replaceAll('Intro call with Sarah', 'Intro call with $fName ($pName)')
        .replaceAll('call with Sarah', 'call with $fName')
        .replaceAll('Sarah reviewed', '$fName reviewed')
        .replaceAll('New guide added by Sarah', 'New guide shared with $pName')
        .replaceAll('Sarah Chen', bName)
        .replaceAll('Sarah', bFirstName);

    String footer = item.footer;
    footer = footer.replaceAll('In your learning path', 'Assigned to $pName');

    // 2. Swapped details
    NotificationDetail? detail;
    if (item.detail != null) {
      String? headerLabel = item.detail!.headerLabel;
      if (headerLabel != null) {
        headerLabel = headerLabel
            .replaceAll('ADDED BY SARAH', 'SHARED WITH ${pName.toUpperCase()}')
            .replaceAll('SARAH', bFirstName.toUpperCase());
      }

      List<NotificationDetailSection> sections = [];
      for (var sec in item.detail!.sections) {
        String secTitle = sec.title;
        List<String> bullets = [];

        if (secTitle.contains('What Sarah already knows about you')) {
          secTitle = 'What you already know about $fName';
          bullets = List.from(sec.bullets);
        } else if (secTitle.contains('Questions to ask Sarah')) {
          secTitle = 'Questions to ask $fName';
          final originalSection3 = item.detail!.sections.firstWhere(
            (s) => s.title.contains('likely to ask you'),
            orElse: () => sec,
          );
          bullets = originalSection3.bullets.map((b) {
            return b.replaceAll('"', '');
          }).toList();
        } else if (secTitle.contains('Questions Sarah is likely to ask you')) {
          secTitle = 'Questions $fName is likely to ask you';
          final originalSection2 = item.detail!.sections.firstWhere(
            (s) => s.title.contains('Questions to ask Sarah'),
            orElse: () => sec,
          );
          bullets = List.from(originalSection2.bullets);
        } else if (secTitle.contains('Documents to have on hand')) {
          secTitle = 'Documents to request from $fName';
          bullets = List.from(sec.bullets);
        } else if (secTitle.contains('Next steps agreed')) {
          secTitle = 'Next steps agreed';
          bullets = sec.bullets.map((b) {
            return b
                .replaceAll('Sarah will send', 'You ($bFirstName) will send')
                .replaceAll('You will upload', '$fName will upload');
          }).toList();
        } else if (secTitle.contains('New material added to your learning path')) {
          secTitle = 'New material assigned to $fName';
          bullets = sec.bullets.map((b) {
            return b.replaceAll('(added by Sarah)', '(assigned by you)');
          }).toList();
        } else if (secTitle.contains('About this guide')) {
          secTitle = 'About this guide';
          bullets = sec.bullets.map((b) {
            return b
                .replaceAll('Added by Sarah Chen based on your Apr 29 call conversation',
                    'Recommended by you based on your Apr 29 call conversation')
                .replaceAll('Sarah Chen', bName)
                .replaceAll('Sarah', bFirstName);
          }).toList();
        } else if (secTitle.contains('What you\'ll learn')) {
          secTitle = 'What they\'ll learn';
          bullets = List.from(sec.bullets);
        } else {
          secTitle = secTitle
              .replaceAll('Sarah', bFirstName)
              .replaceAll('you', fName)
              .replaceAll('your', "$fName's");
          bullets = sec.bullets.map((b) {
            return b
                .replaceAll('Sarah', bFirstName)
                .replaceAll('you', fName)
                .replaceAll('your', "$fName's");
          }).toList();
        }

        sections.add(NotificationDetailSection(
          icon: sec.icon,
          title: secTitle,
          bullets: bullets,
        ));
      }

      detail = NotificationDetail(
        headerLabel: headerLabel,
        sections: sections,
      );
    }

    return NotificationItem(
      title: title,
      message: message,
      footer: footer,
      time: item.time,
      icon: item.icon,
      iconColor: item.iconColor,
      bg: item.bg,
      isPriority: item.isPriority,
      detail: detail,
    );
  } else {
    final firstName = bankerName.split(' ').first;
    final uppercaseFirst = firstName.toUpperCase();

    String replaceName(String text) {
      return text
          .replaceAll('Sarah Chen', bankerName)
          .replaceAll('Sarah', firstName)
          .replaceAll('SARAH', uppercaseFirst)
          .replaceAll('Sarah\'s', "$firstName's");
    }

    String? replaceNameOpt(String? text) {
      if (text == null) return null;
      return replaceName(text);
    }

    return NotificationItem(
      title: replaceName(item.title),
      message: replaceName(item.message),
      footer: replaceName(item.footer),
      time: item.time,
      icon: item.icon,
      iconColor: item.iconColor,
      bg: item.bg,
      isPriority: item.isPriority,
      detail: item.detail == null
          ? null
          : NotificationDetail(
              headerLabel: replaceNameOpt(item.detail!.headerLabel),
              sections: item.detail!.sections.map((sec) {
                return NotificationDetailSection(
                  icon: sec.icon,
                  title: replaceName(sec.title),
                  bullets: sec.bullets.map((b) => replaceName(b)).toList(),
                );
              }).toList(),
            ),
    );
  }
}

class _NotificationsSection extends StatefulWidget {
  final String bankerName;
  final String bankerPosition;
  final bool isBanker;
  final String? prospectName;
  final String? founderName;
  final List<CrmProspect>? prospectsList;

  const _NotificationsSection({
    required this.bankerName,
    required this.bankerPosition,
    this.isBanker = false,
    this.prospectName,
    this.founderName,
    this.prospectsList,
  });

  @override
  State<_NotificationsSection> createState() => _NotificationsSectionState();
}

class _NotificationsSectionState extends State<_NotificationsSection> {
  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _notifService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  void _dismissCard(int index) {
    _notifService.markAsRead(index);
  }

  void _showNotificationDetail(BuildContext context, NotificationItem item, int index) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (dialogContext) {
        return NotificationDetailModal(
          item: item,
          onMarkAsRead: () {
            Navigator.of(dialogContext).pop();
            _dismissCard(index);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build list of (originalIndex, localizedItem) pairs
    final List<(int, NotificationItem)> activeIndexedItems = [];
    for (int i = 0; i < _notifService.activeHubNotifications.length; i++) {
      final item = _notifService.activeHubNotifications[i];
      // In banker view, only show 'Meeting confirmed' in the top bar (one per prospect).
      // Call summary and New guide appear only inside the prospect detail panel.
      if (widget.isBanker && item.title != 'Meeting confirmed') continue;
      String? pName = widget.prospectName;
      String? fName = widget.founderName;
      if (widget.prospectsList != null) {
        final assigned = getProspectForNotification(item, widget.prospectsList!);
        pName = assigned.name;
        fName = assigned.founderName;
      }
      activeIndexedItems.add((i, localizeNotification(
        item,
        widget.bankerName,
        isBanker: widget.isBanker,
        prospectName: pName,
        founderName: fName,
      )));
    }
    final activeItems = activeIndexedItems.map((e) => e.$2).toList();
    final activeIndices = activeIndexedItems.map((e) => e.$1).toList();
    final isMobile = MediaQuery.of(context).size.width < 768;
    if (activeItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
          child: Text(
            'NOTIFICATIONS',
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              color: Color(0xFF8D8578),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
          child: isMobile
              ? Column(
                  children: List.generate(activeItems.length, (i) {
                    final item = activeItems[i];
                    final originalIndex = activeIndices[i];
                    return Padding(
                      padding: EdgeInsets.only(bottom: i < activeItems.length - 1 ? 12 : 0),
                      child: NotificationCard(
                        icon: item.icon,
                        iconColor: item.iconColor,
                        iconBg: item.bg,
                        title: item.title,
                        message: item.message,
                        footer: item.footer,
                        onTap: () => _showNotificationDetail(context, item, originalIndex),
                        onMarkAsRead: () => _dismissCard(originalIndex),
                      ),
                    );
                  }),
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...() {
                      final List<Widget> activeCards = [];
                      for (int i = 0; i < activeItems.length; i++) {
                        final item = activeItems[i];
                        final originalIndex = activeIndices[i];
                        activeCards.add(
                          Expanded(
                            child: NotificationCard(
                              icon: item.icon,
                              iconColor: item.iconColor,
                              iconBg: item.bg,
                              title: item.title,
                              message: item.message,
                              footer: item.footer,
                              onTap: () => _showNotificationDetail(context, item, originalIndex),
                              onMarkAsRead: () => _dismissCard(originalIndex),
                            ),
                          ),
                        );
                      }

                      while (activeCards.length < 3) {
                        activeCards.add(const Expanded(child: SizedBox.shrink()));
                      }

                      final List<Widget> finalRow = [];
                      for (int i = 0; i < activeCards.length; i++) {
                        finalRow.add(activeCards[i]);
                        if (i < activeCards.length - 1) {
                          finalRow.add(const SizedBox(width: 12));
                        }
                      }
                      return finalRow;
                    }(),
                  ],
                ),
        ),
        Container(height: 1, color: const Color(0xFFE7DCC8)),
      ],
    );
  }
}

String _getInitials(String name) {
  if (name.trim().isEmpty) return '';
  final parts = name.trim().split(' ');
  if (parts.length > 1) {
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
  return parts[0][0].toUpperCase();
}

class _HubMainColumn extends ConsumerStatefulWidget {
  final String companyName;
  final String founderName;
  final String industry;
  final String stageLabel;
  final List<String> priorities;
  final String? prospectId;
  final String email;
  final Widget? trailingPanel;
  final void Function(BuildContext context, ProductPublic product)? onTapProduct;
  final String bankerName;
  final String bankerPosition;
  final VoidCallback onMessageTap;
  final List<ProductPublic> products;
  final String? mode;
  final VoidCallback? onUnassignBanker;

  const _HubMainColumn({
    required this.companyName,
    required this.founderName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
    required this.products,
    required this.bankerName,
    required this.bankerPosition,
    required this.onMessageTap,
    this.prospectId,
    this.email = '',
    this.trailingPanel,
    this.onTapProduct,
    this.onTapLearning,
    this.mode,
    this.onUnassignBanker,
  });

  final void Function(BuildContext context, String title)? onTapLearning;

  @override
  ConsumerState<_HubMainColumn> createState() => _HubMainColumnState();
}

class _HubMainColumnState extends ConsumerState<_HubMainColumn> {
  bool _hasInteractedProducts = false;
  bool _hasInteractedLearning = false;
  bool _showAllProducts = false;
  List<ProspectDocument> _documents = [];
  bool _loadingDocs = false;

  @override
  void initState() {
    super.initState();
    _loadDocs();
  }

  void _loadDocs() async {
    if (widget.prospectId == null) return;
    setState(() => _loadingDocs = true);
    try {
      final list = await ConversationService().getDocumentList(widget.prospectId!);
      setState(() {
        _documents = list;
        _loadingDocs = false;
      });
    } catch (e) {
      setState(() => _loadingDocs = false);
    }
  }

  DateTime? _scheduledCallDate;
  bool _hasAddedMeetingToCalendar = false;

  final DateTime _defaultFutureDate = DateTime(2026, 6, 9); // Tuesday, June 9, 2026

  String _formatLongDate(DateTime dt) {
    final weekdays = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String _getMeetingDateString() {
    final dt = _scheduledCallDate ?? _defaultFutureDate;
    return '${_formatLongDate(dt)} · 2:00 PM ET · 30 min';
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Added: ${months[dt.month - 1]} ${dt.day}';
  }

  String _formatDateShort(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }



  Future<void> _selectScheduleDate(BuildContext context) async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _scheduledCallDate = picked;
      });
    }
  }

  void _unassignBanker() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsign Banker?'),
        content: Text('Are you sure you want to unsign your banker, ${widget.bankerName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unsign'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final pid = widget.prospectId;
        if (pid != null) {
          await ConversationService().assignProspectToBanker(pid, null);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Banker unsigned successfully')),
            );
          }
          widget.onUnassignBanker?.call();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unsign banker: $e')),
          );
        }
      }
    }
  }

  void _showUploadModal(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (_) => const _UploadDocModal(),
    ).then((fileName) async {
      if (fileName != null && fileName.isNotEmpty) {
        if (widget.prospectId != null) {
          try {
            final mockLink = 'https://drive.google.com/open?id=uploaded_${DateTime.now().millisecondsSinceEpoch}';
            final newDoc = await ConversationService().uploadProspectDocument(
              widget.prospectId!,
              fileName,
              driveLink: mockLink,
            );
            setState(() {
              _documents.add(newDoc);
            });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload "$fileName": $e'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$fileName" uploaded successfully.'),
            backgroundColor: const Color(0xFF0F6E56),
          ),
        );
      }
    });
  }

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return Icons.payments_outlined;
    if (c.contains('treasury')) return Icons.monitor_heart_outlined;
    if (c.contains('card')) return Icons.credit_card_outlined;
    if (c.contains('international') || c.contains('cross-currency'))
      return Icons.public_outlined;
    if (c.contains('banking')) return Icons.account_balance_wallet_outlined;
    if (c.contains('credit') || c.contains('lending'))
      return Icons.attach_money_rounded;
    return Icons.category_outlined;
  }

  Color _getTintForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return const Color(0xFF7C3AED);
    if (c.contains('treasury')) return const Color(0xFF1D9E75);
    if (c.contains('card')) return const Color(0xFF1A7B99);
    if (c.contains('international') || c.contains('cross-currency'))
      return const Color(0xFF0891B2);
    if (c.contains('banking')) return const Color(0xFF1A7B99);
    if (c.contains('credit') || c.contains('lending'))
      return const Color(0xFF996715);
    return const Color(0xFF64748B);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1180;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // On mobile, show notifications inside the scroll view
          if (!isDesktop && widget.mode != 'banker')
            _NotificationsSection(
              bankerName: widget.bankerName,
              bankerPosition: widget.bankerPosition,
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your banker',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontFamily: 'Georgia',
                        color: AppThemeTokens.modalHeader,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                      ),
                ),
                const SizedBox(height: 18),
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppThemeTokens.modalHeader,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF213E5B),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF314C68)),
                                      ),
                                      child: const Icon(
                                          Icons.calendar_today_rounded,
                                          color: AppThemeTokens.goldAccent,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Text(
                                        'UPCOMING MEETING',
                                        style: TextStyle(
                                          color: AppThemeTokens.goldAccent,
                                          fontSize: 10,
                                          letterSpacing: 1.1,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Intro call with ${widget.bankerName}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 19,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getMeetingDateString(),
                                  style: const TextStyle(
                                    color: Color(0xFFB8C3D1),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _hasAddedMeetingToCalendar = true;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFE2E8F0),
                                          side: const BorderSide(
                                              color: Color(0xFF3E5B79)),
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                        child: Text(_hasAddedMeetingToCalendar
                                            ? _formatDate(_scheduledCallDate ?? _defaultFutureDate)
                                            : 'Add to calendar'),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => const _PrepCallModal(),
                                          );
                                        },
                                        style: FilledButton.styleFrom(
                                          backgroundColor: AppThemeTokens.goldAccent,
                                          foregroundColor: AppThemeTokens.modalHeader,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999)),
                                        ),
                                        child: const Text('Prep for call'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFFE0D7C8)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor:
                                          AppThemeTokens.modalHeader,
                                      child: Text(
                                        _getInitials(widget.bankerName),
                                        style: const TextStyle(
                                          color: AppThemeTokens.goldAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.bankerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.bankerPosition,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (widget.bankerName != 'No Banker Assigned' && widget.mode != 'banker')
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        onSelected: (val) {
                                          if (val == 'unsign') {
                                            _unassignBanker();
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'unsign',
                                            child: Text('Unsign Banker', style: TextStyle(fontSize: 12, color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _MiniActionButton(
                                        label: 'Message',
                                        dark: true,
                                        icon: Icons.chat_bubble_outline_rounded,
                                        onTap: () {
                                          widget.onMessageTap();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _MiniActionButton(
                                        label: _scheduledCallDate != null
                                            ? 'Sched: ${_formatDateShort(_scheduledCallDate!)}'
                                            : 'Schedule',
                                        dark: false,
                                        onTap: () => _selectScheduleDate(context),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: AppThemeTokens.modalHeader,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF213E5B),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: const Color(0xFF314C68)),
                                      ),
                                      child: const Icon(
                                          Icons.calendar_today_rounded,
                                          color: AppThemeTokens.goldAccent,
                                          size: 18),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'UPCOMING MEETING',
                                            style: TextStyle(
                                              color: AppThemeTokens.goldAccent,
                                              fontSize: 10,
                                          letterSpacing: 1.1,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Intro call with ${widget.bankerName}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 19,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getMeetingDateString(),
                                            style: const TextStyle(
                                              color: Color(0xFFB8C3D1),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      onPressed: () {
                                        setState(() {
                                          _hasAddedMeetingToCalendar = true;
                                        });
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFE2E8F0),
                                        side: const BorderSide(
                                            color: Color(0xFF3E5B79)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                      ),
                                      child: Text(_hasAddedMeetingToCalendar
                                          ? _formatDate(_scheduledCallDate ?? _defaultFutureDate)
                                          : 'Add to calendar'),
                                    ),
                                    const SizedBox(width: 10),
                                    FilledButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => const _PrepCallModal(),
                                        );
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: AppThemeTokens.goldAccent,
                                        foregroundColor: AppThemeTokens.modalHeader,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(999)),
                                      ),
                                      child: const Text('Prep for call'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 260,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                      color: const Color(0xFFE0D7C8)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor:
                                              AppThemeTokens.modalHeader,
                                          child: Text(
                                            _getInitials(widget.bankerName),
                                            style: const TextStyle(
                                              color: AppThemeTokens.goldAccent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                widget.bankerName,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                widget.bankerPosition,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (widget.bankerName != 'No Banker Assigned' && widget.mode != 'banker')
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 20),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            color: Colors.white,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            onSelected: (val) {
                                              if (val == 'unsign') {
                                                _unassignBanker();
                                              }
                                            },
                                            itemBuilder: (context) => [
                                              const PopupMenuItem(
                                                value: 'unsign',
                                                child: Text('Unsign Banker', style: TextStyle(fontSize: 12, color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _MiniActionButton(
                                            label: 'Message',
                                            dark: true,
                                            icon: Icons.chat_bubble_outline_rounded,
                                            onTap: () {
                                              widget.onMessageTap();
                                            },
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: _MiniActionButton(
                                            label: _scheduledCallDate != null
                                                ? 'Sched: ${_formatDateShort(_scheduledCallDate!)}'
                                                : 'Schedule',
                                            dark: false,
                                            onTap: () => _selectScheduleDate(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
            child: Row(
              children: [
                Text(
                  'YOUR SHARED DOCUMENTS',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: AppThemeTokens.modalHeader,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _AddDocChip(
                  onTap: () => _showUploadModal(context),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
            child: _loadingDocs
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A4A8A)),
                      ),
                    ),
                  )
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _documents.map((doc) {
                      return _DocChip(
                        doc.fileName,
                        'Shared',
                        onTap: () {
                          if (doc.driveLink != null && doc.driveLink!.isNotEmpty) {
                            html.window.open(doc.driveLink!, '_blank');
                          }
                        },
                      );
                    }).toList(),
                  ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Explore what's available to you",
                  style:
                      Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontFamily: 'Georgia',
                            color: AppThemeTokens.modalHeader,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Products relevant to your stage${widget.stageLabel.isNotEmpty ? ' — ${widget.stageLabel}' : ''}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F675B),
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Wrap(
              spacing: 14,
              runSpacing: 14,
              alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
              children: [
                ...(() {
                  final sorted = List<ProductPublic>.from(widget.products)
                    ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));
                  return sorted.take(_showAllProducts ? sorted.length : 5);
                })().map((product) {
                  final icon = _getIconForCategory(product.category);
                  final tint = _getTintForCategory(product.category);

                  return SizedBox(
                    width: isMobile ? (screenWidth - 48).clamp(320.0, 480.0) : 320.0,
                    child: _ProductCard(
                      icon: icon,
                      tint: tint,
                      iconColor: tint,
                      title: product.name,
                      description: product.shortDescription ?? product.description,
                      cta: 'By ${cleanBrandingText(product.provider?.companyName ?? 'J.P. Morgan', ref.watch(brandingProvider))}',
                      websiteUrl: (product.signupUrl != null && product.signupUrl!.isNotEmpty)
                          ? product.signupUrl
                          : product.provider?.websiteUrl,
                      matchScore: product.matchScore,
                      matchReasoning: product.matchReasoning,
                      productId: product.productId,
                      prospectId: widget.prospectId,
                      onInteraction: () =>
                          setState(() => _hasInteractedProducts = true),
                      onTap: () => widget.onTapProduct?.call(context, product),
                    ),
                  );
                }).toList(),
                if (!_showAllProducts && widget.products.length > 5)
                  SizedBox(
                    width: 320,
                    height: 240,
                    child: Center(
                      child: TextButton(
                        onPressed: () => setState(() => _showAllProducts = true),
                        style: TextButton.styleFrom(
                          foregroundColor: AppThemeTokens.buttonPrimary,
                          textStyle: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Show more"),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE7DCC8)),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Learning material',
                  style: TextStyle(
                    fontFamily: 'Georgia',
                    color: AppThemeTokens.modalHeader,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Curated guides and events to support your next stage of growth.',
                  style: TextStyle(
                    color: Color(0xFF6F675B),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = MediaQuery.of(context).size.width < 768;
                final crossAxisCount = isMobile ? 1 : 2;
                const spacing = 16.0;
                final targetItemHeight = isMobile ? 155.0 : 145.0;
                final itemWidth = isMobile
                    ? constraints.maxWidth
                    : (constraints.maxWidth - spacing) / 2;
                final childAspectRatio = itemWidth / targetItemHeight;
                final bankerFirstName = widget.bankerName.split(' ').first;

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: spacing,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: childAspectRatio,
                  children: [
                    _LearningCard(
                      stripe: AppThemeTokens.goldAccent,
                      tag: 'Guide',
                      title: 'Setting up efficient banking early',
                      description:
                          'Shared by $bankerFirstName to help streamline your initial operations.',
                      meta: '8 min read · Seed · Operations',
                      defaultHover: !_hasInteractedLearning,
                      showNewBadge: true,
                      onInteraction:
                          () => setState(() => _hasInteractedLearning = true),
                      onTap: () => widget.onTapLearning?.call(context, 'Setting up efficient banking early'),
                    ),
                    _LearningCard(
                      stripe: const Color(0xFF378ADD),
                      tag: 'Event',
                      title: 'Treasury habits that scale with you',
                      description:
                          'Added by Michael from our Treasury Team based on your discussion about cash management.',
                      meta: 'May 7 · 1:00 PM ET · 45 min',
                      onInteraction:
                          () => setState(() => _hasInteractedLearning = true),
                      onTap: () => widget.onTapLearning?.call(context, 'Treasury habits that scale with you'),
                    ),
                    _LearningCard(
                      stripe: const Color(0xFF1D9E75),
                      tag: 'Explainer',
                      title: 'How early-stage treasury accounts work',
                      description:
                          'A brief explainer shared by $bankerFirstName to clarify treasury basics.',
                      meta: '5 min read · Finance leads',
                      onTap: () => widget.onTapLearning?.call(context, 'How early-stage treasury accounts work'),
                    ),
                    _LearningCard(
                      stripe: const Color(0xFF7F77DD),
                      tag: 'Guide',
                      title: 'Preparing for your first credit facility',
                      description:
                          'Recommended reading by Elena Rustova ahead of your Series A raise.',
                      meta: '10 min read · Series A · Capital structure',
                      onTap: () => widget.onTapLearning?.call(context, 'Preparing for your first credit facility'),
                    ),
                  ],
                );
              },
            ),
          ),
          if (widget.trailingPanel != null) ...[
            Container(height: 1, color: const Color(0xFFE7DCC8)),
            widget.trailingPanel!,
          ],
        ],
      ),
    );
  }
}

class _AiGuidePanel extends StatefulWidget {
  final String? prospectId;
  final String? bankerId;
  final String founderName;
  final String companyName;
  final String industry;
  final String stageLabel;
  final List<String> priorities;
  final VoidCallback? onClose;
  final String? customActionLabel;
  final VoidCallback? onCustomActionTap;
  final String? bankerName;
  final FocusNode? focusNode;
  final bool inDirectMessagingMode;
  final VoidCallback? onBackToNova;
  final List<CrmProspect>? prospectsList;
  final ValueChanged<CrmProspect>? onProspectSelected;
  final bool lockDropdown;
  final bool showLeftBorder;

  const _AiGuidePanel({
    this.prospectId,
    this.bankerId,
    required this.founderName,
    required this.companyName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
    this.onClose,
    this.customActionLabel,
    this.onCustomActionTap,
    this.bankerName,
    this.focusNode,
    this.inDirectMessagingMode = false,
    this.onBackToNova,
    this.prospectsList,
    this.onProspectSelected,
    this.lockDropdown = false,
    this.showLeftBorder = true,
  });

  @override
  State<_AiGuidePanel> createState() => _AiGuidePanelState();
}

class _AiGuidePanelState extends State<_AiGuidePanel> {
  final ConversationService _service = ConversationService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _historyScrollController = ScrollController();
  final ScrollController _conversationalScrollController = ScrollController();
  FocusNode? _localFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_localFocusNode ??= FocusNode());
  final FocusNode _keyboardListenerFocusNode = FocusNode();
  bool _sending = false;
  String get _bankerFirstName {
    final name = widget.bankerName ?? 'Sarah Chen';
    return name.split(' ').first;
  }

  List<_GuideMessage> _messages = [];
  bool _viewingHistory = false;
  List<_GuideMessage> _historyMessages = [];
  bool _loadingHistory = false;
  bool _historyHasMore = false;
  int _historyEarliestId = 0;


  // Banker history state
  List<_GuideMessage> _voiceTurns = [];
  bool _loadingVoiceConversations = false;
  String _activeBankerTab = 'conversational';

  // Direct Messaging State
  List<DirectMessage> _directMessages = [];
  bool _loadingDirectMessages = false;
  bool? _localDmMode;
  bool get _inDirectMessagingMode => _localDmMode ?? widget.inDirectMessagingMode;

  void _setDmMode(bool value) {
    if (_localDmMode == value) return;
    setState(() {
      _localDmMode = value;
      if (value) {
        _viewingHistory = false;
        _loadDirectMessages();
      } else {
        widget.onBackToNova?.call();
      }
    });
  }

  bool _isDmUser(String sender) {
    final isBankerView = widget.customActionLabel == 'Prospect Chats';
    if (isBankerView) {
      return sender == 'banker';
    } else {
      return sender == 'prospect';
    }
  }

  List<_GuideMessage> get _dmGuideMessages {
    return _directMessages.map((dm) {
      return _GuideMessage(
        isUser: _isDmUser(dm.sender),
        text: dm.content,
        isMarkdown: false,
        animate: false,
      );
    }).toList();
  }

  Future<void> _loadDirectMessages() async {
    if (widget.prospectId == null) return;
    setState(() {
      _loadingDirectMessages = true;
    });
    try {
      final list = await _service.getDirectMessages(widget.prospectId!);
      if (mounted) {
        setState(() {
          _directMessages = list;
          _loadingDirectMessages = false;
        });
        _scrollToBottomInstant();
      }
    } catch (e) {
      debugPrint('Error loading direct messages: $e');
      if (mounted) {
        setState(() {
          _loadingDirectMessages = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _localDmMode = widget.inDirectMessagingMode;
    _resetWelcomeMessage();
    _loadBankerHistory();
    if (_inDirectMessagingMode) {
      _loadDirectMessages();
    }
  }

  void _resetWelcomeMessage() {
    final isBankerView = widget.customActionLabel == 'Prospect Chats';
    final welcomeText = isBankerView
        ? "I have context from ${widget.founderName}'s profile and the materials in ${widget.companyName}'s learning path. Ask me anything to prepare for this startup, suggest products, or review what matters most."
        : "I have context from ${widget.founderName}'s profile and the materials in ${widget.companyName}'s learning path. Ask me anything about the next meeting, $_bankerFirstName's notes, or what matters most right now.";

    _messages = [
      _GuideMessage(
        isUser: false,
        text: welcomeText,
      ),
    ];
  }

  @override
  void didUpdateWidget(covariant _AiGuidePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prospectId != widget.prospectId || oldWidget.bankerName != widget.bankerName) {
      _loadBankerHistory();
      setState(() {
        _resetWelcomeMessage();
      });
    }
    if (oldWidget.inDirectMessagingMode != widget.inDirectMessagingMode) {
      setState(() {
        _localDmMode = widget.inDirectMessagingMode;
      });
    }
    final isDmMode = _inDirectMessagingMode;
    final wasDmMode = oldWidget.inDirectMessagingMode;
    if (isDmMode && (!wasDmMode || oldWidget.prospectId != widget.prospectId)) {
      _loadDirectMessages();
    }
  }

  List<Map<String, dynamic>> _extractTurns(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((item) {
        if (item is Map) {
          final role = item['role'] as String? ?? 'user';
          final message = item['message'] as String? ?? item['text'] as String? ?? '';
          return {
            'role': role.toLowerCase() == 'user' ? 'user' : 'agent',
            'message': message.trim(),
          };
        }
        return <String, dynamic>{};
      }).where((element) => element.isNotEmpty && (element['message'] as String).isNotEmpty).toList();
    }
    if (raw is Map) {
      final turns = raw['turns'] ?? raw['messages'] ?? raw['transcript'] ?? raw['history'];
      if (turns != null) {
        return _extractTurns(turns);
      }
      final list = <Map<String, dynamic>>[];
      raw.forEach((key, value) {
        if (value != null && value.toString().trim().isNotEmpty) {
          final roleStr = key.toString().toLowerCase();
          final isUser = roleStr.contains('user') || roleStr.contains('human');
          list.add({
            'role': isUser ? 'user' : 'agent',
            'message': value.toString().trim(),
          });
        }
      });
      return list;
    }
    return [];
  }

  Future<void> _loadBankerHistory() async {
    final isBanker = widget.customActionLabel == 'Prospect Chats';
    final chatHistoryId = isBanker ? widget.bankerId : widget.prospectId;

    if (chatHistoryId == null && widget.prospectId == null) {
      setState(() {
        _voiceTurns = [];
        _historyMessages = [];
      });
      return;
    }
    setState(() {
      _loadingVoiceConversations = true;
      _voiceTurns = [];
      _historyMessages = [];
      _historyEarliestId = 0;
      _historyHasMore = false;
    });

    // Load Chat History (which handles setting _loadingHistory = true itself)
    await _loadHistory();

    // Load Voice Conversational History
    if (widget.prospectId == null) {
      setState(() {
        _loadingVoiceConversations = false;
      });
      return;
    }
    try {
      final conversations = await _service.getProspectConversations(widget.prospectId!);
      if (mounted) {
        final reversedConvs = conversations.reversed.toList();
        final List<_GuideMessage> turns = [];
        for (var conv in reversedConvs) {
          if (conv is Map) {
            final rawTranscript = conv['transcript_json'];
            final extracted = _extractTurns(rawTranscript);
            for (var ext in extracted) {
              final isUser = ext['role'] == 'user';
              turns.add(_GuideMessage(
                isUser: isUser,
                text: ext['message'] ?? '',
                isMarkdown: false,
                animate: false,
              ));
            }
          }
        }
        setState(() {
          _voiceTurns = turns;
          _loadingVoiceConversations = false;
        });
        _scrollToBottomConversational();
      }
    } catch (e) {
      debugPrint('Error loading voice conversations: $e');
      if (mounted) {
        setState(() {
          _loadingVoiceConversations = false;
        });
      }
    }
  }

  void _scrollToBottomConversational() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_conversationalScrollController.hasClients) return;
      _conversationalScrollController.jumpTo(0);
    });
  }



  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _historyScrollController.dispose();
    _conversationalScrollController.dispose();
    _localFocusNode?.dispose();
    _keyboardListenerFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String message) async {
    final trimmed = message.trim();
    if (trimmed.isEmpty || _sending) return;

    final isDmMode = _inDirectMessagingMode;

    if (isDmMode) {
      final sender = widget.customActionLabel == 'Prospect Chats' ? 'banker' : 'prospect';
      setState(() {
        _sending = true;
        _directMessages.add(DirectMessage(
          messageId: '',
          prospectId: widget.prospectId ?? '',
          bankerId: '',
          sender: sender,
          content: trimmed,
          createdAt: DateTime.now(),
        ));
      });
      _controller.clear();
      _scrollToBottom();

      try {
        await _service.sendDirectMessage(widget.prospectId!, sender, trimmed);
        await _loadDirectMessages();
      } catch (e) {
        debugPrint('Error sending direct message: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to send message. Please try again.')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _sending = false);
          _focusNode.requestFocus();
        }
      }
      return;
    }

    setState(() {
      _sending = true;
      _messages.add(_GuideMessage(isUser: true, text: trimmed));
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final result = await _service.sendRelationshipHubChat(
        trimmed,
        prospectId: widget.prospectId,
        context: {
          'founder_name': widget.founderName,
          'company_name': widget.companyName,
          'industry': widget.industry,
          'stage_label': widget.stageLabel,
          'priorities': widget.priorities,
          if (widget.bankerId != null) 'banker_id': widget.bankerId,
        },
        isBanker: widget.customActionLabel == 'Prospect Chats',
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          _GuideMessage(
            isUser: false,
            text: result.replyMarkdown,
            isMarkdown: true,
            animate: true,
          ),
        );
      });
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _GuideMessage(
            isUser: false,
            text:
                'I could not reach the guide right now. Please try again in a moment.',
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        // Keep focus on the input after sending
        _focusNode.requestFocus();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _scrollToBottomInstant() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (_loadingHistory) return;
    if (loadMore && !_historyHasMore) return;

    final isBanker = widget.customActionLabel == 'Prospect Chats';
    final historyId = isBanker ? (widget.bankerId ?? widget.prospectId) : widget.prospectId;

    if (historyId == null) return;

    setState(() => _loadingHistory = true);

    try {
      final result = await _service.getChatHistory(
        historyId,
        limit: 30,
        beforeId: loadMore ? _historyEarliestId : 0,
      );

      if (!mounted) return;

      final newMessages = result.messages.map((m) {
        final isUser = m.type == 'human';
        return _GuideMessage(isUser: isUser, text: m.content, isMarkdown: true);
      }).toList();

      if (loadMore) {
        _historyMessages = [...newMessages, ..._historyMessages];
      } else {
        _historyMessages = newMessages;
      }

      _historyHasMore = result.hasMore;
      _historyEarliestId = result.messages.isNotEmpty ? result.messages.first.id : 0;
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  void _openReturnLink() {
    final pid = widget.prospectId;
    if (pid == null) return;
    context.go('/?p=$pid');
  }

  void _openHistory() {
    _loadBankerHistory();
    setState(() => _viewingHistory = true);
  }

  void _closeHistory() {
    setState(() {
      _viewingHistory = false;
      _historyMessages = [];
      _historyEarliestId = 0;
      _historyHasMore = false;
    });
  }

  void _onHistoryScroll() {
    if (!_historyScrollController.hasClients || _loadingHistory || !_historyHasMore) return;
    if (_historyScrollController.offset <= 50) {
      _loadHistory(loadMore: true);
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // Only prefill if input is empty
      if (_controller.text.isEmpty && !_sending) {
        try {
          final lastUserMessage = _messages.lastWhere(
            (m) => m.isUser,
          );
          if (lastUserMessage.text.isNotEmpty) {
            _controller.text = lastUserMessage.text;
            // Set cursor at the end
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          }
        } catch (_) {
          // No user messages yet
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: widget.showLeftBorder
            ? const Border(left: BorderSide(color: Color(0xFFE7DCC8)))
            : null,
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (_viewingHistory) _buildBankerTabSwitcher(),
          Expanded(
            child: _viewingHistory
                ? (_activeBankerTab == 'conversational'
                    ? _buildConversationalHistoryBody()
                    : _buildHistoryBody())
                : _buildChatBody(),
          ),
          if (!_viewingHistory) _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isBankerChats = widget.customActionLabel == 'Prospect Chats';

    // 1. Determine Icon based on current view/mode
    final IconData iconData;
    final Color iconColor;
    if (_viewingHistory) {
      iconData = Icons.history_rounded;
      iconColor = const Color(0xFF6B7280);
    } else if (_inDirectMessagingMode) {
      iconData = Icons.chat_bubble_outline_rounded;
      iconColor = AppThemeTokens.buttonPrimary;
    } else {
      iconData = Icons.auto_awesome_rounded;
      iconColor = AppThemeTokens.buttonPrimary;
    }

    // 2. Build Name / Dropdown Widget (Only prospect name, ending with dropdown icon next to it)
    Widget nameWidget;
    if (!_inDirectMessagingMode) {
      nameWidget = const Text(
        'Nova',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppThemeTokens.modalHeader,
          fontWeight: FontWeight.w700,
          fontSize: 14,
          fontFamily: 'Inter',
        ),
      );
    } else {
      if (widget.prospectsList != null && widget.prospectsList!.isNotEmpty) {
        nameWidget = DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.prospectId,
            isExpanded: false,
            icon: widget.lockDropdown
                ? const SizedBox.shrink()
                : const Icon(Icons.arrow_drop_down, color: AppThemeTokens.buttonPrimary),
            style: const TextStyle(
              color: AppThemeTokens.modalHeader,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              fontFamily: 'Inter',
            ),
            onChanged: widget.lockDropdown
                ? null
                : (String? newProspectId) {
                    if (newProspectId != null && widget.onProspectSelected != null) {
                      final selected = widget.prospectsList!.firstWhere((p) => p.id == newProspectId);
                      widget.onProspectSelected!(selected);
                    }
                  },
            items: widget.prospectsList!.map<DropdownMenuItem<String>>((CrmProspect p) {
              return DropdownMenuItem<String>(
                value: p.id,
                child: Text(p.name),
              );
            }).toList(),
          ),
        );
      } else {
        final String displayName;
        if (isBankerChats) {
          displayName = widget.companyName;
        } else {
          displayName = widget.bankerName ?? 'your Banker';
        }
        nameWidget = Text(
          displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppThemeTokens.modalHeader,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'Inter',
          ),
        );
      }
    }

    // 3. Row 1: Icon + NameWidget + Spacer + Segment Switch
    final row1 = Row(
      children: [
        Icon(
          iconData,
          color: iconColor,
          size: 18,
        ),
        const SizedBox(width: 8),
        nameWidget,
        const Spacer(),
        _buildModeSwitch(),
      ],
    );

    // 4. Row 2: History Chip (Only visible in NOVA mode, and only if history exists/is loading/viewing)
    final bool showHistoryChip = !_inDirectMessagingMode &&
        (_viewingHistory ||
            _loadingHistory ||
            _loadingVoiceConversations ||
            _historyMessages.isNotEmpty ||
            _voiceTurns.isNotEmpty);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE7DCC8))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          row1,
          if (showHistoryChip) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    if (_viewingHistory) {
                      _closeHistory();
                    } else {
                      _openHistory();
                    }
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppThemeTokens.buttonPrimary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _viewingHistory
                                ? Icons.arrow_back_rounded
                                : Icons.history_rounded,
                            size: 13,
                            color: AppThemeTokens.buttonPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _viewingHistory
                                ? 'Back to Nova'
                                : (isBankerChats ? 'Prospect Chat History' : 'Chat History'),
                            style: const TextStyle(
                              color: AppThemeTokens.buttonPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    final isDm = _inDirectMessagingMode;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSwitchOption('NOVA', !isDm),
          _buildSwitchOption('Message', isDm),
        ],
      ),
    );
  }

  Widget _buildSwitchOption(String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        _setDmMode(label == 'Message');
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF04213D) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : const Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankerTabSwitcher() {
    final isBankerChats = widget.customActionLabel == 'Prospect Chats';
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0x21000000))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildBankerTabButton('Conversational History', 'conversational'),
          const SizedBox(width: 8),
          _buildBankerTabButton(isBankerChats ? 'Prospect Chat History' : 'Chat History', 'chat'),
        ],
      ),
    );
  }

  Widget _buildBankerTabButton(String label, String tab) {
    final isSelected = _activeBankerTab == tab;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeBankerTab = tab;
        });
        if (tab == 'conversational') {
          _scrollToBottomConversational();
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF04213D) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? const Color(0xFF04213D) : const Color(0xFF6F675B),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationalHistoryBody() {
    return Container(
      color: const Color(0xFFFAFAF8),
      child: _voiceTurns.isEmpty && _loadingVoiceConversations
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : _voiceTurns.isEmpty && !_loadingVoiceConversations
              ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'No conversational history yet.',
                      style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _conversationalScrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true,
                  itemCount: _voiceTurns.length,
                  itemBuilder: (context, index) {
                    final i = _voiceTurns.length - 1 - index;
                    final msg = _voiceTurns[i];
                    final isPrevSame = i > 0 && _voiceTurns[i - 1].isUser == msg.isUser;
                    final isNextSame = i < _voiceTurns.length - 1 && _voiceTurns[i + 1].isUser == msg.isUser;

                    return Padding(
                      padding: EdgeInsets.only(top: isPrevSame ? 2 : 10, bottom: 1),
                      child: _GuideMessageBubble(
                        key: ValueKey('conversational_${i}_${msg.isUser}_${msg.text.hashCode}'),
                        message: msg,
                        isPrevSame: isPrevSame,
                        isNextSame: isNextSame,
                        enableTypewriter: false,
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyDmPlaceholder() {
    final isBanker = widget.customActionLabel == 'Prospect Chats';
    final targetName = isBanker ? widget.companyName : (widget.bankerName ?? 'your Banker');
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 12),
            Text(
              "Send a message to start chatting with $targetName.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    final isDmMode = _inDirectMessagingMode;

    if (isDmMode && _loadingDirectMessages && _directMessages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(AppThemeTokens.goldAccent),
        ),
      );
    }

    if (isDmMode && _directMessages.isEmpty) {
      return _buildEmptyDmPlaceholder();
    }

    final messagesToDisplay = isDmMode ? _dmGuideMessages : _messages;

    return Container(
      color: const Color(0xFFFAFAF8),
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...List.generate(messagesToDisplay.length, (i) {
              final msg = messagesToDisplay[i];
              final isPrevSame = i > 0 && messagesToDisplay[i - 1].isUser == msg.isUser;
              final isNextSame = i < messagesToDisplay.length - 1 && messagesToDisplay[i + 1].isUser == msg.isUser;
              return Padding(
                padding: EdgeInsets.only(top: isPrevSame ? 2 : 10, bottom: 1),
                child: _GuideMessageBubble(
                  key: ValueKey('guide_${i}_${msg.isUser}_${msg.animate}_${msg.text.hashCode}'),
                  message: msg,
                  isPrevSame: isPrevSame,
                  isNextSame: isNextSame,
                  enableTypewriter: !msg.isUser && msg.animate,
                  onTypewriterTick: _scrollToBottomInstant,
                ),
              );
            }),
            if (_sending)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: _GuideTypingBubble(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryBody() {
    return Container(
      color: const Color(0xFFFAFAF8),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            _onHistoryScroll();
          }
          return false;
        },
        child: _historyMessages.isEmpty && _loadingHistory
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              )
            : _historyMessages.isEmpty && !_loadingHistory
                ? const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No chat history yet.',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _historyScrollController,
                    padding: const EdgeInsets.all(16),
                    reverse: true,
                    itemCount: _historyMessages.length +
                        ((_loadingHistory || _historyHasMore) ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _historyMessages.length) {
                        if (_loadingHistory) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                          );
                        }
                        if (_historyHasMore) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Center(
                              child: GestureDetector(
                                onTap: () => _loadHistory(loadMore: true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: const Color(0xFFE1D9CB)),
                                  ),
                                  child: const Text(
                                    'Load more',
                                    style: TextStyle(
                                      color: Color(0xFF6B7280),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }

                      final i = _historyMessages.length - 1 - index;
                      final msg = _historyMessages[i];
                      final isPrevSame = i > 0 && _historyMessages[i - 1].isUser == msg.isUser;
                      final isNextSame = i < _historyMessages.length - 1 && _historyMessages[i + 1].isUser == msg.isUser;

                      return Padding(
                        padding: EdgeInsets.only(top: isPrevSame ? 2 : 10, bottom: 1),
                        child: _GuideMessageBubble(
                          key: ValueKey('history_${i}_${msg.isUser}_${msg.text.hashCode}'),
                          message: msg,
                          isPrevSame: isPrevSame,
                          isNextSame: isNextSame,
                          enableTypewriter: false,
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE7DCC8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFDFCF9),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFD1D5DB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: _keyboardListenerFocusNode,
                      onKeyEvent: _handleKeyEvent,
                      child: TextField(
                        focusNode: _focusNode,
                        controller: _controller,
                        enabled: !_sending,
                        onSubmitted: _sendMessage,
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(
                          color: Color(0xFF1F2937),
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: _inDirectMessagingMode
                              ? (widget.customActionLabel == 'Prospect Chats'
                                  ? 'Write a message for ${widget.companyName}…'
                                  : 'Write a message for ${widget.bankerName ?? 'your Banker'}…')
                              : 'Ask about your materials…',
                          hintStyle: const TextStyle(color: Color(0xFF8D8578)),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _controller,
                      builder: (context, value, _) {
                        final canSend =
                            !_sending && value.text.trim().isNotEmpty;
                        return GestureDetector(
                          onTap: canSend
                              ? () => _sendMessage(value.text)
                              : null,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: canSend
                                  ? AppThemeTokens.modalHeader
                                  : const Color(0xFFE5E7EB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.arrow_upward_rounded,
                              size: 20,
                              color: canSend
                                  ? AppThemeTokens.goldAccent
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _GuideMessageBubble extends StatelessWidget {
  final _GuideMessage message;
  final bool isPrevSame;
  final bool isNextSame;
  final bool enableTypewriter;
  final VoidCallback? onTypewriterTick;

  const _GuideMessageBubble({
    super.key,
    required this.message,
    this.isPrevSame = false,
    this.isNextSame = false,
    this.enableTypewriter = false,
    this.onTypewriterTick,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    Widget avatar(Color bg, Widget child) => Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: Center(child: child),
        );

    final aiAvatar = avatar(
      AppThemeTokens.modalHeader,
      const Text(
        'N',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppThemeTokens.goldAccent,
        ),
      ),
    );


    Widget _buildMessageContent(String data) {
      return message.isMarkdown && !isUser
          ? MarkdownBody(
              data: data,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
                strong: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                ),
                a: const TextStyle(
                  color: AppThemeTokens.buttonPrimary,
                  decoration: TextDecoration.none,
                  fontWeight: FontWeight.w600,
                ),
                listBullet: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
                code: const TextStyle(
                  fontSize: 12,
                  color: AppThemeTokens.modalHeader,
                  backgroundColor: Color(0xFFE5E7EB),
                ),
              ),
            )
          : Text(
              data,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? Colors.white : const Color(0xFF1F2937),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            );
    }

    final bubbleContent = TypewriterReveal(
      text: message.text,
      enabled: enableTypewriter && !isUser,
      onTick: onTypewriterTick,
      builder: _buildMessageContent,
    );

    // Grouped corner radii — same logic as VoiceBubbleRow
    final bubble = Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: isUser ? AppThemeTokens.buttonPrimary : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isPrevSame && !isUser ? 4 : 20),
          topRight: Radius.circular(isPrevSame && isUser ? 4 : 20),
          bottomLeft: Radius.circular(isNextSame && !isUser ? 4 : 20),
          bottomRight: Radius.circular(isNextSame && isUser ? 4 : 20),
        ),
      ),
      child: bubbleContent,
    );

    final estimatedLines =
        (message.text.length / 55).ceil() + '\n'.allMatches(message.text).length;
    final avatarAlign =
        estimatedLines <= 1 ? CrossAxisAlignment.center : CrossAxisAlignment.end;

    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: avatarAlign,
      children: isUser
          ? [
              Flexible(child: bubble),
            ]
          : [
              if (isNextSame) const SizedBox(width: 28) else aiAvatar,
              const SizedBox(width: 8),
              Flexible(child: bubble),
            ],
    );
  }
}

class _GuideTypingBubble extends StatelessWidget {
  const _GuideTypingBubble();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppThemeTokens.modalHeader,
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              'N',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppThemeTokens.goldAccent,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Thinking…',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}

class NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String message;
  final String footer;
  final VoidCallback? onTap;
  final VoidCallback? onMarkAsRead;

  const NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.message,
    required this.footer,
    this.onTap,
    this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: iconBg.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: iconColor.withValues(alpha: 0.18)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon badge
              Container(
                width: 32,
                height: 32,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 12),
              // Text content + footer row
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title + message
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: Color(0xFF202020),
                          fontSize: 13,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: '$title ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: '— $message'),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Footer + "Mark as read" at right end
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          footer,
                          style: const TextStyle(
                            color: Color(0xFF8D8578),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        if (onMarkAsRead != null)
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => onMarkAsRead!(),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: iconColor.withValues(alpha: 0.35)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, size: 10, color: iconColor),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Mark as read',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: iconColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notification Detail Modal ────────────────────────────────────────────────

class NotificationDetailModal extends StatelessWidget {
  final NotificationItem item;
  final VoidCallback onMarkAsRead;

  const NotificationDetailModal({
    required this.item,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final detail = item.detail;
    final isMobile = MediaQuery.of(context).size.width < 640;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: isMobile ? double.infinity : 840,
        height: isMobile ? null : 680,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Dark Navy Header ──────────────────────────────────────────
              Container(
                height: 120,
                color: const Color(0xFF131F2E),
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon circle with gold border
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223A56),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFB99C4C), width: 1.5),
                      ),
                      child: Icon(item.icon, color: const Color(0xFFB99C4C), size: 20),
                    ),
                    const SizedBox(width: 14),
                    // Title + subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (detail?.headerLabel != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                detail!.headerLabel!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 0.9,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB99C4C),
                                ),
                              ),
                            ),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.message,
                            style: const TextStyle(
                              color: Color(0xFFB0BCC8),
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Close button
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // ── White Scrollable Body ──────────────────────────────────────
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: detail == null
                        ? Text(
                            item.message,
                            style: const TextStyle(fontSize: 14, color: Color(0xFF202020)),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: detail.sections.map((section) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 22),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section title row
                                    Row(
                                      children: [
                                        if (section.icon != null) ...[
                                          Icon(section.icon, size: 14, color: const Color(0xFF6B6B6B)),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          section.title,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF202020),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    // Bullet points
                                    ...section.bullets.map((bullet) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.only(top: 6),
                                              child: Container(
                                                width: 5,
                                                height: 5,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF0A4A8A),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                bullet,
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Color(0xFF3D3D3D),
                                                  height: 1.5,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ),
              ),
              // ── Footer ──────────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: Colors.white,
                child: Row(
                  children: [
                    const Spacer(),
                    // Close
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6B6B6B),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 8),
                    // Mark as read
                    ElevatedButton.icon(
                      onPressed: onMarkAsRead,
                      icon: const Icon(Icons.check_circle_outline_rounded, size: 15),
                      label: const Text(
                        'Mark as read',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF131F2E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniActionButton extends StatelessWidget {
  final String label;
  final bool dark;
  final IconData? icon;
  final VoidCallback? onTap;

  const _MiniActionButton({
    required this.label,
    required this.dark,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: dark ? AppThemeTokens.modalHeader : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: dark ? AppThemeTokens.modalHeader : const Color(0xFFE1D9CB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 15, color: dark ? Colors.white : const Color(0xFF1F2937)),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CopyLinkButton extends StatefulWidget {
  final String url;
  const _CopyLinkButton({required this.url});

  @override
  State<_CopyLinkButton> createState() => _CopyLinkButtonState();
}

class _CopyLinkButtonState extends State<_CopyLinkButton> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: widget.url));
        setState(() => _copied = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _copied = false);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _copied
              ? const Color(0xFF1D9E75).withOpacity(0.1)
              : AppThemeTokens.modalHeader.withOpacity(0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          _copied ? 'Copied' : 'Copy link',
          style: TextStyle(
            color: _copied ? const Color(0xFF1D9E75) : AppThemeTokens.modalHeader,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DocChip extends StatelessWidget {
  final String label;
  final String status;
  final VoidCallback? onTap;

  const _DocChip(this.label, this.status, {this.onTap});

  @override
  Widget build(BuildContext context) {
    final isShared = status == 'Shared';
    final isReview = status == 'Needs review';
    return MouseRegion(
      cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE1D9CB)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.insert_drive_file_outlined,
                  size: 16, color: Color(0xFF8D8578)),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isShared
                      ? const Color(0xFFE1F5EE)
                      : isReview
                          ? const Color(0xFFFBEAD5)
                          : const Color(0xFFFBEAD5),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    color: isShared
                        ? const Color(0xFF0F6E56)
                        : const Color(0xFF7C5410),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddDocChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddDocChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1D9CB)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 16, color: Color(0xFF1F2937)),
              SizedBox(width: 6),
              Text(
                'Add document',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatefulWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String description;
  final String cta;
  final double? matchScore;
  final String? matchReasoning;
  final String productId;
  final String? prospectId;
  final String? websiteUrl;
  final VoidCallback? onTap;

  const _ProductCard({
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cta,
    this.matchScore,
    this.matchReasoning,
    required this.productId,
    this.prospectId,
    this.websiteUrl,
    this.onTap,
    this.defaultHover = false,
    this.onInteraction,
  });

  final bool defaultHover;
  final VoidCallback? onInteraction;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool? _localHovered;
  bool _isMatchHovered = false;
  bool _isOverlayHovered = false;
  bool _showReasoning = false;
  final _overlayController = OverlayPortalController();
  final GlobalKey _cardChipKey = GlobalKey();
  
  String? _paraphrasedReasoning;
  bool _isLoadingReasoning = false;
  final _conversationService = ConversationService();

  Future<void> _fetchParaphrasedReasoning() async {
    if (widget.prospectId == null) return;

    // 1. Check shared static cache first to see if we already have this for the current raw reasoning
    final cached = ConversationService.getCachedReasoning(widget.prospectId!, widget.productId, widget.matchReasoning);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = cached.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
      return;
    }

    if (_isLoadingReasoning) return;
    
    setState(() => _isLoadingReasoning = true);
    try {
      final result = await _conversationService.getMatchReasoning(
        prospectId: widget.prospectId!,
        productId: widget.productId,
        currentRaw: widget.matchReasoning,
      );
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = result.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReasoning = false;
          _paraphrasedReasoning = widget.matchReasoning; // Fallback
        });
      }
    }
  }
  
  bool get _isHovered => _localHovered ?? widget.defaultHover;

  void _toggleReasoning() {
    if (widget.matchScore == null || widget.matchScore! <= 0) return;
    setState(() {
      _showReasoning = !_showReasoning;
      if (_showReasoning) {
        _overlayController.show();
      } else {
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
      }
    });
  }

  void _showOverlay() {
    if (widget.matchScore == null || widget.matchScore! <= 0) return;
    _fetchParaphrasedReasoning();
    if (!_showReasoning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showReasoning) {
          _overlayController.show();
        }
      });
    }
  }

  void _hideOverlay() {
    if (widget.matchScore == null || widget.matchScore! <= 0) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_showReasoning && !_isMatchHovered && !_isOverlayHovered && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;
    
    return MouseRegion(
      onEnter: (_) {
        widget.onInteraction?.call();
        setState(() => _localHovered = true);
      },
      onExit: (_) {
        setState(() {
          _localHovered = false;
          _isMatchHovered = false;
        });
        _hideOverlay();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 320,
              height: 240,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _isHovered ? AppThemeTokens.modalHeader : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _isHovered ? AppThemeTokens.modalHeader : const Color(0xFFE1D9CB),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _isHovered
                              ? Colors.white.withOpacity(0.12)
                              : widget.tint.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(widget.icon,
                            color: _isHovered ? Colors.white : widget.iconColor,
                            size: 20),
                      ),
                      if (widget.matchScore != null && widget.matchScore! > 0)
                        OverlayPortal(
                          controller: _overlayController,
                          overlayChildBuilder: (context) {
                            return _buildReasoningOverlay(context);
                          },
                          child: MouseRegion(
                            onEnter: (_) {
                              setState(() => _isMatchHovered = true);
                              _showOverlay();
                            },
                            onExit: (_) {
                              setState(() => _isMatchHovered = false);
                              _hideOverlay();
                            },
                            child: GestureDetector(
                              onTap: isMobile ? _toggleReasoning : null,
                              child: Container(
                                key: _cardChipKey,
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D9E75).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(widget.matchScore! * 100).toInt()}% match',
                                  style: const TextStyle(
                                    color: Color(0xFF1D9E75),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _isHovered ? Colors.white : const Color(0xFF1A1A18),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      widget.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFF6F675B),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.websiteUrl != null && widget.websiteUrl!.isNotEmpty) {
                          html.window.open(widget.websiteUrl!, '_blank');
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Visit the page',
                            style: TextStyle(
                              color: _isHovered ? const Color(0xFF93C5FD) : AppThemeTokens.buttonPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: _isHovered ? const Color(0xFF93C5FD) : AppThemeTokens.buttonPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.open_in_new_rounded,
                            size: 13,
                            color: _isHovered ? const Color(0xFF93C5FD) : AppThemeTokens.buttonPrimary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasoningOverlay(BuildContext context) {
    if (widget.matchReasoning == null) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // We need the chip's position to show the overlay near it
        final renderBox = _cardChipKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();
        
        final offset = renderBox.localToGlobal(Offset.zero);
        final chipSize = renderBox.size;
        
        return Stack(
          children: [
            Positioned(
              left: offset.dx - (280 - chipSize.width),
              top: offset.dy + chipSize.height + 8,
              width: 280,
              child: MouseRegion(
                onEnter: (_) {
                  setState(() => _isOverlayHovered = true);
                },
                onExit: (_) {
                  setState(() => _isOverlayHovered = false);
                  _hideOverlay();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDFA),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFCCFBF1), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology_outlined,
                            size: 16,
                            color: Color(0xFF1D9E75),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Reasoning',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D9E75),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          if (_showReasoning)
                            GestureDetector(
                              onTap: _toggleReasoning,
                              child: const Icon(Icons.close, color: Color(0xFF1D9E75), size: 14),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isLoadingReasoning)
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                        ))
                      else if (_paraphrasedReasoning != null)
                        MarkdownBody(
                          selectable: true,
                          data: _paraphrasedReasoning!,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F766E),
                              height: 1.5,
                            ),
                            strong: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F766E),
                            ),
                          ),
                        )
                      else
                        SelectableText(
                          widget.matchReasoning ?? "Reasoning unavailable",
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF0F766E),
                            height: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ],
        );
      },
    );
  }
}

class _LearningCard extends StatefulWidget {
  final Color stripe;
  final String tag;
  final String title;
  final String meta;
  final String? description;

  final bool defaultHover;
  final bool showNewBadge;
  final VoidCallback? onInteraction;
  final VoidCallback? onTap;

  const _LearningCard({
    required this.stripe,
    required this.tag,
    required this.title,
    required this.meta,
    this.description,
    this.defaultHover = false,
    this.showNewBadge = false,
    this.onInteraction,
    this.onTap,
  });

  @override
  State<_LearningCard> createState() => _LearningCardState();
}

class _LearningCardState extends State<_LearningCard> {
  bool? _localHovered;
  bool get _isHovered => _localHovered ?? widget.defaultHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        widget.onInteraction?.call();
        setState(() => _localHovered = true);
      },
      onExit: (_) => setState(() => _localHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isHovered ? const Color(0xFF1F2937) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _isHovered ? const Color(0xFF1F2937) : const Color(0xFFE1D9CB)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: widget.stripe,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isHovered ? Colors.white.withOpacity(0.12) : const Color(0xFFFBEAD5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.tag,
                          style: TextStyle(
                            color: _isHovered ? Colors.white : const Color(0xFF7C5410),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _isHovered ? Colors.white : const Color(0xFF1A1A18),
                        ),
                      ),
                      if (widget.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          widget.description!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFF6F675B),
                            height: 1.4,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        widget.meta,
                        style: TextStyle(
                          fontSize: 12,
                          color: _isHovered ? const Color(0xFF9CA3AF) : const Color(0xFF8D8578),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: _isHovered ? Colors.white70 : const Color(0xFF8D8578),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    if (widget.showNewBadge)
      Positioned(
        top: 12,
        right: 12,
        child: _TinyBadge('New'),
      ),
  ],
),
),
);
  }
}

class _TinyBadge extends StatelessWidget {
  final String text;

  const _TinyBadge(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F5EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF0F6E56),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Profile Modal
// ─────────────────────────────────────────────────────────────────────────────

class ProspectProfileModal extends StatefulWidget {
  final String? prospectId;
  final String founderName;
  final String companyName;
  final String initials;
  final String? stageBucket;
  final bool isBanker;

  const ProspectProfileModal({
    required this.prospectId,
    required this.founderName,
    required this.companyName,
    required this.initials,
    this.stageBucket,
    this.isBanker = false,
  });

  @override
  State<ProspectProfileModal> createState() => _ProspectProfileModalState();
}

class _ProspectProfileModalState extends State<ProspectProfileModal> with SingleTickerProviderStateMixin {
  final ConversationService _service = ConversationService();
  ProspectFullProfile? _profile;
  bool _loading = true;
  String? _error;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isVoiceTriggerHovered = false;
  bool _isFetchingToken = false;

  bool get _isReturnVisit => (_profile?.conversationCount ?? 0) > 0 || (_profile?.conversationPhase ?? 1) > 1;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: false);

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _loadProfile();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _startSession({required bool isChatMode}) async {
    if (widget.prospectId == null) return;
    
    // 1. Close the profile modal
    Navigator.of(context).pop();
    
    // 2. Go to voice page screen and run voice mode conversation
    final mode = isChatMode ? 'chat' : 'voice';
    final path = '/p=${Uri.encodeComponent(widget.prospectId!)}?mode=$mode';
    context.go(path);
  }

  Future<void> _loadProfile() async {
    if (widget.prospectId == null) {
      setState(() {
        _loading = false;
        _error = 'No prospect ID available.';
      });
      return;
    }
    try {
      final profile = await _service.getProspectFullProfile(widget.prospectId!);
      if (mounted) setState(() { _profile = profile; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'Could not load profile.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: isMobile ? double.infinity : 840,
        height: isMobile ? null : (widget.isBanker ? 520.0 : 680.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              // ── Header ─────────────────────────────────────────────────────
              Container(
                padding: isMobile ? const EdgeInsets.fromLTRB(24, 24, 16, 20) : const EdgeInsets.fromLTRB(24, 20, 16, 16),
                height: isMobile ? null : 120.0,
                color: const Color(0xFF131F2E),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223A56),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFB99C4C), width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        widget.initials,
                        style: const TextStyle(
                          color: Color(0xFFB99C4C),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.founderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.companyName,
                            style: const TextStyle(
                              color: Color(0xFFB99C4C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // ── Body ───────────────────────────────────────────────────────
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: isMobile
                                    ? SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            _buildDetailsList(),
                                            if (!widget.isBanker) ...[
                                              const SizedBox(height: 24),
                                              _buildVoiceInteractionArea(),
                                            ],
                                          ],
                                        ),
                                      )
                                    : Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: widget.isBanker ? 1 : 5,
                                            child: SingleChildScrollView(
                                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                                              child: _buildDetailsList(),
                                            ),
                                          ),
                                          if (!widget.isBanker)
                                            Expanded(
                                              flex: 4,
                                              child: ScrollConfiguration(
                                                behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                                                child: LayoutBuilder(
                                                  builder: (context, constraints) {
                                                    return SingleChildScrollView(
                                                      child: ConstrainedBox(
                                                        constraints: BoxConstraints(
                                                          minHeight: constraints.maxHeight,
                                                        ),
                                                        child: Center(
                                                          child: Padding(
                                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                                            child: _buildVoiceInteractionArea(),
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                              ),
                              // ── Bottom: Team Members (Full Width) ────────
                              _buildTeamSection(),
                            ],
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsList() {
    if (_profile == null) return const SizedBox.shrink();
    
    final companyLabel = widget.companyName.isNotEmpty
        ? '${widget.companyName.toUpperCase()} DETAILS'
        : 'COMPANY DETAILS';

    final manualFormRows = [
      _buildRow('Industry', _profile!.industry),
      _buildRow('Stage', _profile!.companyStage),
      _buildRow('Headcount', _profile!.headcount),
      _buildRow('Incorporated', _profile!.incorporated ? 'Yes' : 'No'),
      if (_profile!.selectedPrioritiesJson.isNotEmpty)
        _buildRow(
          'Priorities',
          _profile!.selectedPrioritiesJson.entries
              .where((e) => e.value)
              .map((e) => e.key)
              .join(', '),
        ),
    ];

    final firstFormRows = [
      _buildRow('Email', _profile!.email),
      _buildRow('Phone', _profile!.phoneNumber),
      _buildRow('Company', _profile!.companyName),
      _buildRow('Conversations', '${_profile!.conversationCount}'),
    ];

    final insightRows = _profile!.aiAttributes.isNotEmpty
        ? _profile!.aiAttributes.entries
            .map((e) => _buildRow(
                  _formatAttributeLabel(e.key),
                  _formatAttributeValue(e.value),
                ))
            .toList()
        : null;

    if (widget.isBanker) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildSection(companyLabel, manualFormRows),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildSection('YOUR DETAILS', firstFormRows),
              ),
            ],
          ),
          if (insightRows != null && insightRows.isNotEmpty) ...[
            const SizedBox(height: 32),
            _buildSentenceSection('What We Have Collected', insightRows),
          ],
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSection(companyLabel, manualFormRows),
        const SizedBox(height: 32),
        _buildSection('YOUR DETAILS', firstFormRows),
        if (insightRows != null && insightRows.isNotEmpty) ...[
          const SizedBox(height: 32),
          _buildSentenceSection('What We Have Collected', insightRows),
        ],
      ],
    );
  }

  String _formatAttributeLabel(String key) {
    final spaced = key
        .replaceAll('_', ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        );
    return spaced
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String? _formatAttributeValue(dynamic value) {
    if (value == null || value == '') return null;
    if (value is bool) return value ? 'Yes' : 'No';
    if (value is Iterable) {
      final values = value.where((item) => item != null && item.toString().isNotEmpty);
      return values.isEmpty ? null : values.join(', ');
    }
    if (value is Map) {
      final values = value.entries
          .where((entry) => entry.value != null && entry.value.toString().isNotEmpty)
          .map((entry) => '${_formatAttributeLabel(entry.key.toString())}: ${entry.value}');
      return values.isEmpty ? null : values.join(', ');
    }
    return value.toString();
  }

  Widget _buildVoiceInteractionArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: _isFetchingToken ? SystemMouseCursors.basic : SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isVoiceTriggerHovered = true),
          onExit: (_) => setState(() => _isVoiceTriggerHovered = false),
          child: GestureDetector(
            onTap: _isFetchingToken ? null : () => _startSession(isChatMode: false),
            child: SizedBox(
              height: 200,
              width: 200,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (ctx, child) {
                  final color = _isVoiceTriggerHovered ? AppThemeTokens.buttonPrimaryHover : AppThemeTokens.buttonPrimary;
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Container(
                          width: 120 + (80 * ((_pulseAnimation.value + (i * 0.33)) % 1.0)),
                          height: 120 + (80 * ((_pulseAnimation.value + (i * 0.33)) % 1.0)),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppThemeTokens.buttonPrimary.withOpacity(0.35 * (1.0 - ((_pulseAnimation.value + (i * 0.33)) % 1.0))),
                              width: 1.5,
                            ),
                          ),
                        ),
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 54),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Tap the orb to Talk to Nova',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppThemeTokens.brandInk),
        ),
        const SizedBox(height: 6),
        Text(
          _isReturnVisit
              ? 'Continue where Nova left off'
              : '⏱️ 4-7 min · Nova asks, you answer',
          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 16),
        _buildOrSeparator(),
        const SizedBox(height: 16),
        if (_isFetchingToken)
          const CircularProgressIndicator(color: AppThemeTokens.buttonPrimary)
        else
          ElevatedButton(
            onPressed: () => _startSession(isChatMode: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF3F4F6),
              foregroundColor: AppThemeTokens.buttonPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text(
              'Chat with Nova',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
      ],
    );
  }

  Widget _buildOrSeparator() {
    return SizedBox(
      width: 160,
      child: Row(
        children: [
          Expanded(child: Container(height: 1, color: Colors.black.withOpacity(0.06))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'OR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.black.withOpacity(0.25),
              ),
            ),
          ),
          Expanded(child: Container(height: 1, color: Colors.black.withOpacity(0.06))),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildSectionTitle('TEAM MEMBERS'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              itemCount: _mockTeam.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 16),
              itemBuilder: (ctx, i) => _TeamMemberCard(member: _mockTeam[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.2,
        color: Color(0xFF8D8578),
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildSectionSentenceTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF4B5563),
      ),
    );
  }

  Widget _buildSentenceSection(String label, List<Widget?> rows) {
    final nonNullRows = rows.whereType<Widget>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionSentenceTitle(label),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7DCC8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: nonNullRows
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        entry.value,
                        if (entry.key < nonNullRows.length - 1)
                          const Divider(height: 1, color: Color(0xFFEDE7DB), indent: 14, endIndent: 14),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String label, List<Widget?> rows) {
    final nonNullRows = rows.whereType<Widget>().toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE7DCC8)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: nonNullRows
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        entry.value,
                        if (entry.key < nonNullRows.length - 1)
                          const Divider(height: 1, color: Color(0xFFEDE7DB), indent: 14, endIndent: 14),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget? _buildRow(String label, String? value) {
    if (value == null || value.isEmpty) return null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




// ─────────────────────────────────────────────────────────────────────────────
// Product Detail Modal
// ─────────────────────────────────────────────────────────────────────────────

class _ProductDetailModal extends StatefulWidget {
  final ProductPublic product;
  final String? prospectId;

  _ProductDetailModal({
    required this.product,
    this.prospectId,
  });

  @override
  State<_ProductDetailModal> createState() => _ProductDetailModalState();
}

class _ProductDetailModalState extends State<_ProductDetailModal> {
  final _overlayController = OverlayPortalController();
  final GlobalKey _modalChipKey = GlobalKey();
  bool _isMatchHovered = false;
  bool _isOverlayHovered = false;
  bool _showReasoning = false;

  String? _paraphrasedReasoning;
  bool _isLoadingReasoning = false;
  final _conversationService = ConversationService();

  Future<void> _fetchParaphrasedReasoning() async {
    if (widget.prospectId == null) return;

    // 1. Check shared static cache first
    final cached = ConversationService.getCachedReasoning(widget.prospectId!, widget.product.productId, widget.product.matchReasoning);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = cached.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
      return;
    }

    if (_isLoadingReasoning) return;
    
    setState(() => _isLoadingReasoning = true);
    try {
      final result = await _conversationService.getMatchReasoning(
        prospectId: widget.prospectId!,
        productId: widget.product.productId,
        currentRaw: widget.product.matchReasoning,
      );
      if (mounted) {
        setState(() {
          _paraphrasedReasoning = result.paraphrasedReasoning;
          _isLoadingReasoning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReasoning = false;
          _paraphrasedReasoning = widget.product.matchReasoning; // Fallback
        });
      }
    }
  }

  void _toggleReasoning() {
    if (widget.product.matchScore == null || widget.product.matchScore! <= 0) return;
    setState(() {
      _showReasoning = !_showReasoning;
      if (_showReasoning) {
        _overlayController.show();
      } else {
        if (_overlayController.isShowing) {
          _overlayController.hide();
        }
      }
    });
  }

  void _showOverlay() {
    if (widget.product.matchScore == null || widget.product.matchScore! <= 0) return;
    _fetchParaphrasedReasoning();
    if (!_showReasoning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_showReasoning) {
          _overlayController.show();
        }
      });
    }
  }

  void _hideOverlay() {
    if (widget.product.matchScore == null || widget.product.matchScore! <= 0) return;
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_showReasoning && !_isMatchHovered && !_isOverlayHovered && _overlayController.isShowing) {
        _overlayController.hide();
      }
    });
  }

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return Icons.payments_outlined;
    if (c.contains('treasury')) return Icons.monitor_heart_outlined;
    if (c.contains('card')) return Icons.credit_card_outlined;
    if (c.contains('international') || c.contains('cross-currency'))
      return Icons.public_outlined;
    if (c.contains('banking')) return Icons.account_balance_wallet_outlined;
    if (c.contains('credit') || c.contains('lending'))
      return Icons.attach_money_rounded;
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final icon = _getIconForCategory(product.category);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1180;
    final String? productLink = (product.signupUrl != null && product.signupUrl!.isNotEmpty)
        ? product.signupUrl
        : product.provider?.websiteUrl;

    Widget? matchChip;
    if (product.matchScore != null && product.matchScore! > 0) {
      matchChip = OverlayPortal(
        controller: _overlayController,
        overlayChildBuilder: (context) => _buildReasoningOverlay(context),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            _showOverlay();
          },
          onExit: (_) {
            _hideOverlay();
          },
          child: GestureDetector(
            onTap: _toggleReasoning,
            child: Container(
              key: _modalChipKey,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF1D9E75).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(product.matchScore! * 100).toInt()}% match',
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF34D399), size: 14),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final modalContent = Column(
      children: [
        if (!isDesktop)
          // Drag handle/peek bar
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                Navigator.of(context).pop();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: AppThemeTokens.modalHeader,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ),
        // ── Header ─────────────────────────────────────────
        Container(
          padding: isDesktop ? const EdgeInsets.fromLTRB(24, 20, 16, 16) : const EdgeInsets.fromLTRB(24, 24, 24, 20),
          height: isDesktop ? 120.0 : null,
          color: AppThemeTokens.modalHeader,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (product.provider != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${product.provider!.companyName}${product.provider!.hqLocation != null ? ' • ${product.provider!.hqLocation}' : ''}',
                            style: const TextStyle(
                              color: Color(0xFFB99C4C),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (matchChip != null && isDesktop) ...[
                    const SizedBox(width: 14),
                    matchChip,
                  ],
                  if (isDesktop) ...[
                    const SizedBox(width: 14),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white70, size: 24),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ],
              ),
              if (productLink != null || matchChip != null) ...[
                SizedBox(height: isDesktop ? 4 : 8),
                Padding(
                  padding: const EdgeInsets.only(left: 58),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (productLink != null)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              html.window.open(productLink, '_blank');
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Visit the page',
                                  style: TextStyle(
                                    color: Color(0xFFB99C4C),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFFB99C4C),
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.open_in_new_rounded,
                                  color: Color(0xFFB99C4C),
                                  size: 13,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (matchChip != null && !isDesktop)
                        matchChip
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // ── Body ───────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDropdownSection(
                  title: 'OVERVIEW',
                  initiallyExpanded: true,
                  content: Text(
                    product.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                      height: 1.5,
                    ),
                  ),
                ),
                if (product.features.isNotEmpty)
                  _buildDropdownSection(
                    title: 'KEY FEATURES',
                    content: _buildColumnList(product.features.map((f) => f.toString()).toList()),
                  ),
                if (product.benefits.isNotEmpty)
                  _buildDropdownSection(
                    title: 'BENEFITS',
                    content: _buildColumnList(product.benefits),
                  ),
                if (product.pricingDetails != null)
                  _buildDropdownSection(
                    title: 'PRICING',
                    content: Text(
                      product.pricingDetails!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                if (product.eligibilityCriteria.isNotEmpty)
                  _buildDropdownSection(
                    title: 'ELIGIBILITY',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: product.eligibilityCriteria.entries.map((e) =>
                          _buildBulletPoint('${e.key}: ${e.value}')).toList(),
                    ),
                  ),
                _buildDropdownSection(
                  title: 'CLASSIFICATION',
                  content: Text(
                    '${product.category}${product.subcategory != null ? ' • ${product.subcategory}' : ''}',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: 840,
          height: 680.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: modalContent,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: modalContent,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnList(List<String> items) {
    if (items.length <= 4) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((i) => _buildBulletPoint(i)).toList(),
      );
    } else {
      int mid = (items.length / 2).ceil();
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.sublist(0, mid).map((i) => _buildBulletPoint(i)).toList(),
            ),
          ),
          const SizedBox(width: 32),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items.sublist(mid).map((i) => _buildBulletPoint(i)).toList(),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildReasoningOverlay(BuildContext context) {
    if (widget.product.matchReasoning == null) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final renderBox = _modalChipKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox == null) return const SizedBox.shrink();
        
        final offset = renderBox.localToGlobal(Offset.zero);
        final chipSize = renderBox.size;
        
        return Stack(
          children: [
            Positioned(
              left: offset.dx - (280 - chipSize.width),
              top: offset.dy + chipSize.height + 8,
              width: 280,
              child: MouseRegion(
                onEnter: (_) {
                  setState(() => _isOverlayHovered = true);
                },
                onExit: (_) {
                  setState(() => _isOverlayHovered = false);
                  _hideOverlay();
                },
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDFA),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFCCFBF1), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.psychology_outlined,
                              size: 16,
                              color: Color(0xFF1D9E75),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Reasoning',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D9E75),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            if (_showReasoning)
                              GestureDetector(
                                onTap: _toggleReasoning,
                                child: const Icon(Icons.close, color: Color(0xFF1D9E75), size: 14),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isLoadingReasoning)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1D9E75)),
                          ))
                        else if (_paraphrasedReasoning != null)
                          MarkdownBody(
                            selectable: true,
                            data: _paraphrasedReasoning!,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F766E),
                                height: 1.5,
                              ),
                              strong: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                          )
                        else
                          SelectableText(
                            widget.product.matchReasoning ?? "Reasoning unavailable",
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF0F766E),
                              height: 1.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 12,
        letterSpacing: 1.2,
        color: Color(0xFF64748B),
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF334155),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSection({
    required String title,
    required Widget content,
    bool initiallyExpanded = false,
  }) {
    return _ModalDropdownSection(
      title: title,
      content: content,
      initiallyExpanded: initiallyExpanded,
    );
  }
}

class _ModalDropdownSection extends StatefulWidget {
  final String title;
  final Widget content;
  final bool initiallyExpanded;

  const _ModalDropdownSection({
    required this.title,
    required this.content,
    this.initiallyExpanded = false,
  });

  @override
  State<_ModalDropdownSection> createState() => _ModalDropdownSectionState();
}

class _ModalDropdownSectionState extends State<_ModalDropdownSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            child: Row(
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 16),
            child: widget.content,
          ),
        const Divider(color: Color(0xFFE2E8F0), height: 1),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Learning Material Modal
// ─────────────────────────────────────────────────────────────────────────────

class _LearningMaterialModal extends StatelessWidget {
  final String title;

  const _LearningMaterialModal({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1180;
    final modalContent = Column(
      children: [
        if (!isDesktop)
          // Drag handle/peek bar
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 100) {
                Navigator.of(context).pop();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: AppThemeTokens.modalHeader,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
          ),
        // ── Header ─────────────────────────────────────────
        Container(
          padding: isDesktop ? const EdgeInsets.fromLTRB(24, 20, 16, 16) : const EdgeInsets.fromLTRB(24, 24, 24, 20),
          height: isDesktop ? 120.0 : null,
          color: AppThemeTokens.modalHeader,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFB99C4C).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFFB99C4C), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'CURATED GUIDE • 8 MIN READ',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDesktop)
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 24),
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        ),
        // ── Body ───────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection('INTRODUCTION', 
                  'For early-stage startups, the foundation of your financial operations can dictate your speed of growth. This guide outlines how to establish a robust banking setup that automates manual tasks, ensures compliance, and prepares you for your first institutional funding round.'),
                
                const SizedBox(height: 32),
                
                _buildSection('WHY BANKING ARCHITECTURE MATTERS', 
                  'Many founders treat banking as a utility, but it’s actually your most critical financial infrastructure. A well-designed setup helps you:\n\n• Maintain clean books for future audits\n• Automate vendor payments without manual oversight\n• Safeguard investor capital through multi-layered security\n• Leverage treasury solutions to extend your runway'),
                
                const SizedBox(height: 40),
                
                const Text(
                  'KEY STEPS TO GETTING STARTED',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppThemeTokens.modalHeader,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                
                _buildStepCard(
                  '1', 
                  'Choose the Right Entity Bank Account', 
                  'Ensure your bank supports C-Corp structures and has specialized startup teams who understand VC-backed growth models.'
                ),
                _buildStepCard(
                  '2', 
                  'Implement Proper Segregation of Duties', 
                  'Set up secondary approvers for large transfers to prevent fraud and internal errors from day one.'
                ),
                _buildStepCard(
                  '3', 
                  'Link Your Accounting Stack', 
                  'Connect your bank feeds directly to QuickBooks or Xero to eliminate manual data entry and minimize reconciliation lag.'
                ),
                
                const SizedBox(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFB99C4C), size: 20),
                          SizedBox(width: 8),
                          Text(
                            'PRO TIP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFB99C4C),
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Consider opening a secondary "Reserve" account. Move 80% of your venture capital into this account and only pull into your "Operating" account what is needed for the month\'s burn. This reduces risk and improves interest yield management.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey.shade800,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                const Divider(color: Color(0xFFE2E8F0)),
                const SizedBox(height: 20),
                const Text(
                  'Ready to optimize your treasury?\nSchedule a 1:1 consultation with Sarah to review your current setup.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemeTokens.buttonPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Book Consultation', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    if (isDesktop) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Container(
          width: 840,
          height: 680.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: modalContent,
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => Navigator.of(context).pop(),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Material(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: modalContent,
            ),
          ),
        ),
      ),
    );
}

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E293B),
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStepCard(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppThemeTokens.modalHeader.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: AppThemeTokens.modalHeader,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






class _TeamMember {
  final String name;
  final String role;
  final String email;
  final String initials;

  _TeamMember(this.name, this.role, this.email, this.initials);
}

final List<_TeamMember> _mockTeam = [
  _TeamMember('Alex Chen', 'Co-Founder & CTO', 'alex@bank.ai', 'AC'),
  _TeamMember('Sarah Johnson', 'Head of Product', 'sarah@bank.ai', 'SJ'),
  _TeamMember('Michael Brown', 'Lead Engineer', 'michael@bank.ai', 'MB'),
  _TeamMember('Emily Davis', 'Marketing Director', 'emily@bank.ai', 'ED'),
  _TeamMember('David Wilson', 'Operations Lead', 'david@bank.ai', 'DW'),
];

class _TeamMemberCard extends StatefulWidget {
  final _TeamMember member;
  const _TeamMemberCard({required this.member});

  @override
  State<_TeamMemberCard> createState() => _TeamMemberCardState();
}

class _TeamMemberCardState extends State<_TeamMemberCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => _TeamMemberProfileModal(member: widget.member),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF9FAFB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _isHovered ? const Color(0xFFD1D5DB) : const Color(0xFFE7DCC8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFF223A56),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      widget.member.initials,
                      style: const TextStyle(
                        color: AppThemeTokens.goldAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A18),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.member.role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamMemberProfileModal extends StatelessWidget {
  final _TeamMember member;
  const _TeamMemberProfileModal({required this.member});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 16, 20),
              decoration: const BoxDecoration(
                color: AppThemeTokens.modalHeader,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF223A56),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppThemeTokens.goldAccent, width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      member.initials,
                      style: const TextStyle(
                        color: AppThemeTokens.goldAccent,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.role,
                          style: const TextStyle(color: AppThemeTokens.goldAccent, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.email_outlined, 'Email', member.email),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.business_center_outlined, 'Department', 'Core Team'),
                  const SizedBox(height: 16),
                  _buildDetailRow(Icons.location_on_outlined, 'Location', 'Remote'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF4B5563)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, color: Color(0xFF111827), fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadDocModal extends StatefulWidget {
  const _UploadDocModal();

  @override
  State<_UploadDocModal> createState() => _UploadDocModalState();
}

class _UploadDocModalState extends State<_UploadDocModal> {
  String? _fileName;
  int? _fileSize;
  bool _isDragging = false;
  bool _isUploading = false;
  
  StreamSubscription? _dragOverSub;
  StreamSubscription? _dragLeaveSub;
  StreamSubscription? _dropSub;

  @override
  void initState() {
    super.initState();
    _dragOverSub = html.window.onDragOver.listen((event) {
      event.preventDefault();
      if (event.dataTransfer.types?.contains('Files') == true) {
        if (!_isDragging) {
          setState(() {
            _isDragging = true;
          });
        }
      }
    });

    _dragLeaveSub = html.window.onDragLeave.listen((event) {
      event.preventDefault();
      if (_isDragging) {
        setState(() {
          _isDragging = false;
        });
      }
    });

    _dropSub = html.window.onDrop.listen((event) {
      event.preventDefault();
      if (_isDragging) {
        setState(() {
          _isDragging = false;
        });
      }
      if (event.dataTransfer.files != null && event.dataTransfer.files!.isNotEmpty) {
        final file = event.dataTransfer.files!.first;
        _handleFileSelected(file.name, file.size);
      }
    });
  }

  @override
  void dispose() {
    _dragOverSub?.cancel();
    _dragLeaveSub?.cancel();
    _dropSub?.cancel();
    super.dispose();
  }

  void _handleFileSelected(String name, int size) {
    setState(() {
      _fileName = name;
      _fileSize = size;
    });
  }

  void _triggerFilePicker() {
    final input = html.InputElement(type: 'file');
    input.accept = '.pdf,.docx,.xlsx,.xls,.png,.jpg,.jpeg';
    input.click();
    input.onChange.listen((event) {
      if (input.files != null && input.files!.isNotEmpty) {
        final file = input.files!.first;
        _handleFileSelected(file.name, file.size);
      }
    });
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    if (bytes < 1024 * 1024 * 1024) return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
    return "${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB";
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: isMobile ? double.infinity : 520.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
                color: AppThemeTokens.modalHeader,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppThemeTokens.goldAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppThemeTokens.goldAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Upload Document',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white60, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Share pitch decks, financials, or other documentation directly with your startup banking team.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _triggerFilePicker,
                      child: Container(
                        height: 180,
                        decoration: BoxDecoration(
                          color: _isDragging
                              ? AppThemeTokens.goldAccent.withOpacity(0.06)
                              : const Color(0xFFFAF9F6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isDragging
                                ? AppThemeTokens.goldAccent
                                : const Color(0xFFE1D9CB),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isDragging
                                    ? Icons.file_download_outlined
                                    : Icons.upload_file_outlined,
                                size: 44,
                                color: _isDragging
                                    ? AppThemeTokens.goldAccent
                                    : AppThemeTokens.buttonPrimary,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _isDragging
                                    ? 'Drop the file to select'
                                    : 'Drag & drop file here, or click to browse',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: _isDragging
                                      ? AppThemeTokens.goldAccent
                                      : const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Supports PDF, DOCX, XLSX up to 50MB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8D8578),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_fileName != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1F5EE),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBBEAD8)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file_outlined,
                              color: Color(0xFF0F6E56),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _fileName!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0F6E56),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatBytes(_fileSize ?? 0),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF3F8A74),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Color(0xFF0F6E56),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _fileName = null;
                                  _fileSize = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF4B5563),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: (_fileName == null || _isUploading)
                              ? null
                              : () async {
                                  setState(() => _isUploading = true);
                                  await Future.delayed(const Duration(milliseconds: 600));
                                  if (mounted) {
                                    Navigator.of(context).pop(_fileName);
                                  }
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppThemeTokens.buttonPrimary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                )
                              : const Text('Upload'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrepCallModal extends StatelessWidget {
  const _PrepCallModal();

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 640;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Container(
        width: isMobile ? double.infinity : 520.0,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
                color: AppThemeTokens.modalHeader,
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFF213E5B),
                      child: Text(
                        'SC',
                        style: TextStyle(
                          color: AppThemeTokens.goldAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Prep Call with Sarah Chen',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Innovation Banking Relationship Manager',
                            style: TextStyle(
                              color: Color(0xFFB8C3D1),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Colors.white60, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Suggested Talking Points & Agenda',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPrepItem(
                      text: 'Review the Q1 Financial Statements & investor deck uploaded recently.',
                    ),
                    _buildPrepItem(
                      text: 'Be ready to discuss credit line options and interest rate tiers.',
                    ),
                    _buildPrepItem(
                      text: 'Identify treasury services needed for international wire transfers.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF9F6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE1D9CB)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppThemeTokens.goldAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'AI Insight',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Sarah Chen leads innovation banking and focuses on early-stage tech funding. Emphasize your runway extension objectives during the call.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemeTokens.buttonPrimary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Start Call prep',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrepItem({required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, left: 4, right: 12),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppThemeTokens.buttonPrimary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF4B5563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AiGuidePanel extends StatelessWidget {
  final String? prospectId;
  final String? bankerId;
  final String founderName;
  final String companyName;
  final String industry;
  final String stageLabel;
  final List<String> priorities;
  final VoidCallback? onClose;
  final String? customActionLabel;
  final VoidCallback? onCustomActionTap;
  final String? bankerName;
  final FocusNode? focusNode;
  final bool inDirectMessagingMode;
  final VoidCallback? onBackToNova;
  final List<CrmProspect>? prospectsList;
  final ValueChanged<CrmProspect>? onProspectSelected;
  final bool lockDropdown;
  final bool showLeftBorder;

  const AiGuidePanel({
    super.key,
    this.prospectId,
    this.bankerId,
    required this.founderName,
    required this.companyName,
    required this.industry,
    required this.stageLabel,
    required this.priorities,
    this.onClose,
    this.customActionLabel,
    this.onCustomActionTap,
    this.bankerName,
    this.focusNode,
    this.inDirectMessagingMode = false,
    this.onBackToNova,
    this.prospectsList,
    this.onProspectSelected,
    this.lockDropdown = false,
    this.showLeftBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return _AiGuidePanel(
      prospectId: prospectId,
      bankerId: bankerId,
      founderName: founderName,
      companyName: companyName,
      industry: industry,
      stageLabel: stageLabel,
      priorities: priorities,
      onClose: onClose,
      customActionLabel: customActionLabel,
      onCustomActionTap: onCustomActionTap,
      bankerName: bankerName,
      focusNode: focusNode,
      inDirectMessagingMode: inDirectMessagingMode,
      onBackToNova: onBackToNova,
      prospectsList: prospectsList,
      onProspectSelected: onProspectSelected,
      lockDropdown: lockDropdown,
      showLeftBorder: showLeftBorder,
    );
  }
}

class NotificationsSection extends StatelessWidget {
  final String bankerName;
  final String bankerPosition;
  final bool isBanker;
  final String? prospectName;
  final String? founderName;
  final List<CrmProspect>? prospectsList;

  const NotificationsSection({
    key,
    this.bankerName = 'Sarah Chen',
    this.bankerPosition = 'Innovation Banking',
    this.isBanker = false,
    this.prospectName,
    this.founderName,
    this.prospectsList,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _NotificationsSection(
      bankerName: bankerName,
      bankerPosition: bankerPosition,
      isBanker: isBanker,
      prospectName: prospectName,
      founderName: founderName,
      prospectsList: prospectsList,
    );
  }
}

class ProductCard extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final Color iconColor;
  final String title;
  final String description;
  final String cta;
  final double? matchScore;
  final String? matchReasoning;
  final String productId;
  final String? prospectId;
  final String? websiteUrl;
  final VoidCallback? onTap;
  final bool defaultHover;
  final VoidCallback? onInteraction;

  const ProductCard({
    super.key,
    required this.icon,
    required this.tint,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cta,
    this.matchScore,
    this.matchReasoning,
    required this.productId,
    this.prospectId,
    this.websiteUrl,
    this.onTap,
    this.defaultHover = false,
    this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return _ProductCard(
      icon: icon,
      tint: tint,
      iconColor: iconColor,
      title: title,
      description: description,
      cta: cta,
      matchScore: matchScore,
      matchReasoning: matchReasoning,
      productId: productId,
      prospectId: prospectId,
      websiteUrl: websiteUrl,
      onTap: onTap,
      defaultHover: defaultHover,
      onInteraction: onInteraction,
    );
  }
}

class ProductDetailModal extends StatelessWidget {
  final ProductPublic product;
  final String? prospectId;

  const ProductDetailModal({
    super.key,
    required this.product,
    this.prospectId,
  });

  @override
  Widget build(BuildContext context) {
    return _ProductDetailModal(
      product: product,
      prospectId: prospectId,
    );
  }
}
