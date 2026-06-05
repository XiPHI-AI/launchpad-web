import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/hub_nav_bar.dart';
import '../../shared/widgets/prospect_id_provider.dart';
import '../../services/prospect_storage.dart';
import '../../services/conversation_service.dart';
import '../relationship_hub/relationship_hub_page.dart';

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
    );
  }
}

// --- RIVERPOD PROSPECTS STATE PROVIDER ---

class BankerProspectsNotifier extends StateNotifier<List<CrmProspect>> {
  BankerProspectsNotifier() : super([]) {
    loadProspects();
  }

  Future<void> loadProspects() async {
    try {
      final list = await ConversationService().listProspects();
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
        icon: IconData(
          a['codePoint'] as int? ?? Icons.chat_bubble_outline_rounded.codePoint,
          fontFamily: a['fontFamily'] as String? ?? 'MaterialIcons',
        ),
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

    int docsReceivedCount = docs.where((d) => d.status == 'Received').length;
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
      lastActive: mockMatch?.lastActive ?? 'Today',
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
  return await ConversationService().listBankers();
});

final activeBankerProvider = StateProvider<Banker?>((ref) {
  return ProspectStorage().getActiveBankerSync();
});

final bankerProspectsProvider = StateNotifierProvider<BankerProspectsNotifier, List<CrmProspect>>((ref) {
  return BankerProspectsNotifier();
});

// --- STANDALONE DETAIL PANEL ---

class BankerDetailPanel extends ConsumerStatefulWidget {
  final String prospectId;
  final bool showBackButton;
  final VoidCallback? onClose;

  const BankerDetailPanel({
    super.key,
    required this.prospectId,
    this.showBackButton = false,
    this.onClose,
  });

  @override
  ConsumerState<BankerDetailPanel> createState() => _BankerDetailPanelState();
}

class _BankerDetailPanelState extends ConsumerState<BankerDetailPanel> {
  String _activeTab = 'assign';
  final TextEditingController _notesController = TextEditingController();
  List<ProductPublic> _products = [];
  bool _loadingProducts = false;
  List<String> _suggestedQuestions = [];
  bool _loadingQuestions = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchSuggestedQuestions();
  }

