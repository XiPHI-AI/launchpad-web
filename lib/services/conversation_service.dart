import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ProspectClassification {
  final String? inferredStageBucket;
  final double? inferredStageConfidence;
  final String? inferredStageConfidenceLabel;
  final List<String> inferredStageReasons;
  final String? inferredStageUpdatedAt;
  final String? confirmedStageBucket;
  final String? stageSelectionSource;
  final String? confirmedStageUpdatedAt;

  const ProspectClassification({
    this.inferredStageBucket,
    this.inferredStageConfidence,
    this.inferredStageConfidenceLabel,
    this.inferredStageReasons = const [],
    this.inferredStageUpdatedAt,
    this.confirmedStageBucket,
    this.stageSelectionSource,
    this.confirmedStageUpdatedAt,
  });

  bool get hasClassification =>
      inferredStageBucket != null && inferredStageBucket!.isNotEmpty;
}

class UpdateProspectClassificationResult {
  final String prospectId;
  final ProspectClassification classification;

  const UpdateProspectClassificationResult({
    required this.prospectId,
    required this.classification,
  });
}

class ProspectInitResult {
  final String prospectId;
  final String stageBucket;
  final String agentDisplayName;
  final int conversationPhase;
  final bool isReturning;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? companyName;
  final bool incorporated;
  final String? companyStage;
  final String? industry;
  final String? headcount;
  final Map<String, bool> selectedPrioritiesJson;
  final ProspectClassification? classification;
  final Map<String, dynamic> profileSnapshot;
  final String? bankerId;
  final String? bankerName;
  final String? bankerPosition;

  ProspectInitResult({
    required this.prospectId,
    required this.stageBucket,
    required this.agentDisplayName,
    this.conversationPhase = 1,
    this.isReturning = false,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.companyName,
    this.incorporated = false,
    this.companyStage,
    this.industry,
    this.headcount,
    this.selectedPrioritiesJson = const {},
    this.classification,
    this.profileSnapshot = const {},
    this.bankerId,
    this.bankerName,
    this.bankerPosition,
  });

  Map<String, dynamic> toDynamicVariables({bool lockProfileFields = false}) {
    final selectedPriorities = selectedPrioritiesJson.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    return {
      'is_return_visit': isReturning,
      'lock_profile_fields': lockProfileFields,
      if (fullName != null) 'userName': fullName,
      if (email != null) 'userEmail': email,
      if (phoneNumber != null) 'userPhone': phoneNumber,
      if (companyName != null) 'companyName': companyName,
      'isPostIncorporated': incorporated,
      if (companyStage != null) 'stage': companyStage,
      if (industry != null) 'industry': industry,
      if (headcount != null) 'headcount': headcount,
      if (selectedPrioritiesJson.isNotEmpty)
        'selectedPriorities': selectedPrioritiesJson,
      if (selectedPriorities.isNotEmpty) 'priorities': selectedPriorities,
    };
  }
}

/// Response from the voice-token endpoint.
class VoiceTokenResult {
  final String conversationToken;
  final String agentId;
  final String stageBucket;
  final String? prospectId;
  final bool isReturningUser;
  final Map<String, dynamic> dynamicVariables;

  VoiceTokenResult({
    required this.conversationToken,
    required this.agentId,
    required this.stageBucket,
    this.prospectId,
    this.isReturningUser = false,
    this.dynamicVariables = const {},
  });
}

class RelationshipHubChatResult {
  final String replyMarkdown;
  final Map<String, dynamic> rawResponse;

  const RelationshipHubChatResult({
    required this.replyMarkdown,
    this.rawResponse = const {},
  });
}

class ChatHistoryMessage {
  final int id;
  final String type;
  final String content;

  const ChatHistoryMessage({
    required this.id,
    required this.type,
    required this.content,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    return ChatHistoryMessage(
      id: json['id'] as int,
      type: json['type'] as String? ?? '',
      content: json['content'] as String? ?? '',
    );
  }
}

class ChatHistoryResult {
  final List<ChatHistoryMessage> messages;
  final int total;
  final bool hasMore;

