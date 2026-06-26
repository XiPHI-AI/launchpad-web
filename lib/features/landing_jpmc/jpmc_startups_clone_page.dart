import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/conversation_service.dart';
import '../../shared/widgets/app_shell.dart';
import '../../shared/widgets/hub_nav_bar.dart';
import '../../theme/app_theme.dart';
import '../../services/prospect_storage.dart';
import '../../features/relationship_hub/relationship_hub_page.dart';
import '../../shared/widgets/prospect_id_provider.dart';
import '../../core/branding/branding_provider.dart';

class JpmcStartupsClonePage extends ConsumerStatefulWidget {
  final String? invitationCode;
  final String? returnProspectId;

  const JpmcStartupsClonePage({
    super.key,
    this.invitationCode,
    this.returnProspectId,
  });

  @override
  ConsumerState<JpmcStartupsClonePage> createState() => _JpmcStartupsClonePageState();
}

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_StickyHeaderDelegate oldDelegate) {
    return height != oldDelegate.height || child != oldDelegate.child;
  }
}

class _JpmcStartupsClonePageState extends ConsumerState<JpmcStartupsClonePage> {
  final _service = ConversationService();
  String _b(String text) {
    final branding = ref.watch(brandingProvider);
    return cleanBrandingText(text, branding);
  }
  bool _isLoading = false;
  String? _errorMessage;
  ProspectInitResult? _resolvedProspect;
  ProspectInitResult? _resolvedProspectForNavbar;
  bool _startAtModeSelection = false;
  String? _storedProspectId;
  final _prospectStorage = ProspectStorage();

