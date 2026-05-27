import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DemoBanner extends StatelessWidget {
  final bool dismissible;
  final VoidCallback? onDismiss;

  const DemoBanner({
    super.key,
    this.dismissible = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final text =
        '🔵 Demo mockup — Prospectz.ai simulation${isMobile ? '' : ' of the J.P. Morgan startups page by Intelligence Labz'}';

    return Material(
      color: AppThemeTokens.demoBannerBg,
      child: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppThemeTokens.demoBannerBorder,
              width: 1,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: AppThemeTokens.demoBannerVerticalPadding,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(right: dismissible ? 28 : 0),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppThemeTokens.demoBannerText,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (dismissible)
              Positioned(
                right: 0,
                child: InkWell(
                  onTap: onDismiss,
                  borderRadius: BorderRadius.circular(12),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: AppThemeTokens.demoBannerText,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}