  @override
  void didUpdateWidget(covariant BankerDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.prospectId != widget.prospectId) {
      _fetchProducts();
      _fetchSuggestedQuestions();
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
    _notesController.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final prospects = ref.watch(bankerProspectsProvider);
    
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: BankerColors.line2)),
          ),
          child: Row(
            children: [
              ElevatedButton(
                onPressed: () => _showAssignModal(context, prospect),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BankerColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '+ Assign education',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => _showDocModal(context, prospect),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: BankerColors.line2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  '+ Request doc',
                  style: TextStyle(fontSize: 11, color: BankerColors.ink, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                onPressed: () => _showMsgModal(context, prospect),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: BankerColors.line2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text(
                  'Message',
                  style: TextStyle(fontSize: 11, color: BankerColors.ink, fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (!widget.showBackButton)
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
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: BankerColors.line2)),
          ),
          child: Row(
            children: [
              _buildTabButton('Next steps', 'assign'),
              _buildTabButton('Recommended products', 'products'),
              _buildTabButton('Suggested questions', 'questions'),
              _buildTabButton('Notes', 'notes'),
            ],
          ),
        ),

        // Tab Content
        Expanded(
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: _buildActiveTabContent(prospect),
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
                color: isActive ? BankerColors.navy : Colors.transparent,
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

  Widget _buildActiveTabContent(CrmProspect prospect) {
    switch (_activeTab) {
      case 'assign':
        return _buildNextStepsTab(prospect);
      case 'products':
        return _buildRecommendedProductsTab(prospect);
      case 'questions':
        return _buildSuggestedQuestionsTab(prospect);
      case 'notes':
        return _buildNotesTab(prospect);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildNextStepsTab(CrmProspect prospect) {
    final docsTotal = prospect.docsTotalCount;
    final docsReceived = prospect.docsReceivedCount;
    final materialsReadText = prospect.materialsReadText;
    final materialsReadSub = prospect.materialsReadSub;

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

        // 2. Documents Requested Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Documents requested',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.navy),
            ),
            GestureDetector(
              onTap: () => _showDocModal(context, prospect),
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  '+ Request',
                  style: TextStyle(fontSize: 10, color: BankerColors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (prospect.docs.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No documents requested yet.',
              style: TextStyle(fontSize: 11, color: BankerColors.muted),
            ),
          )
        else
          Column(
            children: prospect.docs.map((doc) {
              Color statusColor = BankerColors.muted2;
              Color statusBg = BankerColors.cream;
              if (doc.status == 'Received') {
                statusColor = const Color(0xFF0F6E56);
                statusBg = BankerColors.greenSoft;
              } else if (doc.status == 'Needs review') {
                statusColor = const Color(0xFF7C5410);
                statusBg = BankerColors.amberSoft;
              } else if (doc.status == 'Not uploaded') {
                statusColor = const Color(0xFF991B1B);
                statusBg = BankerColors.redSoft;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: BankerColors.cream,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file_outlined, size: 12, color: BankerColors.muted2),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        doc.name,
                        style: const TextStyle(fontSize: 11, color: BankerColors.ink, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        doc.status,
                        style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 18),

        // 3. Education Assigned Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Education assigned',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.navy),
            ),
            GestureDetector(
              onTap: () => _showAssignModal(context, prospect),
              child: const MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Text(
                  '+ Assign',
                  style: TextStyle(fontSize: 10, color: BankerColors.blue, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        if (prospect.education.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No education guides assigned yet.',
              style: TextStyle(fontSize: 11, color: BankerColors.muted),
            ),
          )
        else
          Column(
            children: prospect.education.map((edu) {
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: BankerColors.cream,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 28,
                      decoration: BoxDecoration(
                        color: edu.stripeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            edu.title,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: BankerColors.ink),
                          ),
                          const SizedBox(height: 1),
                          Row(
                            children: [
                              _buildEduTag(edu.tag),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  edu.status.replaceAll('${edu.tag} · ', ''),
                                  style: const TextStyle(fontSize: 10, color: BankerColors.muted2),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ref.read(bankerProspectsProvider.notifier).removeEducation(prospect.id, edu.title);
                      },
                      child: const MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Icon(Icons.close, size: 14, color: BankerColors.muted2),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
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
        const Text(
          'Recommended J.P. Morgan products matching stage & sector fit:',
          style: TextStyle(fontSize: 11, color: BankerColors.muted2),
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
                cta: 'By ${product.provider?.companyName ?? 'J.P. Morgan'}',
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

    final questions = _suggestedQuestions.isNotEmpty ? _suggestedQuestions : [
      'How can J.P. Morgan help us extend our runway given our current stage?',
      'What are the requirements and onboarding timelines for setting up multi-currency accounts or global banking at J.P. Morgan?',
      'How do your transaction fees and payment gateway integrations compare to standard processors we are using?',
      'What venture debt options are available for us to complement our upcoming fundraising rounds?',
    ];

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
        )),
      ],
    );
  }

  Widget _buildNotesTab(CrmProspect prospect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Private · only visible to you',
          style: TextStyle(fontSize: 11, color: BankerColors.muted2),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: BankerColors.cream,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: BankerColors.line2),
          ),
          child: TextField(
            controller: _notesController,
            maxLines: 8,
            style: const TextStyle(fontSize: 11, color: BankerColors.ink, height: 1.4),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: ElevatedButton(
            onPressed: () {
              ref.read(bankerProspectsProvider.notifier).updateNotes(prospect.id, _notesController.text);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Note saved successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: BankerColors.navy,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save note', style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
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
  String _searchQuery = '';
  String _sortColumn = 'Company';
  bool _sortAscending = true;

  // Active hover row
  int? _hoveredIndex;

  // Text controller for search
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- FILTER & SORT LOGIC ---
  List<CrmProspect> _getFilteredAndSortedProspects(List<CrmProspect> prospects) {
    // 1. Filter
    List<CrmProspect> filtered = prospects.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sector.toLowerCase().contains(_searchQuery.toLowerCase());
      if (!matchesSearch) return false;

      if (_activeFilter == 'all') return true;
      if (_activeFilter == 'action') {
        return p.status.contains('Awaiting docs') || p.status.contains('Call');
      }
      if (_activeFilter == 'call') {
        return p.status.contains('Call');
      }
      if (_activeFilter == 'docs') {
        return p.status.contains('Awaiting docs');
      }
      if (_activeFilter == 'done') {
        return p.status.contains('Fully onboarded');
      }
      return true;
    }).toList();

    // 2. Sort
    filtered.sort((a, b) {
      int cmp = 0;
      switch (_sortColumn) {
        case 'Company':
          cmp = a.name.compareTo(b.name);
          break;
        case 'Stage':
          cmp = a.stage.compareTo(b.stage);
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

    // Auto-select banker with persistence
    bankersAsync.whenData((bankers) {
      if (activeBanker == null && bankers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final savedId = await ProspectStorage().getActiveBankerId();
          if (savedId != null) {
            final savedBanker = bankers.firstWhere(
              (b) => b.bankerId == savedId,
              orElse: () => bankers.first,
            );
            ref.read(activeBankerProvider.notifier).state = savedBanker;
            ProspectStorage().saveActiveBanker(savedBanker);
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
      return p.bankerId == activeBanker.bankerId;
    }).toList();

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
          bankers: bankersAsync.value ?? [],
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. SUMMARY BAR
          _buildSummaryBar(
            isMobile: isMobile,
            activeCount: activeCount,
            needsActionCount: needsActionCount,
            callsCount: callsCount,
            awaitingDocsCount: awaitingDocsCount,
            onboardedCount: onboardedCount,
          ),

          // 2. TOOLBAR
          _buildToolbar(isMobile),

          // 3. FULL-WIDTH TABLE REGION
          Expanded(
            child: Container(
              color: Colors.white,
              child: _buildCrmTable(prospects),
            ),
          ),
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
      _StatItem(value: '$needsActionCount', label: 'Need action', sub: '⚠ Review today', subColor: const Color(0xFFD97706)),
      _StatItem(value: '$callsCount', label: 'Calls this week', sub: 'Next: May 6', subColor: BankerColors.muted2),
      _StatItem(value: '$awaitingDocsCount', label: 'Awaiting docs', sub: '4 overdue', subColor: const Color(0xFFD97706)),
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
                  const SizedBox(height: 2),
                  Text(
                    stat.sub,
                    style: TextStyle(fontSize: 10, color: stat.subColor, fontWeight: FontWeight.w600),
                  ),
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
                  const SizedBox(height: 3),
                  Text(
                    stat.sub,
                    style: TextStyle(fontSize: 10, color: stat.subColor, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildToolbar(bool isMobile) {
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
          Row(
            mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 5),
                      _buildFilterChip('⚠ Needs action', 'action'),
                      const SizedBox(width: 5),
                      _buildFilterChip('📅 Call scheduled', 'call'),
                      const SizedBox(width: 5),
                      _buildFilterChip('📄 Awaiting docs', 'docs'),
                      const SizedBox(width: 5),
                      _buildFilterChip('✓ Onboarded', 'done'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Exporting prospects list to CSV...'), duration: Duration(seconds: 2)),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  side: const BorderSide(color: BankerColors.line2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Export', style: TextStyle(fontSize: 11, color: BankerColors.ink, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _showAddProspectDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BankerColors.navy,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('+ Add prospect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildCrmTable(List<CrmProspect> prospects) {
    final list = _getFilteredAndSortedProspects(prospects);

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
              _buildHeaderCell('Stage', flex: 1),
              _buildHeaderCell('Status', flex: 2),
              _buildHeaderCell('Profile', flex: 2),
              _buildHeaderCell('Docs', flex: 2),
              _buildHeaderCell('Materials read', flex: 2),
              _buildHeaderCell('Last active', flex: 2),
              _buildHeaderCell('Actions', flex: 2, sortable: false),
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
                              // Stage
                              Expanded(
                                flex: 1,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Text(prospect.stage, style: const TextStyle(fontSize: 11, color: BankerColors.muted)),
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
                                  child: _buildDocsBadge(prospect.docsReceivedText),
                                ),
                              ),
                              // Materials
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(prospect.materialsReadText, style: const TextStyle(fontSize: 11, color: BankerColors.ink)),
                                      if (prospect.materialsReadSub.isNotEmpty)
                                        Text(
                                          prospect.materialsReadSub,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: prospect.materialsReadSub.contains('✓') ? BankerColors.green : BankerColors.muted2,
                                            fontWeight: prospect.materialsReadSub.contains('✓') ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              // Last Active
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.centerLeft,
                                  child: Text(prospect.lastActive, style: const TextStyle(fontSize: 11, color: BankerColors.ink)),
                                ),
                              ),
                              // Actions
                              Expanded(
                                flex: 2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  alignment: Alignment.center,
                                  child: isHovered
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                // Quick action to individual Banker detail page
                                                context.go('/banker/${prospect.id}');
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(color: BankerColors.navy, borderRadius: BorderRadius.circular(6)),
                                                child: const Text('Assign', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            GestureDetector(
                                              onTap: () {
                                                context.go('/banker/${prospect.id}');
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  border: Border.all(color: BankerColors.line2),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  prospect.status.contains('Waiting') ? 'Nudge' : 'Message',
                                                  style: const TextStyle(fontSize: 10, color: BankerColors.ink),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : const SizedBox.shrink(),
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

  Widget _buildDocsBadge(String text) {
    Color bg = BankerColors.cream;
    Color fg = BankerColors.muted2;

    if (text.contains('1/')) {
      bg = BankerColors.amberSoft;
      fg = const Color(0xFF7C5410);
    } else if (text.contains('0/')) {
      bg = BankerColors.redSoft;
      fg = const Color(0xFF991B1B);
    } else if (text.contains('3/3') || text.contains('4/4')) {
      bg = BankerColors.greenSoft;
      fg = const Color(0xFF0F6E56);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: TextStyle(fontSize: 10, color: fg, fontWeight: FontWeight.w600)),
    );
  }

  void _showAddProspectDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final sectorCtrl = TextEditingController();
    String stage = 'Seed';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Prospect',
                      style: TextStyle(fontFamily: 'DM Serif Display', fontSize: 18, fontWeight: FontWeight.bold, color: BankerColors.navy),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Company Name', labelStyle: TextStyle(fontSize: 12), border: OutlineInputBorder()),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(fontSize: 12), border: OutlineInputBorder()),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: sectorCtrl,
                      decoration: const InputDecoration(labelText: 'Sector / Industry', labelStyle: TextStyle(fontSize: 12), border: OutlineInputBorder()),
                      enabled: !isSaving,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: stage,
                      decoration: const InputDecoration(labelText: 'Funding Stage', labelStyle: TextStyle(fontSize: 12), border: OutlineInputBorder()),
                      items: ['Pre-seed', 'Seed', 'Series A', 'Series B'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: isSaving ? null : (val) {
                        if (val != null) {
                          setModalState(() => stage = val);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isSaving ? null : () => Navigator.pop(dialogContext), 
                          child: const Text('Cancel', style: TextStyle(color: BankerColors.muted))
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: isSaving ? null : () async {
                            final name = nameCtrl.text.trim();
                            final email = emailCtrl.text.trim();
                            final sector = sectorCtrl.text.trim();
                            
                            if (name.isEmpty || email.isEmpty) return;

                            setModalState(() => isSaving = true);

                            String stageBucket = 'super_agent';
                            String companyStage = 'seed';
                            if (stage == 'Pre-seed') {
                              stageBucket = 'pre_seed';
                              companyStage = 'pre_seed';
                            } else if (stage == 'Seed') {
                              stageBucket = 'seed';
                              companyStage = 'seed';
                            } else if (stage == 'Series A') {
                              stageBucket = 'early_stage';
                              companyStage = 'series_a';
                            } else if (stage == 'Series B') {
                              stageBucket = 'growth_stage';
                              companyStage = 'series_b_plus';
                            }

                            try {
                              // Create the prospect in PostgreSQL
                              final prospectId = await ConversationService().createProspect(stageBucket, email: email);
                              
                              final initialSnapshot = {
                                'status': '⏳ Waiting — no chat yet',
                                'userEmail': email,
                              };
                              
                              // Update details
                              await ConversationService().updateProspectProfile(
                                prospectId,
                                email: email,
                                companyName: name,
                                industry: sector.isEmpty ? 'Technology' : sector,
                                companyStage: companyStage,
                                fullName: name,
                                profileSnapshot: initialSnapshot,
                              );

                              final initials = name.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();
                              final newProspect = CrmProspect(
                                id: prospectId,
                                name: name,
                                email: email,
                                sector: sector.isEmpty ? 'Technology' : sector,
                                stage: stage,
                                status: '⏳ Waiting — no chat yet',
                                profileProgress: 0.15,
                                docsReceivedText: 'None assigned',
                                docsReceivedCount: 0,
                                docsTotalCount: 0,
                                materialsReadText: '—',
                                materialsReadSub: '',
                                lastActive: 'Today',
                                avatarText: initials.isEmpty ? 'C' : initials,
                                avatarBg: BankerColors.blueSoft,
                                avatarFg: BankerColors.blue,
                                docs: [],
                                education: [],
                                activity: [
                                  CrmActivity(
                                    icon: Icons.input_rounded,
                                    iconBg: BankerColors.purpleSoft,
                                    iconColor: const Color(0xFF6B21A8),
                                    text: 'Prospect manually added to system',
                                    time: 'Today',
                                  ),
                                ],
                                notes: '',
                              );

                              ref.read(bankerProspectsProvider.notifier).addProspect(newProspect);
                              Navigator.pop(dialogContext);
                            } catch (e) {
                              print("Failed to manually create prospect: $e");
                              setModalState(() => isSaving = false);
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: BankerColors.navy, foregroundColor: Colors.white),
                          child: isSaving 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Create'),
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

class BankerDetailPage extends ConsumerWidget {
  final String prospectId;

  const BankerDetailPage({
    key,
    required this.prospectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bankersAsync = ref.watch(bankersProvider);
    final activeBanker = ref.watch(activeBankerProvider);

    // Auto-select banker with persistence
    bankersAsync.whenData((bankers) {
      if (activeBanker == null && bankers.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final savedId = await ProspectStorage().getActiveBankerId();
          if (savedId != null) {
            final savedBanker = bankers.firstWhere(
              (b) => b.bankerId == savedId,
              orElse: () => bankers.first,
            );
            ref.read(activeBankerProvider.notifier).state = savedBanker;
            ProspectStorage().saveActiveBanker(savedBanker);
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
      (p) => p.id == prospectId,
      orElse: () => CrmProspect(
        id: prospectId,
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
              bankers: bankersAsync.value ?? [],
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
            const NotificationsSection(),
            Expanded(
              child: isMobile
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            color: Colors.white,
                            child: BankerDetailPanel(
                              prospectId: prospectId,
                              showBackButton: true,
                            ),
                          ),
                          const Divider(height: 1, color: Color(0xFFE7DCC8)),
                          SizedBox(
                            height: 600,
                            child: AiGuidePanel(
                              prospectId: prospectId,
                              founderName: prospect.name,
                              companyName: prospect.name,
                              industry: prospect.sector,
                              stageLabel: prospect.stage,
                              priorities: const [],
                              customActionLabel: 'Prospect Chats',
                              onCustomActionTap: () {},
                              bankerName: bankerName,
                            ),
                          ),
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
                              prospectId: prospectId,
                              showBackButton: true,
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, color: Color(0xFFE7DCC8)),
                        SizedBox(
                          width: 420,
                          child: AiGuidePanel(
                            prospectId: prospectId,
                            founderName: prospect.name,
                            companyName: prospect.name,
                            industry: prospect.sector,
                            stageLabel: prospect.stage,
                            priorities: const [],
                            customActionLabel: 'Prospect Chats',
                            onCustomActionTap: () {},
                            bankerName: bankerName,
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
}
