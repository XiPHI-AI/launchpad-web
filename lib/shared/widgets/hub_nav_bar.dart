import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'notification_icon.dart';
import 'prospect_id_provider.dart';

class HubNavBar extends StatelessWidget {
  final String companyName;
  final String founderName;
  final String initials;
  final VoidCallback? onProfileTap;
  final VoidCallback? onInteractionsTap;
  final VoidCallback? onClose;
  final VoidCallback? onLogout;
  final String activeLabel;
  final bool isHubEnabled;
  final bool isBankerView;

  const HubNavBar({
    super.key,
    required this.companyName,
    required this.founderName,
    required this.initials,
    this.onProfileTap,
    this.onInteractionsTap,
    this.onClose,
    this.onLogout,
    this.activeLabel = 'Hub',
    this.isHubEnabled = false,
    this.isBankerView = false,
  });

  void _showStartFreshDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 400,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.22),
                  blurRadius: 36,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: const BoxDecoration(
                    color: AppThemeTokens.modalHeader,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(11),
                          border: Border.all(color: Colors.white.withOpacity(0.18)),
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: AppThemeTokens.goldAccent,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Start Fresh?',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Are you sure you want to start fresh? This will clear your current session and all saved progress.",
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF374151),
                                side: const BorderSide(
                                  color: Color(0xFFD1D5DB),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                onLogout?.call();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[700],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'YES, START FRESH',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
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
      ),
    );
  }

  void _showMobileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemeTokens.modalHeader,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Navigation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(sheetContext),
                    ),
                  ],
                ),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                _mobileMenuLink(
                  context,
                  label: 'Home',
                  active: activeLabel == 'Home' || activeLabel == 'Dashboard',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    context.go('/');
                  },
                ),
                const SizedBox(height: 8),
                _mobileMenuLink(
                  context,
                  label: 'Relationship Hub',
                  active: activeLabel == 'Relationship Hub',
                  enabled: isHubEnabled,
                  onTap: isHubEnabled ? () {
                    Navigator.pop(sheetContext);
                    final pid = ProspectIdProvider.of(context);
                    if (pid != null) {
                      context.go('/relationship-hub?p=$pid');
                    } else {
                      context.go('/relationship-hub');
                    }
                  } : null,
                ),
                const SizedBox(height: 8),
                _mobileMenuLink(
                  context,
                  label: 'Nova',
                  active: activeLabel == 'Nova' || activeLabel == 'Nova' || activeLabel == 'Interactions',
                  onTap: onInteractionsTap != null ? () {
                    Navigator.pop(sheetContext);
                    onInteractionsTap!();
                  } : null,
                ),
                const SizedBox(height: 8),
                _mobileMenuLink(
                  context,
                  label: isBankerView ? 'Switch to Prospect View' : 'Switch to Banker View',
                  active: false,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (isBankerView) {
                      final pid = ProspectIdProvider.of(context);
                      if (pid != null) {
                        context.go('/relationship-hub?p=$pid');
                      } else {
                        context.go('/');
                      }
                    } else {
                      context.go('/banker');
                    }
                  },
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223A56),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFB99C4C), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppThemeTokens.goldAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            founderName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            companyName.isNotEmpty && companyName != 'Launchpad'
                                ? companyName
                                : 'Launchpad Guest',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (onProfileTap != null)
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppThemeTokens.goldAccent),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          onProfileTap!();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (onLogout != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            _showStartFreshDialog(context);
                          },
                          icon: const Icon(Icons.logout_rounded, size: 16),
                          label: const Text('START FRESH'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red[300],
                            side: BorderSide(color: Colors.red.withOpacity(0.4)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    if (onLogout != null && onClose != null) const SizedBox(width: 12),
                    if (onClose != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(sheetContext);
                            onClose!();
                          },
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('CLOSE'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _mobileMenuLink(
    BuildContext context, {
    required String label,
    required bool active,
    bool enabled = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF28486C) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active
                    ? Colors.white
                    : (enabled ? const Color(0xFFB6C2D2) : const Color(0xFF5A6B80)),
                fontSize: 15,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            if (active)
              const Icon(Icons.check_circle_outline, color: AppThemeTokens.goldAccent, size: 18)
            else if (!enabled)
              const Icon(Icons.lock_outline, color: Color(0xFF5A6B80), size: 18)
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.white30, size: 18),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 900;

    return Container(
      height: 74,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
      color: AppThemeTokens.modalHeader,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              final pid = ProspectIdProvider.of(context);
              if (pid != null) {
                context.go('/?p=$pid');
              } else {
                context.go('/');
              }
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: AppThemeTokens.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: [
                    const TextSpan(text: 'JPMorgan '),
                    const TextSpan(
                      text: 'Innovation Economy',
                      style: TextStyle(color: AppThemeTokens.goldAccent),
                    ),
                    if (isBankerView)
                      const TextSpan(
                        text: '  ·  Banker view',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF8D8578),
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
          if (!isMobile) ...[
            if (isBankerView) ...[
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C).withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFFC9A84C).withOpacity(0.25)),
                ),
                child: const Text(
                  'Innovation Banking',
                  style: TextStyle(
                    color: AppThemeTokens.goldAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                children: [
                  NavPill(
                    label: 'Home',
                    active: activeLabel == 'Home' || activeLabel == 'Dashboard',
                    onTap: () => context.go('/'),
                  ),
                  NavPill(
                    label: 'Relationship Hub',
                    active: activeLabel == 'Relationship Hub',
                    enabled: isHubEnabled,
                    onTap: isHubEnabled ? () {
                      final pid = ProspectIdProvider.of(context);
                      if (pid != null) {
                        context.go('/relationship-hub?p=$pid');
                      } else {
                        context.go('/relationship-hub');
                      }
                    } : null,
                  ),
                  NavPill(
                    label: 'Nova',
                    active: activeLabel == 'Nova' || activeLabel == 'Nova' || activeLabel == 'Interactions',
                    onTap: onInteractionsTap,
                  ),
                ],
              ),
            ],
            const Spacer(),
            const NavbarNotificationIcon(),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(
                isBankerView ? Icons.swap_horiz_rounded : Icons.admin_panel_settings_rounded,
                color: isBankerView ? AppThemeTokens.goldAccent : Colors.white70,
                size: 22,
              ),
              tooltip: isBankerView ? 'Switch to Prospect View' : 'Switch to Banker View',
              onPressed: () {
                if (isBankerView) {
                  final pid = ProspectIdProvider.of(context);
                  if (pid != null) {
                    context.go('/relationship-hub?p=$pid');
                  } else {
                    context.go('/');
                  }
                } else {
                  context.go('/banker');
                }
              },
            ),
            const SizedBox(width: 16),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onProfileTap,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF223A56),
                        borderRadius: BorderRadius.circular(999),
                        border:
                            Border.all(color: const Color(0xFFB99C4C), width: 1),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppThemeTokens.goldAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      companyName.isNotEmpty && companyName != 'Launchpad'
                          ? companyName
                          : founderName.split(' ').first,
                      style: const TextStyle(
                        color: Color(0xFFE2E8F0),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onLogout != null) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => _showStartFreshDialog(context),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.logout_rounded, color: Colors.white, size: 16),
                  ),
                ),
              ),
            ],
            if (onClose != null) ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onClose,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ] else ...[
            IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
              onPressed: () => _showMobileMenu(context),
            ),
          ],
        ],
      ),
    );
  }
}

class NavPill extends StatelessWidget {
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback? onTap;

  const NavPill({
    super.key,
    required this.label,
    this.active = false,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFF28486C) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active 
                  ? Colors.white 
                  : (enabled ? const Color(0xFFB6C2D2) : const Color(0xFF5A6B80)),
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
