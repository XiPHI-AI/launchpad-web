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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 28),
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
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: AppThemeTokens.fontFamily,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  children: [
                    TextSpan(text: 'JPMorgan '),
                    TextSpan(
                      text: 'Innovation Economy',
                      style: TextStyle(color: AppThemeTokens.goldAccent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),
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
          const Spacer(),
          const NavbarNotificationIcon(),
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
