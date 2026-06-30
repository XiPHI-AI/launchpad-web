import 'package:flutter/material.dart';

class NotificationDetail {
  /// Optional header label shown above the modal title (e.g. "NEXT MEETING · MAY 6 · 2:00 PM ET")
  final String? headerLabel;

  /// Sections shown in the detail modal
  final List<NotificationDetailSection> sections;

  const NotificationDetail({
    this.headerLabel,
    required this.sections,
  });
}

class NotificationDetailSection {
  final IconData? icon;
  final String title;
  final List<String> bullets;

  const NotificationDetailSection({
    this.icon,
    required this.title,
    required this.bullets,
  });
}

class NotificationItem {
  final String title;
  final String message;
  final String footer;
  final String time;
  final IconData icon;
  final Color iconColor;
  final Color bg;
  final bool isPriority;

  /// Which slot (0, 1, 2) this notification belongs to.
  /// Slot maps to the prospect at that index in the active banker's prospects list.
  /// Defaults to 0.
  final int prospectSlot;

  /// Optional rich detail shown in the modal when the card is tapped
  final NotificationDetail? detail;

  NotificationItem({
    required this.title,
    this.message = '',
    this.footer = '',
    required this.time,
    required this.icon,
    required this.iconColor,
    required this.bg,
    this.isPriority = false,
    this.prospectSlot = 0,
    this.detail,
  });
}

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _activeHubNotifications = [
    // Slot 0 (Aster Labs, Jumbo / Co1)
    NotificationItem(
      title: 'Meeting confirmed',
      message: 'Intro call with Sarah on May 6 at 2:00 PM ET. Tap to prep.',
      footer: 'Apr 28 · Click to prepare',
      time: 'Apr 28',
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF7C5410),
      bg: const Color(0xFFFBEAD5),
      isPriority: true,
      prospectSlot: 0,
      detail: NotificationDetail(
        headerLabel: 'NEXT MEETING · MAY 6 · 2:00 PM ET',
        sections: const [
          NotificationDetailSection(
            icon: Icons.person_outline_rounded,
            title: 'What Sarah already knows about you',
            bullets: [
              'Seed-stage company, recent funding round, lean team of under 10',
              'Growth posture: capital efficiency — not aggressive expansion mode',
              'Priority areas flagged: treasury setup, operating account structure, banking foundation',
              'Uploaded materials: investor deck (reviewed) and product one-pager (pending)',
            ],
          ),
          NotificationDetailSection(
            icon: Icons.help_outline_rounded,
            title: 'Questions to ask Sarah',
            bullets: [
              'What account structure do you recommend for a seed-stage company at our balance size?',
              'Do you offer sweep accounts that move idle cash overnight — and what\'s the current yield?',
              'How does FDIC coverage work for balances over \$250K — what are our options?',
              'When should we start thinking about a credit facility, and what would that process look like?',
              'What would a deeper banking relationship unlock for us at our current stage?',
            ],
          ),
        ],
      ),
    ),
    NotificationItem(
      title: 'Call summary available',
      message: 'Apr 29 call with Sarah. Topics, next steps, and new material added.',
      footer: 'Apr 29 · Click to view',
      time: 'Apr 29',
      icon: Icons.call_outlined,
      iconColor: const Color(0xFF0F6E56),
      bg: const Color(0xFFE1F5EE),
      isPriority: true,
      prospectSlot: 0,
      detail: NotificationDetail(
        headerLabel: 'CALL SUMMARY · APR 29',
        sections: const [
          NotificationDetailSection(
            icon: Icons.summarize_outlined,
            title: 'Key topics discussed',
            bullets: [
              'Treasury setup and operating account structure for seed-stage companies',
              'FDIC coverage for balances above \$250K and sweep account options',
              'Credit facility timelines and what qualifies at Series A',
            ],
          ),
          NotificationDetailSection(
            icon: Icons.next_plan_outlined,
            title: 'Next steps agreed',
            bullets: [
              'Sarah will send a comparison of sweep account options by May 3',
              'You will upload 18-month cash projection before the next call',
              'Follow-up call scheduled for May 13 to review account setup options',
            ],
          ),
        ],
      ),
    ),
    NotificationItem(
      title: 'New guide added by Sarah',
      message: 'Preparing for your first credit facility, based on your call.',
      footer: 'Apr 29 · In your learning path',
      time: 'Apr 29',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF5B55D9),
      bg: const Color(0xFFEEEDFE),
      isPriority: true,
      prospectSlot: 0,
      detail: NotificationDetail(
        headerLabel: 'NEW GUIDE · ADDED BY SARAH',
        sections: const [
          NotificationDetailSection(
            icon: Icons.info_outline_rounded,
            title: 'About this guide',
            bullets: [
              'Title: Preparing for your first credit facility',
              '10 min read · Series A · Capital structure',
              'Added by Sarah Chen based on your Apr 29 call conversation',
            ],
          ),
        ],
      ),
    ),

    // Slot 1 (Vancouver / 123's)
    NotificationItem(
      title: 'Meeting confirmed',
      message: 'Intro call with Sarah on June 15 at 10:30 AM ET. Tap to prep.',
      footer: 'June 10 · Click to prepare',
      time: 'June 10',
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF7C5410),
      bg: const Color(0xFFFBEAD5),
      isPriority: true,
      prospectSlot: 1,
      detail: NotificationDetail(
        headerLabel: 'NEXT MEETING · JUNE 15 · 10:30 AM ET',
        sections: const [
          NotificationDetailSection(
            icon: Icons.person_outline_rounded,
            title: 'What Sarah already knows about you',
            bullets: [
              'Growth-stage posture, key expansion metrics, team of over 20',
              'Seeking credit line options to leverage recent Series A funding round',
              'Priority areas flagged: sweep account setup, risk management, operating accounts',
            ],
          ),
          NotificationDetailSection(
            icon: Icons.help_outline_rounded,
            title: 'Questions to ask Sarah',
            bullets: [
              'What credit facility terms can we negotiate based on our Series A balance?',
              'How long does the approval process take for an enterprise revolving credit line?',
            ],
          ),
        ],
      ),
    ),
    NotificationItem(
      title: 'Call summary available',
      message: 'June 8 call with Sarah. Topics, next steps, and new material added.',
      footer: 'June 8 · Click to view',
      time: 'June 8',
      icon: Icons.call_outlined,
      iconColor: const Color(0xFF0F6E56),
      bg: const Color(0xFFE1F5EE),
      isPriority: true,
      prospectSlot: 1,
      detail: NotificationDetail(
        headerLabel: 'CALL SUMMARY · JUNE 8',
        sections: const [
          NotificationDetailSection(
            icon: Icons.summarize_outlined,
            title: 'Key topics discussed',
            bullets: [
              'Enterprise treasury architecture and investment sweep account yields',
              'Credit facility limits and baseline covenant requirements',
            ],
          ),
          NotificationDetailSection(
            icon: Icons.next_plan_outlined,
            title: 'Next steps agreed',
            bullets: [
              'Sarah will connect you with the lending director by June 12',
              'You will upload your updated Q2 balance sheet by end of week',
            ],
          ),
        ],
      ),
    ),
    NotificationItem(
      title: 'New guide added by Sarah',
      message: 'Preparing for your first credit facility, based on your call.',
      footer: 'June 9 · In your learning path',
      time: 'June 9',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF5B55D9),
      bg: const Color(0xFFEEEDFE),
      isPriority: true,
      prospectSlot: 1,
      detail: NotificationDetail(
        headerLabel: 'NEW GUIDE · ADDED BY SARAH',
        sections: const [
          NotificationDetailSection(
            icon: Icons.info_outline_rounded,
            title: 'About this guide',
            bullets: [
              'Title: Preparing for your first credit facility',
              '10 min read · Series A · Capital structure',
              'Added by Sarah Chen based on your June 8 call conversation',
            ],
          ),
        ],
      ),
    ),

    // Slot 2 (Meridian Health / Gil.inc)
    NotificationItem(
      title: 'Meeting confirmed',
      message: 'Intro call with Sarah on July 22 at 4:15 PM ET. Tap to prep.',
      footer: 'July 18 · Click to prepare',
      time: 'July 18',
      icon: Icons.calendar_today_rounded,
      iconColor: const Color(0xFF7C5410),
      bg: const Color(0xFFFBEAD5),
      isPriority: true,
      prospectSlot: 2,
      detail: NotificationDetail(
        headerLabel: 'NEXT MEETING · JULY 22 · 4:15 PM ET',
        sections: const [
          NotificationDetailSection(
            icon: Icons.person_outline_rounded,
            title: 'What Sarah already knows about you',
            bullets: [
              'Early-stage climate-tech venture, focused on scalable hardware solutions',
              'Current banking needs: domestic operational setup and international vendor payments',
            ],
          ),
          NotificationDetailSection(
            icon: Icons.help_outline_rounded,
            title: 'Questions to ask Sarah',
            bullets: [
              'Do you support multi-currency business accounts for overseas supplier bills?',
              'What FX fees apply to high-volume cross-border wire transfers?',
            ],
          ),
        ],
      ),
    ),
    NotificationItem(
      title: 'Call summary available',
      message: 'July 14 call with Sarah. Topics, next steps, and new material added.',
      footer: 'July 14 · Click to view',
      time: 'July 14',
      icon: Icons.call_outlined,
      iconColor: const Color(0xFF0F6E56),
      bg: const Color(0xFFE1F5EE),
      isPriority: true,
      prospectSlot: 2,
      detail: NotificationDetail(
        headerLabel: 'CALL SUMMARY · JULY 14',
        sections: const [
          NotificationDetailSection(
            icon: Icons.summarize_outlined,
            title: 'Key topics discussed',
            bullets: [
              'International wire setups, foreign exchange services, and risk mitigation',
            ],
          ),
          NotificationDetailSection(
            icon: Icons.next_plan_outlined,
            title: 'Next steps agreed',
            bullets: [
              'Sarah to send international wire processing checklists by July 16',
              'You to provide lists of target supplier countries and currencies',
            ],
          ),
        ],
      ),
    ),
    NotificationItem(
      title: 'New guide added by Sarah',
      message: 'Preparing for your first credit facility, based on your call.',
      footer: 'July 15 · In your learning path',
      time: 'July 15',
      icon: Icons.description_outlined,
      iconColor: const Color(0xFF5B55D9),
      bg: const Color(0xFFEEEDFE),
      isPriority: true,
      prospectSlot: 2,
      detail: NotificationDetail(
        headerLabel: 'NEW GUIDE · ADDED BY SARAH',
        sections: const [
          NotificationDetailSection(
            icon: Icons.info_outline_rounded,
            title: 'About this guide',
            bullets: [
              'Title: Preparing for your first credit facility',
              '10 min read · Series A · Capital structure',
              'Added by Sarah Chen based on your July 14 call conversation',
            ],
          ),
        ],
      ),
    ),
  ];

  final List<NotificationItem> _dropdownHistory = [
    NotificationItem(
      title: 'Sarah reviewed your guide',
      time: '2 hours ago',
      icon: Icons.description_outlined,
      bg: const Color(0xFFEEEDFE),
      iconColor: const Color(0xFF5B55D9),
    ),
    NotificationItem(
      title: 'New message from Nova',
      time: '5 hours ago',
      icon: Icons.message_outlined,
      bg: const Color(0xFFE1F5EE),
      iconColor: const Color(0xFF0F6E56),
    ),
    NotificationItem(
      title: 'Upcoming meeting: Q3 Review',
      time: '1 day ago',
      icon: Icons.calendar_today_rounded,
      bg: const Color(0xFFFBEAD5),
      iconColor: const Color(0xFF7C5410),
    ),
  ];

  List<NotificationItem> get activeHubNotifications => _activeHubNotifications;
  List<NotificationItem> get dropdownHistory => _dropdownHistory;

  void markAsRead(int index) {
    if (index >= 0 && index < _activeHubNotifications.length) {
      final item = _activeHubNotifications.removeAt(index);
      // Add to history at the top, keep priority flag but update time
      _dropdownHistory.insert(0, NotificationItem(
        title: item.title,
        time: 'Just now',
        icon: item.icon,
        iconColor: item.iconColor,
        bg: item.bg,
        isPriority: true, // Keep it highlighted as it was a hub notification
      ));
      notifyListeners();
    }
  }

  void markAllAsRead() {
    final items = List<NotificationItem>.from(_activeHubNotifications);
    _activeHubNotifications.clear();
    for (final item in items) {
      _dropdownHistory.insert(0, NotificationItem(
        title: item.title,
        time: 'Just now',
        icon: item.icon,
        iconColor: item.iconColor,
        bg: item.bg,
        isPriority: true,
      ));
    }
    notifyListeners();
  }

  void clearHistory() {
    _activeHubNotifications.clear();
    _dropdownHistory.clear();
    notifyListeners();
  }
}