  const ChatHistoryResult({
    required this.messages,
    required this.total,
    required this.hasMore,
  });
}

/// Combined profile: form data + AI-collected attributes from ElevenLabs conversations.
class ProviderPublic {
  final String providerId;
  final String companyName;
  final String? description;
  final String? websiteUrl;
  final String? hqLocation;
  final int? foundedYear;
  final String? logoUrl;

  ProviderPublic({
    required this.providerId,
    required this.companyName,
    this.description,
    this.websiteUrl,
    this.hqLocation,
    this.foundedYear,
    this.logoUrl,
  });

  factory ProviderPublic.fromJson(Map<String, dynamic> json) {
    return ProviderPublic(
      providerId: json['provider_id'] as String,
      companyName: json['company_name'] as String,
      description: json['description'] as String?,
      websiteUrl: json['website_url'] as String?,
      hqLocation: json['hq_location'] as String?,
      foundedYear: json['founded_year'] as int?,
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class ProductPublic {
  final String productId;
  final String name;
  final String category;
  final String? subcategory;
  final String description;
  final String? shortDescription;
  final Map<String, dynamic> eligibilityCriteria;
  final List<String> stageFit;
  final List<String> targetIndustries;
  final String? pricingModel;
  final String? pricingDetails;
  final List<dynamic> features;
  final List<String> benefits;
  final String? integrationInfo;
  final String? signupUrl;
  final double? matchScore;
  final String? matchReasoning;
  final String? paraphrasedMatchReasoning;
  final ProviderPublic? provider;

  ProductPublic({
    required this.productId,
    required this.name,
    required this.category,
    this.subcategory,
    required this.description,
    this.shortDescription,
    this.eligibilityCriteria = const {},
    this.stageFit = const [],
    this.targetIndustries = const [],
    this.pricingModel,
    this.pricingDetails,
    this.features = const [],
    this.benefits = const [],
    this.integrationInfo,
    this.signupUrl,
    this.matchScore,
    this.matchReasoning,
    this.paraphrasedMatchReasoning,
    this.provider,
  });

  factory ProductPublic.fromJson(Map<String, dynamic> json) {
    return ProductPublic(
      productId: json['product_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      description: json['description'] as String,
      shortDescription: json['short_description'] as String?,
      eligibilityCriteria:
          Map<String, dynamic>.from(json['eligibility_criteria'] ?? {}),
      stageFit: List<String>.from(json['stage_fit'] ?? []),
      targetIndustries: List<String>.from(json['target_industries'] ?? []),
      pricingModel: json['pricing_model'] as String?,
      pricingDetails: json['pricing_details'] as String?,
      features: List<dynamic>.from(json['features'] ?? []),
      benefits: List<String>.from(json['benefits'] ?? []),
      integrationInfo: json['integration_info'] as String?,
      signupUrl: json['signup_url'] as String?,
      matchScore: (json['match_score'] as num?)?.toDouble(),
      matchReasoning: json['match_reasoning'] as String?,
      paraphrasedMatchReasoning: json['paraphrased_match_reasoning'] as String?,
      provider: json['provider'] != null
          ? ProviderPublic.fromJson(json['provider'])
          : null,
    );
  }
}

class ProspectFullProfile {
  final String prospectId;
  final String? email;
  final String? fullName;
  final String? phoneNumber;
  final String? companyName;
  final bool incorporated;
  final String? companyStage;
  final String? industry;
  final String? headcount;
  final Map<String, bool> selectedPrioritiesJson;
  final String? stageBucket;
  final int conversationCount;
  final int conversationPhase;
  final String? invitationCode;
  final Map<String, dynamic> aiAttributes;
  final Map<String, dynamic> aiAttributesHistorical;
  final String? bankerId;

  const ProspectFullProfile({
    required this.prospectId,
    this.email,
    this.fullName,
    this.phoneNumber,
    this.companyName,
    this.incorporated = false,
    this.companyStage,
    this.industry,
    this.headcount,
    this.selectedPrioritiesJson = const {},
    this.stageBucket,
    this.conversationCount = 0,
    this.conversationPhase = 1,
    this.invitationCode,
    this.aiAttributes = const {},
    this.aiAttributesHistorical = const {},
    this.bankerId,
  });
}

class Banker {
  final String bankerId;
  final String email;
  final String? name;
  final String? position;
  final String? role;

  const Banker({
    required this.bankerId,
    required this.email,
    this.name,
    this.position,
    this.role,
  });

  factory Banker.fromJson(Map<String, dynamic> json) {
    return Banker(
      bankerId: json['banker_id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      position: json['position'] as String?,
      role: json['role'] as String?,
    );
  }
}


class CheckpointMaster {
  final String checkpointId;
  final String category;
  final String title;
  final String? description;
  final List<String> miniCheckpoints;

  const CheckpointMaster({
    required this.checkpointId,
    required this.category,
    required this.title,
    this.description,
    required this.miniCheckpoints,
  });

  factory CheckpointMaster.fromJson(Map<String, dynamic> json) {
    return CheckpointMaster(
      checkpointId: json['checkpoint_id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      miniCheckpoints: List<String>.from(json['mini_checkpoints'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'checkpoint_id': checkpointId,
      'category': category,
      'title': title,
      'description': description,
      'mini_checkpoints': miniCheckpoints,
    };
  }
}

class ProspectCheckpoint {
  final String id;
  final String prospectId;
  final String checkpointId;
  final String? documentId;
  final bool checked;
  final Map<String, String> miniCheckpointAnswers;
  final CheckpointMaster? checkpoint;

  const ProspectCheckpoint({
    required this.id,
    required this.prospectId,
    required this.checkpointId,
    this.documentId,
    required this.checked,
    required this.miniCheckpointAnswers,
    this.checkpoint,
  });

  factory ProspectCheckpoint.fromJson(Map<String, dynamic> json) {
    return ProspectCheckpoint(
      id: json['id'] as String,
      prospectId: json['prospect_id'] as String,
      checkpointId: json['checkpoint_id'] as String,
      documentId: json['document_id'] as String?,
      checked: json['checked'] as bool? ?? false,
      miniCheckpointAnswers: Map<String, String>.from(json['mini_checkpoint_answers'] ?? {}),
      checkpoint: json['checkpoint'] != null
          ? CheckpointMaster.fromJson(json['checkpoint'] as Map<String, dynamic>)
          : null,
    );
  }

  ProspectCheckpoint copyWith({
    String? id,
    String? prospectId,
    String? checkpointId,
    String? documentId,
    bool? checked,
    Map<String, String>? miniCheckpointAnswers,
    CheckpointMaster? checkpoint,
  }) {
    return ProspectCheckpoint(
      id: id ?? this.id,
      prospectId: prospectId ?? this.prospectId,
      checkpointId: checkpointId ?? this.checkpointId,
      documentId: documentId ?? this.documentId,
      checked: checked ?? this.checked,
      miniCheckpointAnswers: miniCheckpointAnswers ?? this.miniCheckpointAnswers,
      checkpoint: checkpoint ?? this.checkpoint,
    );
  }
}

class ProspectDocument {
  final String documentId;
  final String prospectId;
  final String fileName;
  final String version;
  final String status;
  final double confidenceScore;
  final String? comparisonReport;
  final String? previousVersionDocumentId;
  final String? driveLink;
  final DateTime uploadedAt;

  const ProspectDocument({
    required this.documentId,
    required this.prospectId,
    required this.fileName,
    this.version = 'v1.0',
    this.status = 'Approved',
    this.confidenceScore = 0.85,
    this.comparisonReport,
    this.previousVersionDocumentId,
    this.driveLink,
    required this.uploadedAt,
  });

  factory ProspectDocument.fromJson(Map<String, dynamic> json) {
    return ProspectDocument(
      documentId: json['document_id'] as String,
      prospectId: json['prospect_id'] as String,
      fileName: json['file_name'] as String,
      version: json['version'] as String? ?? 'v1.0',
      status: json['status'] as String? ?? 'Approved',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.85,
      comparisonReport: json['comparison_report'] as String?,
      previousVersionDocumentId: json['previous_version_document_id'] as String?,
      driveLink: json['drive_link'] as String?,
      uploadedAt: DateTime.parse(json['uploaded_at'] as String).toLocal(),
    );
  }
}

class DocumentAuditLog {
  final String logId;
  final String documentId;
  final String action;
  final String actor;
  final DateTime performedAt;

  const DocumentAuditLog({
    required this.logId,
    required this.documentId,
    required this.action,
    required this.actor,
    required this.performedAt,
  });

  factory DocumentAuditLog.fromJson(Map<String, dynamic> json) {
    return DocumentAuditLog(
      logId: json['log_id'] as String,
      documentId: json['document_id'] as String,
      action: json['action'] as String,
      actor: json['actor'] as String,
      performedAt: DateTime.parse(json['performed_at'] as String).toLocal(),
    );
  }
}


class MatchReasoningResult {
  final String productId;
  final String prospectId;
  final String rawReasoning;
  final String paraphrasedReasoning;
  final double matchScore;

  const MatchReasoningResult({
    required this.productId,
    required this.prospectId,
    required this.rawReasoning,
    required this.paraphrasedReasoning,
    required this.matchScore,
  });

  factory MatchReasoningResult.fromJson(Map<String, dynamic> json) {
    return MatchReasoningResult(
      productId: json['product_id'] as String,
      prospectId: json['prospect_id'] as String,
      rawReasoning: json['raw_reasoning'] as String? ?? '',
      paraphrasedReasoning: json['paraphrased_reasoning'] as String? ?? '',
      matchScore: (json['match_score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}


class DirectMessage {
  final String messageId;
  final String prospectId;
  final String bankerId;
  final String sender;
  final String content;
  final DateTime createdAt;
  final DateTime? readAt;

  const DirectMessage({
    required this.messageId,
    required this.prospectId,
    required this.bankerId,
    required this.sender,
    required this.content,
    required this.createdAt,
    this.readAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    return DirectMessage(
      messageId: json['message_id'] as String,
      prospectId: json['prospect_id'] as String,
      bankerId: json['banker_id'] as String,
      sender: json['sender'] as String,
      content: json['content'] as String,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String).toLocal() : null,
    );
  }
}


class ConversationService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 60),
    receiveTimeout: const Duration(seconds: 60),
  ));

  // Static in-memory cache to share reasoning between different card/modal instances.
  // Key format: "prospectId_productId" -> { "raw": "...", "result": MatchReasoningResult }
  static final Map<String, Map<String, dynamic>> _reasoningCache = {};

  static MatchReasoningResult? getCachedReasoning(String prospectId, String productId, String? currentRaw) {
    final cacheKey = '${prospectId}_$productId';
    final cachedEntry = _reasoningCache[cacheKey];
    if (cachedEntry != null && cachedEntry['raw'] == currentRaw) {
      return cachedEntry['result'] as MatchReasoningResult;
    }
    return null;
  }

  /// Creates a pre-auth prospect and returns the prospect_id.
  Future<String> createProspect(String stageBucket, {String? email}) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect',
      data: {
        'stage_bucket': stageBucket,
        if (email != null) 'email': email,
      },
    );
    return response.data['prospect_id'] as String;
  }

  Future<void> updateProspectProfile(
    String prospectId, {
    required String email,
    String? fullName,
    String? phoneNumber,
    String? companyName,
    bool? incorporated,
    String? companyStage,
    String? industry,
    String? headcount,
    Map<String, bool>? selectedPrioritiesJson,
    Map<String, dynamic>? profileSnapshot,
  }) async {
    await _dio.patch(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/profile',
      data: {
        'email': email,
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (companyName != null) 'company_name': companyName,
        if (incorporated != null) 'incorporated': incorporated,
        if (companyStage != null) 'company_stage': companyStage,
        if (industry != null) 'industry': industry,
        if (headcount != null) 'headcount': headcount,
        if (selectedPrioritiesJson != null)
          'selected_priorities_json': selectedPrioritiesJson,
        if (profileSnapshot != null)
          'profile_snapshot': profileSnapshot,
      },
    );
  }

  /// Initialize a prospect session from an invitation code.
  /// Resolves the invitation code to a stage_bucket and agent.
  Future<ProspectInitResult> initProspect(
    String invitationCode, {
    String? email,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect/init',
      data: {
        'invitation_code': invitationCode,
        if (email != null) 'email': email,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return ProspectInitResult(
      prospectId: data['prospect_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      agentDisplayName: data['agent_display_name'] as String,
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning: data['is_returning'] as bool? ?? false,
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value == true,
            ),
          ) ??
          const {},
      profileSnapshot: data['profile_snapshot'] as Map<String, dynamic>? ?? const {},
      bankerId: data['banker_id'] as String?,
      bankerName: data['banker_name'] as String?,
      bankerPosition: data['banker_position'] as String?,
    );
  }

  /// Fetches an existing prospect by email for pre-filling.
  Future<ProspectInitResult> lookupProspectByEmail(String email) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/lookup-email/$email',
    );
    final data = response.data as Map<String, dynamic>;
    final conversationCount = data['conversation_count'] as int? ?? 0;
    return ProspectInitResult(
      prospectId: data['prospect_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      agentDisplayName:
          data['agent_display_name'] as String? ?? 'your JPMC AI Advisor',
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning:
          data['is_returning_user'] as bool? ?? (conversationCount > 0),
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value == true,
            ),
          ) ??
          const {},
      profileSnapshot: data['profile_snapshot'] as Map<String, dynamic>? ?? const {},
      bankerId: data['banker_id'] as String?,
      bankerName: data['banker_name'] as String?,
      bankerPosition: data['banker_position'] as String?,
    );
  }

  /// Fetches an existing prospect by ID.
  /// Used for return visits via /?p=<UUID>.
  Future<ProspectInitResult> getProspect(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId',
    );
    final data = response.data as Map<String, dynamic>;
    final conversationCount = data['conversation_count'] as int? ?? 0;
    final classificationData = data['classification'] as Map<String, dynamic>?;
    return ProspectInitResult(
      prospectId: data['prospect_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      agentDisplayName:
          data['agent_display_name'] as String? ?? 'your JPMC AI Advisor',
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      isReturning:
          data['is_returning_user'] as bool? ?? (conversationCount > 0),
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
            (key, value) => MapEntry(
              key.toString(),
              value == true,
            ),
          ) ??
          const {},
      profileSnapshot: data['profile_snapshot'] as Map<String, dynamic>? ?? const {},
      bankerId: data['banker_id'] as String?,
      bankerName: data['banker_name'] as String?,
      bankerPosition: data['banker_position'] as String?,
      classification: classificationData == null
          ? null
          : ProspectClassification(
              inferredStageBucket:
                  classificationData['inferred_stage_bucket'] as String?,
              inferredStageConfidence:
                  (classificationData['inferred_stage_confidence'] as num?)
                      ?.toDouble(),
              inferredStageConfidenceLabel:
                  classificationData['inferred_stage_confidence_label']
                      as String?,
              inferredStageReasons:
                  (classificationData['inferred_stage_reasons'] as List?)
                          ?.whereType<String>()
                          .toList() ??
                      const [],
              inferredStageUpdatedAt:
                  classificationData['inferred_stage_updated_at'] as String?,
              confirmedStageBucket:
                  classificationData['confirmed_stage_bucket'] as String?,
              stageSelectionSource:
                  classificationData['stage_selection_source'] as String?,
              confirmedStageUpdatedAt:
                  classificationData['confirmed_stage_updated_at'] as String?,
            ),
    );
  }

  Future<UpdateProspectClassificationResult> updateProspectClassification(
    String prospectId, {
    required String selectedStageBucket,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/classification',
      data: {
        'selected_stage_bucket': selectedStageBucket,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final classificationData = data['classification'] as Map<String, dynamic>;
    return UpdateProspectClassificationResult(
      prospectId: data['prospect_id'] as String,
      classification: ProspectClassification(
        inferredStageBucket:
            classificationData['inferred_stage_bucket'] as String?,
        inferredStageConfidence:
            (classificationData['inferred_stage_confidence'] as num?)
                ?.toDouble(),
        inferredStageConfidenceLabel:
            classificationData['inferred_stage_confidence_label'] as String?,
        inferredStageReasons:
            (classificationData['inferred_stage_reasons'] as List?)
                    ?.whereType<String>()
                    .toList() ??
                const [],
        inferredStageUpdatedAt:
            classificationData['inferred_stage_updated_at'] as String?,
        confirmedStageBucket:
            classificationData['confirmed_stage_bucket'] as String?,
        stageSelectionSource:
            classificationData['stage_selection_source'] as String?,
        confirmedStageUpdatedAt:
            classificationData['confirmed_stage_updated_at'] as String?,
      ),
    );
  }

  /// Calls POST /conversations/voice-token and returns the full result
  /// including dynamic_variables for the SDK.
  Future<VoiceTokenResult> getVoiceToken(
    String stageBucket, {
    String? prospectId,
    bool isReconnect = false,
  }) async {
    final response = await _dio.post(
      ApiConfig.voiceTokenEndpoint,
      data: {
        'stage_bucket': stageBucket,
        if (prospectId != null) 'prospect_id': prospectId,
        if (isReconnect) 'is_reconnect': true,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return VoiceTokenResult(
      conversationToken: data['conversation_token'] as String,
      agentId: data['agent_id'] as String,
      stageBucket: data['stage_bucket'] as String,
      prospectId: data['prospect_id'] as String?,
      isReturningUser: data['is_returning_user'] as bool? ?? false,
      dynamicVariables:
          (data['dynamic_variables'] as Map<String, dynamic>?) ?? {},
    );
  }

  Future<RelationshipHubChatResult> sendRelationshipHubChat(
    String userMessage, {
    String? prospectId,
    Map<String, dynamic> context = const {},
    bool isBanker = false,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/relationship-hub/chat',
      data: {
        'user_message': userMessage,
        if (prospectId != null) 'prospect_id': prospectId,
        'context': context,
        'is_banker': isBanker,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return RelationshipHubChatResult(
      replyMarkdown: data['reply_markdown'] as String? ?? '',
      rawResponse: (data['raw_response'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const {},
    );
  }

  /// Fetches profile form data plus the latest AI-collected attribute list.
  Future<ProspectFullProfile> getProspectFullProfile(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/full-profile',
    );
    final data = response.data as Map<String, dynamic>;
    return ProspectFullProfile(
      prospectId: data['prospect_id'] as String,
      email: data['email'] as String?,
      fullName: data['full_name'] as String?,
      phoneNumber: data['phone_number'] as String?,
      companyName: data['company_name'] as String?,
      incorporated: data['incorporated'] as bool? ?? false,
      companyStage: data['company_stage'] as String?,
      industry: data['industry'] as String?,
      headcount: data['headcount'] as String?,
      selectedPrioritiesJson:
          (data['selected_priorities_json'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value == true),
              ) ??
              const {},
      stageBucket: data['stage_bucket'] as String?,
      conversationCount: data['conversation_count'] as int? ?? 0,
      conversationPhase: data['conversation_phase'] as int? ?? 1,
      invitationCode: data['invitation_code'] as String?,
      aiAttributes:
          (data['ai_attributes'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              const {},
      aiAttributesHistorical:
          (data['ai_attributes_historical'] as Map?)?.map(
                (key, value) => MapEntry(key.toString(), value),
              ) ??
              const {},
      bankerId: data['banker_id'] as String?,
    );
  }

  /// Fetch paginated chat history from the n8n_chat_histories table.
  ///
  /// Uses cursor-based pagination: pass [beforeId] to load messages older than
  /// that id.  Omit or pass 0 to load the most recent messages.
  Future<ChatHistoryResult> getChatHistory(
    String prospectId, {
    int limit = 30,
    int beforeId = 0,
  }) async {
    final queryParams = <String, dynamic>{'limit': limit};
    if (beforeId > 0) {
      queryParams['before_id'] = beforeId;
    }
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/relationship-hub/chat-history/$prospectId',
      queryParameters: queryParams,
    );
    final data = response.data;
    if (data is! Map) {
      return const ChatHistoryResult(messages: [], total: 0, hasMore: false);
    }
    final messages = (data['messages'] as List<dynamic>?)
            ?.map((m) =>
                ChatHistoryMessage.fromJson(m as Map<String, dynamic>))
            .toList() ??
        [];
    return ChatHistoryResult(
      messages: messages,
      total: data['total'] as int? ?? 0,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  Future<List<ProductPublic>> listProducts({String? prospectId}) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/products',
      queryParameters: {
        if (prospectId != null) 'prospect_id': prospectId,
      },
    );
    final data = response.data;
    if (data is! Map || data['products'] is! List) {
      return [];
    }
    final list = data['products'] as List;
    return list.map((json) => ProductPublic.fromJson(json)).toList();
  }

  Future<MatchReasoningResult> getMatchReasoning({
    required String prospectId,
    required String productId,
    String? currentRaw,
  }) async {
    final cacheKey = '${prospectId}_$productId';
    
    // 1. Check cache first with raw reasoning validation
    final cached = getCachedReasoning(prospectId, productId, currentRaw);
    if (cached != null) {
      return cached;
    }

    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/match-reasoning',
      queryParameters: {
        'prospect_id': prospectId,
        'product_id': productId,
      },
    );
    
    final result = MatchReasoningResult.fromJson(response.data as Map<String, dynamic>);
    
    // 2. Store in cache for future hovers/modals
    _reasoningCache[cacheKey] = {
      'raw': currentRaw ?? result.rawReasoning,
      'result': result,
    };
    
    return result;
  }

  Future<List<ProspectInitResult>> listProspects() async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospects',
    );
    final data = response.data;
    if (data is! List) {
      throw Exception('Expected list of prospects from API, but got: $data');
    }
    final list = data as List;
    return list.map((item) {
      final data = item as Map<String, dynamic>;
      final conversationCount = data['conversation_count'] as int? ?? 0;
      final classificationData = data['classification'] as Map<String, dynamic>?;
      return ProspectInitResult(
        prospectId: data['prospect_id'] as String,
        stageBucket: data['stage_bucket'] as String? ?? 'super_agent',
        agentDisplayName:
            data['agent_display_name'] as String? ?? 'your JPMC AI Advisor',
        conversationPhase: data['conversation_phase'] as int? ?? 1,
        isReturning:
            data['is_returning_user'] as bool? ?? (conversationCount > 0),
        email: data['email'] as String?,
        fullName: data['full_name'] as String?,
        phoneNumber: data['phone_number'] as String?,
        companyName: data['company_name'] as String?,
        incorporated: data['incorporated'] as bool? ?? false,
        companyStage: data['company_stage'] as String?,
        industry: data['industry'] as String?,
        headcount: data['headcount'] as String?,
        selectedPrioritiesJson: (data['selected_priorities_json'] as Map?)?.map(
              (key, value) => MapEntry(
                key.toString(),
                value == true,
              ),
            ) ??
            const {},
        profileSnapshot: data['profile_snapshot'] as Map<String, dynamic>? ?? const {},
        bankerId: data['banker_id'] as String?,
        bankerName: data['banker_name'] as String?,
        bankerPosition: data['banker_position'] as String?,
        classification: classificationData == null
            ? null
            : ProspectClassification(
                inferredStageBucket:
                    classificationData['inferred_stage_bucket'] as String?,
                inferredStageConfidence:
                    (classificationData['inferred_stage_confidence'] as num?)
                        ?.toDouble(),
                inferredStageConfidenceLabel:
                    classificationData['inferred_stage_confidence_label']
                        as String?,
                inferredStageReasons:
                    (classificationData['inferred_stage_reasons'] as List?)
                            ?.whereType<String>()
                            .toList() ??
                        const [],
                inferredStageUpdatedAt:
                    classificationData['inferred_stage_updated_at'] as String?,
                confirmedStageBucket:
                    classificationData['confirmed_stage_bucket'] as String?,
                stageSelectionSource:
                    classificationData['stage_selection_source'] as String?,
                confirmedStageUpdatedAt:
                    classificationData['confirmed_stage_updated_at'] as String?,
              ),
      );
    }).toList();
  }

  Future<List<Banker>> listBankers() async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/bankers',
    );
    final data = response.data;
    if (data is! List) {
      throw Exception('Expected list of bankers from API, but got: $data');
    }
    final list = data as List;
    return list
        .map((item) => Banker.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<dynamic>> getProspectConversations(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/conversations',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data as List;
  }

  Future<List<String>> getSuggestedQuestions(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/suggested-questions',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return (data as List).map((item) => item.toString()).toList();
  }

  Future<List<dynamic>> getUnassignedProspects() async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospects/unassigned',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data as List;
  }

  Future<void> assignProspectToBanker(String prospectId, String? bankerId) async {
    await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/assign-banker',
      data: {'banker_id': bankerId},
    );
  }

  Future<List<ProspectCheckpoint>> getProspectCheckpoints(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/checkpoints',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return (data as List)
        .map((item) => ProspectCheckpoint.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProspectCheckpoint> updateProspectCheckpoint(
    String prospectId,
    String checkpointId, {
    bool? checked,
    Map<String, String>? miniAnswers,
  }) async {
    final response = await _dio.patch(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/checkpoints/$checkpointId',
      data: {
        if (checked != null) 'checked': checked,
        if (miniAnswers != null) 'mini_checkpoint_answers': miniAnswers,
      },
    );
    return ProspectCheckpoint.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DirectMessage>> getDirectMessages(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/messages',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data
        .map((item) => DirectMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DirectMessage> sendDirectMessage(
    String prospectId,
    String sender,
    String content,
  ) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/messages',
      data: {
        'sender': sender,
        'content': content,
      },
    );
    return DirectMessage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ProspectDocument>> getDocumentList(String prospectId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/documents',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data
        .map((item) => ProspectDocument.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProspectDocument> uploadProspectDocument(
    String prospectId,
    String fileName, {
    String? driveLink,
  }) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/prospect/$prospectId/document',
      data: {
        'file_name': fileName,
        if (driveLink != null) 'drive_link': driveLink,
      },
    );
    return ProspectDocument.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<ProspectCheckpoint>> getDocumentCheckpoints(String documentId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/document/$documentId/checkpoints',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data
        .map((item) => ProspectCheckpoint.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ProspectCheckpoint> updateDocumentCheckpoint(
    String documentId,
    String checkpointId, {
    bool? checked,
    Map<String, String>? miniAnswers,
  }) async {
    final response = await _dio.patch(
      '${ApiConfig.baseUrl}/conversations/document/$documentId/checkpoints/$checkpointId',
      data: {
        if (checked != null) 'checked': checked,
        if (miniAnswers != null) 'mini_checkpoint_answers': miniAnswers,
      },
    );
    return ProspectCheckpoint.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ProspectDocument> updateDocumentStatus(
    String documentId,
    String status,
    String actor,
  ) async {
    final response = await _dio.post(
      '${ApiConfig.baseUrl}/conversations/document/$documentId/status',
      data: {
        'status': status,
        'actor': actor,
      },
    );
    return ProspectDocument.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<DocumentAuditLog>> getDocumentAuditLogs(String documentId) async {
    final response = await _dio.get(
      '${ApiConfig.baseUrl}/conversations/document/$documentId/audit-logs',
    );
    final data = response.data;
    if (data is! List) {
      return [];
    }
    return data
        .map((item) => DocumentAuditLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Cache for Prospect and Product data to prevent transitions loading spinners
// ─────────────────────────────────────────────────────────────────────────────

class ProspectCache {
  static final Map<String, ProspectInitResult> _cache = {};

  static ProspectInitResult? get(String prospectId) => _cache[prospectId];

  static void set(String prospectId, ProspectInitResult result) {
    _cache[prospectId] = result;
  }

  static void clear() {
    _cache.clear();
  }
}

class ProductCache {
  static final Map<String, List<ProductPublic>> _cache = {};

  static List<ProductPublic>? get(String prospectId) => _cache[prospectId];

  static void set(String prospectId, List<ProductPublic> products) {
    _cache[prospectId] = products;
  }

  static void clear() {
    _cache.clear();
  }
}