  String get _initials {
    final vars = _resolvedProspectForNavbar?.toDynamicVariables();
    final name = vars?['userName']?.toString() ?? 'Guest';
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).take(2).toList();
    if (parts.isEmpty) return 'G';
    return parts.map((p) => p[0].toUpperCase()).join();
  }

  String get _companyName {
    final vars = _resolvedProspectForNavbar?.toDynamicVariables();
    return vars?['companyName']?.toString() ?? 'Prospectz.ai';
  }

  String get _founderName {
    final vars = _resolvedProspectForNavbar?.toDynamicVariables();
    return vars?['userName']?.toString() ?? 'Guest';
  }

  bool get _isHubEnabled {
    final phase = _resolvedProspectForNavbar?.conversationPhase ?? 1;
    return phase > 1;
  }

  @override
  void initState() {
    super.initState();
    final returnProspectId =
        widget.returnProspectId ?? Uri.base.queryParameters['p'];
    final invitationCode =
        widget.invitationCode ?? Uri.base.queryParameters['invite'];
    
    _checkStoredProspect();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (returnProspectId != null && returnProspectId.isNotEmpty) {
        _handleReturnVisit(returnProspectId);
      } else if (invitationCode != null && invitationCode.isNotEmpty) {
        _handleInviteCode(invitationCode);
      }
    });
  }

  Future<void> _checkStoredProspect() async {
    final pid = await _prospectStorage.getProspectId();
    if (pid != null) {
      if (mounted) {
        setState(() {
          _storedProspectId = pid;
          final cached = ProspectCache.get(pid);
          if (cached != null) {
            _resolvedProspectForNavbar = cached;
          }
        });
      }
      try {
        final prospect = await _service.getProspect(pid);
        ProspectCache.set(pid, prospect);
        if (mounted) {
          setState(() {
            _resolvedProspectForNavbar = prospect;
          });
        }
      } catch (e) {
        debugPrint('Failed to load prospect for navbar: $e');
      }
    }
  }

  Future<void> _handleReturnVisit(String prospectId) async {
    setState(() => _isLoading = true);
    try {
      final prospect = await _service.getProspect(prospectId);
      if (!mounted) return;
      setState(() {
        _resolvedProspect = prospect;
        _startAtModeSelection = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Could not resume session.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleInviteCode(String invitationCode) async {
    setState(() => _isLoading = true);
    try {
      final initResult = await _service.initProspect(invitationCode);
      if (!mounted) return;
      setState(() {
        _resolvedProspect = initResult;
        _startAtModeSelection = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Invalid link.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _startSession() async {
    final returnPid = _storedProspectId;
    if (returnPid != null) {
      context.go('/stages?p=$returnPid');
    } else {
      context.go('/stages');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppThemeTokens.buttonPrimary),
              ),
              const SizedBox(height: 24),
              Text(
                'Resuming your session...',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_resolvedProspect != null) {
      final resolved = _resolvedProspect!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final path = _startAtModeSelection
              ? '/p=${Uri.encodeComponent(resolved.prospectId)}'
              : '/stages?p=${Uri.encodeComponent(resolved.prospectId)}';
          context.go(path);
        }
      });
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppThemeTokens.buttonPrimary),
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isDesktop = screenWidth >= 1024;

    const jpmcBrown = Color(0xFF4A3C31);
    const jpmcLightBrown = AppThemeTokens.goldAccent;
    const jpmcDarkNavy = Color(0xFF131F2E);
    const jpmcTeal = AppThemeTokens.buttonPrimary;
    const lpIndigo = Color(0xFF4F46E5);
    const lpIndigoDk = Color(0xFF3730A3);
    const navy = AppThemeTokens.modalHeader;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    const darkGreyBar = Color(0xFF333A43);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyHeaderDelegate(
                  height: 74,
                  child: ProspectIdProvider(
                    prospectId: _storedProspectId,
                    child: HubNavBar(
                      companyName: _companyName,
                      founderName: _founderName,
                      initials: _initials,
                      activeLabel: 'Home',
                      isHubEnabled: _isHubEnabled,
                      onInteractionsTap: _startSession,
                      onProfileTap: _storedProspectId != null
                          ? () {
                              showDialog(
                                context: context,
                                builder: (_) => ProspectProfileModal(
                                  prospectId: _storedProspectId,
                                  founderName: _founderName,
                                  companyName: _companyName,
                                  initials: _initials,
                                  stageBucket: _resolvedProspectForNavbar?.stageBucket ?? 'super_agent',
                                ),
                              );
                            }
                          : null,
                      onLogout: _storedProspectId != null
                          ? () async {
                              ProspectCache.clear();
                              ProductCache.clear();
                              await _prospectStorage.clearProspectId();
                              if (mounted) {
                                setState(() {
                                  _storedProspectId = null;
                                  _resolvedProspect = null;
                                  _resolvedProspectForNavbar = null;
                                  _startAtModeSelection = false;
                                });
                              }
                            }
                          : null,
                    ),
                  ),
                ),
              ),

              // Sub-navigation breadcrumb
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Commercial Banking',
                        style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(Icons.chevron_right, size: 16, color: Colors.black54),
                      ),
                      Text(
                        'Innovation Economy',
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),

              // Hero Section
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Background Image
                    Container(
                      height: 600,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E1E1E), // Fallback
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=2940&auto=format&fit=crop'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black45, // Darken image slightly for text readability
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                    
                    // Content
                    Positioned.fill(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Banking the innovation\neconomy',
                              style: TextStyle(
                                fontSize: isMobile ? 40 : 64,
                                color: Colors.white,
                                fontWeight: FontWeight.w400,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: 600,
                              child: Text(
                                'Streamlined financial solutions and expert guidance to support your startup from seed to IPO and beyond.',
                                style: TextStyle(
                                  fontSize: isMobile ? 16 : 18,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 48),
                            ElevatedButton(
                              onPressed: _startSession,
                              style: Theme.of(context)
                                  .elevatedButtonTheme
                                  .style
                                  ?.copyWith(
                                    padding: WidgetStateProperty.all(
                                      const EdgeInsets.symmetric(
                                          horizontal: 32, vertical: 18),
                                    ),
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(0),
                                      ),
                                    ),
                                  ),
                              child: Text(
                                (_resolvedProspect != null || _storedProspectId != null) ? 'CONTINUE' : 'GET STARTED',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 80), // Space for bottom bar
                          ],
                        ),
                      ),
                    ),

                    // Bottom Floating Bar
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: const Color(0xFF333333).withOpacity(0.95),
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80),
                        height: 70,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!isMobile)
                              Row(
                                children: [
                                  _bottomBarItem('Banking solutions'),
                                  _bottomBarItem('Support at any stage'),
                                  _bottomBarItem('Industries & leaders'),
                                  _bottomBarItem('Expert insights'),
                                  _bottomBarItem('FAQs'),
                                ],
                              ),
                            
                            // Banker's Portal action
                            InkWell(
                              onTap: () => context.go('/banker'),
                              child: Container(
                                height: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                decoration: BoxDecoration(
                                  border: Border(
                                    left: BorderSide(color: Colors.white.withOpacity(0.2)),
                                  ),
                                ),
                                child: Row(
                                  children: const [
                                    Text(
                                      "BANKER'S PORTAL",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.chevron_right, color: Colors.white, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Hero White Section (Bank your startup with confidence)
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: isMobile ? 60 : 100),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: AppThemeTokens.fontFamily,
                                  fontSize: 36,
                                  color: Color(0xFF4A5568),
                                  fontWeight: FontWeight.w300,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(text: 'Bank your startup '),
                                  TextSpan(text: 'with\n', style: TextStyle(color: jpmcLightBrown)),
                                  TextSpan(text: 'confidence', style: TextStyle(color: jpmcLightBrown)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'With decades of global experience, a robust professional and venture capital network and scalable money-management solutions, we\'re dedicated to helping you succeed at every stage.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                height: 1.6,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: AppThemeTokens.fontFamily,
                                    fontSize: 54,
                                    color: Color(0xFF4A5568),
                                    fontWeight: FontWeight.w300,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(text: 'Bank your startup '),
                                    TextSpan(text: 'with\n', style: TextStyle(color: jpmcLightBrown)),
                                    TextSpan(text: 'confidence', style: TextStyle(color: jpmcLightBrown)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  'With decades of global experience, a robust professional and venture capital network and scalable money-management solutions, we\'re dedicated to helping you succeed at every stage.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Stats Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 80, vertical: 40),
                  child: isMobile
                      ? Column(
                          children: [
                            _statItem('11K', const Color(0xFF1E88E5), 'INNOVATION ECONOMY BANKING CLIENTS GLOBALLY'),
                            const SizedBox(height: 40),
                            _statItem('40+', const Color(0xFF8E24AA), 'COUNTRIES WHERE WE SUPPORT INNOVATIVE COMPANIES'),
                            const SizedBox(height: 40),
                            _statItem('550+', const Color(0xFFE65100), 'INNOVATION ECONOMY BANKERS GLOBALLY'),
                            const SizedBox(height: 40),
                            _statItem('\$18B', const Color(0xFF2E7D32), 'INVESTED IN TECHNOLOGY'),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _statItem('11K', const Color(0xFF42A5F5), 'INNOVATION ECONOMY BANKING CLIENTS\nGLOBALLY')),
                            Expanded(child: _statItem('40+', const Color(0xFFAB47BC), 'COUNTRIES WHERE WE SUPPORT INNOVATIVE\nCOMPANIES')),
                            Expanded(child: _statItem('550+', const Color(0xFFEF6C00), 'INNOVATION ECONOMY BANKERS GLOBALLY')),
                            Expanded(child: _statItem('\$18B', const Color(0xFF2E7D32), 'INVESTED IN TECHNOLOGY')),
                          ],
                        ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),

              // Dark Data Background Section + Floating Card
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    // Dark background image
                    Container(
                      height: isMobile ? 400 : 500,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: jpmcDarkNavy,
                        image: DecorationImage(
                          image: NetworkImage(
                              'https://images.unsplash.com/photo-1551288049-bebda4e38f71?q=80&w=2940&auto=format&fit=crop'),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black54,
                            BlendMode.darken,
                          ),
                        ),
                      ),
                    ),
                    
                    // White floating card
                    Positioned(
                      bottom: 0,
                      left: isMobile ? 24 : 120,
                      right: isMobile ? 24 : 120,
                      child: Container(
                        padding: EdgeInsets.all(isMobile ? 20 : 64),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            top: BorderSide(color: jpmcLightBrown, width: 4),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontFamily: AppThemeTokens.fontFamily,
                                  fontSize: isMobile ? 24 : 48,
                                  color: const Color(0xFF4A5568),
                                  fontWeight: FontWeight.w300,
                                  height: 1.2,
                                ),
                                children: [
                                  const TextSpan(text: 'Banking solutions to '),
                                  TextSpan(text: isMobile ? 'match your ' : 'match your\n', style: const TextStyle(color: jpmcLightBrown)),
                                  const TextSpan(text: 'scale and needs', style: TextStyle(color: jpmcLightBrown)),
                                ],
                              ),
                            ),
                            SizedBox(height: isMobile ? 16 : 32),
                            Text(
                              'Our products can help you reduce costs, save time and make more informed decisions—allowing you to focus on growing your business.',
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 18,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Colored Solutions Cards Carousel
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 120, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carousel Controls
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
                            child: Icon(Icons.chevron_left, color: Colors.grey.shade600, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Text('1 / 4', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
                            child: Icon(Icons.chevron_right, color: Colors.grey.shade600, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      // Horizontal Cards
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _solutionCardCol(
                              color: const Color(0xFF42A5F5),
                              iconUrl: 'https://cdn-icons-png.flaticon.com/512/2761/2761118.png', 
                              title: 'Manage multiple accounts with Connect',
                              points: [
                                'Automate invoicing, manage cash flow and streamline reporting',
                                'Send wires in nearly 70 currencies',
                                'No fees for up to three years on included services',
                              ],
                            ),
                            _solutionCardCol(
                              color: const Color(0xFFAB47BC),
                              iconUrl: 'https://cdn-icons-png.flaticon.com/512/3063/3063822.png',
                              title: 'Streamline payments with Cashflow360℠',
                              points: [
                                '2x faster payments with ACH vs. traditional check',
                                'Spend 50% less time paying and approving bills',
                                'Automatically sync with your accounting software',
                              ],
                            ),
                            _solutionCardCol(
                              color: const Color(0xFFEF6C00),
                              iconUrl: 'https://cdn-icons-png.flaticon.com/512/2953/2953363.png',
                              title: 'Maximize yield on idle cash',
                              points: [
                                'Get instant access to liquidity with no limit on deposits',
                                'No period trades, rollover or administration required',
                                'Integrated with our treasury tools for efficient capital management',
                              ],
                            ),
                            _solutionCardCol(
                              color: const Color(0xFF2E7D32),
                              iconUrl: 'https://cdn-icons-png.flaticon.com/512/4021/4021708.png',
                              title: 'Monetize B2B spend with commercial cards',
                              points: [
                                'Choose from physical and virtual cards',
                                'Enable spend for travel, procurement and more',
                                '24/7 customer support and fraud protection',
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Expertise Section
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 120, vertical: isMobile ? 60 : 100),
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: const TextSpan(
                                style: TextStyle(
                                  fontFamily: AppThemeTokens.fontFamily,
                                  fontSize: 32,
                                  color: Color(0xFF4A5568),
                                  fontWeight: FontWeight.w300,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(text: 'Expertise supporting your growth '),
                                  TextSpan(text: 'at every stage', style: TextStyle(color: jpmcLightBrown)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'We work with companies throughout their entire lifecycle—early stage, growth stage, late stage, pre-IPO and beyond—to help them scale and grow.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                height: 1.6,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: AppThemeTokens.fontFamily,
                                    fontSize: 48,
                                    color: Color(0xFF4A5568),
                                    fontWeight: FontWeight.w300,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(text: 'Expertise supporting your\ngrowth '),
                                    TextSpan(text: 'at every stage', style: TextStyle(color: jpmcLightBrown)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 40),
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text(
                                  'We work with companies throughout their entire lifecycle—\early stage, growth stage, late stage, pre-IPO and beyond—to\nhelp them scale and grow.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // Dark Navy Tabs Section
              SliverToBoxAdapter(
                child: Container(
                  color: jpmcDarkNavy,
                  child: Column(
                    children: [
                      // Tabs
                      Container(
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.1))),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 120),
                          child: Row(
                            children: [
                              Expanded(child: Center(child: _stageTab(context, 'Early stage', isActive: true))),
                              Expanded(child: Center(child: _stageTab(context, 'Growth stage'))),
                              Expanded(child: Center(child: _stageTab(context, 'Late stage'))),
                            ],
                          ),
                        ),
                      ),
                      
                      // Content Area
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 120, vertical: isMobile ? 40 : 80),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Early stage',
                                    style: TextStyle(
                                      fontSize: isMobile ? 28 : 42,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontFamily: AppThemeTokens.fontFamily,
                                        fontSize: isMobile ? 15 : 18,
                                        color: Colors.white.withOpacity(0.8),
                                        height: 1.6,
                                      ),
                                      children: const [
                                        TextSpan(text: 'From pre-seed to seed, we offer comprehensive support including operating accounts, liquidity management, card and merchant processing, cap table management, '),
                                        TextSpan(text: 'Startup Offers', style: TextStyle(decoration: TextDecoration.underline)),
                                        TextSpan(text: ' and financing alternatives to help you grow.'),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 32 : 48),
                                  InkWell(
                                    onTap: _startSession,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Text(
                                          'LEARN MORE',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Icon(Icons.chevron_right, color: Colors.white, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isMobile) ...[
                              const SizedBox(width: 80),
                              Expanded(
                                flex: 1,
                                child: Container(
                                  height: 400,
                                  decoration: BoxDecoration(
                                    image: const DecorationImage(
                                      image: NetworkImage(
                                          'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?q=80&w=2940&auto=format&fit=crop'),
                                      fit: BoxFit.cover,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // FAQ Section
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                              color: const Color(0xFFF4F6F8),
                              child: RichText(
                                text: const TextSpan(
                                  style: TextStyle(
                                    fontFamily: AppThemeTokens.fontFamily,
                                    fontSize: 32,
                                    color: Color(0xFF4A5568),
                                    fontWeight: FontWeight.w300,
                                    height: 1.2,
                                  ),
                                  children: [
                                    TextSpan(text: 'Frequently asked '),
                                    TextSpan(text: 'questions', style: TextStyle(color: jpmcLightBrown)),
                                  ],
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                              child: Column(
                                children: [
                                  _faqItem('What is J.P. Morgan Innovation Economy Banking?'),
                                  _faqItem('How does J.P. Morgan support innovation companies globally?'),
                                  _faqItem('Does J.P. Morgan work with early-stage companies?'),
                                  _faqItem('How is J.P. Morgan different from other banks that work with startups?'),
                                  _faqItem('What startup bank accounts do I need to run my business?'),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 80),
                                color: const Color(0xFFF4F6F8),
                                child: RichText(
                                  text: const TextSpan(
                                    style: TextStyle(
                                      fontFamily: AppThemeTokens.fontFamily,
                                      fontSize: 42,
                                      color: Color(0xFF4A5568),
                                      fontWeight: FontWeight.w300,
                                      height: 1.2,
                                    ),
                                    children: [
                                      TextSpan(text: 'Frequently asked\n'),
                                      TextSpan(text: 'questions', style: TextStyle(color: jpmcLightBrown)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 7,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 80),
                                child: Column(
                                  children: [
                                    _faqItem('What is J.P. Morgan Innovation Economy Banking?'),
                                    _faqItem('How does J.P. Morgan support innovation companies globally?'),
                                    _faqItem('Does J.P. Morgan work with early-stage companies?'),
                                    _faqItem('How is J.P. Morgan different from other banks that work with startups?'),
                                    _faqItem('What startup bank accounts do I need to run my business?'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              // LaunchPad CTA Band
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 48 : 80, horizontal: isMobile ? 24 : 40),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [lpIndigo, lpIndigoDk],
                    ),
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: SizedBox(
                        width: double.infinity,
                        child: isMobile || isTablet
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.13),
                                      border: Border.all(color: Colors.white.withOpacity(0.22)),
                                      borderRadius: BorderRadius.circular(100),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle)),
                                        const SizedBox(width: 8),
                                        Text('NEW · PARTNER PROGRAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), letterSpacing: 1.2))
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text('Meet Prospectz.ai — your startup intelligence partner', style: TextStyle(fontSize: isMobile ? 28 : 40, color: Colors.white, height: 1.18)),
                                  const SizedBox(height: 18),
                                  Text(_b('We\'ve partnered with Prospectz.ai to give J.P. Morgan startup clients access to a personalised AI advisor that understands your business and maps your needs to exactly the right financial products — no forms, no waiting.'), style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.72), height: 1.68)),
                                  const SizedBox(height: 28),
                                  _lpBullet('Voice + text AI that adapts to your startup\'s stage and goals'),
                                  _lpBullet('Instant matching to relevant J.P. Morgan products and services'),
                                  _lpBullet('Direct handoff to a J.P. Morgan advisor when you\'re ready to move forward'),
                                  _lpBullet('Private learn hub: webinars, 1:1 sessions, and personalised resources'),
                                  const SizedBox(height: 32),
                                  Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 10,
                                    runSpacing: 10,
                                    children: [
                                      Text('POWERED BY', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), letterSpacing: 0.8)),
                                      _lpChip('Prospectz.ai'),
                                      Text('×', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.2))),
                                      _lpChip('J.P. Morgan'),
                                    ],
                                  ),
                                  const SizedBox(height: 48),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(0),
                                    child: Column(
                                      children: [
                                        ElevatedButton(
                                          onPressed: _startSession,
                                          style: Theme.of(context)
                                              .elevatedButtonTheme
                                              .style
                                              ?.copyWith(
                                                padding: WidgetStateProperty.all(
                                                  const EdgeInsets.symmetric(
                                                      vertical: 17,
                                                      horizontal: 32),
                                                ),
                                                shape: WidgetStateProperty.all(
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                ),
                                                elevation:
                                                    WidgetStateProperty.all(10),
                                                minimumSize:
                                                    WidgetStateProperty.all(
                                                  const Size(double.infinity, 50),
                                                ),
                                              ),
                                          child: const Text('Get Started with Prospectz.ai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(_b('Free for J.P. Morgan startup clients'), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                                        const SizedBox(height: 20),
                                        Text(_b('You\'ll be redirected to Prospectz.ai with your J.P. Morgan partnership credentials pre-applied.'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35), height: 1.5)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.13),
                                            border: Border.all(color: Colors.white.withOpacity(0.22)),
                                            borderRadius: BorderRadius.circular(100),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF86EFAC), shape: BoxShape.circle)),
                                              const SizedBox(width: 8),
                                              Text('NEW · PARTNER PROGRAM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9), letterSpacing: 1.2))
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 22),
                                        Text('Meet Prospectz.ai — your startup intelligence partner', style: TextStyle(fontSize: 40, color: Colors.white, height: 1.18)),
                                        const SizedBox(height: 18),
                                        Text(_b('We\'ve partnered with Prospectz.ai to give J.P. Morgan startup clients access to a personalised AI advisor that understands your business and maps your needs to exactly the right financial products — no forms, no waiting.'), style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.72), height: 1.68)),
                                        const SizedBox(height: 28),
                                        _lpBullet('Voice + text AI that adapts to your startup\'s stage and goals'),
                                        _lpBullet('Instant matching to relevant J.P. Morgan products and services'),
                                        _lpBullet('Direct handoff to a J.P. Morgan advisor when you\'re ready to move forward'),
                                        _lpBullet('Private learn hub: webinars, 1:1 sessions, and personalised resources'),
                                        const SizedBox(height: 32),
                                        Wrap(
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 10,
                                          runSpacing: 10,
                                          children: [
                                            Text('POWERED BY', style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.4), letterSpacing: 0.8)),
                                            _lpChip('Prospectz.ai'),
                                            Text('×', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.2))),
                                            _lpChip('J.P. Morgan'),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 64),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        children: [
                                          ElevatedButton(
                                            onPressed: _startSession,
                                            style: Theme.of(context)
                                                .elevatedButtonTheme
                                                .style
                                                ?.copyWith(
                                                  padding: WidgetStateProperty.all(
                                                    const EdgeInsets.symmetric(
                                                        vertical: 17,
                                                        horizontal: 32),
                                                  ),
                                                  shape: WidgetStateProperty.all(
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                    ),
                                                  ),
                                                  elevation:
                                                      WidgetStateProperty.all(10),
                                                  minimumSize:
                                                      WidgetStateProperty.all(
                                                    const Size(double.infinity, 50),
                                                  ),
                                                ),
                                            child: const Text('Get Started with Prospectz.ai', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                          ),
                                          const SizedBox(height: 12),
                                           Text(_b('Free for J.P. Morgan startup clients'), style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.45))),
                                           const SizedBox(height: 20),
                                           Text(_b('You\'ll be redirected to Prospectz.ai with your J.P. Morgan partnership credentials pre-applied.'), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.35), height: 1.5)),
                                        ],
                                      ),
                                    ),
                                  )
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ),

              // Footer (White)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(top: 80, bottom: 40, left: isMobile ? 24 : 80, right: isMobile ? 24 : 80),
                  child: Column(
                    children: [
                      if (isMobile)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _footerLightCol('SOLUTIONS', [
                              'Asset Management',
                              'Commercial Banking',
                              'Credit and Financing',
                              'Investment Banking',
                              'Markets',
                              'Payments',
                              'Prime Services',
                              'Private Banking',
                              'Securities Services',
                              'Wealth Management',
                            ]),
                            const SizedBox(height: 32),
                            _footerLightCol('CAREERS', []),
                            const SizedBox(height: 32),
                            _footerLightCol('HELPFUL LINKS', [
                              'About Us', 'Apps', 'Events and Conferences', 'Impact',
                              'Industries', 'Insights', 'Investor Relations', 'Media Center',
                              'News and Announcements', 'Newsletters'
                            ]),
                            const SizedBox(height: 32),
                            _footerLightCol('JPMORGANCHASE SITES', [
                              'Chase', 'JPMorganChase', 'Payments Partner Network'
                            ]),
                            const SizedBox(height: 32),
                            _footerLightCol('CONNECT WITH US', [
                              'Alumni Network', 'Client Login', 'Contact Us'
                            ]),
                            const SizedBox(height: 48),
                            InkWell(
                              onTap: () {
                                Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                                context.go('/');
                              },
                              child: Text(
                                _b('J.P.Morgan'),
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: jpmcBrown,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                _socialIcon('https://cdn-icons-png.flaticon.com/512/3536/3536505.png'),
                                _socialIcon('https://cdn-icons-png.flaticon.com/512/5969/5969020.png'),
                                _socialIcon('https://cdn-icons-png.flaticon.com/512/145/145802.png'),
                                _socialIcon('https://cdn-icons-png.flaticon.com/512/2111/2111463.png'),
                                _socialIcon('https://cdn-icons-png.flaticon.com/512/1384/1384060.png'),
                              ],
                            ),
                          ],
                        )
                      else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _footerLightCol('SOLUTIONS', [
                                'Asset Management',
                                'Commercial Banking',
                                'Credit and Financing',
                                'Investment Banking',
                                'Markets',
                                'Payments',
                                'Prime Services',
                                'Private Banking',
                                'Securities Services',
                                'Wealth Management',
                              ]),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _footerLightCol('CAREERS', []),
                                  const SizedBox(height: 32),
                                  _footerLightCol('HELPFUL LINKS', [
                                    'About Us', 'Apps', 'Events and Conferences', 'Impact',
                                    'Industries', 'Insights', 'Investor Relations', 'Media Center',
                                    'News and Announcements', 'Newsletters'
                                  ]),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _footerLightCol('JPMORGANCHASE SITES', [
                                    'Chase', 'JPMorganChase', 'Payments Partner Network'
                                  ]),
                                  const SizedBox(height: 32),
                                  _footerLightCol('CONNECT WITH US', [
                                    'Alumni Network', 'Client Login', 'Contact Us'
                                  ]),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);
                                      context.go('/');
                                    },
                                    child: Text(
                                      _b('J.P.Morgan'),
                                      style: const TextStyle(
                                        fontSize: 32,
                                        color: jpmcBrown,
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  Row(
                                    children: [
                                      _socialIcon('https://cdn-icons-png.flaticon.com/512/3536/3536505.png'),
                                      _socialIcon('https://cdn-icons-png.flaticon.com/512/5969/5969020.png'),
                                      _socialIcon('https://cdn-icons-png.flaticon.com/512/145/145802.png'),
                                      _socialIcon('https://cdn-icons-png.flaticon.com/512/2111/2111463.png'),
                                      _socialIcon('https://cdn-icons-png.flaticon.com/512/1384/1384060.png'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 100),
                      Flex(
                        direction: isMobile ? Axis.vertical : Axis.horizontal,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Privacy', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              Text('|', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                              Text('Terms of Use', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              Text('|', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                              Text('Accessibility', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              Text('|', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                              Text('Cookies Policy', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              Text('|', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                              Text('Regulatory Disclosures', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            ],
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: isMobile ? 24 : 0),
                            child: Text(
                              _b('© 2026 JPMorgan Chase & Co.\nAll rights reserved.'),
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
                              textAlign: isMobile ? TextAlign.left : TextAlign.right,
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

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _topNavDropdown(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _topUtilityLink(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF9E3A30),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _bottomBarItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 48),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String number, Color color, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w400,
            color: color,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: Color(0xFF4A5568),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _solutionCardCol({
    required Color color,
    required String iconUrl,
    required String title,
    required List<String> points,
  }) {
    return Container(
      width: 320,
      height: 480, // Fixed height to align them nicely
      margin: const EdgeInsets.only(right: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(iconUrl, width: 48, height: 48, color: color),
          const SizedBox(height: 40),
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              color: color,
              fontWeight: FontWeight.w400,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 32),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8, right: 12),
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade500, shape: BoxShape.circle),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        p,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _stageTab(BuildContext context, String text, {bool isActive = false}) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 24, horizontal: isMobile ? 12 : 48),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isActive ? AppThemeTokens.goldAccent : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppThemeTokens.fontFamily,
          fontSize: isMobile ? 12 : 14,
          color: isActive
              ? AppThemeTokens.goldAccent
              : Colors.white.withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _lpBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✓', style: TextStyle(color: Color(0xFF86EFAC), fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(_b(text), style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.82))))
        ],
      )
    );
  }

  Widget _lpChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white.withOpacity(0.2)), borderRadius: BorderRadius.circular(4)),
      child: Text(_b(text), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.7))),
    );
  }

  Widget _footerCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_b(title), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white.withOpacity(0.38))),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Text(_b(link), style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.58))),
        )),
      ]
    );
  }

  Widget _faqItem(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              _b(text),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const Icon(Icons.add, color: AppThemeTokens.buttonPrimary, size: 20),
        ],
      ),
    );
  }

  Widget _footerLightCol(String title, List<String> links) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_b(title), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5, color: Color(0xFF4A5568))),
        const SizedBox(height: 16),
        ...links.map((link) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(_b(link), style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
        )),
      ]
    );
  }

  Widget _socialIcon(String url) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Image.network(url, width: 20, height: 20, color: Colors.grey.shade800),
    );
  }
}
