import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../../shared/widgets/hub_nav_bar.dart';
import '../../services/prospect_storage.dart';
import '../../services/conversation_service.dart';
import '../../services/notification_service.dart';
import '../relationship_hub/relationship_hub_page.dart';
import '../../core/branding/branding_provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'datascience_analytics_views.dart';

// --- COLOR PALETTE FROM HTML ---
class BankerColors {
  static const Color navy = Color(0xFF04213D);
  static const Color navy2 = Color(0xFF06325E);
  static const Color blue = Color(0xFF0A4A8A);
  static const Color gold = Color(0xFFC9A84C);
  static const Color goldLight = Color(0xFFE8CC7A);
  static const Color cream = Color(0xFFFAF7F0);
  static const Color ink = Color(0xFF1A1A18);
  static const Color muted = Color(0xFF6F675B);
  static const Color muted2 = Color(0xFF8D8578);
  static const Color green = Color(0xFF1D9E75);
  static const Color greenSoft = Color(0xFFE1F5EE);
  static const Color blueSoft = Color(0xFFE6F1FB);
  static const Color amberSoft = Color(0xFFFAEEDA);
  static const Color purpleSoft = Color(0xFFEEEDFE);
  static const Color redSoft = Color(0xFFFEE2E2);
  static const Color line = Color(0x14000000); // rgba(0,0,0,0.08)
  static const Color line2 = Color(0x21000000); // rgba(0,0,0,0.13)
}

// --- DATA MODELS ---
class CrmDoc {
  final String name;
  String status; // 'Received', 'Needs review', 'Not uploaded'

  CrmDoc({required this.name, required this.status});

  CrmDoc copyWith({String? name, String? status}) {
    return CrmDoc(
      name: name ?? this.name,
      status: status ?? this.status,
    );
  }
}

class CrmEdu {
  final String title;
  final String tag;
  final Color stripeColor;
  final String status;

  CrmEdu({
    required this.title,
    required this.tag,
    required this.stripeColor,
    required this.status,
  });

  CrmEdu copyWith({
    String? title,
    String? tag,
    Color? stripeColor,
    String? status,
  }) {
    return CrmEdu(
      title: title ?? this.title,
      tag: tag ?? this.tag,
      stripeColor: stripeColor ?? this.stripeColor,
      status: status ?? this.status,
    );
  }
}

class CrmActivity {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String text;
  final String time;

  CrmActivity({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.text,
    required this.time,
  });

  CrmActivity copyWith({
    IconData? icon,
    Color? iconBg,
    Color? iconColor,
    String? text,
    String? time,
  }) {
    return CrmActivity(
      icon: icon ?? this.icon,
      iconBg: iconBg ?? this.iconBg,
      iconColor: iconColor ?? this.iconColor,
      text: text ?? this.text,
      time: time ?? this.time,
    );
  }
}

const Map<int, IconData> _crmActivityIconByCodePoint = {
  0xf62f: Icons.chat_bubble_outline_rounded,
  0xf12d: Icons.insert_drive_file_outlined,
  0xf51a: Icons.access_time_rounded,
  0xf28c: Icons.phone_in_talk_outlined,
  0xf0167: Icons.settings_voice_rounded,
  0xf06a4: Icons.handshake_outlined,
  0xf5fe: Icons.calendar_today_rounded,
  0xf026a: Icons.upload_file_rounded,
  0xf634: Icons.check_circle_outline_rounded,
  0xf817: Icons.input_rounded,
  0xf63e: Icons.chrome_reader_mode_rounded,
  0xef51: Icons.chrome_reader_mode_outlined,
  0xf006a: Icons.person_add_rounded,
};

IconData _crmActivityIconFromSnapshot(Map activity) {
  final codePoint =
      activity['codePoint'] as int? ?? Icons.chat_bubble_outline_rounded.codePoint;
  return _crmActivityIconByCodePoint[codePoint] ??
      Icons.chat_bubble_outline_rounded;
}

class CrmProspect {
  final String id;
  final String name;
  final String email;
  final String sector;
  final String stage;
  final String status;
  final double profileProgress;
  final String docsReceivedText;
  final int docsReceivedCount;
  final int docsTotalCount;
  final String materialsReadText;
  final String materialsReadSub;
  final String lastActive;
  final String avatarText;
  final Color avatarBg;
  final Color avatarFg;
  final String? bankerId;
  final String founderName;
  final String stageBucket;
  final String phoneNumber;
  final String headcount;
  final bool incorporated;
  final List<String> priorities;
  
  final List<CrmDoc> docs;
  final List<CrmEdu> education;
  final List<CrmActivity> activity;
  final String notes;

  final String? leadTemperature;
  final double? conversionProbability;
  final String? salesPriority;

  CrmProspect({
    required this.id,
    required this.name,
    required this.email,
    required this.sector,
    required this.stage,
    required this.status,
    required this.profileProgress,
    required this.docsReceivedText,
    required this.docsReceivedCount,
    required this.docsTotalCount,
    required this.materialsReadText,
    required this.materialsReadSub,
    required this.lastActive,
    required this.avatarText,
    required this.avatarBg,
    required this.avatarFg,
    required this.docs,
    required this.education,
    required this.activity,
    required this.notes,
    this.bankerId,
    this.founderName = 'Guest',
    this.stageBucket = 'exploration',
    this.phoneNumber = '',
    this.headcount = '1-10',
    this.incorporated = false,
    this.priorities = const [],
    this.leadTemperature,
    this.conversionProbability,
    this.salesPriority,
  });

  String get initials {
    final source = founderName.trim().isNotEmpty ? founderName : name;
    final parts = source
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty
        ? 'G'
        : parts.map((part) => part[0].toUpperCase()).join();
  }

  CrmProspect copyWith({
    String? id,
    String? name,
    String? email,
    String? sector,
    String? stage,
    String? status,
    double? profileProgress,
    String? docsReceivedText,
    int? docsReceivedCount,
    int? docsTotalCount,
    String? materialsReadText,
    String? materialsReadSub,
    String? lastActive,
    String? avatarText,
    Color? avatarBg,
    Color? avatarFg,
    List<CrmDoc>? docs,
    List<CrmEdu>? education,
    List<CrmActivity>? activity,
    String? notes,
    String? bankerId,
    String? founderName,
    String? stageBucket,
    String? phoneNumber,
    String? headcount,
    bool? incorporated,
    List<String>? priorities,
    String? leadTemperature,
    double? conversionProbability,
    String? salesPriority,
  }) {
    return CrmProspect(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      sector: sector ?? this.sector,
      stage: stage ?? this.stage,
      status: status ?? this.status,
      profileProgress: profileProgress ?? this.profileProgress,
      docsReceivedText: docsReceivedText ?? this.docsReceivedText,
      docsReceivedCount: docsReceivedCount ?? this.docsReceivedCount,
      docsTotalCount: docsTotalCount ?? this.docsTotalCount,
      materialsReadText: materialsReadText ?? this.materialsReadText,
      materialsReadSub: materialsReadSub ?? this.materialsReadSub,
      lastActive: lastActive ?? this.lastActive,
      avatarText: avatarText ?? this.avatarText,
      avatarBg: avatarBg ?? this.avatarBg,
      avatarFg: avatarFg ?? this.avatarFg,
      docs: docs ?? List.from(this.docs),
      education: education ?? List.from(this.education),
      activity: activity ?? List.from(this.activity),
      notes: notes ?? this.notes,
      bankerId: bankerId ?? this.bankerId,
      founderName: founderName ?? this.founderName,
      stageBucket: stageBucket ?? this.stageBucket,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      headcount: headcount ?? this.headcount,
      incorporated: incorporated ?? this.incorporated,
      priorities: priorities ?? this.priorities,
      leadTemperature: leadTemperature ?? this.leadTemperature,
      conversionProbability: conversionProbability ?? this.conversionProbability,
      salesPriority: salesPriority ?? this.salesPriority,
    );
  }
}

// --- RIVERPOD PROSPECTS STATE PROVIDER ---

class BankerProspectsNotifier extends StateNotifier<List<CrmProspect>> {
  final Ref ref;
  final String bankId;

  BankerProspectsNotifier(this.ref, this.bankId) : super([]) {
    loadProspects();
  }

  Future<void> loadProspects() async {
    try {
      final list = await ConversationService().listProspects(bankId: bankId);
      state = list.map((r) => _mapToCrmProspect(r)).toList();
    } catch (e) {
      print("Failed to load prospects from database: $e");
      // Fallback: load all mock data so the UI works even if backend fails
      state = _getMockProspects();
    }
  }

  Future<void> _saveProspect(String prospectId) async {
    final prospectIndex = state.indexWhere((p) => p.id == prospectId);
    if (prospectIndex == -1) return;
    final prospect = state[prospectIndex];

    try {
      await ConversationService().updateProspectProfile(
        prospectId,
        email: prospect.email,
        companyName: prospect.name,
        industry: prospect.sector,
        profileSnapshot: _buildSnapshotMap(prospect),
      );
    } catch (e) {
      print("Failed to update prospect $prospectId in DB: $e");
    }
  }

  Map<String, dynamic> _buildSnapshotMap(CrmProspect p) {
    return {
      'status': p.status,
      'userEmail': p.email,
      'notes': p.notes,
      'docs': p.docs.map((d) => {
        'name': d.name,
        'status': d.status,
      }).toList(),
      'education': p.education.map((e) => {
        'title': e.title,
        'tag': e.tag,
        'stripeColor': e.stripeColor.value,
        'status': e.status,
      }).toList(),
      'activity': p.activity.map((a) => {
        'codePoint': a.icon.codePoint,
        'fontFamily': a.icon.fontFamily,
        'iconBg': a.iconBg.value,
        'iconColor': a.iconColor.value,
        'text': a.text,
        'time': a.time,
      }).toList(),
    };
  }

  String _mapPhaseToStatus(int phase) {
    switch (phase) {
      case 1: return '⏳ Waiting — no chat yet';
      case 2: return '✨ Intro chat done';
      case 3: return '💬 In conversation';
      case 4: return '✓ Fully onboarded';
      default: return '💬 In conversation';
    }
  }

  String _mapCompanyStage(String? stage, String? bucket) {
    if (stage == null || stage.isEmpty) {
      if (bucket == null || bucket.isEmpty) return 'Seed';
      switch (bucket) {
        case 'pre_seed': return 'Pre-seed';
        case 'seed': return 'Seed';
        case 'growth': return 'Growth';
        case 'early_stage': return 'Early Stage';
        case 'growth_stage': return 'Growth Stage';
        case 'late_stage': return 'Late Stage';
        case 'ipo_beyond': return 'IPO & Beyond';
        default: return bucket[0].toUpperCase() + bucket.substring(1);
      }
    }
    switch (stage) {
      case 'pre_seed': return 'Pre-seed';
      case 'seed': return 'Seed';
      case 'series_a': return 'Series A';
      case 'series_b_plus': return 'Series B+';
      case 'revenue_generating_no_vc': return 'Revenue Generating';
      default: return stage[0].toUpperCase() + stage.substring(1);
    }
  }

  String _formatLastSeenAt(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      final weekdayStr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][dt.weekday - 1];
      final monthStr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][dt.month - 1];
      final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
      final ampm = dt.hour >= 12 ? 'PM' : 'AM';
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$weekdayStr, $monthStr ${dt.day} at $hour:$minute $ampm';
    } catch (_) {
      return 'Today';
    }
  }

  CrmProspect _mapToCrmProspect(ProspectInitResult r) {
    final snapshot = r.profileSnapshot;
    final String id = r.prospectId;
    final String email = r.email ?? '';
    final String name = r.companyName ?? r.fullName ?? r.email ?? 'Unnamed Prospect';
    final String sector = r.industry ?? 'Fintech';
    final String stage = _mapCompanyStage(r.companyStage, r.stageBucket);
    final String status = snapshot['status'] as String? ?? _mapPhaseToStatus(r.conversationPhase);

    // Try to match a mock prospect for fallback lists
    CrmProspect? mockMatch;
    final nameLower = name.toLowerCase();
    for (final mock in _getMockProspects()) {
      if (nameLower.contains(mock.name.toLowerCase()) ||
          mock.name.toLowerCase().contains(nameLower) ||
          mock.id == id ||
          (r.email != null && mock.email.toLowerCase() == r.email!.toLowerCase())) {
        mockMatch = mock;
        break;
      }
    }

    List<CrmDoc> docs = [];
    if (snapshot.containsKey('docs')) {
      final docsList = snapshot['docs'] as List;
      docs = docsList.map((d) => CrmDoc(
        name: d['name'] as String,
        status: d['status'] as String,
      )).toList();
    } else if (mockMatch != null) {
      docs = List.from(mockMatch.docs);
    } else {
      docs = [
        CrmDoc(name: 'Investor overview deck', status: 'Needs review'),
        CrmDoc(name: 'Product one-pager', status: 'Not uploaded'),
      ];
    }

    List<CrmEdu> education = [];
    if (snapshot.containsKey('education')) {
      final eduList = snapshot['education'] as List;
      education = eduList.map((e) => CrmEdu(
        title: e['title'] as String,
        tag: e['tag'] as String,
        stripeColor: Color(e['stripeColor'] as int),
        status: e['status'] as String,
      )).toList();
    } else if (mockMatch != null) {
      education = List.from(mockMatch.education);
    } else {
      education = [
        CrmEdu(
          title: 'Setting up efficient banking early',
          tag: 'Guide',
          stripeColor: BankerColors.gold,
          status: 'Guide · Not yet read',
        ),
      ];
    }

    List<CrmActivity> activity = [];
    if (snapshot.containsKey('activity')) {
      final actList = snapshot['activity'] as List;
      activity = actList.map((a) => CrmActivity(
        icon: _crmActivityIconFromSnapshot(a as Map),
        iconBg: Color(a['iconBg'] as int),
        iconColor: Color(a['iconColor'] as int),
        text: a['text'] as String,
        time: a['time'] as String,
      )).toList();
    } else if (mockMatch != null) {
      activity = List.from(mockMatch.activity);
    } else {
      activity = [
        CrmActivity(
          icon: Icons.input_rounded,
          iconBg: BankerColors.purpleSoft,
          iconColor: const Color(0xFF6B21A8),
          text: 'Prospect entered database',
          time: 'Today',
        ),
      ];
    }

    String notes = '';
    if (snapshot.containsKey('notes')) {
      notes = snapshot['notes'] as String;
    } else if (mockMatch != null) {
      notes = mockMatch.notes;
    }

    int docsReceivedCount = docs.where((d) => d.status == 'Received' || d.status == 'Needs review').length;
    int docsTotalCount = docs.length;
    String docsReceivedText = docsTotalCount == 0 ? 'None assigned' : '$docsReceivedCount/$docsTotalCount received';

    int materialsReadCount = education.where((e) => !e.status.contains('Not yet read')).length;
    int materialsTotalCount = education.length;
    String materialsReadText = materialsTotalCount == 0 ? '—' : '$materialsReadCount / $materialsTotalCount';
    String materialsReadSub = materialsTotalCount == 0 
        ? '' 
        : (materialsTotalCount - materialsReadCount == 0 ? 'All read ✓' : '${materialsTotalCount - materialsReadCount} unread');

    double profileProgress = 0.20;
    if (mockMatch != null) {
      profileProgress = mockMatch.profileProgress;
    } else {
      profileProgress = 0.2 + (r.conversationPhase - 1) * 0.25;
      if (profileProgress > 1.0) profileProgress = 1.0;
    }

    final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();
    final Color avatarBg = mockMatch?.avatarBg ?? BankerColors.blueSoft;
    final Color avatarFg = mockMatch?.avatarFg ?? BankerColors.blue;

    final String phoneNumber = r.phoneNumber ?? '';
    final String headcount = r.headcount ?? '1-10';
    final bool incorporated = r.incorporated;
    final List<String> priorities = r.selectedPrioritiesJson.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    return CrmProspect(
      id: id,
      name: name,
      email: email,
      sector: sector,
      stage: stage,
      status: status,
      profileProgress: profileProgress,
      docsReceivedText: docsReceivedText,
      docsReceivedCount: docsReceivedCount,
      docsTotalCount: docsTotalCount,
      materialsReadText: materialsReadText,
      materialsReadSub: materialsReadSub,
      lastActive: r.lastSeenAt != null ? _formatLastSeenAt(r.lastSeenAt!) : (mockMatch?.lastActive ?? 'Today'),
      avatarText: initials.isEmpty ? 'C' : initials,
      avatarBg: avatarBg,
      avatarFg: avatarFg,
      docs: docs,
      education: education,
      activity: activity,
      notes: notes,
      bankerId: r.bankerId,
      founderName: r.fullName ?? 'Guest',
      stageBucket: r.stageBucket,
      phoneNumber: phoneNumber,
      headcount: headcount,
      incorporated: incorporated,
      priorities: priorities,
      leadTemperature: r.leadTemperature,
      conversionProbability: r.conversionProbability,
      salesPriority: r.salesPriority,
    );
  }

  void updateNotes(String prospectId, String notes) {
    state = [
      for (final p in state)
        if (p.id == prospectId)
          p.copyWith(notes: notes)
        else
          p
    ];
    _saveProspect(prospectId);
  }

  void addDocumentRequest(String prospectId, List<String> docNames) {
    state = [
      for (final p in state)
        if (p.id == prospectId)
          p.copyWith(
            docs: [
              ...p.docs,
              for (final name in docNames)
                if (!p.docs.any((d) => d.name == name))
                  CrmDoc(name: name, status: 'Not uploaded')
            ],
            docsReceivedText: '${p.docsReceivedCount}/${p.docsTotalCount + docNames.length} received',
            docsTotalCount: p.docsTotalCount + docNames.length,
            activity: [
              CrmActivity(
                icon: Icons.insert_drive_file_outlined,
                iconBg: BankerColors.blueSoft,
                iconColor: BankerColors.blue,
                text: 'Requested ${docNames.length} document(s): ${docNames.join(", ")}',
                time: 'Today',
              ),
              ...p.activity,
            ],
          )
        else
          p
    ];
    _saveProspect(prospectId);
  }

  void removeEducation(String prospectId, String title) {
    state = [
      for (final p in state)
        if (p.id == prospectId)
          p.copyWith(
            education: [
              for (final e in p.education)
                if (e.title != title) e
            ]
          )
        else
          p
    ];
    _saveProspect(prospectId);
  }

  void addEducation(String prospectId, List<CrmEdu> eduItems) {
    state = [
      for (final p in state)
        if (p.id == prospectId)
          p.copyWith(
            education: [
              ...p.education,
              for (final e in eduItems)
                if (!p.education.any((x) => x.title == e.title)) e
            ],
            activity: [
              CrmActivity(
                icon: Icons.chrome_reader_mode_rounded,
                iconBg: BankerColors.greenSoft,
                iconColor: BankerColors.green,
                text: 'Assigned ${eduItems.length} education item(s) to learning path',
                time: 'Today',
              ),
              ...p.activity,
            ]
          )
        else
          p
    ];
    _saveProspect(prospectId);
  }

  void sendMessage(String prospectId, String messageText) {
    state = [
      for (final p in state)
        if (p.id == prospectId)
          p.copyWith(
            activity: [
              CrmActivity(
                icon: Icons.chat_bubble_outline_rounded,
                iconBg: BankerColors.blueSoft,
                iconColor: BankerColors.blue,
                text: 'Sent message: "$messageText"',
                time: 'Today',
              ),
              ...p.activity,
            ]
          )
        else
          p
    ];
    _saveProspect(prospectId);
  }

  void addProspect(CrmProspect prospect) {
    state = [prospect, ...state];
  }

  List<CrmProspect> _getMockProspects() {
    return [
      CrmProspect(
        id: 'aster',
        name: 'Aster Labs',
        email: 'contact@asterlabs.com',
        sector: 'Fintech infrastructure',
        stage: 'Seed',
        status: '📅 Call May 6',
        profileProgress: 0.78,
        docsReceivedText: '1/3 received',
        docsReceivedCount: 1,
        docsTotalCount: 3,
        materialsReadText: '1 / 4',
        materialsReadSub: '3 unread',
        lastActive: 'Today',
        avatarText: 'AL',
        avatarBg: BankerColors.blueSoft,
        avatarFg: BankerColors.blue,
        docs: [
          CrmDoc(name: 'Investor overview deck', status: 'Received'),
          CrmDoc(name: 'Product one-pager', status: 'Needs review'),
          CrmDoc(name: 'Financial statements Q1', status: 'Not uploaded'),
        ],
        education: [
          CrmEdu(
            title: 'Setting up efficient banking early',
            tag: 'Guide',
            stripeColor: BankerColors.gold,
            status: 'Guide · Not yet read',
          ),
          CrmEdu(
            title: 'Treasury habits that scale with you',
            tag: 'Event',
            stripeColor: BankerColors.blue,
            status: 'Event · Registered',
          ),
          CrmEdu(
            title: 'Preparing for your first credit facility',
            tag: 'Guide',
            stripeColor: const Color(0xFF7F77DD),
            status: 'Guide · Added by you · Not yet read',
          ),
        ],
        activity: [
          CrmActivity(
            icon: Icons.chat_bubble_outline_rounded,
            iconBg: BankerColors.blueSoft,
            iconColor: BankerColors.blue,
            text: 'Sent message re: operating vs. reserve accounts',
            time: 'Today',
          ),
          CrmActivity(
            icon: Icons.insert_drive_file_outlined,
            iconBg: BankerColors.greenSoft,
            iconColor: BankerColors.green,
            text: 'Read: Treasury accounts explainer',
            time: 'Yesterday',
          ),
          CrmActivity(
            icon: Icons.access_time_rounded,
            iconBg: BankerColors.amberSoft,
            iconColor: const Color(0xFF7C5410),
            text: 'Logged in — viewed banker section and documents',
            time: 'Yesterday',
          ),
          CrmActivity(
            icon: Icons.phone_in_talk_outlined,
            iconBg: BankerColors.purpleSoft,
            iconColor: const Color(0xFF4B43B6),
            text: 'Completed intro call · 28 min · Accounts, FDIC, sweep yields, credit facility',
            time: 'Apr 29',
          ),
          CrmActivity(
            icon: Icons.settings_voice_rounded,
            iconBg: BankerColors.blueSoft,
            iconColor: BankerColors.blue,
            text: 'AI guide: asked 3 questions — sweep accounts, FDIC, credit facility timing',
            time: 'Apr 29',
          ),
        ],
        notes: 'Strong product instinct, lean on financial ops experience. Needs hand-holding on treasury basics but picks it up fast. Credit facility conversation could move quickly if they hit Q3 targets. Follow up on CFO hire plans.',
      ),
      CrmProspect(
        id: 'meridian',
        name: 'Meridian Health',
        email: 'info@meridianhealth.com',
        sector: 'Health tech',
        stage: 'Series A',
        status: '⚠ Awaiting docs',
        profileProgress: 0.62,
        docsReceivedText: '0/2 received',
        docsReceivedCount: 0,
        docsTotalCount: 2,
        materialsReadText: '3 / 5',
        materialsReadSub: '2 unread',
        lastActive: 'Yesterday',
        avatarText: 'MH',
        avatarBg: BankerColors.greenSoft,
        avatarFg: BankerColors.green,
        docs: [
          CrmDoc(name: 'Investor overview deck', status: 'Needs review'),
          CrmDoc(name: 'Cap table summary', status: 'Not uploaded'),
        ],
        education: [
          CrmEdu(
            title: 'Running a disciplined startup treasury',
            tag: 'Explainer',
            stripeColor: BankerColors.green,
            status: 'Explainer · Not yet read',
          ),
        ],
        activity: [
          CrmActivity(
            icon: Icons.insert_drive_file_outlined,
            iconBg: BankerColors.redSoft,
            iconColor: const Color(0xFF991B1B),
            text: 'Initiated document request',
            time: 'Yesterday',
          ),
          CrmActivity(
            icon: Icons.handshake_outlined,
            iconBg: BankerColors.blueSoft,
            iconColor: BankerColors.blue,
            text: 'Intro conversation completed',
            time: 'May 1',
          ),
        ],
        notes: 'Discussed corporate cards integration. Interest in yield sweeps for their Series A funding. Review cap table when received.',
      ),
      CrmProspect(
        id: 'fold',
        name: 'Fold Dynamics',
        email: 'hello@folddynamics.com',
        sector: 'Climate tech',
        stage: 'Seed',
        status: '✨ Intro chat done',
        profileProgress: 0.45,
        docsReceivedText: '1/3 received',
        docsReceivedCount: 1,
        docsTotalCount: 3,
        materialsReadText: '0 / 3',
        materialsReadSub: 'Nothing read yet',
        lastActive: '2d ago',
        avatarText: 'FD',
        avatarBg: BankerColors.amberSoft,
        avatarFg: const Color(0xFF7C5410),
        docs: [
          CrmDoc(name: 'Investor overview deck', status: 'Received'),
          CrmDoc(name: 'Board deck (most recent)', status: 'Not uploaded'),
          CrmDoc(name: '18-month cash flow projection', status: 'Not uploaded'),
        ],
        education: [],
        activity: [
          CrmActivity(
            icon: Icons.calendar_today_rounded,
            iconBg: BankerColors.blueSoft,
            iconColor: BankerColors.blue,
            text: 'Intro call scheduled',
            time: '2d ago',
          ),
        ],
        notes: 'Intro call scheduled, follow up on their hardware scaling timelines.',
      ),
      CrmProspect(
        id: 'arc',
        name: 'Arc Systems',
        email: 'ops@arcsystems.com',
        sector: 'Defense tech',
        stage: 'Series A',
        status: '💬 In conversation',
        profileProgress: 0.85,
        docsReceivedText: '3/3 received',
        docsReceivedCount: 3,
        docsTotalCount: 3,
        materialsReadText: '4 / 4',
        materialsReadSub: 'All read ✓',
        lastActive: '3d ago',
        avatarText: 'AR',
        avatarBg: BankerColors.purpleSoft,
        avatarFg: const Color(0xFF4B43B6),
        docs: [
          CrmDoc(name: 'Investor overview deck', status: 'Received'),
          CrmDoc(name: 'Financial statements Q1', status: 'Received'),
          CrmDoc(name: 'Cap table summary', status: 'Received'),
        ],
        education: [],
        activity: [
          CrmActivity(
            icon: Icons.upload_file_rounded,
            iconBg: BankerColors.greenSoft,
            iconColor: BankerColors.green,
            text: 'Uploaded financial statements Q1',
            time: '3d ago',
          ),
        ],
        notes: 'Defense contract secured, looking to establish credit facility early next month.',
      ),
      CrmProspect(
        id: 'lume',
        name: 'Lume Materials',
        email: 'contact@lumematerials.com',
        sector: 'Deep tech',
        stage: 'Seed',
        status: '✓ Fully onboarded',
        profileProgress: 1.0,
        docsReceivedText: '4/4 received',
        docsReceivedCount: 4,
        docsTotalCount: 4,
        materialsReadText: '6 / 6',
        materialsReadSub: 'All read ✓',
        lastActive: '1w ago',
        avatarText: 'LM',
        avatarBg: const Color(0x1404213D),
        avatarFg: BankerColors.navy,
        docs: [
          CrmDoc(name: 'Investor overview deck', status: 'Received'),
          CrmDoc(name: 'Financial statements Q1', status: 'Received'),
          CrmDoc(name: 'Cap table summary', status: 'Received'),
          CrmDoc(name: 'Articles of incorporation', status: 'Received'),
        ],
        education: [],
        activity: [
          CrmActivity(
            icon: Icons.check_circle_outline_rounded,
            iconBg: BankerColors.greenSoft,
            iconColor: BankerColors.green,
            text: 'Onboarding completed',
            time: '1w ago',
          ),
        ],
        notes: 'Clean onboard. Transitioned fully to Innovation Banking. Setting up automated treasury sweep next week.',
      ),
      CrmProspect(
        id: 'echo',
        name: 'Echoway',
        email: 'hello@echoway.com',
        sector: 'Consumer',
        stage: 'Pre-seed',
        status: '⏳ Waiting — no chat yet',
        profileProgress: 0.20,
        docsReceivedText: 'None assigned',
        docsReceivedCount: 0,
        docsTotalCount: 0,
        materialsReadText: '—',
        materialsReadSub: '',
        lastActive: '1w ago',
        avatarText: 'EW',
        avatarBg: BankerColors.blueSoft,
        avatarFg: BankerColors.blue,
        docs: [],
        education: [],
        activity: [
          CrmActivity(
            icon: Icons.input_rounded,
            iconBg: BankerColors.purpleSoft,
            iconColor: const Color(0xFF6B21A8),
            text: 'Prospect entered database',
            time: '1w ago',
          ),
        ],
        notes: 'No direct touch yet. Need to trigger outreach email.',
      ),
      CrmProspect(
        id: 'kova',
        name: 'Kova Bio',
        email: 'contact@kovabio.com',
        sector: 'Biotech',
        stage: 'Series A',
        status: '💬 In conversation',
        profileProgress: 0.70,
        docsReceivedText: '2/4 received',
        docsReceivedCount: 2,
        docsTotalCount: 4,
        materialsReadText: '2 / 5',
        materialsReadSub: '3 unread',
        lastActive: '2w ago',
        avatarText: 'KV',
        avatarBg: BankerColors.greenSoft,
        avatarFg: BankerColors.green,
        docs: [
          CrmDoc(name: 'Investor overview deck', status: 'Received'),
          CrmDoc(name: 'Cap table summary', status: 'Received'),
          CrmDoc(name: 'Product one-pager', status: 'Needs review'),
          CrmDoc(name: 'Financial statements Q1', status: 'Not uploaded'),
        ],
        education: [],
        activity: [
          CrmActivity(
            icon: Icons.chrome_reader_mode_outlined,
            iconBg: BankerColors.amberSoft,
            iconColor: const Color(0xFF7C5410),
            text: 'Reviewed treasury guides',
            time: '2w ago',
          ),
        ],
        notes: 'Strong funding runway, check in on clinical trial milestones next month.',
      ),
    ];
  }
}

final bankersProvider = FutureProvider<List<Banker>>((ref) async {
  final bankId = ref.watch(activeBankIdProvider);
  return await ConversationService().listBankers(bankId: bankId);
});

final activeBankerProvider = StateProvider<Banker?>((ref) {
  return ProspectStorage().getActiveBankerSync();
});

final bankerProspectsProvider = StateNotifierProvider<BankerProspectsNotifier, List<CrmProspect>>((ref) {
  final bankId = ref.watch(activeBankIdProvider);
  return BankerProspectsNotifier(ref, bankId);
});

// --- STANDALONE DETAIL PANEL ---

class BankerDetailPanel extends ConsumerStatefulWidget {
  final String prospectId;
  final bool showBackButton;
  final VoidCallback? onClose;
  final VoidCallback? onMessageTap;

  const BankerDetailPanel({
    super.key,
    required this.prospectId,
    this.showBackButton = false,
    this.onClose,
    this.onMessageTap,
  });

  @override
  ConsumerState<BankerDetailPanel> createState() => _BankerDetailPanelState();
}

class _BankerDetailPanelState extends ConsumerState<BankerDetailPanel> {
  String _activeTab = 'assign';
  final TextEditingController _notesController = TextEditingController();
  final NotificationService _notifService = NotificationService();
  List<ProductPublic> _products = [];
  bool _loadingProducts = false;
  List<String> _suggestedQuestions = [];
  bool _loadingQuestions = false;
  List<ProspectCheckpoint> _checkpoints = [];
  bool _loadingCheckpoints = false;
  final Map<String, bool> _expandedCategories = {};

  List<ProspectDocument> _documents = [];
  bool _loadingDocuments = false;
  ProspectDocument? _selectedDocumentForAnalysis;
  List<ProspectCheckpoint> _documentCheckpoints = [];
  bool _loadingDocCheckpoints = false;
  String _docDetailSubTab = 'checklist';
  List<DocumentAuditLog> _documentAuditLogs = [];
  bool _loadingAuditLogs = false;
  final Map<String, bool> _expandedDocCategories = {};

  ProspectFullProfile? _fullProfile;
  bool _loadingFullProfile = false;

  ProspectDataScienceDetails? _dsDetails;
  bool _loadingDsDetails = false;
  bool _runningDsScoring = false;
  Map<String, dynamic> _simulatedFeatures = {};
  bool _isSandboxDirty = false;

  Future<void> _fetchFullProfile() async {
    if (!mounted) return;
    setState(() {
      _loadingFullProfile = true;
    });
    try {
      final profile = await ConversationService().getProspectFullProfile(widget.prospectId);
      if (mounted) {
        setState(() {
          _fullProfile = profile;
          _loadingFullProfile = false;
        });
      }
    } catch (e) {
      print("Failed to fetch full profile: $e");
      if (mounted) {
        setState(() {
          _loadingFullProfile = false;
        });
      }
    }
  }

  Future<void> _fetchDsDetails() async {
    if (!mounted) return;
    setState(() {
      _loadingDsDetails = true;
    });
    try {
      final details = await ConversationService().getProspectDataScience(widget.prospectId);
      if (mounted) {
        setState(() {
          _dsDetails = details;
          _loadingDsDetails = false;
          _simulatedFeatures = Map<String, dynamic>.from(details.rawFeaturesJson);
          _isSandboxDirty = false;
        });
      }
    } catch (e) {
      print("Failed to fetch data science details: $e");
      if (mounted) {
        setState(() {
          _dsDetails = null;
          _loadingDsDetails = false;
        });
      }
    }
  }

  Future<void> _runDsScoring({bool useSimulation = false}) async {
    if (!mounted) return;
    setState(() {
      _runningDsScoring = true;
    });
    try {
      if (useSimulation) {
        // Simulation run: calculated details are returned directly, DB is not modified
        final details = await ConversationService().runProspectDataScience(
          widget.prospectId,
          features: _simulatedFeatures,
          simulation: true,
        ) as ProspectDataScienceDetails;
        
        if (mounted) {
          setState(() {
            _dsDetails = details;
            _simulatedFeatures = Map<String, dynamic>.from(details.rawFeaturesJson);
            _isSandboxDirty = false;
            _runningDsScoring = false;
          });
        }
      } else {
        // Live run: saves to database and refreshes DB cache
        await ConversationService().runProspectDataScience(widget.prospectId, features: null, simulation: false);
        ref.read(bankerProspectsProvider.notifier).loadProspects();
        final details = await ConversationService().getProspectDataScience(widget.prospectId);
        
        if (mounted) {
          setState(() {
            _dsDetails = details;
            _simulatedFeatures = Map<String, dynamic>.from(details.rawFeaturesJson);
            _isSandboxDirty = false;
            _runningDsScoring = false;
          });
        }
      }
    } catch (e) {
      print("Failed to run data science scoring: $e");
      if (mounted) {
        setState(() {
          _runningDsScoring = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final activeBanker = ref.read(activeBankerProvider);
    _activeTab = (activeBanker?.bankerId == 'datascience') ? 'data_science' : 'assign';
    _notifService.addListener(_onNotifUpdate);
    _fetchProducts();
    _fetchSuggestedQuestions();
    _fetchCheckpoints();
    _fetchDocuments();
    _fetchFullProfile();
    _fetchDsDetails();
  }

  void _onNotifUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant BankerDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prospectId != widget.prospectId) {
      _fetchProducts();
      _fetchSuggestedQuestions();
      _fetchCheckpoints();
      _fetchDocuments();
      _fetchFullProfile();
      _fetchDsDetails();
      _selectedDocumentForAnalysis = null;
    }
  }

  Future<void> _fetchCheckpoints() async {
    if (!mounted) return;
    setState(() {
      _loadingCheckpoints = true;
    });
    try {
      final list = await ConversationService().getProspectCheckpoints(widget.prospectId);
      
      // Sort numerically by checkpoint number: e.g. "checkpoint_12" -> 12
      list.sort((a, b) {
        final regExp = RegExp(r'\d+');
        final matchA = regExp.firstMatch(a.checkpointId);
        final matchB = regExp.firstMatch(b.checkpointId);
        if (matchA != null && matchB != null) {
          final intA = int.parse(matchA.group(0)!);
          final intB = int.parse(matchB.group(0)!);
          return intA.compareTo(intB);
        }
        return a.checkpointId.compareTo(b.checkpointId);
      });

      if (mounted) {
        setState(() {
          _checkpoints = list;
          if (list.isNotEmpty) {
            final firstCat = list.first.checkpoint?.category;
            if (firstCat != null) {
              _expandedCategories[firstCat] = true;
            }
          }
          _loadingCheckpoints = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching checkpoints: $e');
      if (mounted) {
        setState(() {
          _loadingCheckpoints = false;
        });
      }
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _loadingProducts = true;
    });
    try {
      final products = await ConversationService().listProducts(prospectId: widget.prospectId);
      if (mounted) {
        setState(() {
          _products = products;
          _loadingProducts = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching products for banker panel: $e');
      if (mounted) {
        setState(() {
          _loadingProducts = false;
        });
      }
    }
  }

  Future<void> _fetchSuggestedQuestions() async {
    if (!mounted) return;
    setState(() {
      _loadingQuestions = true;
      _suggestedQuestions = [];
    });
    try {
      final questions = await ConversationService().getSuggestedQuestions(widget.prospectId);
      if (mounted) {
        setState(() {
          _suggestedQuestions = questions;
          _loadingQuestions = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching suggested questions: $e');
      if (mounted) {
        setState(() {
          _loadingQuestions = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notifService.removeListener(_onNotifUpdate);
    _notesController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final prospects = ref.watch(bankerProspectsProvider);
    final activeBanker = ref.watch(activeBankerProvider);
    final isDs = activeBanker?.bankerId == 'datascience';
    
    if (prospects.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
          ),
        ),
      );
    }
    
    // Find matching prospect
    final prospect = prospects.firstWhere(
      (p) => p.id == widget.prospectId,
      orElse: () => prospects.first,
    );

    // Sync notes text safely
    if (_notesController.text != prospect.notes && !_notesController.value.isComposingRangeValid) {
      _notesController.text = prospect.notes;
    }



    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Head
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: BankerColors.line2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.showBackButton) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: BankerColors.navy, size: 20),
                  onPressed: () {
                    context.go('/banker');
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 10),
              ],
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: prospect.avatarBg,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      prospect.avatarText,
                      style: TextStyle(
                        fontFamily: 'DM Serif Display',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: prospect.avatarFg,
                      ),
                    ),
                  ),
                  if (() {
                    final targetIndex = prospects.indexOf(prospect);
                    if (targetIndex == -1) return false;
                    for (var item in _notifService.activeHubNotifications) {
                      if (item.prospectSlot == targetIndex) return true;
                    }
                    return false;
                  }())
                    Positioned(
                      top: -1,
                      right: -1,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0533C),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prospect.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: BankerColors.ink),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${prospect.stage} · ${prospect.sector}',
                            style: const TextStyle(fontSize: 11, color: BankerColors.muted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      ],
                    ),
                  ],
                ),
              ),
              if (widget.onClose != null)
                GestureDetector(
                  onTap: widget.onClose,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Text(
                      '×',
                      style: TextStyle(fontSize: 22, color: BankerColors.muted2, height: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Actions
        if (!widget.showBackButton && !isDs)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: BankerColors.line2)),
            ),
            child: Row(
              children: [
                const Spacer(),
                TextButton(
                  onPressed: () {
                    context.go('/banker/${prospect.id}');
                  },
                  child: const Text(
                    'Open detail →',
                    style: TextStyle(fontSize: 11, color: BankerColors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

        // Tabs Header
        if (!isDs)
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: BankerColors.line2)),
            ),
            child: Row(
              children: [
                _buildTabButton('Next steps', 'assign'),
                _buildTabButton('Documents', 'documents'),
                _buildTabButton('Recommended products', 'products'),
                _buildTabButton('Suggested questions', 'questions'),
                _buildTabButton('Data Science', 'data_science'),
              ],
            ),
          ),

        // Tab Content
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: isDs ? _buildDataScienceTab(prospect) : _buildActiveTabContent(prospect),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabButton(String label, String tabKey) {
    final isActive = _activeTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTab = tabKey;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? BankerColors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: BankerColors.blue,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(CrmProspect prospect) {
    switch (_activeTab) {
      case 'assign':
        return _buildNextStepsTab(prospect);
      case 'documents':
        return _buildDocumentsTab(prospect);
      case 'products':
        return _buildRecommendedProductsTab(prospect);
      case 'questions':
        return _buildSuggestedQuestionsTab(prospect);
      case 'data_science':
        return _buildDataScienceTab(prospect);
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _toggleMajorCheckpoint(ProspectCheckpoint cp) async {
    final nextChecked = !cp.checked;

    // Optimistically update local state
    setState(() {
      final index = _checkpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
      if (index != -1) {
        final current = _checkpoints[index];
        final updatedMinis = {...current.miniCheckpointAnswers};
        if (current.checkpoint?.miniCheckpoints.isNotEmpty ?? false) {
          for (final mini in current.checkpoint!.miniCheckpoints) {
            updatedMinis[mini] = nextChecked ? 'yes' : 'no';
          }
        }
        _checkpoints[index] = current.copyWith(
          checked: nextChecked,
          miniCheckpointAnswers: updatedMinis,
        );
      }
    });

    try {
      final updated = await ConversationService().updateProspectCheckpoint(
        widget.prospectId,
        cp.checkpointId,
        checked: nextChecked,
      );
      if (mounted) {
        setState(() {
          final index = _checkpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
          if (index != -1) {
            _checkpoints[index] = updated;
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling checkpoint: $e');
      _fetchCheckpoints();
    }
  }

  Future<void> _setMiniAnswer(ProspectCheckpoint cp, String mini, String value) async {
    final index = _checkpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
    if (index == -1) return;

    final current = _checkpoints[index];
    final updatedMinis = {...current.miniCheckpointAnswers};
    updatedMinis[mini] = value;

    bool allYes = false;
    if (current.checkpoint?.miniCheckpoints.isNotEmpty ?? false) {
      allYes = current.checkpoint!.miniCheckpoints.every((m) => updatedMinis[m] == 'yes');
    }

    // Optimistically update local state
    setState(() {
      _checkpoints[index] = current.copyWith(
        checked: allYes,
        miniCheckpointAnswers: updatedMinis,
      );
    });

    try {
      final updated = await ConversationService().updateProspectCheckpoint(
        widget.prospectId,
        cp.checkpointId,
        miniAnswers: updatedMinis,
      );
      if (mounted) {
        setState(() {
          final idx = _checkpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
          if (idx != -1) {
            _checkpoints[idx] = updated;
          }
        });
      }
    } catch (e) {
      debugPrint('Error setting mini answer: $e');
      _fetchCheckpoints();
    }
  }

  Widget _buildTriStateButton({
    required String label,
    required bool isSelected,
    required Color selectedBg,
    required Color selectedFg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? selectedBg : BankerColors.line2,
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: isSelected ? selectedFg : BankerColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _fetchDocuments() async {
    if (!mounted) return;
    setState(() {
      _loadingDocuments = true;
    });
    try {
      final list = await ConversationService().getDocumentList(widget.prospectId);
      if (mounted) {
        setState(() {
          _documents = list;
          _loadingDocuments = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching documents: $e');
      if (mounted) {
        setState(() {
          _loadingDocuments = false;
        });
      }
    }
  }

  Future<void> _selectDocumentForAnalysis(ProspectDocument doc) async {
    setState(() {
      _selectedDocumentForAnalysis = doc;
      _loadingDocCheckpoints = true;
      _documentCheckpoints = [];
      _docDetailSubTab = 'checklist';
    });
    try {
      final list = await ConversationService().getDocumentCheckpoints(doc.documentId);
      list.sort((a, b) {
        final regExp = RegExp(r'\d+');
        final matchA = regExp.firstMatch(a.checkpointId);
        final matchB = regExp.firstMatch(b.checkpointId);
        if (matchA != null && matchB != null) {
          final intA = int.parse(matchA.group(0)!);
          final intB = int.parse(matchB.group(0)!);
          return intA.compareTo(intB);
        }
        return a.checkpointId.compareTo(b.checkpointId);
      });

      if (mounted) {
        setState(() {
          _documentCheckpoints = list;
          if (list.isNotEmpty) {
            final firstCat = list.first.checkpoint?.category;
            if (firstCat != null) {
              _expandedDocCategories[firstCat] = true;
            }
          }
          _loadingDocCheckpoints = false;
        });
      }
      _fetchAuditLogs(doc.documentId);
    } catch (e) {
      debugPrint('Error fetching document checkpoints: $e');
      if (mounted) {
        setState(() {
          _loadingDocCheckpoints = false;
        });
      }
    }
  }

  Future<void> _fetchAuditLogs(String documentId) async {
    setState(() {
      _loadingAuditLogs = true;
      _documentAuditLogs = [];
    });
    try {
      final logs = await ConversationService().getDocumentAuditLogs(documentId);
      if (mounted) {
        setState(() {
          _documentAuditLogs = logs;
          _loadingAuditLogs = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      if (mounted) {
        setState(() {
          _loadingAuditLogs = false;
        });
      }
    }
  }

  Future<void> _toggleDocumentMajorCheckpoint(ProspectCheckpoint cp) async {
    if (_selectedDocumentForAnalysis == null) return;
    final docId = _selectedDocumentForAnalysis!.documentId;
    final nextChecked = !cp.checked;

    setState(() {
      final index = _documentCheckpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
      if (index != -1) {
        final current = _documentCheckpoints[index];
        final updatedMinis = {...current.miniCheckpointAnswers};
        if (current.checkpoint?.miniCheckpoints.isNotEmpty ?? false) {
          for (final mini in current.checkpoint!.miniCheckpoints) {
            updatedMinis[mini] = nextChecked ? 'yes' : 'no';
          }
        }
        _documentCheckpoints[index] = current.copyWith(
          checked: nextChecked,
          miniCheckpointAnswers: updatedMinis,
        );
      }
    });

    try {
      final updated = await ConversationService().updateDocumentCheckpoint(
        docId,
        cp.checkpointId,
        checked: nextChecked,
      );
      if (mounted) {
        setState(() {
          final index = _documentCheckpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
          if (index != -1) {
            _documentCheckpoints[index] = updated;
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling document checkpoint: $e');
      _selectDocumentForAnalysis(_selectedDocumentForAnalysis!);
    }
  }

  Future<void> _updateDocumentMiniCheckpointAnswer(
    ProspectCheckpoint cp,
    String miniKey,
    String value,
  ) async {
    if (_selectedDocumentForAnalysis == null) return;
    final docId = _selectedDocumentForAnalysis!.documentId;

    final index = _documentCheckpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
    if (index == -1) return;
    final current = _documentCheckpoints[index];
    final updatedMinis = {...current.miniCheckpointAnswers};
    updatedMinis[miniKey] = value;

    bool allVerified = true;
    if (current.checkpoint?.miniCheckpoints.isNotEmpty ?? false) {
      allVerified = current.checkpoint!.miniCheckpoints.every((m) =>
          updatedMinis[m] == 'yes' || updatedMinis[m] == 'no' || updatedMinis[m] == 'na');
    }

    setState(() {
      _documentCheckpoints[index] = current.copyWith(
        checked: allVerified,
        miniCheckpointAnswers: updatedMinis,
      );
    });

    try {
      final updated = await ConversationService().updateDocumentCheckpoint(
        docId,
        cp.checkpointId,
        miniAnswers: {miniKey: value},
      );
      if (mounted) {
        setState(() {
          final idx = _documentCheckpoints.indexWhere((c) => c.checkpointId == cp.checkpointId);
          if (idx != -1) {
            _documentCheckpoints[idx] = updated;
          }
        });
      }
    } catch (e) {
      debugPrint('Error updating mini-checkpoint answer: $e');
      _selectDocumentForAnalysis(_selectedDocumentForAnalysis!);
    }
  }

  void _showMockDownloadNotification(String item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Started downloading ' + item + '...',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: BankerColors.navy2,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return month + ' ' + day + ', ' + dt.year.toString() + ' ' + hour + ':' + minute;
  }

  Widget _buildDocumentsTab(CrmProspect prospect) {
    if (_loadingDocuments) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_documents.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: BankerColors.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankerColors.line2),
            ),
            child: const Center(
              child: Text(
                'No documents uploaded yet.',
                style: TextStyle(fontSize: 12, color: BankerColors.muted),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: BankerColors.line2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(4.0),
                1: FlexColumnWidth(2.5),
                2: FlexColumnWidth(2.0),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [
                TableRow(
                  decoration: const BoxDecoration(
                    color: BankerColors.cream,
                    border: Border(bottom: BorderSide(color: BankerColors.line2)),
                  ),
                  children: [
                    _buildTableHeaderCell('Document Name'),
                    _buildTableHeaderCell('Uploaded At'),
                    _buildTableHeaderCell('Link'),
                  ],
                ),
                ..._documents.map((doc) {
                  return TableRow(
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: BankerColors.line, width: 0.5)),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: BankerColors.blueSoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.insert_drive_file_outlined,
                                size: 14,
                                color: BankerColors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                doc.fileName,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: BankerColors.navy,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          _formatDateTime(doc.uploadedAt),
                          style: const TextStyle(
                            fontSize: 11,
                            color: BankerColors.muted,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: BankerColors.blueSoft,
                              foregroundColor: BankerColors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                                side: const BorderSide(color: BankerColors.blue, width: 0.5),
                              ),
                            ),
                            onPressed: doc.driveLink != null && doc.driveLink!.isNotEmpty
                                ? () => html.window.open(doc.driveLink!, '_blank')
                                : null,
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Open in Drive',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: BankerColors.muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDocumentStatusBadge(String status) {
    Color bg;
    Color fg;
    String label = status;

    if (status == 'Approved') {
      bg = BankerColors.greenSoft;
      fg = BankerColors.green;
      label = 'Approved';
    } else if (status == 'Reject') {
      bg = BankerColors.redSoft;
      fg = const Color(0xFF991B1B);
      label = 'Rejected';
    } else {
      bg = BankerColors.amberSoft;
      fg = const Color(0xFF7C5410);
      label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildDocumentAnalysisDetail(CrmProspect prospect, ProspectDocument doc) {
    final activeBanker = ref.watch(activeBankerProvider);
    final bankerName = activeBanker?.name ?? activeBanker?.email ?? 'Content SME';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _selectedDocumentForAnalysis = null;
                });
              },
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: BankerColors.navy),
                    SizedBox(width: 4),
                    Text(
                      'Back to Documents List',
                      style: TextStyle(
                        fontSize: 11,
                        color: BankerColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 16, color: BankerColors.line2),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                '${doc.fileName} (${doc.version})',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: BankerColors.navy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            _buildDocumentStatusBadge(doc.status),
            const SizedBox(width: 16),
            Container(width: 1, height: 16, color: BankerColors.line2),
            const SizedBox(width: 16),
            Text(
              'SME: $bankerName',
              style: const TextStyle(fontSize: 10, color: BankerColors.muted, fontWeight: FontWeight.w500),
            ),
            const SizedBox(width: 12),
            Text(
              'Uploaded: ${_formatDateTime(doc.uploadedAt)}',
              style: const TextStyle(fontSize: 10, color: BankerColors.muted, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: BankerColors.line2)),
          ),
          child: Row(
            children: [
              _buildDocumentSubTabButton('Quality Checklist', 'checklist'),
              _buildDocumentSubTabButton('Show comparative view', 'comparison'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_docDetailSubTab == 'checklist')
          _buildDocumentCheckpointsSection(doc)
        else
          _buildDocumentComparisonSection(doc),

        const SizedBox(height: 24),

        if (_docDetailSubTab == 'comparison' && doc.status != 'Approved' && doc.status != 'Reject')
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BankerColors.line)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF991B1B),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    backgroundColor: BankerColors.redSoft,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _updateStatusAndGoBack(doc.documentId, 'Reject', bankerName),
                  child: const Text('Reject and wait for internal review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BankerColors.navy,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onPressed: () => _updateStatusAndGoBack(doc.documentId, 'Approved', bankerName),
                  child: const Text('Proceed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDocumentSubTabButton(String label, String tabKey) {
    final isActive = _docDetailSubTab == tabKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _docDetailSubTab = tabKey;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? BankerColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive ? BankerColors.navy : BankerColors.muted,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateStatusAndGoBack(String documentId, String status, String actor) async {
    try {
      await ConversationService().updateDocumentStatus(documentId, status, actor);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'Approved' 
                ? 'Document status updated to Approved.' 
                : 'Document version rejected and logged in audit log.',
          ),
          backgroundColor: status == 'Approved' ? BankerColors.green : const Color(0xFF991B1B),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await _fetchDocuments();
      
      if (mounted) {
        setState(() {
          _selectedDocumentForAnalysis = null;
        });
      }
    } catch (e) {
      debugPrint('Error updating document status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update document status: ' + e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildDocumentCheckpointsSection(ProspectDocument doc) {
    if (_loadingDocCheckpoints) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
          ),
        ),
      );
    }

    if (_documentCheckpoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: BankerColors.cream,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BankerColors.line2),
        ),
        child: const Center(
          child: Text(
            'No quality checkpoints defined for this document.',
            style: TextStyle(fontSize: 11, color: BankerColors.muted),
          ),
        ),
      );
    }

    final confidenceScorePercent = (doc.confidenceScore * 100).toInt();
    final totalMajor = _documentCheckpoints.length;
    final verifiedMajor = _documentCheckpoints.where((c) => c.checked).length;

    final Map<String, List<ProspectCheckpoint>> grouped = {};
    for (final cp in _documentCheckpoints) {
      final cat = cp.checkpoint?.category ?? 'Other Checkpoints';
      grouped.putIfAbsent(cat, () => []).add(cp);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: BankerColors.blueSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BankerColors.blue.withOpacity(0.15)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics_outlined, size: 16, color: BankerColors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'AI Analysis Confidence: ' + confidenceScorePercent.toString() + '%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: BankerColors.blue,
                    ),
                  ),
                ],
              ),
              Text(
                verifiedMajor.toString() + ' of ' + totalMajor.toString() + ' major checkpoints verified',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: BankerColors.navy,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ...grouped.entries.map((entry) {
          final category = entry.key;
          final cps = entry.value;
          final isExpanded = _expandedDocCategories[category] ?? false;

          final checkedCount = cps.where((c) => c.checked).length;
          final totalCount = cps.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: BankerColors.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankerColors.line2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedDocCategories[category] = !isExpanded;
                    });
                  },
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: BankerColors.navy,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                checkedCount.toString() + ' of ' + totalCount.toString() + ' checkpoints verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: checkedCount == totalCount
                                      ? const Color(0xFF0F6E56)
                                      : BankerColors.muted2,
                                  fontWeight: checkedCount == totalCount
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: BankerColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: BankerColors.line2),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(46),
                            1: FlexColumnWidth(4),
                            2: FixedColumnWidth(150),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4),
                                  child: Center(
                                    child: Text(
                                      'VERIFIED',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: BankerColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Text(
                                    'CHECKPOINT REQUIREMENT',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: BankerColors.muted,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'VERIFICATION STATUS',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: BankerColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...cps.map((cp) {
                          final title = cp.checkpoint?.title ?? cp.checkpointId;
                          final description = cp.checkpoint?.description;
                          final hasMinis = cp.checkpoint?.miniCheckpoints.isNotEmpty ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: BankerColors.line2, width: 0.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(46),
                                1: FlexColumnWidth(4),
                                2: FixedColumnWidth(150),
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: hasMinis
                                        ? const Border(bottom: BorderSide(color: BankerColors.line, width: 0.5))
                                        : null,
                                  ),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: doc.status == 'Approved' ? null : () => _toggleDocumentMajorCheckpoint(cp),
                                          child: MouseRegion(
                                            cursor: doc.status == 'Approved' ? SystemMouseCursors.basic : SystemMouseCursors.click,
                                            child: Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                color: cp.checked ? BankerColors.blue : Colors.transparent,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: cp.checked ? BankerColors.blue : BankerColors.muted2,
                                                  width: 1.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: cp.checked
                                                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: BankerColors.ink,
                                            ),
                                          ),
                                          if (description != null && description.isNotEmpty) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              description,
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                color: BankerColors.muted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: cp.checked
                                            ? const Icon(Icons.check_circle_outline, size: 14, color: BankerColors.green)
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ),
                                if (hasMinis) ...[
                                  ...cp.checkpoint!.miniCheckpoints.asMap().entries.map((miniEntry) {
                                    final miniIdx = miniEntry.key;
                                    final mini = miniEntry.value;
                                    final isLastMini = miniIdx == cp.checkpoint!.miniCheckpoints.length - 1;
                                    final answer = cp.miniCheckpointAnswers[mini] ?? 'no';

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: isLastMini
                                            ? null
                                            : const Border(bottom: BorderSide(color: BankerColors.line, width: 0.5)),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Center(
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: BankerColors.muted2.withOpacity(0.55),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          child: Text(
                                            mini,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: BankerColors.ink,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildDocumentTriStateButton(
                                                  label: 'N/A',
                                                  isSelected: answer == 'na',
                                                  selectedBg: Colors.blueGrey.shade100,
                                                  selectedFg: Colors.blueGrey.shade800,
                                                  onTap: doc.status == 'Approved' ? null : () => _updateDocumentMiniCheckpointAnswer(cp, mini, 'na'),
                                                ),
                                                const SizedBox(width: 4),
                                                _buildDocumentTriStateButton(
                                                  label: 'Yes',
                                                  isSelected: answer == 'yes',
                                                  selectedBg: BankerColors.greenSoft,
                                                  selectedFg: const Color(0xFF0F6E56),
                                                  onTap: doc.status == 'Approved' ? null : () => _updateDocumentMiniCheckpointAnswer(cp, mini, 'yes'),
                                                ),
                                                const SizedBox(width: 4),
                                                _buildDocumentTriStateButton(
                                                  label: 'No',
                                                  isSelected: answer == 'no',
                                                  selectedBg: BankerColors.redSoft,
                                                  selectedFg: const Color(0xFF991B1B),
                                                  onTap: doc.status == 'Approved' ? null : () => _updateDocumentMiniCheckpointAnswer(cp, mini, 'no'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildDocumentComparisonSection(ProspectDocument doc) {
    final hasPrev = doc.previousVersionDocumentId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BankerColors.cream,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Row(
            children: [
              const Icon(Icons.compare_arrows_rounded, size: 16, color: BankerColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasPrev
                      ? 'Displaying version differences between the current version (' + doc.version + ') and the previous version.'
                      : 'This is the initial version of this document. No previous version was found for comparison.',
                  style: const TextStyle(fontSize: 11, color: BankerColors.navy, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (hasPrev) ...[
          const Text(
            'AI-GENERATED COMPARISON SUMMARY',
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1.2,
              color: BankerColors.navy,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankerColors.line2),
            ),
            child: SelectableText(
              doc.comparisonReport ?? 'No comparison report generated.',
              style: const TextStyle(
                fontSize: 11.5,
                fontFamily: 'Courier',
                color: BankerColors.ink,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        const Text(
          'AVAILABLE DOWNLOAD ACTIONS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 1.2,
            color: BankerColors.navy,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: BankerColors.blueSoft,
                foregroundColor: BankerColors.blue,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onPressed: () => _showMockDownloadNotification(doc.fileName),
              icon: const Icon(Icons.download, size: 14),
              label: const Text('Download Current Version', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            if (hasPrev) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BankerColors.blueSoft,
                  foregroundColor: BankerColors.blue,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _showMockDownloadNotification('Previous Version'),
                icon: const Icon(Icons.download, size: 14),
                label: const Text('Download Previous Version', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BankerColors.goldLight.withOpacity(0.2),
                  foregroundColor: BankerColors.gold,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _showMockDownloadNotification('AI Comparison Report'),
                icon: const Icon(Icons.assignment, size: 14),
                label: const Text('Download Comparison Report', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildDocumentTriStateButton({
    required String label,
    required bool isSelected,
    required Color selectedBg,
    required Color selectedFg,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: MouseRegion(
        cursor: onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            border: Border.all(
              color: isSelected ? selectedFg.withOpacity(0.5) : BankerColors.line2,
              width: isSelected ? 1 : 0.5,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.bold,
              color: isSelected ? selectedFg : BankerColors.muted,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildValidationCheckpointsSection() {
    if (_loadingCheckpoints) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
            ),
          ),
        ),
      );
    }

    if (_checkpoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final Map<String, List<ProspectCheckpoint>> grouped = {};
    for (final cp in _checkpoints) {
      final cat = cp.checkpoint?.category ?? 'Other';
      grouped.putIfAbsent(cat, () => []).add(cp);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Validation Standard Checkpoints',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: BankerColors.navy,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Mandatory validation checkpoints before article approval for AI systems',
          style: TextStyle(
            fontSize: 10,
            color: BankerColors.muted,
          ),
        ),
        const SizedBox(height: 8),
        ...grouped.entries.map((entry) {
          final category = entry.key;
          final cps = entry.value;
          final isExpanded = _expandedCategories[category] ?? false;

          final checkedCount = cps.where((c) => c.checked).length;
          final totalCount = cps.length;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: BankerColors.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankerColors.line2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () {
                    setState(() {
                      _expandedCategories[category] = !isExpanded;
                    });
                  },
                  borderRadius: isExpanded
                      ? const BorderRadius.vertical(top: Radius.circular(10))
                      : BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: BankerColors.navy,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$checkedCount of $totalCount checkpoints verified',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: checkedCount == totalCount
                                      ? const Color(0xFF0F6E56)
                                      : BankerColors.muted2,
                                  fontWeight: checkedCount == totalCount
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          size: 16,
                          color: BankerColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (isExpanded) ...[
                  const Divider(height: 1, color: BankerColors.line2),
                  Padding(
                    padding: const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Column header table for aligning labels
                        Table(
                          columnWidths: const {
                            0: FixedColumnWidth(46), // checkbox/indent width
                            1: FlexColumnWidth(4),
                            2: FixedColumnWidth(110),
                          },
                          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                          children: [
                            const TableRow(
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                                  child: Center(
                                    child: Text(
                                      'STATUS',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: BankerColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Text(
                                    'CHECKPOINT REQUIREMENT',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      color: BankerColors.muted,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'VERIFICATION',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: BankerColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Checkpoint cards list
                        ...cps.map((cp) {
                          final title = cp.checkpoint?.title ?? cp.checkpointId;
                          final description = cp.checkpoint?.description;
                          final hasMinis = cp.checkpoint?.miniCheckpoints.isNotEmpty ?? false;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: BankerColors.line2, width: 0.5),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Table(
                              columnWidths: const {
                                0: FixedColumnWidth(46), // checkbox/indent width
                                1: FlexColumnWidth(4),
                                2: FixedColumnWidth(110),
                              },
                              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                              children: [
                                // Major Checkpoint Row
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: hasMinis
                                        ? const Border(bottom: BorderSide(color: BankerColors.line, width: 0.5))
                                        : null,
                                  ),
                                  children: [
                                    // Col 1: Checkbox
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Center(
                                        child: GestureDetector(
                                          onTap: () => _toggleMajorCheckpoint(cp),
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: Container(
                                              width: 15,
                                              height: 15,
                                              decoration: BoxDecoration(
                                                color: cp.checked ? BankerColors.blue : Colors.transparent,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: cp.checked ? BankerColors.blue : BankerColors.muted2,
                                                  width: 1.5,
                                                ),
                                              ),
                                              alignment: Alignment.center,
                                              child: cp.checked
                                                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    // Col 2: Text Title & Description
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: BankerColors.ink,
                                            ),
                                          ),
                                          if (description != null && description.isNotEmpty) ...[
                                            const SizedBox(height: 1),
                                            Text(
                                              description,
                                              style: const TextStyle(
                                                fontSize: 9.5,
                                                color: BankerColors.muted,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    // Col 3: Done icon or empty
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: cp.checked
                                            ? const Icon(Icons.check_circle_outline, size: 14, color: BankerColors.green)
                                            : const SizedBox.shrink(),
                                      ),
                                    ),
                                  ],
                                ),
                                // Mini Checkpoint Rows
                                if (hasMinis) ...[
                                  ...cp.checkpoint!.miniCheckpoints.asMap().entries.map((miniEntry) {
                                    final miniIdx = miniEntry.key;
                                    final mini = miniEntry.value;
                                    final isLastMini = miniIdx == cp.checkpoint!.miniCheckpoints.length - 1;
                                    final answer = cp.miniCheckpointAnswers[mini] ?? 'no';

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: isLastMini
                                            ? null
                                            : const Border(bottom: BorderSide(color: BankerColors.line, width: 0.5)),
                                      ),
                                      children: [
                                        // Col 1: Custom circular dot bullet
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8),
                                          child: Center(
                                            child: Container(
                                              width: 6,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                color: BankerColors.muted2.withOpacity(0.55),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Col 2: Mini requirement text
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                          child: Text(
                                            mini,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: BankerColors.ink,
                                            ),
                                          ),
                                        ),
                                        // Col 3: Tri-state buttons (Yes / No)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                _buildTriStateButton(
                                                  label: 'Yes',
                                                  isSelected: answer == 'yes',
                                                  selectedBg: BankerColors.greenSoft,
                                                  selectedFg: const Color(0xFF0F6E56),
                                                  onTap: () => _setMiniAnswer(cp, mini, 'yes'),
                                                ),
                                                const SizedBox(width: 4),
                                                _buildTriStateButton(
                                                  label: 'No',
                                                  isSelected: answer == 'no',
                                                  selectedBg: BankerColors.redSoft,
                                                  selectedFg: const Color(0xFF991B1B),
                                                  onTap: () => _setMiniAnswer(cp, mini, 'no'),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
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

  /// Returns the prospect slot for a given notification, using the explicit
  /// [prospectSlot] field on the item (reliable with real API data).
  int _notificationIndexForItem(NotificationItem item) {
    return item.prospectSlot;
  }

  Widget _buildNextStepsTab(CrmProspect prospect) {
    final docsTotal = prospect.docsTotalCount;
    final docsReceived = prospect.docsReceivedCount;
    final materialsReadText = prospect.materialsReadText;
    final materialsReadSub = prospect.materialsReadSub;
    final prospects = ref.read(bankerProspectsProvider);
    final activeBanker = ref.read(activeBankerProvider);
    final bankerName = activeBanker?.name ?? activeBanker?.email ?? 'Your Banker';

    // Collect notifications assigned to this prospect.
    // getProspectForNotification maps by list index (0→Meeting, 1→CallSummary, 2→NewGuide).
    // We compare the prospect's position in the list rather than its UUID so this works
    // with real API data where UUIDs won't match the mock service's fixed indices.
    final prospectIndex = prospects.isEmpty ? -1 : prospects.indexWhere((p) => p.id == prospect.id);
    final List<(int, NotificationItem)> prospectNotifications = [];
    if (prospectIndex >= 0) {
      for (int i = 0; i < _notifService.activeHubNotifications.length; i++) {
        final item = _notifService.activeHubNotifications[i];
        // Determine which index this notification is assigned to
        final assignedIndex = prospects.isEmpty
            ? 0
            : _notificationIndexForItem(item) % prospects.length;
        if (assignedIndex == prospectIndex) {
          final localized = localizeNotification(
            item,
            bankerName,
            isBanker: true,
            prospectName: prospect.name,
            founderName: prospect.founderName,
          );
          prospectNotifications.add((i, localized));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile details at top
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: BankerColors.cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${prospect.name.toUpperCase()} PROFILE DETAILS',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  color: BankerColors.navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left details (Company details)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInlineDetailRow('Industry', prospect.sector),
                        _buildInlineDetailRow('Stage', prospect.stage),
                        _buildInlineDetailRow('Headcount', prospect.headcount),
                        _buildInlineDetailRow('Incorporated', prospect.incorporated ? 'Yes' : 'No'),
                        if (prospect.priorities.isNotEmpty)
                          _buildInlineDetailRow('Priorities', prospect.priorities.join(', ')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Right details (Contact details)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInlineDetailRow('Founder', prospect.founderName),
                        _buildInlineDetailRow('Email', prospect.email),
                        if (prospect.phoneNumber.isNotEmpty)
                          _buildInlineDetailRow('Phone', prospect.phoneNumber),
                        _buildInlineDetailRow('Company', prospect.name),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // 1. Stats Row
        Row(
          children: [
            Expanded(
              child: _buildPanelStatCard(
                label: 'Profile',
                value: '${(prospect.profileProgress * 100).toInt()}%',
                sub: prospect.profileProgress >= 0.7 ? 'Nearly full signal' : 'Building context',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPanelStatCard(
                label: 'Materials read',
                value: materialsReadText,
                sub: materialsReadSub.isEmpty ? '—' : materialsReadSub,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPanelStatCard(
                label: 'Docs received',
                value: docsTotal > 0 ? '$docsReceived/$docsTotal' : 'None',
                sub: docsReceived == docsTotal && docsTotal > 0
                    ? 'All uploaded'
                    : 'Financials missing',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 2. Attributes Collected from Calls Section
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Attributes collected from calls',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.navy),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (_loadingFullProfile)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
              ),
            ),
          )
        else if (_fullProfile == null || _fullProfile!.aiAttributesHistorical.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: BankerColors.cream,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankerColors.line2),
            ),
            child: const Center(
              child: Text(
                'No attributes collected from calls yet.',
                style: TextStyle(fontSize: 11, color: BankerColors.muted),
              ),
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: BankerColors.line2),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: _fullProfile!.aiAttributesHistorical.entries.map((entry) {
                final valStr = entry.value.toString();
                final prevIndex = valStr.indexOf(' (Previously: ');
                Widget valueWidget;
                if (prevIndex != -1) {
                  final currentVal = valStr.substring(0, prevIndex);
                  final prevVal = valStr.substring(prevIndex);
                  valueWidget = RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 11, color: BankerColors.ink, fontFamily: 'Outfit'),
                      children: [
                        TextSpan(text: currentVal, style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(
                          text: prevVal,
                          style: const TextStyle(
                            color: BankerColors.muted2,
                            fontStyle: FontStyle.italic,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  valueWidget = Text(
                    valStr,
                    style: const TextStyle(fontSize: 11, color: BankerColors.ink),
                  );
                }

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: BankerColors.line, width: 0.5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          _formatAttributeLabel(entry.key),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: BankerColors.navy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 5,
                        child: valueWidget,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEduTag(String tag) {
    Color bg = BankerColors.amberSoft;
    Color fg = const Color(0xFF7C5410);

    if (tag == 'Event') {
      bg = BankerColors.blueSoft;
      fg = const Color(0xFF185FA5);
    } else if (tag == 'Explainer') {
      bg = BankerColors.greenSoft;
      fg = const Color(0xFF0F6E56);
    } else if (tag == 'Guide') {
      bg = BankerColors.purpleSoft;
      fg = const Color(0xFF4B43B6);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        tag,
        style: TextStyle(fontSize: 9, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPanelStatCard({required String label, required String value, required String sub}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: BankerColors.cream,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'DM Serif Display',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BankerColors.navy,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: const TextStyle(fontSize: 10, color: BankerColors.muted),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInlineDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: BankerColors.muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                color: BankerColors.ink,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return Icons.payments_outlined;
    if (c.contains('treasury')) return Icons.monitor_heart_outlined;
    if (c.contains('card')) return Icons.credit_card_outlined;
    if (c.contains('international') || c.contains('cross-currency')) {
      return Icons.public_outlined;
    }
    if (c.contains('banking')) return Icons.account_balance_wallet_outlined;
    if (c.contains('credit') || c.contains('lending')) {
      return Icons.attach_money_rounded;
    }
    return Icons.category_outlined;
  }

  Color _getTintForCategory(String category) {
    final c = category.toLowerCase();
    if (c.contains('payment')) return const Color(0xFF7C3AED);
    if (c.contains('treasury')) return const Color(0xFF1D9E75);
    if (c.contains('card')) return const Color(0xFF1A7B99);
    if (c.contains('international') || c.contains('cross-currency')) {
      return const Color(0xFF0891B2);
    }
    if (c.contains('banking')) return const Color(0xFF1A7B99);
    if (c.contains('credit') || c.contains('lending')) {
      return const Color(0xFF996715);
    }
    return const Color(0xFF64748B);
  }

  Widget _buildRecommendedProductsTab(CrmProspect prospect) {
    if (_loadingProducts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No recommended products found for this prospect.',
          style: TextStyle(fontSize: 11, color: BankerColors.muted),
        ),
      );
    }

    final sorted = List<ProductPublic>.from(_products)
      ..sort((a, b) => (b.matchScore ?? 0).compareTo(a.matchScore ?? 0));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          cleanBrandingText('Recommended J.P. Morgan products matching stage & sector fit:', ref.watch(brandingProvider)),
          style: const TextStyle(fontSize: 11, color: BankerColors.muted2),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sorted.map((product) {
            final icon = _getIconForCategory(product.category);
            final tint = _getTintForCategory(product.category);

            return SizedBox(
              width: 320.0,
              child: ProductCard(
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
                prospectId: prospect.id,
                onTap: () {
                  final screenWidth = MediaQuery.of(context).size.width;
                  final isDesktop = screenWidth >= 1180;
                  if (isDesktop) {
                    showDialog(
                      context: context,
                      builder: (_) => ProductDetailModal(
                        product: product,
                        prospectId: prospect.id,
                      ),
                    );
                  } else {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ProductDetailModal(
                        product: product,
                        prospectId: prospect.id,
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDataScienceTab(CrmProspect prospect) {
    if (_loadingDsDetails || _runningDsScoring) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
              ),
              const SizedBox(height: 16),
              const Text(
                'Analyzing conversion metrics, chat history, and uploaded documents...',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: BankerColors.muted2, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      );
    }

    if (_dsDetails == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.analytics_outlined, size: 48, color: BankerColors.muted),
              const SizedBox(height: 16),
              const Text(
                'No prediction data available yet.',
                style: TextStyle(fontSize: 13, color: BankerColors.ink, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Run the Data Science pipeline to score this prospect and generate predictions.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: BankerColors.muted2),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: BankerColors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _runDsScoring,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                label: const Text('Calculate Scores', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final ds = _dsDetails!;
    final probColor = ds.conversionProbability >= 65
        ? const Color(0xFFE0533C)
        : (ds.conversionProbability >= 35 ? BankerColors.gold : BankerColors.blue);

    // Extract breakdown lists
    final positives = ds.scoreBreakdownJson['positives'] as List? ?? [];
    final negatives = ds.scoreBreakdownJson['negatives'] as List? ?? [];
    final recommendedServices = ds.recommendedServicesJson.cast<Map<String, dynamic>>();
    final rawParams = ds.rawFeaturesJson;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Action Bar at the top of the tab
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'CONVERSION PREDICTION MODEL SUMMARY',
                style: TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              InkWell(
                onTap: _runDsScoring,
                borderRadius: BorderRadius.circular(4),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded, size: 14, color: BankerColors.blue),
                      SizedBox(width: 4),
                      Text('Recalculate Scores', style: TextStyle(fontSize: 10, color: BankerColors.blue, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metrics Summary Row
          Row(
            children: [
              // Lead Temp Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BankerColors.line2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('LEAD TEMPERATURE', style: TextStyle(fontSize: 9, color: BankerColors.muted2, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _buildLeadBadge(ds.leadTemperature),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Conversion Prob Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BankerColors.line2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('CONVERSION PROBABILITY', style: TextStyle(fontSize: 9, color: BankerColors.muted2, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: ds.conversionProbability / 100.0,
                                minHeight: 8,
                                backgroundColor: BankerColors.cream,
                                valueColor: AlwaysStoppedAnimation<Color>(probColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${ds.conversionProbability.toInt()}%',
                            style: TextStyle(fontSize: 12, color: probColor, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Sales Priority Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: BankerColors.line2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('SALES PRIORITY', style: TextStyle(fontSize: 9, color: BankerColors.muted2, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      _buildPriorityBadge(ds.salesPriority),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Positive Drivers & Friction Factors Split
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Positive Drivers
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.trending_up_rounded, size: 16, color: BankerColors.green),
                        SizedBox(width: 6),
                        Text(
                          'Positive Drivers',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.green),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (positives.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BankerColors.cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No positive drivers detected.', style: TextStyle(fontSize: 11, color: BankerColors.muted2)),
                      )
                    else
                      ...positives.map((pos) {
                        final map = pos as Map;
                        final name = map['label'] ?? map['key'] ?? '';
                        final optionLabel = map['option_label'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border.all(color: const Color(0xFFDCFCE7)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('✦ ', style: TextStyle(color: BankerColors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                              Expanded(
                                child: Text(
                                  optionLabel.isNotEmpty ? '$name: $optionLabel' : '$name',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Friction/Risk Factors
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.report_problem_outlined, size: 16, color: const Color(0xFFE0533C)),
                        SizedBox(width: 6),
                        Text(
                          'Risk & Friction Factors',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFFE0533C)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (negatives.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BankerColors.cream,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('No friction factors detected.', style: TextStyle(fontSize: 11, color: BankerColors.muted2)),
                      )
                    else
                      ...negatives.map((neg) {
                        final map = neg as Map;
                        final name = map['label'] ?? map['key'] ?? '';
                        final optionLabel = map['option_label'] ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(color: const Color(0xFFFEE2E2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('⚠ ', style: TextStyle(color: const Color(0xFFE0533C), fontWeight: FontWeight.bold, fontSize: 12)),
                              Expanded(
                                child: Text(
                                  optionLabel.isNotEmpty ? '$name: $optionLabel' : '$name',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          const Text(
            'MODEL-RECOMMENDED BANKING SERVICES',
            style: TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          if (recommendedServices.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: BankerColors.cream,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: BankerColors.line2),
              ),
              child: const Text('No recommended services for this stage.', style: TextStyle(fontSize: 11, color: BankerColors.muted2)),
            )
          else
            Column(
              children: recommendedServices.map((prod) {
                final String name = prod['name'] ?? '';
                final String reason = prod['reason'] ?? '';
                final String priority = prod['priority'] ?? 'Low';
                final String icon = prod['icon'] ?? '💼';
                final String sme = prod['sme'] ?? '';
                final String session = prod['session'] ?? '';

                Color priBg = const Color(0xFFF3F4F6);
                Color priFg = const Color(0xFF374151);
                if (priority == 'High') {
                  priBg = const Color(0xFFE1F5EE);
                  priFg = BankerColors.green;
                } else if (priority == 'Medium') {
                  priBg = const Color(0xFFFAEEDA);
                  priFg = const Color(0xFFD97706);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: BankerColors.line2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: BankerColors.cream,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(icon, style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.navy)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: priBg, borderRadius: BorderRadius.circular(4)),
                                  child: Text('$priority Fit', style: TextStyle(color: priFg, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(reason, style: const TextStyle(fontSize: 10.5, color: BankerColors.muted, height: 1.3)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (session.isNotEmpty) ...[
                                  const Icon(Icons.forum_outlined, size: 10, color: BankerColors.muted2),
                                  const SizedBox(width: 4),
                                  Text(session, style: const TextStyle(fontSize: 9.5, color: BankerColors.muted2)),
                                  const SizedBox(width: 12),
                                ],
                                if (sme.isNotEmpty) ...[
                                  const Icon(Icons.person_outline, size: 10, color: BankerColors.muted2),
                                  const SizedBox(width: 4),
                                  Text('SME: $sme', style: const TextStyle(fontSize: 9.5, color: BankerColors.muted2)),
                                ],
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MODEL SCORING PARAMETERS (SIMULATION SANDBOX)',
                style: TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.bold, letterSpacing: 0.8),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _isSandboxDirty ? () => _runDsScoring(useSimulation: false) : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      side: BorderSide(color: _isSandboxDirty ? BankerColors.muted : BankerColors.muted.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Reset Override',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isSandboxDirty ? BankerColors.muted : BankerColors.muted.withOpacity(0.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSandboxDirty ? () => _runDsScoring(useSimulation: true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSandboxDirty ? BankerColors.blue : BankerColors.blue.withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(
                      'Apply Simulation',
                      style: TextStyle(
                        fontSize: 10,
                        color: _isSandboxDirty ? Colors.white : Colors.white.withOpacity(0.6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildEditableFeaturesTable(ds.scoreBreakdownJson, ds.isEngagementSchema),

        ],
      ),
    );
  }

  Widget _buildSuggestedQuestionsTab(CrmProspect prospect) {
    if (_loadingQuestions) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
          ),
        ),
      );
    }

    final questions = (_suggestedQuestions.isNotEmpty ? _suggestedQuestions : [
      'How can J.P. Morgan help us extend our runway given our current stage?',
      'What are the requirements and onboarding timelines for setting up multi-currency accounts or global banking at J.P. Morgan?',
      'How do your transaction fees and payment gateway integrations compare to standard processors we are using?',
      'What venture debt options are available for us to complement our upcoming fundraising rounds?',
    ]).map((q) => cleanBrandingText(q, ref.watch(brandingProvider))).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Questions the prospect might ask you during the relationship call (to prepare for):',
          style: TextStyle(fontSize: 11, color: BankerColors.muted2),
        ),
        const SizedBox(height: 12),
        ...questions.map((q) => Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: BankerColors.cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: BankerColors.line2),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: BankerColors.blue,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  q,
                  style: const TextStyle(
                    fontSize: 12,
                    color: BankerColors.ink,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Copy to clipboard',
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: q));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Question copied to clipboard!'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: BankerColors.muted2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildEditableFeaturesTable(Map<String, dynamic> scoreBreakdownJson, bool isEngagement) {
    final featuresList = scoreBreakdownJson['features'] as List? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: BankerColors.line2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Table(
        columnWidths: const {
          0: FlexColumnWidth(4),
          1: FlexColumnWidth(5),
        },
        border: TableBorder.symmetric(
          inside: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
        ),
        children: [
          // Header
          const TableRow(
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'PARAMETER / WEIGHT',
                  style: TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  'SIMULATED VALUE',
                  style: TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),

          // Rows
          ...featuresList.map((f) {
            final map = f as Map;
            final key = map['key'] as String? ?? '';
            final label = map['label'] as String? ?? '';
            final weight = map['weight'] as num? ?? 0;
            final currentOption = map['option_label'] as String? ?? 'Missing';

            final options = getOptionsForKey(key);
            final displayValue = _getDisplayValueForSchemaKey(key, currentOption);

            return TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Weight: $weight%',
                        style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: options.isEmpty
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              currentOption,
                              style: const TextStyle(fontSize: 11, color: BankerColors.muted2, fontStyle: FontStyle.italic),
                            ),
                          ),
                        )
                      : Container(
                          height: 38,
                          alignment: Alignment.centerLeft,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: options.contains(displayValue) ? displayValue : options.first,
                              icon: const Icon(Icons.arrow_drop_down, color: BankerColors.blue, size: 20),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              style: const TextStyle(fontSize: 11, color: BankerColors.blue, fontWeight: FontWeight.w600),
                              items: options.map((opt) {
                                return DropdownMenuItem<String>(
                                  value: opt,
                                  child: Text(opt, style: const TextStyle(fontSize: 11, color: BankerColors.ink)),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                if (newVal != null) {
                                  setState(() {
                                    _updateRawFeaturesFromOption(key, newVal);
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  List<String> getOptionsForKey(String key) {
    switch (key) {
      case 'intent':
        return [
          'Treasury Management',
          'Merchant / Commerce Services',
          'Credit / Startup Financing',
          'Payments (Payables & Receivables)',
          'Commercial Cards / Expense Management',
          'International / FX / Cross-Border',
          'Trade & Working Capital',
          'Core Banking (general)',
          'General Inquiry / Unspecified'
        ];
      case 'revenue':
        return [
          'Pre-revenue',
          '< \$500K ARR',
          '\$500K – \$1M ARR',
          '\$1M – \$2M ARR',
          '\$2M – \$5M ARR',
          '\$5M – \$20M ARR',
          '\$20M+ ARR'
        ];
      case 'runway':
        return [
          '< 6 Months',
          '6 – 12 Months',
          '12 – 18 Months',
          '18 – 24 Months',
          '24+ Months / Profitable'
        ];
      case 'funding':
        return [
          'Bootstrapped / Pre-Seed',
          'Seed',
          'Series A',
          'Series B',
          'Series C+',
          'Public / IPO'
        ];
      case 'investor':
        return [
          'No Institutional Investor',
          'Tier 3 / Angel',
          'Tier 2 VC',
          'Tier 1 VC'
        ];
      case 'profitability':
        return [
          'Significant Losses',
          'Moderate Losses',
          'Near Breakeven',
          'Profitable'
        ];
      case 'next_raise':
        return [
          'Not Planning to Raise',
          '12+ Months Out',
          '6 – 12 Months',
          'Within 6 Months'
        ];
      case 'international':
        return [
          'Domestic Only',
          'One Additional Country',
          'Multiple Countries',
          'Global Operations'
        ];
      case 'credit_need':
        return ['No', 'Yes'];
      case 'strategic_priority':
        return [
          'Product / MVP Build-Out',
          'Compliance',
          'Cost Reduction',
          'Efficiency',
          'Risk Management',
          'Expansion'
        ];
      case 'financial_bottleneck':
        return [
          'None',
          'FX Volatility',
          'Payment Delays',
          'Access to Credit',
          'Cash Flow'
        ];
      case 'pipeline_stage':
        return [
          'Closed Lost',
          'New Lead',
          'MQL',
          'SQL',
          'Opportunity',
          'Negotiation',
          'Closed Won'
        ];
      case 'sales_readiness':
        return [
          'Neither demo nor budget confirmed',
          'One of demo requested / budget confirmed',
          'Demo requested and budget confirmed'
        ];
      case 'decision_maker':
        return ['Not yet identified', 'Identified'];
      case 'competitive_risk':
        return ['No competitor mentioned', 'Competitor mentioned'];
      default:
        return [];
    }
  }

  String _getDisplayValueForSchemaKey(String key, String currentOption) {
    switch (key) {
      case 'intent':
        final val = _simulatedFeatures['primary_intent'];
        if (val != null) return _mapRawIntentToOption(val.toString());
        break;
      case 'revenue':
        final val = _simulatedFeatures['annual_revenue'];
        if (val != null) return _mapRawRevenueToOption(val);
        break;
      case 'runway':
        final val = _simulatedFeatures['runway_months'];
        if (val != null) return _mapRawRunwayToOption(val);
        break;
      case 'funding':
        final val = _simulatedFeatures['last_round_stage'];
        if (val != null) return val.toString();
        break;
      case 'investor':
        final t1 = _simulatedFeatures['tier_1_investor_flag'];
        final type = _simulatedFeatures['investor_types'];
        return _mapRawInvestorToOption(t1, type);
      case 'profitability':
        final val = _simulatedFeatures['profitability_status'];
        if (val != null) return val.toString();
        break;
      case 'next_raise':
        final f6 = _simulatedFeatures['fundraising_within_6_months_flag'];
        final timing = _simulatedFeatures['next_raise_timing'];
        return _mapRawNextRaiseToOption(f6, timing);
      case 'international':
        final exposure = _simulatedFeatures['fx_exposure_level'];
        final mc = _simulatedFeatures['multi_currency_flag'];
        return _mapRawInternationalToOption(exposure, mc);
      case 'credit_need':
        final val = _simulatedFeatures['credit_need_flag'];
        if (val != null) return (val == true || val == 'true') ? 'Yes' : 'No';
        break;
      case 'strategic_priority':
        final val = _simulatedFeatures['top_priority_1'];
        if (val != null) return val.toString();
        break;
      case 'financial_bottleneck':
        final val = _simulatedFeatures['primary_financial_bottleneck'];
        if (val != null) return val.toString();
        break;
      case 'pipeline_stage':
        final val = _simulatedFeatures['crm_pipeline_stage'];
        if (val != null) return val.toString();
        break;
      case 'sales_readiness':
        final demo = _simulatedFeatures['demo_requested'];
        final budget = _simulatedFeatures['budget_confirmed_flag'];
        return _mapRawSalesReadinessToOption(demo, budget);
      case 'decision_maker':
        final val = _simulatedFeatures['decision_maker_identified_flag'];
        if (val != null) return (val == true || val == 'true') ? 'Identified' : 'Not yet identified';
        break;
      case 'competitive_risk':
        final val = _simulatedFeatures['competitor_mentioned_flag'];
        if (val != null) return (val == true || val == 'true') ? 'Competitor mentioned' : 'No competitor mentioned';
        break;
    }
    return currentOption;
  }

  String _mapRawIntentToOption(String raw) {
    final t = raw.replaceAll('_', ' ').toLowerCase();
    if (t.contains('treasury') || t.contains('cash management') || t.contains('sweep')) return 'Treasury Management';
    if (t.contains('credit') || t.contains('financing') || t.contains('loan') || t.contains('debt')) return 'Credit / Startup Financing';
    if (t.contains('merchant') || t.contains('commerce') || t.contains('card program')) return 'Merchant / Commerce Services';
    if (t.contains('payment') || t.contains('payable') || t.contains('receivable') || t.contains('ach') || t.contains('invoicing')) return 'Payments (Payables & Receivables)';
    if (t.contains('fx') || t.contains('international') || t.contains('cross-border') || t.contains('multi-currency')) return 'International / FX / Cross-Border';
    if (t.contains('trade') || t.contains('working capital')) return 'Trade & Working Capital';
    return 'General Inquiry / Unspecified';
  }

  String _mapRawRevenueToOption(dynamic raw) {
    if (raw == null) return 'Pre-revenue';
    final s = raw.toString().toLowerCase();
    if (s.contains('pre-revenue')) return 'Pre-revenue';
    if (s.contains('< \$500k')) return '< \$500K ARR';
    if (s.contains('500k – \$1m') || s.contains('500k - \$1m')) return '\$500K – \$1M ARR';
    if (s.contains('1m – \$2m') || s.contains('1m - \$2m')) return '\$1M – \$2M ARR';
    if (s.contains('2m – \$5m') || s.contains('2m - \$5m')) return '\$2M – \$5M ARR';
    if (s.contains('5m – \$20m') || s.contains('5m - \$20m')) return '\$5M – \$20M ARR';
    if (s.contains('20m+')) return '\$20M+ ARR';

    final clean = s.replaceAll(RegExp(r'[^\d.]'), '');
    final val = double.tryParse(clean);
    if (val == null || val <= 0) return 'Pre-revenue';
    if (val < 500000) return '< \$500K ARR';
    if (val < 1000000) return '\$500K – \$1M ARR';
    if (val < 2000000) return '\$1M – \$2M ARR';
    if (val < 5000000) return '\$2M – \$5M ARR';
    if (val < 20000000) return '\$5M – \$20M ARR';
    return '\$20M+ ARR';
  }

  String _mapRawRunwayToOption(dynamic raw) {
    if (raw == null) return '6 – 12 Months';
    final s = raw.toString();
    final val = double.tryParse(s.replaceAll(RegExp(r'[^\d.]'), ''));
    if (val == null) return '6 – 12 Months';
    if (val < 6) return '< 6 Months';
    if (val < 12) return '6 – 12 Months';
    if (val < 18) return '12 – 18 Months';
    if (val < 24) return '18 – 24 Months';
    return '24+ Months / Profitable';
  }

  String _mapRawInvestorToOption(dynamic t1, dynamic type) {
    final isT1 = (t1 == true || t1 == 'true');
    if (isT1) return 'Tier 1 VC';
    final t = type?.toString().toLowerCase() ?? '';
    if (t.contains('angel') || t.contains('family office')) return 'Tier 3 / Angel';
    if (t.contains('venture') || t.contains('corporate') || t.contains('strategic')) return 'Tier 2 VC';
    return 'No Institutional Investor';
  }

  String _mapRawNextRaiseToOption(dynamic f6, dynamic timing) {
    final isF6 = (f6 == true || f6 == 'true');
    if (isF6) return 'Within 6 Months';
    final t = timing?.toString().toLowerCase() ?? '';
    if (t.contains('currently raising') || t.contains('within 6 months')) return 'Within 6 Months';
    if (t.contains('6 – 12 months') || t.contains('6-12 months')) return '6 – 12 Months';
    if (t.contains('12+ months') || t.contains('12-15 months') || t.contains('15 months')) return '12+ Months Out';
    return 'Not Planning to Raise';
  }

  String _mapRawInternationalToOption(dynamic exposure, dynamic mc) {
    final exp = exposure?.toString().toLowerCase() ?? '';
    if (exp.contains('material') || exp.contains('global')) return 'Global Operations';
    if (exp.contains('significant')) return 'Multiple Countries';
    if (exp.contains('minor')) return 'One Additional Country';
    if (exp.contains('none')) return 'Domestic Only';
    final isMc = (mc == true || mc == 'true');
    if (isMc) return 'Multiple Countries';
    return 'Domestic Only';
  }

  String _mapRawSalesReadinessToOption(dynamic demo, dynamic budget) {
    final isDemo = (demo == true || demo == 'true');
    final isBudget = (budget == true || budget == 'true');
    if (isDemo && isBudget) return 'Demo requested and budget confirmed';
    if (isDemo || isBudget) return 'One of demo requested / budget confirmed';
    return 'Neither demo nor budget confirmed';
  }

  void _updateRawFeaturesFromOption(String key, String selectedOption) {
    setState(() {
      _isSandboxDirty = true;
    });
    switch (key) {
      case 'intent':
        _simulatedFeatures['primary_intent'] = selectedOption;
        break;
      case 'revenue':
        _simulatedFeatures['annual_revenue'] = selectedOption;
        break;
      case 'runway':
        if (selectedOption == '< 6 Months') _simulatedFeatures['runway_months'] = 3;
        else if (selectedOption == '6 – 12 Months') _simulatedFeatures['runway_months'] = 9;
        else if (selectedOption == '12 – 18 Months') _simulatedFeatures['runway_months'] = 15;
        else if (selectedOption == '18 – 24 Months') _simulatedFeatures['runway_months'] = 20;
        else _simulatedFeatures['runway_months'] = 26;
        break;
      case 'funding':
        _simulatedFeatures['last_round_stage'] = selectedOption;
        break;
      case 'investor':
        if (selectedOption == 'No Institutional Investor') {
          _simulatedFeatures['tier_1_investor_flag'] = false;
          _simulatedFeatures['investor_types'] = '';
        } else if (selectedOption == 'Tier 3 / Angel') {
          _simulatedFeatures['tier_1_investor_flag'] = false;
          _simulatedFeatures['investor_types'] = 'Angel';
        } else if (selectedOption == 'Tier 2 VC') {
          _simulatedFeatures['tier_1_investor_flag'] = false;
          _simulatedFeatures['investor_types'] = 'Venture';
        } else {
          _simulatedFeatures['tier_1_investor_flag'] = true;
          _simulatedFeatures['investor_types'] = 'crossover';
        }
        break;
      case 'profitability':
        _simulatedFeatures['profitability_status'] = selectedOption;
        break;
      case 'next_raise':
        if (selectedOption == 'Not Planning to Raise') {
          _simulatedFeatures['fundraising_within_6_months_flag'] = false;
          _simulatedFeatures['next_raise_timing'] = 'Not planning';
        } else if (selectedOption == '12+ Months Out') {
          _simulatedFeatures['fundraising_within_6_months_flag'] = false;
          _simulatedFeatures['next_raise_timing'] = '15 months';
        } else if (selectedOption == '6 – 12 Months') {
          _simulatedFeatures['fundraising_within_6_months_flag'] = false;
          _simulatedFeatures['next_raise_timing'] = '9 months';
        } else {
          _simulatedFeatures['fundraising_within_6_months_flag'] = true;
          _simulatedFeatures['next_raise_timing'] = 'currently raising';
        }
        break;
      case 'international':
        if (selectedOption == 'Domestic Only') {
          _simulatedFeatures['fx_exposure_level'] = 'None';
          _simulatedFeatures['multi_currency_flag'] = false;
        } else if (selectedOption == 'One Additional Country') {
          _simulatedFeatures['fx_exposure_level'] = 'Minor';
          _simulatedFeatures['multi_currency_flag'] = false;
        } else if (selectedOption == 'Multiple Countries') {
          _simulatedFeatures['fx_exposure_level'] = 'Significant';
          _simulatedFeatures['multi_currency_flag'] = true;
        } else {
          _simulatedFeatures['fx_exposure_level'] = 'Material';
          _simulatedFeatures['multi_currency_flag'] = true;
        }
        break;
      case 'credit_need':
        _simulatedFeatures['credit_need_flag'] = (selectedOption == 'Yes');
        break;
      case 'strategic_priority':
        _simulatedFeatures['top_priority_1'] = selectedOption;
        break;
      case 'financial_bottleneck':
        _simulatedFeatures['primary_financial_bottleneck'] = selectedOption;
        break;
      case 'pipeline_stage':
        _simulatedFeatures['crm_pipeline_stage'] = selectedOption;
        break;
      case 'sales_readiness':
        if (selectedOption == 'Neither demo nor budget confirmed') {
          _simulatedFeatures['demo_requested'] = false;
          _simulatedFeatures['budget_confirmed_flag'] = false;
        } else if (selectedOption == 'One of demo requested / budget confirmed') {
          _simulatedFeatures['demo_requested'] = true;
          _simulatedFeatures['budget_confirmed_flag'] = false;
        } else {
          _simulatedFeatures['demo_requested'] = true;
          _simulatedFeatures['budget_confirmed_flag'] = true;
        }
        break;
      case 'decision_maker':
        _simulatedFeatures['decision_maker_identified_flag'] = (selectedOption == 'Identified');
        break;
      case 'competitive_risk':
        _simulatedFeatures['competitor_mentioned_flag'] = (selectedOption == 'Competitor mentioned');
        break;
    }
  }

  // --- ACTIONS MODALS INSIDE PANEL ---

  void _showDocModal(BuildContext context, CrmProspect prospect) {
    final docsAvailable = [
      {'name': 'Bank statements (last 3 months)', 'meta': 'Helps assess cash management maturity'},
      {'name': '18-month cash flow projection', 'meta': 'Required for credit facility conversations'},
      {'name': 'Cap table summary', 'meta': 'Useful for understanding ownership and dilution'},
      {'name': 'Board deck (most recent)', 'meta': 'Context on direction and burn rate'},
      {'name': 'Existing bank agreements', 'meta': 'Needed if switching or supplementing current banking'},
    ];

    final Set<int> selectedIndices = {};
    String search = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredDocs = docsAvailable.where((d) => (d['name'] as String).toLowerCase().contains(search.toLowerCase())).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Request a document',
                          style: TextStyle(
                            fontFamily: 'DM Serif Display',
                            fontSize: 16,
                            color: BankerColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: BankerColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BankerColors.line2),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() => search = val);
                        },
                        style: const TextStyle(fontSize: 11, color: BankerColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Search document types…',
                          hintStyle: TextStyle(color: BankerColors.muted2),
                          prefixIcon: Icon(Icons.search, size: 14, color: BankerColors.muted2),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(filteredDocs.length, (idx) {
                            final docItem = filteredDocs[idx];
                            final originalIdx = docsAvailable.indexWhere((element) => element['name'] == docItem['name']);
                            final isSel = selectedIndices.contains(originalIdx);

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSel) {
                                    selectedIndices.remove(originalIdx);
                                  } else {
                                    selectedIndices.add(originalIdx);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel ? BankerColors.blueSoft : Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: isSel ? BankerColors.blue : BankerColors.line),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            docItem['name']!,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.ink),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            docItem['meta']!,
                                            style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: isSel,
                                      activeColor: BankerColors.blue,
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (isSel) {
                                            selectedIndices.remove(originalIdx);
                                          } else {
                                            selectedIndices.add(originalIdx);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BankerColors.line2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: BankerColors.ink, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedIndices.isEmpty) return;
                            final List<String> docNames = [];
                            for (var idx in selectedIndices) {
                              docNames.add(docsAvailable[idx]['name']!);
                            }
                            ref.read(bankerProspectsProvider.notifier).addDocumentRequest(prospect.id, docNames);
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BankerColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Request selected', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignModal(BuildContext context, CrmProspect prospect) {
    final eduAvailable = [
      {
        'title': 'Running a disciplined startup treasury',
        'tag': 'Explainer',
        'color': BankerColors.green,
        'meta': '7 min · Operations · Seed+'
      },
      {
        'title': 'Office hours with Innovation Banking',
        'tag': 'Event',
        'color': BankerColors.blue,
        'meta': 'May 12 · 3:30 PM ET · 45 min'
      },
      {
        'title': 'Hiring your first CFO: what to look for',
        'tag': 'Guide',
        'color': const Color(0xFF7F77DD),
        'meta': '6 min · Series A · Team building'
      },
      {
        'title': 'Equity vs. debt: when to use each',
        'tag': 'Guide',
        'color': BankerColors.gold,
        'meta': '8 min · Series A · Capital strategy'
      },
      {
        'title': 'Disciplined startup treasury function',
        'tag': 'Event',
        'color': BankerColors.blue,
        'meta': 'May 7 · 1:00 PM ET · 45 min'
      },
    ];

    final Set<int> selectedIndices = {};
    String search = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredEdu = eduAvailable.where((e) => (e['title'] as String).toLowerCase().contains(search.toLowerCase())).toList();

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Assign education',
                          style: TextStyle(
                            fontFamily: 'DM Serif Display',
                            fontSize: 16,
                            color: BankerColors.navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: BankerColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BankerColors.line2),
                      ),
                      child: TextField(
                        onChanged: (val) {
                          setModalState(() => search = val);
                        },
                        style: const TextStyle(fontSize: 11, color: BankerColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Search guides, events, explainers…',
                          hintStyle: TextStyle(color: BankerColors.muted2),
                          prefixIcon: Icon(Icons.search, size: 14, color: BankerColors.muted2),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: SingleChildScrollView(
                        child: Column(
                          children: List.generate(filteredEdu.length, (idx) {
                            final eduItem = filteredEdu[idx];
                            final originalIdx = eduAvailable.indexWhere((element) => element['title'] == eduItem['title']);
                            final isSel = selectedIndices.contains(originalIdx);

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSel) {
                                    selectedIndices.remove(originalIdx);
                                  } else {
                                    selectedIndices.add(originalIdx);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSel ? BankerColors.blueSoft : Colors.white,
                                  borderRadius: BorderRadius.circular(9),
                                  border: Border.all(color: isSel ? BankerColors.blue : BankerColors.line),
                                ),
                                child: Row(
                                  children: [
                                    _buildEduTag(eduItem['tag'] as String),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            eduItem['title'] as String,
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.ink),
                                          ),
                                          const SizedBox(height: 1),
                                          Text(
                                            eduItem['meta'] as String,
                                            style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Checkbox(
                                      value: isSel,
                                      activeColor: BankerColors.blue,
                                      onChanged: (val) {
                                        setModalState(() {
                                          if (isSel) {
                                            selectedIndices.remove(originalIdx);
                                          } else {
                                            selectedIndices.add(originalIdx);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: BankerColors.line2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Cancel', style: TextStyle(color: BankerColors.ink, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedIndices.isEmpty) return;
                            final List<CrmEdu> assignedItems = [];
                            for (var idx in selectedIndices) {
                              final item = eduAvailable[idx];
                              assignedItems.add(
                                CrmEdu(
                                  title: item['title'] as String,
                                  tag: item['tag'] as String,
                                  stripeColor: item['color'] as Color,
                                  status: '${item["tag"]} · Just assigned · Not yet read',
                                ),
                              );
                            }
                            ref.read(bankerProspectsProvider.notifier).addEducation(prospect.id, assignedItems);
                            Navigator.pop(dialogContext);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BankerColors.navy,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Add to learning path', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMsgModal(BuildContext context, CrmProspect prospect) {
    final msgCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Message ${prospect.name}',
                      style: const TextStyle(
                        fontFamily: 'DM Serif Display',
                        fontSize: 16,
                        color: BankerColors.navy,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  "Appears in the founder's hub as a message from you. They'll be notified.",
                  style: TextStyle(fontSize: 11, color: BankerColors.muted2),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: BankerColors.cream,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: BankerColors.line2),
                  ),
                  child: TextField(
                    controller: msgCtrl,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 11, color: BankerColors.ink, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'Write a message…',
                      hintStyle: TextStyle(color: BankerColors.muted2),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: BankerColors.line2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancel', style: TextStyle(color: BankerColors.ink, fontSize: 11)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (msgCtrl.text.trim().isEmpty) return;
                        ref.read(bankerProspectsProvider.notifier).sendMessage(prospect.id, msgCtrl.text.trim());
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Message sent to ${prospect.name}!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BankerColors.navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Send', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
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
}

// --- MAIN PAGE WIDGET ---

class BankerCrmPage extends ConsumerStatefulWidget {
  const BankerCrmPage({super.key});

  @override
  ConsumerState<BankerCrmPage> createState() => _BankerCrmPageState();
}

class _BankerCrmPageState extends ConsumerState<BankerCrmPage> {
  // Selection and UI Filter State
  String _activeFilter = 'all'; // 'all', 'action', 'call', 'docs', 'done'
  String _selectedStatusFilter = 'all'; // 'all', 'Waiting — no chat yet', 'Intro chat done', 'In conversation', 'Fully onboarded'
  String _searchQuery = '';
  String _sortColumn = 'Company';
  bool _sortAscending = true;

  // Data Science view sub-chips and summary state
  String _activeDsViewChip = 'prospects'; // 'prospects', 'analytics', 'summary', 'models'
  String _summarySearchQuery = '';
  CrmProspect? _summaryTarget;

  // Active hover row
  int? _hoveredIndex;

  // DS pipeline scoring state — tracks which prospect IDs are currently being scored
  final Set<String> _scoringProspectIds = {};
  bool _scoringAll = false; // true when "Score All" is running

  // Text controller for search
  final TextEditingController _searchController = TextEditingController();

  // Floating chatbot state
  bool _showFloatingChatbot = false;
  String? _floatingChatbotProspectId;
  bool _floatingChatbotLockDropdown = false;

  final NotificationService _notifService = NotificationService();

  @override
  void initState() {
    super.initState();
    _notifService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    _notifService.removeListener(_onServiceUpdate);
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  /// Triggers the DS pipeline for a single prospect and refreshes the list on completion.
  Future<void> _runDsPipelineForProspect(String prospectId) async {
    if (_scoringProspectIds.contains(prospectId)) return;
    setState(() => _scoringProspectIds.add(prospectId));
    try {
      await ConversationService().runProspectDataScience(prospectId);
      await ref.read(bankerProspectsProvider.notifier).loadProspects();
    } catch (e) {
      debugPrint('DS pipeline failed for $prospectId: $e');
    } finally {
      if (mounted) setState(() => _scoringProspectIds.remove(prospectId));
    }
  }

  /// Triggers the DS pipeline for ALL currently-listed prospects sequentially.
  Future<void> _runAllDsPipeline() async {
    if (_scoringAll) return;
    final prospects = ref.read(bankerProspectsProvider);
    final listed = _getFilteredAndSortedProspects(prospects);
    if (listed.isEmpty) return;
    setState(() => _scoringAll = true);
    try {
      for (final p in listed) {
        if (!mounted) break;
        setState(() => _scoringProspectIds.add(p.id));
        try {
          await ConversationService().runProspectDataScience(p.id);
        } catch (e) {
          debugPrint('DS pipeline failed for ${p.id}: $e');
        } finally {
          if (mounted) setState(() => _scoringProspectIds.remove(p.id));
        }
      }
      // Final refresh after all done
      if (mounted) await ref.read(bankerProspectsProvider.notifier).loadProspects();
    } finally {
      if (mounted) setState(() => _scoringAll = false);
    }
  }

  // --- FILTER & SORT LOGIC ---
  List<CrmProspect> _getFilteredAndSortedProspects(List<CrmProspect> prospects) {
    // 1. Filter
    List<CrmProspect> filtered = prospects.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sector.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;
 
      if (_selectedStatusFilter != 'all') {
        final statusLower = p.status.toLowerCase();
        if (_selectedStatusFilter == 'Waiting — no chat yet') {
          if (!statusLower.contains('waiting')) return false;
        } else if (_selectedStatusFilter == 'Intro chat done') {
          if (!statusLower.contains('intro chat done')) return false;
        } else if (_selectedStatusFilter == 'In conversation') {
          if (!statusLower.contains('in conversation')) return false;
        } else if (_selectedStatusFilter == 'Fully onboarded') {
          if (!statusLower.contains('fully onboarded')) return false;
        }
      }

      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'action') {
        return p.status.contains('Awaiting docs') || p.status.contains('Call') || p.docsReceivedCount < p.docsTotalCount || p.status.contains('Waiting') || p.status.contains('⏳');
      }
      if (_activeFilter == 'call') {
        return p.status.contains('Call') || p.status.contains('Intro chat done') || p.status.contains('📅') || p.status.contains('✨');
      }
      if (_activeFilter == 'docs') {
        return p.status.contains('Awaiting docs') || p.docsReceivedCount < p.docsTotalCount || p.status.contains('⚠');
      }
      if (_activeFilter == 'done') {
        return p.status.contains('Fully onboarded') || p.status.contains('onboard') || p.status.contains('✓');
      }
      return true;
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      // If we clicked a filter chip, let's also sort accordingly by status priority!
      if (_activeFilter == 'action') {
        final aVal = a.status.contains('Waiting') || a.status.contains('⏳') ? 0 : (a.docsReceivedCount < a.docsTotalCount ? 1 : 2);
        final bVal = b.status.contains('Waiting') || b.status.contains('⏳') ? 0 : (b.docsReceivedCount < b.docsTotalCount ? 1 : 2);
        if (aVal != bVal) return aVal.compareTo(bVal);
      } else if (_activeFilter == 'call') {
        final aVal = a.status.contains('Call') || a.status.contains('📅') ? 0 : (a.status.contains('Intro chat done') || a.status.contains('✨') ? 1 : 2);
        final bVal = b.status.contains('Call') || b.status.contains('📅') ? 0 : (b.status.contains('Intro chat done') || b.status.contains('✨') ? 1 : 2);
        if (aVal != bVal) return aVal.compareTo(bVal);
      } else if (_activeFilter == 'docs') {
        final aRatio = a.docsTotalCount > 0 ? (a.docsReceivedCount / a.docsTotalCount) : 1.0;
        final bRatio = b.docsTotalCount > 0 ? (b.docsReceivedCount / b.docsTotalCount) : 1.0;
        if (aRatio != bRatio) return aRatio.compareTo(bRatio);
      } else if (_activeFilter == 'done') {
        final aVal = a.status.contains('Fully onboarded') || a.status.contains('✓') ? 0 : 1;
        final bVal = b.status.contains('Fully onboarded') || b.status.contains('✓') ? 0 : 1;
        if (aVal != bVal) return aVal.compareTo(bVal);
      }

      int cmp = 0;
      switch (_sortColumn) {
        case 'Company':
          cmp = a.name.compareTo(b.name);
          break;
        case 'Status':
          cmp = a.status.compareTo(b.status);
          break;
        case 'Profile':
          cmp = a.profileProgress.compareTo(b.profileProgress);
          break;
        case 'Docs':
          final aRatio = a.docsTotalCount > 0 ? (a.docsReceivedCount / a.docsTotalCount) : -1.0;
          final bRatio = b.docsTotalCount > 0 ? (b.docsReceivedCount / b.docsTotalCount) : -1.0;
          cmp = aRatio.compareTo(bRatio);
          break;
        case 'Materials read':
          cmp = a.materialsReadText.compareTo(b.materialsReadText);
          break;
        case 'Last active':
          int timeWeight(String lastActive) {
            if (lastActive.toLowerCase().contains('today')) return 0;
            if (lastActive.toLowerCase().contains('yesterday')) return 1;
            if (lastActive.toLowerCase().contains('2d')) return 2;
            if (lastActive.toLowerCase().contains('3d')) return 3;
            if (lastActive.toLowerCase().contains('1w')) return 4;
            if (lastActive.toLowerCase().contains('2w')) return 5;
            return 99;
          }
          cmp = timeWeight(a.lastActive).compareTo(timeWeight(b.lastActive));
          break;
      }
      return _sortAscending ? cmp : -cmp;
    });

    return filtered;
  }

  void _handleSort(String column) {
    setState(() {
      if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 1000;
    
    // Read from Riverpod Provider
    final bankersAsync = ref.watch(bankersProvider);
    final activeBanker = ref.watch(activeBankerProvider);
    final allProspects = ref.watch(bankerProspectsProvider);

    final List<Banker> navbarBankers = [
      ...(bankersAsync.value ?? []),
      const Banker(
        bankerId: 'datascience',
        email: 'datascience@convpredict.ai',
        name: 'Data Science View',
        position: 'Model & Conv Intelligence',
        role: 'datascience',
      ),
    ];

    // Auto-select banker with persistence
    bankersAsync.whenData((bankers) {
      final hasActiveBanker = activeBanker != null && 
          (activeBanker.bankerId == 'datascience' || bankers.any((b) => b.bankerId == activeBanker.bankerId));
      if (!hasActiveBanker && bankers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final savedId = await ProspectStorage().getActiveBankerId();
          if (savedId != null) {
            if (savedId == 'datascience') {
              ref.read(activeBankerProvider.notifier).state = const Banker(
                bankerId: 'datascience',
                email: 'datascience@convpredict.ai',
                name: 'Data Science View',
                position: 'Model & Conv Intelligence',
                role: 'datascience',
              );
            } else {
              final savedBanker = bankers.firstWhere(
                (b) => b.bankerId == savedId,
                orElse: () => bankers.first,
              );
              ref.read(activeBankerProvider.notifier).state = savedBanker;
              ProspectStorage().saveActiveBanker(savedBanker);
            }
          } else {
            ref.read(activeBankerProvider.notifier).state = bankers.first;
            ProspectStorage().saveActiveBanker(bankers.first);
          }
        });
      }
    });

    // Filter prospects by active banker
    final prospects = allProspects.where((p) {
      if (activeBanker == null) return true;
      if (activeBanker.bankerId == 'datascience') return true;
      return p.bankerId == activeBanker.bankerId;
    }).toList();

    final targetProspect = prospects.firstWhere(
      (p) => p.name.contains("123") || p.id == "68ac5ad3-9bbd-40b6-acdf-cdda65a78e1b",
      orElse: () => prospects.isNotEmpty
          ? prospects.first
          : CrmProspect(
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
            ),
    );

    // Dynamic stats computations
    final activeCount = prospects.length;
    final needsActionCount = prospects.where((p) => p.status.contains('Awaiting docs') || p.status.contains('Call')).length;
    final callsCount = prospects.where((p) => p.status.contains('Call')).length;
    final awaitingDocsCount = prospects.where((p) => p.status.contains('Awaiting docs')).length;
    final onboardedCount = prospects.where((p) => p.status.contains('Fully onboarded')).length;

    final bankerName = activeBanker?.name ??
        (bankersAsync.value?.isNotEmpty == true
            ? (bankersAsync.value!.first.name ?? 'Banker')
            : 'Loading...');
    final activeName = activeBanker?.name ?? 
        (bankersAsync.value?.isNotEmpty == true 
            ? (bankersAsync.value!.first.name ?? 'Banker') 
            : 'Loading...');
    final initials = activeName != 'Loading...'
        ? activeName.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : '...';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(74),
        child: HubNavBar(
          companyName: bankerName,
          founderName: bankerName,
          initials: initials,
          isBankerView: true,
          activeLabel: 'Banker View',
          bankers: navbarBankers,
          activeBanker: activeBanker,
          onBankerSelected: (banker) {
            ref.read(activeBankerProvider.notifier).state = banker;
            ProspectStorage().saveActiveBanker(banker);
          },
          onLogout: () async {
            ProspectCache.clear();
            ProductCache.clear();
            await ProspectStorage().clearProspectId();
            if (context.mounted) {
              context.go('/');
            }
          },
        ),
      ),
      body: Stack(
              children: [
          // Main content
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (activeBanker?.bankerId != 'datascience' && _notifService.activeHubNotifications.isNotEmpty)
                NotificationsSection(
                  isBanker: true,
                  prospectName: targetProspect.name,
                  founderName: targetProspect.founderName,
                  bankerName: bankerName,
                  prospectsList: prospects,
                ),

              // 1. SUMMARY BAR
              if (activeBanker?.bankerId != 'datascience')
                _buildSummaryBar(
                  isMobile: isMobile,
                  activeCount: activeCount,
                  needsActionCount: needsActionCount,
                  callsCount: callsCount,
                  awaitingDocsCount: awaitingDocsCount,
                  onboardedCount: onboardedCount,
                ),

              // 2. TOOLBAR
              _buildToolbar(isMobile, prospects),

              // 3. FULL-WIDTH TABLE REGION
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: _buildDsViewContent(prospects),
                ),
              ),
            ],
          ),

          // Click-outside tap barrier
          if (_showFloatingChatbot)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() {
                    _showFloatingChatbot = false;
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

          // Floating chatbot overlay
          if (_showFloatingChatbot) ...[
            Builder(
              builder: (context) {
                final resolvedProspectId = _floatingChatbotProspectId ?? (prospects.isNotEmpty ? prospects.first.id : null);
                final selectedProspect = prospects.isNotEmpty
                    ? prospects.firstWhere(
                        (p) => p.id == resolvedProspectId,
                        orElse: () => prospects.first,
                      )
                    : null;

                if (selectedProspect == null) {
                  return const SizedBox.shrink();
                }

                return Positioned(
                  bottom: 90,
                  right: 24,
                  child: Container(
                    width: 420,
                    height: 600,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE7DCC8), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14.5), // Match inner boundary of 1.5px border
                      child: AiGuidePanel(
                        prospectId: selectedProspect.id,
                        bankerId: activeBanker?.bankerId,
                        founderName: selectedProspect.name,
                        companyName: selectedProspect.name,
                        industry: selectedProspect.sector,
                        stageLabel: selectedProspect.stage,
                        priorities: const [],
                        customActionLabel: 'Prospect Chats',
                        onCustomActionTap: () {},
                        bankerName: bankerName,
                        inDirectMessagingMode: true,
                        lockDropdown: _floatingChatbotLockDropdown,
                        showLeftBorder: false, // Hide straight left line inside overlay card
                        prospectsList: prospects,
                        onProspectSelected: (p) {
                          setState(() {
                            _floatingChatbotProspectId = p.id;
                          });
                        },
                        onClose: () {
                          setState(() {
                            _showFloatingChatbot = false;
                          });
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              bottom: 24,
              right: 24,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _showFloatingChatbot = false;
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: BankerColors.navy,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- UI BUILDING HELPERS ---

  Widget _buildSummaryBar({
    required bool isMobile,
    required int activeCount,
    required int needsActionCount,
    required int callsCount,
    required int awaitingDocsCount,
    required int onboardedCount,
  }) {
    final stats = [
      _StatItem(value: '$activeCount', label: 'Active prospects', sub: '↑ 3 this month', subColor: BankerColors.green),
      _StatItem(value: '$needsActionCount', label: 'Need action', sub: '', subColor: const Color(0xFFD97706)),
      _StatItem(value: '$callsCount', label: 'Calls this week', sub: 'Next: May 6', subColor: BankerColors.muted2),
      _StatItem(value: '$awaitingDocsCount', label: 'Awaiting docs', sub: '', subColor: const Color(0xFFD97706)),
      _StatItem(value: '$onboardedCount', label: 'Fully onboarded', sub: '↑ 1 this week', subColor: BankerColors.green),
    ];

    if (isMobile) {
      return Container(
        height: 90,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: BankerColors.line2, width: 1)),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: stats.length,
          separatorBuilder: (context, index) => Container(
            width: 1,
            color: BankerColors.line2,
            margin: const EdgeInsets.symmetric(vertical: 4),
          ),
          itemBuilder: (context, index) {
            final stat = stats[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontFamily: 'DM Serif Display',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: BankerColors.navy,
                    ),
                  ),
                  Text(
                    stat.label,
                    style: const TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.w500),
                  ),
                  if (stat.sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      stat.sub,
                      style: TextStyle(fontSize: 10, color: stat.subColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BankerColors.line2, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      child: Row(
        children: List.generate(stats.length, (index) {
          final stat = stats[index];
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: index < stats.length - 1
                    ? const Border(right: BorderSide(color: BankerColors.line2, width: 1))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.value,
                    style: const TextStyle(
                      fontFamily: 'DM Serif Display',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: BankerColors.navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    stat.label,
                    style: const TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.w500),
                  ),
                  if (stat.sub.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      stat.sub,
                      style: TextStyle(fontSize: 10, color: stat.subColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildToolbar(bool isMobile, List<CrmProspect> prospects) {
    final activeBanker = ref.watch(activeBankerProvider);
    if (activeBanker?.bankerId == 'datascience') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: BankerColors.line2, width: 1)),
        ),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildDsViewChip('📋 Prospects', 'prospects'),
                _buildDsViewChip('📊 Analytics', 'analytics'),
                _buildDsViewChip('🔍 Column Summary', 'summary'),
                _buildDsViewChip('🏋️ Models', 'models'),
              ],
            ),
            if (_activeDsViewChip == 'prospects')
              Container(
                width: 200,
                height: 30,
                decoration: BoxDecoration(
                  color: BankerColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BankerColors.line2),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 11, color: BankerColors.ink),
                  decoration: const InputDecoration(
                    hintText: 'Search prospects…',
                    hintStyle: TextStyle(color: BankerColors.muted2, fontSize: 11),
                    prefixIcon: Icon(Icons.search, size: 14, color: BankerColors.muted2),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    final isManager = activeBanker?.role == 'manager';

    final hasWaiting = prospects.any((p) => p.status.toLowerCase().contains('waiting'));
    final hasIntro = prospects.any((p) => p.status.toLowerCase().contains('intro chat done'));
    final hasConversation = prospects.any((p) => p.status.toLowerCase().contains('in conversation'));
    final hasOnboarded = prospects.any((p) => p.status.toLowerCase().contains('fully onboarded'));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: BankerColors.line2, width: 1)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Container(
                width: 200,
                height: 30,
                decoration: BoxDecoration(
                  color: BankerColors.cream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: BankerColors.line2),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: const TextStyle(fontSize: 11, color: BankerColors.ink),
                  decoration: const InputDecoration(
                    hintText: 'Search prospects…',
                    hintStyle: TextStyle(color: BankerColors.muted2),
                    prefixIcon: Icon(Icons.search, size: 14, color: BankerColors.muted2),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip('All', 'all'),
              if (hasWaiting) _buildStatusChip('⏳ Waiting', 'Waiting — no chat yet'),
              if (hasIntro) _buildStatusChip('✨ Intro Chat', 'Intro chat done'),
              if (hasConversation) _buildStatusChip('💬 Conversation', 'In conversation'),
              if (hasOnboarded) _buildStatusChip('✓ Onboarded', 'Fully onboarded'),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isManager) ...[
                ElevatedButton(
                  onPressed: _showAssignProspectDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BankerColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+ Assign Prospect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _showCreateBankerDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BankerColors.navy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('+ Create Banker', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],
              // ⚡ Score All — visible to everyone, runs DS pipeline for every listed prospect
              Tooltip(
                message: _scoringAll
                    ? 'Scoring in progress… each prospect is processed one by one'
                    : 'Run DS pipeline for all listed prospects',
                child: ElevatedButton.icon(
                  onPressed: _scoringAll ? null : _runAllDsPipeline,
                  icon: _scoringAll
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.bolt_rounded, size: 14),
                  label: Text(
                    _scoringAll ? 'Scoring…' : 'Score All',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1D4ED8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF93C5FD),
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey) {
    final isOn = _activeFilter == filterKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterKey;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isOn ? BankerColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isOn ? BankerColors.navy : BankerColors.line2),
          ),
          child: Text(
            label,
            style: TextStyle(fontSize: 10, color: isOn ? Colors.white : BankerColors.muted, fontWeight: isOn ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, String statusKey) {
    final isOn = _selectedStatusFilter == statusKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedStatusFilter = statusKey;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isOn ? BankerColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOn ? BankerColors.navy : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isOn ? FontWeight.bold : FontWeight.normal,
              color: isOn ? Colors.white : const Color(0xFF4A5568),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDsViewChip(String label, String chipKey) {
    final isOn = _activeDsViewChip == chipKey;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeDsViewChip = chipKey;
        });
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isOn ? BankerColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOn ? BankerColors.navy : const Color(0xFFE2E8F0),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isOn ? FontWeight.bold : FontWeight.w500,
              color: isOn ? Colors.white : const Color(0xFF4A5568),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDsViewContent(List<CrmProspect> prospects) {
    final activeBanker = ref.watch(activeBankerProvider);
    final isDs = activeBanker?.bankerId == 'datascience';
    if (!isDs || _activeDsViewChip == 'prospects') {
      return _buildCrmTable(prospects);
    }
    return buildDsViewContent(
      context: context,
      activeDsViewChip: _activeDsViewChip,
      prospects: prospects,
      searchQuery: _summarySearchQuery,
      onSearchQueryChanged: (val) {
        setState(() {
          _summarySearchQuery = val;
        });
      },
      summaryTarget: _summaryTarget,
      onSummaryTargetSelected: (val) {
        setState(() {
          _summaryTarget = val;
        });
      },
    );
  }

  Widget _buildCrmTable(List<CrmProspect> prospects) {
    final list = _getFilteredAndSortedProspects(prospects);
    final activeBanker = ref.watch(activeBankerProvider);

    return Column(
      children: [
        // Table Header
        Container(
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: BankerColors.line2, width: 2)),
          ),
          child: Row(
            children: [
              _buildHeaderCell('Company', flex: 3),
              _buildHeaderCell('Lead', flex: 2),
              _buildHeaderCell('Probability', flex: 2),
              _buildHeaderCell('Priority', flex: 2),
              _buildHeaderCell('Status', flex: 2),
              _buildHeaderCell('Profile', flex: 2),
              _buildHeaderCell('Docs', flex: 2),
              _buildHeaderCell('Actions', flex: 3, sortable: false),
            ],
          ),
        ),
        // Table Body
        Expanded(
          child: list.isEmpty
              ? const Center(
                  child: Text('No prospects found matching your query.', style: TextStyle(color: BankerColors.muted, fontSize: 13)),
                )
              : ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const Divider(height: 1, thickness: 1, color: BankerColors.line),
                  itemBuilder: (context, index) {
                    final prospect = list[index];
                    final isHovered = _hoveredIndex == index;

                    return MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to individual Banker detail page for that prospect
                          context.go('/banker/${prospect.id}');
                        },
                        child: Container(
                          height: 52,
                          color: isHovered ? const Color(0xFFF8F6F1) : Colors.white,
                          child: Row(
                            children: [
                              // Company
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.only(left: 14, right: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Row(
                                    children: [
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(color: prospect.avatarBg, shape: BoxShape.circle),
                                            alignment: Alignment.center,
                                            child: Text(
                                              prospect.avatarText,
                                              style: TextStyle(
                                                fontFamily: 'DM Serif Display',
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: prospect.avatarFg,
                                              ),
                                            ),
                                          ),
                                          if (() {
                                            final targetIndex = prospects.indexOf(prospect);
                                            if (targetIndex == -1) return false;
                                            for (var item in _notifService.activeHubNotifications) {
                                              if (item.prospectSlot == targetIndex) return true;
                                            }
                                            return false;
                                          }())
                                            Positioned(
                                              top: -2,
                                              right: -2,
                                              child: Container(
                                                width: 10,
                                                height: 10,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0533C),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 1.5),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(width: 9),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              prospect.name,
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: BankerColors.ink),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              prospect.sector,
                                              style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Lead
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: _buildLeadBadge(prospect.leadTemperature),
                                ),
                              ),
                              // Probability
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: _buildProbabilityCell(prospect.conversionProbability),
                                ),
                              ),
                              // Priority
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: _buildPriorityBadge(prospect.salesPriority),
                                ),
                              ),

                              // Status
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: _buildStatusBadge(prospect.status),
                                ),
                              ),
                              // Profile
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 5,
                                        width: 80,
                                        decoration: BoxDecoration(color: BankerColors.cream, borderRadius: BorderRadius.circular(999)),
                                        alignment: Alignment.centerLeft,
                                        child: FractionallySizedBox(
                                          widthFactor: prospect.profileProgress,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: prospect.profileProgress == 1.0 ? BankerColors.green : BankerColors.blue,
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text('${(prospect.profileProgress * 100).toInt()}%', style: const TextStyle(fontSize: 10, color: BankerColors.muted2)),
                                    ],
                                  ),
                                ),
                              ),
                              // Docs
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: _buildDocsBadge(prospect),
                                ),
                              ),
                              // Actions
                              Expanded(
                                flex: 3,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _showFloatingChatbot = true;
                                              _floatingChatbotProspectId = prospect.id;
                                              _floatingChatbotLockDropdown = true;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              border: Border.all(color: BankerColors.line2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              prospect.status.contains('Waiting') ? 'Nudge' : 'Message',
                                              style: const TextStyle(fontSize: 10, color: BankerColors.ink, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        // DS Pipeline button — shows when no scores yet, spinner while running
                                        _buildDsScoreButton(prospect),
                                        if (activeBanker?.role == 'manager') ...[
                                          const SizedBox(width: 4),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, size: 16, color: BankerColors.muted),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            onSelected: (val) {
                                              if (val == 'reassign') {
                                                _showReassignProspectDialog(prospect);
                                              } else if (val == 'unassign') {
                                                _unassignProspect(prospect);
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem(
                                                value: 'reassign',
                                                child: Text('Reassign Prospect', style: TextStyle(fontSize: 12)),
                                              ),
                                              const PopupMenuItem(
                                                value: 'unassign',
                                                child: Text('Unassign Prospect', style: TextStyle(fontSize: 12, color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Inline DS pipeline button for the Actions cell.
  /// - Shows nothing if scores already exist (leadTemperature != null).
  /// - Shows a spinner while the pipeline is running for this prospect.
  /// - Shows a ⚡ "Score" button otherwise.
  Widget _buildDsScoreButton(CrmProspect prospect) {
    final isScoring = _scoringProspectIds.contains(prospect.id);
    final alreadyScored = prospect.leadTemperature != null;

    if (isScoring) {
      return const Tooltip(
        message: 'Running DS pipeline…',
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
          ),
        ),
      );
    }

    return Tooltip(
      message: alreadyScored ? 'Recalculate DS scores' : 'Run DS pipeline to score this prospect',
      child: GestureDetector(
        onTap: () => _runDsPipelineForProspect(prospect.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: alreadyScored ? BankerColors.cream : const Color(0xFFEFF6FF),
            border: Border.all(color: alreadyScored ? BankerColors.line2 : BankerColors.blue),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                alreadyScored ? Icons.refresh_rounded : Icons.bolt_rounded,
                size: 13,
                color: BankerColors.blue,
              ),
              const SizedBox(width: 3),
              Text(
                alreadyScored ? 'Rescore' : 'Score',
                style: const TextStyle(fontSize: 10, color: BankerColors.blue, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String label, {required int flex, bool sortable = true}) {
    final isSorted = _sortColumn == label;
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: sortable ? () => _handleSort(label) : null,
        child: MouseRegion(
          cursor: sortable ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: BankerColors.muted2, letterSpacing: 0.4),
                ),
                if (sortable && isSorted)
                  Text(
                    _sortAscending ? ' ↑' : ' ↓',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.ink),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildStatusBadge(String status) {
    Color bg = BankerColors.purpleSoft;
    Color fg = const Color(0xFF4B43B6);

    if (status.contains('Call')) {
      bg = const Color(0xFFFEF3C7);
      fg = const Color(0xFF92400E);
    } else if (status.contains('Awaiting docs')) {
      bg = BankerColors.redSoft;
      fg = const Color(0xFF991B1B);
    } else if (status.contains('Intro chat done')) {
      bg = BankerColors.blueSoft;
      fg = const Color(0xFF185FA5);
    } else if (status.contains('In conversation')) {
      bg = BankerColors.amberSoft;
      fg = const Color(0xFF7C5410);
    } else if (status.contains('Fully onboarded')) {
      bg = BankerColors.greenSoft;
      fg = const Color(0xFF0F6E56);
    } else if (status.contains('Waiting')) {
      bg = const Color(0xFFF3E8FF);
      fg = const Color(0xFF6B21A8);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildDocsBadge(CrmProspect prospect) {
    Color bg = BankerColors.cream;
    Color fg = BankerColors.muted2;

    final received = prospect.docsReceivedCount;
    final total = prospect.docsTotalCount;

    if (total == 0) {
      bg = BankerColors.cream;
      fg = BankerColors.muted2;
    } else if (received == 0) {
      bg = BankerColors.redSoft;
      fg = const Color(0xFF991B1B);
    } else if (received == total) {
      bg = BankerColors.greenSoft;
      fg = const Color(0xFF0F6E56);
    } else {
      bg = BankerColors.amberSoft;
      fg = const Color(0xFF7C5410);
    }

    final text = '$received received';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  void _showCreateBankerDialog() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final positionController = TextEditingController();
    bool isSaving = false;
    String? errorMessage;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> handleCreate() async {
              final name = nameController.text.trim();
              final email = emailController.text.trim();
              final position = positionController.text.trim();

              if (name.isEmpty || email.isEmpty || position.isEmpty) {
                setModalState(() {
                  errorMessage = 'All fields are required.';
                });
                return;
              }

              setModalState(() {
                isSaving = true;
                errorMessage = null;
              });

              try {
                await ConversationService().createBanker(
                  name,
                  email,
                  position,
                  ref.read(activeBankIdProvider),
                );
                
                ref.invalidate(bankersProvider);

                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Successfully created banker $name.')),
                );
              } catch (e) {
                setModalState(() {
                  isSaving = false;
                  errorMessage = e.toString().replaceAll('Exception:', '').trim();
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_add_rounded, color: BankerColors.navy, size: 22),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Create New Banker',
                            style: TextStyle(
                              fontFamily: 'DM Serif Display',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: BankerColors.ink,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20, color: BankerColors.muted),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the credentials and title of the new banker. They will belong to this bank branch.',
                      style: TextStyle(fontSize: 12, color: BankerColors.muted, height: 1.4),
                    ),
                    const SizedBox(height: 20),
                    if (errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF991B1B), fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'FULL NAME',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: BankerColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BankerColors.line2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 12, color: BankerColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'John Doe',
                          hintStyle: TextStyle(color: BankerColors.muted2, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'EMAIL ADDRESS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: BankerColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BankerColors.line2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 12, color: BankerColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'john.doe@bank.com',
                          hintStyle: TextStyle(color: BankerColors.muted2, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'POSITION / TITLE',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: BankerColors.cream,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: BankerColors.line2),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: positionController,
                        style: const TextStyle(fontSize: 12, color: BankerColors.ink),
                        decoration: const InputDecoration(
                          hintText: 'Managing Director / VP / Associate',
                          hintStyle: TextStyle(color: BankerColors.muted2, fontSize: 12),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: BankerColors.muted,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSaving ? null : handleCreate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BankerColors.navy,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Create Banker', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAssignProspectDialog() {
    final activeBanker = ref.read(activeBankerProvider);
    if (activeBanker == null) return;

    String _search = '';
    List<dynamic> _unassigned = [];
    bool _loading = true;
    Map<String, bool> _assigning = {};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Load unassigned prospects once on first build
            if (_loading && _unassigned.isEmpty) {
              ConversationService().getUnassignedProspects(bankId: ref.read(activeBankIdProvider)).then((list) {
                setModalState(() {
                  _unassigned = list;
                  _loading = false;
                });
              }).catchError((e) {
                setModalState(() => _loading = false);
              });
            }

            final filtered = _unassigned.where((p) {
              final companyName = ((p['company_name'] ?? '') as String).toLowerCase();
              final fullName = ((p['full_name'] ?? '') as String).toLowerCase();
              final email = ((p['email'] ?? '') as String).toLowerCase();
              final prospectId = ((p['prospect_id'] ?? '') as String).toLowerCase();
              final fallbackName = 'prospect - ${prospectId.length >= 8 ? prospectId.substring(0, 8) : prospectId}';
              final q = _search.toLowerCase();
              return companyName.contains(q) ||
                  fullName.contains(q) ||
                  email.contains(q) ||
                  fallbackName.contains(q) ||
                  prospectId.contains(q);
            }).toList();

            Future<void> _handleAssign(
              String prospectId,
              String displayName,
              String email,
              String industry,
              String initials,
              Map<String, dynamic> p,
            ) async {
              if (_assigning[prospectId] == true) return;

              final bankers = ref.read(bankersProvider).value ?? [];
              if (bankers.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('No bankers available to assign.')),
                );
                return;
              }

              final aiSuggestedIndex = prospectId.hashCode.abs() % bankers.length;
              final aiSuggestedBanker = bankers[aiSuggestedIndex];

              Banker? selectedBanker = aiSuggestedBanker;
              String _bankerSearch = '';
              bool isSaving = false;

              final assignedResult = await showDialog<bool>(
                context: dialogContext,
                builder: (assignContext) {
                  return StatefulBuilder(
                    builder: (ctx, setAssignState) {
                      final filteredBankers = bankers.where((b) {
                        final name = (b.name ?? '').toLowerCase();
                        final email = b.email.toLowerCase();
                        final q = _bankerSearch.toLowerCase();
                        return name.contains(q) || email.contains(q);
                      }).toList();

                      final isAiSuggested = selectedBanker?.bankerId == aiSuggestedBanker.bankerId;
                      final buttonText = isAiSuggested ? 'Assign Prospect' : 'Override Match Recommendations';

                      return Dialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          width: 520,
                          constraints: const BoxConstraints(maxHeight: 600),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header
                              Row(
                                children: [
                                  const Icon(Icons.person_add_rounded, color: BankerColors.navy, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Assign: $displayName',
                                      style: const TextStyle(
                                        fontFamily: 'DM Serif Display',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: BankerColors.navy,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18, color: BankerColors.muted),
                                    onPressed: () => Navigator.pop(assignContext, false),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Select a banker to assign to this prospect.',
                                style: TextStyle(color: BankerColors.muted, fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              // Search bar
                              TextField(
                                onChanged: (val) => setAssignState(() => _bankerSearch = val),
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Search bankers by name or email...',
                                  prefixIcon: const Icon(Icons.search, size: 16, color: BankerColors.muted),
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BankerColors.line)),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BankerColors.line)),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Column Headers
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF9F9FB),
                                  border: Border(bottom: BorderSide(color: BankerColors.line, width: 1)),
                                ),
                                child: Row(
                                  children: const [
                                    Expanded(flex: 3, child: Text('BANKER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                                    Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                                    Expanded(flex: 2, child: Text('AI SUGGESTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                                  ],
                                ),
                              ),
                              // List
                              Expanded(
                                child: filteredBankers.isEmpty
                                    ? const Center(child: Text('No bankers found.', style: TextStyle(color: BankerColors.muted)))
                                    : ListView.separated(
                                        itemCount: filteredBankers.length,
                                        separatorBuilder: (c, idx) => const Divider(height: 1, color: BankerColors.line),
                                        itemBuilder: (c, idx) {
                                          final b = filteredBankers[idx];
                                          final isSelected = selectedBanker?.bankerId == b.bankerId;
                                          final bIsSuggested = b.bankerId == aiSuggestedBanker.bankerId;
                                          final bInitials = b.name != null
                                              ? b.name!.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                                              : 'B';

                                          return InkWell(
                                            onTap: () => setAssignState(() => selectedBanker = b),
                                            child: Container(
                                              color: isSelected ? const Color(0xFFF0F4F8) : Colors.transparent,
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              child: Row(
                                                children: [
                                                  // Banker Info
                                                  Expanded(
                                                    flex: 3,
                                                    child: Row(
                                                      children: [
                                                        Container(
                                                          width: 28,
                                                          height: 28,
                                                          decoration: BoxDecoration(
                                                            color: isSelected ? BankerColors.navy : const Color(0xFFE2E8F0),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          alignment: Alignment.center,
                                                          child: Text(
                                                            bInitials,
                                                            style: TextStyle(
                                                              color: isSelected ? Colors.white : BankerColors.ink,
                                                              fontSize: 10,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              Text(
                                                                b.name ?? b.email,
                                                                style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                                  color: BankerColors.ink,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              if (b.name != null)
                                                                Text(
                                                                  b.email,
                                                                  style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  // Role
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: b.role == 'manager' ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          b.role == 'manager' ? 'Team Lead' : (b.position ?? 'Associate'),
                                                          style: TextStyle(
                                                            color: b.role == 'manager' ? const Color(0xFF92400E) : const Color(0xFF475569),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  // AI Suggested
                                                  Expanded(
                                                    flex: 2,
                                                    child: Align(
                                                      alignment: Alignment.centerLeft,
                                                      child: bIsSuggested
                                                          ? Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                              decoration: BoxDecoration(
                                                                color: const Color(0xFFDCFCE7),
                                                                borderRadius: BorderRadius.circular(12),
                                                              ),
                                                              child: Row(
                                                                mainAxisSize: MainAxisSize.min,
                                                                children: const [
                                                                  Icon(Icons.auto_awesome, color: Color(0xFF166534), size: 10),
                                                                  SizedBox(width: 4),
                                                                  Text(
                                                                    'AI Suggested',
                                                                    style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold),
                                                                  ),
                                                                ],
                                                              ),
                                                            )
                                                          : const Text('—', style: TextStyle(color: BankerColors.muted2, fontSize: 11)),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 16),
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(assignContext, false),
                                    child: const Text('Cancel', style: TextStyle(color: BankerColors.muted)),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    onPressed: (selectedBanker == null || isSaving)
                                        ? null
                                        : () async {
                                            setAssignState(() => isSaving = true);
                                            try {
                                              await ConversationService().assignProspectToBanker(prospectId, selectedBanker!.bankerId);
                                              Navigator.pop(assignContext, true);
                                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                                SnackBar(content: Text('Successfully assigned $displayName to ${selectedBanker!.name ?? selectedBanker!.email}')),
                                              );
                                              // If assigned to active banker, add to their notifier, otherwise reload
                                              if (selectedBanker!.bankerId == activeBanker.bankerId) {
                                                final avatarInitials = initials.isEmpty ? '?' : initials;
                                                final newProspect = CrmProspect(
                                                  id: prospectId,
                                                  name: displayName,
                                                  email: email,
                                                  sector: industry.isNotEmpty ? industry : 'Technology',
                                                  stage: (() {
                                                    final bucket = p['stage_bucket'] as String? ?? '';
                                                    if (bucket == 'pre_seed') return 'Pre-seed';
                                                    if (bucket == 'seed') return 'Seed';
                                                    if (bucket == 'early_stage') return 'Series A';
                                                    if (bucket == 'growth_stage') return 'Series B';
                                                    return 'Seed';
                                                  })(),
                                                  status: 'In conversation',
                                                  profileProgress: 0.5,
                                                  docsReceivedText: '0/2 received',
                                                  docsReceivedCount: 0,
                                                  docsTotalCount: 2,
                                                  materialsReadText: '—',
                                                  materialsReadSub: '',
                                                  lastActive: 'Today',
                                                  avatarText: avatarInitials,
                                                  avatarBg: BankerColors.blueSoft,
                                                  avatarFg: BankerColors.blue,
                                                  docs: [],
                                                  education: [],
                                                  activity: [
                                                    CrmActivity(
                                                      icon: Icons.person_add_rounded,
                                                      iconBg: BankerColors.blueSoft,
                                                      iconColor: BankerColors.blue,
                                                      text: 'Prospect assigned to ${selectedBanker!.name ?? selectedBanker!.email}',
                                                      time: 'Today',
                                                    ),
                                                  ],
                                                  notes: '',
                                                  bankerId: selectedBanker!.bankerId,
                                                  founderName: p['full_name'] as String? ?? displayName,
                                                  stageBucket: p['stage_bucket'] as String? ?? 'seed',
                                                );
                                                ref.read(bankerProspectsProvider.notifier).addProspect(newProspect);
                                              } else {
                                                // Just reload prospects list
                                                ref.read(bankerProspectsProvider.notifier).loadProspects();
                                              }
                                            } catch (e) {
                                              setAssignState(() => isSaving = false);
                                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                                SnackBar(content: Text('Failed to assign: $e')),
                                              );
                                            }
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isAiSuggested ? BankerColors.navy : const Color(0xFFD97706),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: isSaving
                                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                        : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );

              if (assignedResult == true) {
                // Remove from unassigned list
                setModalState(() {
                  _unassigned.removeWhere((item) => item['prospect_id'] == prospectId);
                });
              }
            }

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 480,
                constraints: const BoxConstraints(maxHeight: 560),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.person_add_rounded, color: BankerColors.navy, size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Assign Prospect',
                            style: TextStyle(
                              fontFamily: 'DM Serif Display',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BankerColors.navy,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: BankerColors.muted),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select an unassigned prospect to assign to ${activeBanker.name ?? activeBanker.email}',
                      style: const TextStyle(fontSize: 12, color: BankerColors.muted),
                    ),
                    const SizedBox(height: 14),
                    // Search bar
                    TextField(
                      autofocus: true,
                      onChanged: (val) => setModalState(() => _search = val),
                      decoration: InputDecoration(
                        hintText: 'Search by name, company, or email...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 16, color: BankerColors.muted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: BankerColors.line2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: BankerColors.blue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // List
                    Flexible(
                      child: _loading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24.0),
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(BankerColors.blue),
                                ),
                              ),
                            )
                          : filtered.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.people_outline_rounded, size: 40, color: BankerColors.muted.withOpacity(0.5)),
                                        const SizedBox(height: 8),
                                        Text(
                                          _search.isEmpty ? 'No unassigned prospects found' : 'No prospects match your search',
                                          style: const TextStyle(fontSize: 13, color: BankerColors.muted),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1, color: BankerColors.line2),
                                  itemBuilder: (_, i) {
                                    final p = filtered[i];
                                    final prospectId = p['prospect_id'] as String? ?? '';
                                    final companyName = p['company_name'] as String? ?? '';
                                    final fullName = p['full_name'] as String? ?? '';
                                    final email = p['email'] as String? ?? '';
                                    final industry = p['industry'] as String? ?? '';
                                    final displayName = companyName.isNotEmpty
                                        ? companyName
                                        : (fullName.isNotEmpty
                                            ? fullName
                                            : (email.isNotEmpty ? email : 'Prospect - ${prospectId.length >= 8 ? prospectId.substring(0, 8) : prospectId}'));
                                    final subtitle = [
                                      if (fullName.isNotEmpty && companyName.isNotEmpty) fullName,
                                      if (industry.isNotEmpty) industry,
                                      email.isNotEmpty ? email : 'No email provided',
                                    ].join(' · ');
                                    final initials = displayName.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();
                                    final isAssigning = _assigning[prospectId] == true;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: isAssigning ? null : () => _handleAssign(prospectId, displayName, email, industry, initials, p),
                                          child: Row(
                                            children: [
                                              // Avatar
                                              Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: BankerColors.blueSoft,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    initials.isEmpty ? '?' : initials,
                                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: BankerColors.blue),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              // Name + subtitle
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      displayName,
                                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: BankerColors.navy),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (subtitle.isNotEmpty)
                                                      Text(
                                                        subtitle,
                                                        style: const TextStyle(fontSize: 11, color: BankerColors.muted),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Assign button
                                              SizedBox(
                                                width: 70,
                                                height: 30,
                                                child: ElevatedButton(
                                                  onPressed: isAssigning ? null : () => _handleAssign(prospectId, displayName, email, industry, initials, p),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: BankerColors.navy,
                                                    foregroundColor: Colors.white,
                                                    elevation: 0,
                                                    padding: EdgeInsets.zero,
                                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                                  ),
                                                  child: isAssigning
                                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                                      : const Text('Assign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                    const SizedBox(height: 8),
                    // Footer
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Close', style: TextStyle(color: BankerColors.muted)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _unassignProspect(CrmProspect prospect) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unassign Prospect?'),
        content: Text('Are you sure you want to unassign ${prospect.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: BankerColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BankerColors.navy,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Unassign'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ConversationService().assignProspectToBanker(prospect.id, null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully unassigned ${prospect.name}.')),
      );
      ref.read(bankerProspectsProvider.notifier).loadProspects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to unassign: $e')),
      );
    }
  }

  void _showReassignProspectDialog(CrmProspect prospect) {
    final bankers = ref.read(bankersProvider).value ?? [];
    if (bankers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No bankers available to assign.')),
      );
      return;
    }

    final aiSuggestedIndex = prospect.id.hashCode.abs() % bankers.length;
    final aiSuggestedBanker = bankers[aiSuggestedIndex];

    Banker? selectedBanker;
    // Find who the banker is currently assigned to (if any)
    for (final b in bankers) {
      if (b.bankerId == prospect.bankerId) {
        selectedBanker = b;
        break;
      }
    }

    String _search = '';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final filteredBankers = bankers.where((b) {
              final name = (b.name ?? '').toLowerCase();
              final email = b.email.toLowerCase();
              final q = _search.toLowerCase();
              return name.contains(q) || email.contains(q);
            }).toList();

            final isAiSuggested = selectedBanker?.bankerId == aiSuggestedBanker.bankerId;
            final buttonText = isAiSuggested ? 'Reassign Prospect' : 'Override Match Recommendations';

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 520,
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.person_add_rounded, color: BankerColors.navy, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Reassign: ${prospect.name}',
                            style: const TextStyle(
                              fontFamily: 'DM Serif Display',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BankerColors.navy,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: BankerColors.muted),
                          onPressed: () => Navigator.pop(dialogContext),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a banker to assign to this prospect.',
                      style: TextStyle(color: BankerColors.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    // Search bar
                    TextField(
                      onChanged: (val) => setModalState(() => _search = val),
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search bankers by name or email...',
                        prefixIcon: const Icon(Icons.search, size: 16, color: BankerColors.muted),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BankerColors.line)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: BankerColors.line)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Column Headers
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9F9FB),
                        border: Border(bottom: BorderSide(color: BankerColors.line, width: 1)),
                      ),
                      child: Row(
                        children: const [
                          Expanded(flex: 3, child: Text('BANKER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                          Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                          Expanded(flex: 2, child: Text('AI SUGGESTED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: BankerColors.muted2))),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: filteredBankers.isEmpty
                          ? const Center(child: Text('No bankers found.', style: TextStyle(color: BankerColors.muted)))
                          : ListView.separated(
                              itemCount: filteredBankers.length,
                              separatorBuilder: (c, idx) => const Divider(height: 1, color: BankerColors.line),
                              itemBuilder: (c, idx) {
                                final b = filteredBankers[idx];
                                final isSelected = selectedBanker?.bankerId == b.bankerId;
                                final bIsSuggested = b.bankerId == aiSuggestedBanker.bankerId;
                                final bInitials = b.name != null
                                    ? b.name!.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
                                    : 'B';

                                return InkWell(
                                  onTap: () => setModalState(() => selectedBanker = b),
                                  child: Container(
                                    color: isSelected ? const Color(0xFFF0F4F8) : Colors.transparent,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    child: Row(
                                      children: [
                                        // Banker Info
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  color: isSelected ? BankerColors.navy : const Color(0xFFE2E8F0),
                                                  shape: BoxShape.circle,
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  bInitials,
                                                  style: TextStyle(
                                                    color: isSelected ? Colors.white : BankerColors.ink,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      b.name ?? b.email,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                        color: BankerColors.ink,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (b.name != null)
                                                      Text(
                                                        b.email,
                                                        style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Role
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: b.role == 'manager' ? const Color(0xFFFEF3C7) : const Color(0xFFF1F5F9),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                b.role == 'manager' ? 'Team Lead' : (b.position ?? 'Associate'),
                                                style: TextStyle(
                                                  color: b.role == 'manager' ? const Color(0xFF92400E) : const Color(0xFF475569),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        // AI Suggested
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: bIsSuggested
                                                ? Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFDCFCE7),
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: const [
                                                        Icon(Icons.auto_awesome, color: Color(0xFF166534), size: 10),
                                                        SizedBox(width: 4),
                                                        Text(
                                                          'AI Suggested',
                                                          style: TextStyle(color: Color(0xFF166534), fontSize: 9, fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                  )
                                                : const Text('—', style: TextStyle(color: BankerColors.muted2, fontSize: 11)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 16),
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          child: const Text('Cancel', style: TextStyle(color: BankerColors.muted)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (selectedBanker == null || isSaving)
                              ? null
                              : () async {
                                  setModalState(() => isSaving = true);
                                  try {
                                    await ConversationService().assignProspectToBanker(prospect.id, selectedBanker!.bankerId);
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Successfully reassigned ${prospect.name} to ${selectedBanker!.name ?? selectedBanker!.email}')),
                                    );
                                    ref.read(bankerProspectsProvider.notifier).loadProspects();
                                  } catch (e) {
                                    setModalState(() => isSaving = false);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to reassign: $e')),
                                    );
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAiSuggested ? BankerColors.navy : const Color(0xFFD97706),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: isSaving
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _StatItem {
  final String value;
  final String label;
  final String sub;
  final Color subColor;

  _StatItem({required this.value, required this.label, required this.sub, required this.subColor});
}

class BankerDetailPage extends ConsumerStatefulWidget {
  final String prospectId;

  const BankerDetailPage({
    key,
    required this.prospectId,
  }) : super(key: key);

  @override
  ConsumerState<BankerDetailPage> createState() => _BankerDetailPageState();
}

class _BankerDetailPageState extends ConsumerState<BankerDetailPage> {
  bool _inDirectMessagingMode = false;

  @override
  Widget build(BuildContext context) {
    final bankersAsync = ref.watch(bankersProvider);
    final activeBanker = ref.watch(activeBankerProvider);

    final List<Banker> navbarBankers = [
      ...(bankersAsync.value ?? []),
      const Banker(
        bankerId: 'datascience',
        email: 'datascience@convpredict.ai',
        name: 'Data Science View',
        position: 'Model & Conv Intelligence',
        role: 'datascience',
      ),
    ];

    // Auto-select banker with persistence
    bankersAsync.whenData((bankers) {
      final hasActiveBanker = activeBanker != null && 
          (activeBanker.bankerId == 'datascience' || bankers.any((b) => b.bankerId == activeBanker.bankerId));
      if (!hasActiveBanker && bankers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final savedId = await ProspectStorage().getActiveBankerId();
          if (savedId != null) {
            if (savedId == 'datascience') {
              ref.read(activeBankerProvider.notifier).state = const Banker(
                bankerId: 'datascience',
                email: 'datascience@convpredict.ai',
                name: 'Data Science View',
                position: 'Model & Conv Intelligence',
                role: 'datascience',
              );
            } else {
              final savedBanker = bankers.firstWhere(
                (b) => b.bankerId == savedId,
                orElse: () => bankers.first,
              );
              ref.read(activeBankerProvider.notifier).state = savedBanker;
              ProspectStorage().saveActiveBanker(savedBanker);
            }
          } else {
            ref.read(activeBankerProvider.notifier).state = bankers.first;
            ProspectStorage().saveActiveBanker(bankers.first);
          }
        });
      }
    });

    final bankerName = activeBanker?.name ??
        (bankersAsync.value?.isNotEmpty == true
            ? (bankersAsync.value!.first.name ?? 'Banker')
            : 'Loading...');
    final activeName = activeBanker?.name ?? 
        (bankersAsync.value?.isNotEmpty == true 
            ? (bankersAsync.value!.first.name ?? 'Banker') 
            : 'Loading...');
    final initials = activeName != 'Loading...'
        ? activeName.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join()
        : '...';

    final prospects = ref.watch(bankerProspectsProvider);
    // Find matching prospect
    final prospect = prospects.firstWhere(
      (p) => p.id == widget.prospectId,
      orElse: () => CrmProspect(
        id: widget.prospectId,
        name: 'Prospect',
        email: '',
        sector: 'Fintech',
        stage: 'Seed',
        status: 'In conversation',
        profileProgress: 0.5,
        docsReceivedText: '0/2 received',
        docsReceivedCount: 0,
        docsTotalCount: 2,
        materialsReadText: '0 / 1',
        materialsReadSub: '1 unread',
        lastActive: 'Today',
        avatarText: 'P',
        avatarBg: Colors.blue,
        avatarFg: Colors.white,
        docs: [],
        education: [],
        activity: [],
        notes: '',
      ),
    );

    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EE),
      body: SafeArea(
        child: Column(
          children: [
            HubNavBar(
              companyName: bankerName,
              founderName: bankerName,
              initials: initials,
              isBankerView: true,
              activeLabel: 'Banker View',
              bankers: navbarBankers,
              activeBanker: activeBanker,
              onBankerSelected: (banker) {
                ref.read(activeBankerProvider.notifier).state = banker;
                ProspectStorage().saveActiveBanker(banker);
                // Go back to the main banker dashboard
                context.go('/banker');
              },
              onLogout: () async {
                ProspectCache.clear();
                ProductCache.clear();
                await ProspectStorage().clearProspectId();
                if (context.mounted) {
                   context.go('/');
                }
              },
            ),
            if (activeBanker?.bankerId != 'datascience')
              NotificationsSection(
                isBanker: true,
                isDetailPage: true,
                prospectName: prospect.name,
                founderName: prospect.founderName,
                bankerName: bankerName,
                prospectsList: prospects,
              ),
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            color: Colors.white,
                            child: BankerDetailPanel(
                              prospectId: widget.prospectId,
                              showBackButton: true,
                              onMessageTap: () {
                                setState(() {
                                  _inDirectMessagingMode = true;
                                });
                              },
                            ),
                          ),
                          if (activeBanker?.bankerId != 'datascience') ...[
                            const Divider(height: 1, color: Color(0xFFE7DCC8)),
                            SizedBox(
                              height: 600,
                              child: AiGuidePanel(
                                prospectId: widget.prospectId,
                                bankerId: activeBanker?.bankerId,
                                founderName: prospect.name,
                                companyName: prospect.name,
                                industry: prospect.sector,
                                stageLabel: prospect.stage,
                                priorities: const [],
                                customActionLabel: 'Prospect Chats',
                                onCustomActionTap: () {},
                                bankerName: bankerName,
                                inDirectMessagingMode: _inDirectMessagingMode,
                                onBackToNova: () {
                                  setState(() {
                                    _inDirectMessagingMode = false;
                                  });
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Container(
                            color: Colors.white,
                            child: BankerDetailPanel(
                              prospectId: widget.prospectId,
                              showBackButton: true,
                              onMessageTap: () {
                                setState(() {
                                  _inDirectMessagingMode = true;
                                });
                              },
                            ),
                          ),
                        ),
                        if (activeBanker?.bankerId != 'datascience') ...[
                          const VerticalDivider(width: 1, color: Color(0xFFE7DCC8)),
                          SizedBox(
                            width: 420,
                            child: AiGuidePanel(
                              prospectId: widget.prospectId,
                              bankerId: activeBanker?.bankerId,
                              founderName: prospect.name,
                              companyName: prospect.name,
                              industry: prospect.sector,
                              stageLabel: prospect.stage,
                              priorities: const [],
                              customActionLabel: 'Prospect Chats',
                              onCustomActionTap: () {},
                              bankerName: bankerName,
                              inDirectMessagingMode: _inDirectMessagingMode,
                              onBackToNova: () {
                                setState(() {
                                  _inDirectMessagingMode = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildLeadBadge(String? lead) {
  if (lead == null) return const Text('—', style: TextStyle(color: BankerColors.muted));
  Color bg = const Color(0xFFF9FAFB);
  Color fg = const Color(0xFF374151);
  String icon = '';
  if (lead.toLowerCase() == 'hot') {
    bg = const Color(0xFFFEE2E2);
    fg = const Color(0xFFDC2626);
    icon = '🔥 ';
  } else if (lead.toLowerCase() == 'warm') {
    bg = const Color(0xFFFEF3C7);
    fg = const Color(0xFFD97706);
    icon = '🌤️ ';
  } else if (lead.toLowerCase() == 'cold') {
    bg = const Color(0xFFE0F2FE);
    fg = const Color(0xFF0284C7);
    icon = '❄️ ';
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      '$icon$lead',
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}

Widget _buildProbabilityCell(double? prob) {
  if (prob == null) return const Text('—', style: TextStyle(color: BankerColors.muted));
  final val = prob / 100.0;
  Color barColor = BankerColors.blue;
  if (prob >= 65) {
    barColor = const Color(0xFFE0533C);
  } else if (prob >= 35) {
    barColor = BankerColors.gold;
  } else {
    barColor = BankerColors.blue;
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        height: 5,
        width: 80,
        decoration: BoxDecoration(color: BankerColors.cream, borderRadius: BorderRadius.circular(999)),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: val,
          child: Container(
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
      const SizedBox(height: 3),
      Text('${prob.toInt()}%*', style: const TextStyle(fontSize: 10, color: BankerColors.muted2, fontWeight: FontWeight.bold)),
    ],
  );
}

Widget _buildPriorityBadge(String? priority) {
  if (priority == null) return const Text('—', style: TextStyle(color: BankerColors.muted));
  Color bg = const Color(0xFFF3F4F6);
  Color fg = const Color(0xFF4B5563);
  if (priority.toLowerCase() == 'high') {
    bg = const Color(0xFFFEE2E2);
    fg = const Color(0xFFB91C1C);
  } else if (priority.toLowerCase() == 'medium') {
    bg = const Color(0xFFFEF3C7);
    fg = const Color(0xFFB45309);
  } else if (priority.toLowerCase() == 'low') {
    bg = const Color(0xFFE5E7EB);
    fg = const Color(0xFF374151);
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      priority,
      style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
    ),
  );
}

