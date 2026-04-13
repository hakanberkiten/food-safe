class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.body});

  final String message;
  final int? statusCode;
  final String? body;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }
    return 'HTTP $statusCode: $message';
  }
}

class AuthToken {
  AuthToken({required this.accessToken, required this.tokenType});

  final String accessToken;
  final String tokenType;

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
    );
  }
}

class UserProfileData {
  UserProfileData({
    required this.allergies,
    required this.conditions,
    required this.special,
    this.sessionId,
  });

  final List<String> allergies;
  final List<String> conditions;
  final List<String> special;
  final String? sessionId;

  factory UserProfileData.empty({String? sessionId}) {
    return UserProfileData(
      allergies: const [],
      conditions: const [],
      special: const [],
      sessionId: sessionId,
    );
  }

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      allergies: _readStringList(json['allergies']),
      conditions: _readStringList(json['conditions']),
      special: _readStringList(json['special']),
      sessionId: json['session_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergies': allergies,
      'conditions': conditions,
      'special': special,
      if (sessionId != null) 'session_id': sessionId,
    };
  }
}

class RiskIngredient {
  RiskIngredient({
    required this.ingredient,
    required this.riskLevel,
    required this.summary,
  });

  final String ingredient;
  final String riskLevel;
  final String summary;

  factory RiskIngredient.fromJson(Map<String, dynamic> json) {
    return RiskIngredient(
      ingredient: json['ingredient']?.toString() ?? 'Unknown ingredient',
      riskLevel: json['risk_level']?.toString() ?? 'unknown',
      summary: json['summary']?.toString() ?? '',
    );
  }
}

class AlternativeProduct {
  AlternativeProduct({
    required this.name,
    required this.reason,
    required this.tags,
  });

  final String name;
  final String reason;
  final List<String> tags;

  factory AlternativeProduct.fromJson(Map<String, dynamic> json) {
    return AlternativeProduct(
      name: json['name']?.toString() ?? 'Alternative',
      reason: json['reason']?.toString() ?? '',
      tags: _readStringList(json['tags']),
    );
  }
}

class ExecutionTrace {
  ExecutionTrace({
    required this.stage,
    required this.provider,
    required this.preferredModel,
    required this.actualModel,
    required this.fallbackUsed,
    required this.success,
    required this.notes,
  });

  final String stage;
  final String provider;
  final String preferredModel;
  final String actualModel;
  final bool fallbackUsed;
  final bool success;
  final List<String> notes;

  factory ExecutionTrace.fromJson(Map<String, dynamic> json) {
    return ExecutionTrace(
      stage: json['stage']?.toString() ?? 'unknown',
      provider: json['provider']?.toString() ?? 'google-genai',
      preferredModel: json['preferred_model']?.toString() ?? '',
      actualModel: json['actual_model']?.toString() ?? '',
      fallbackUsed: json['fallback_used'] == true,
      success: json['success'] != false,
      notes: _readStringList(json['notes']),
    );
  }
}

class AnalysisOverview {
  AnalysisOverview({
    required this.productName,
    required this.detectedLanguage,
    required this.ingredientCount,
    required this.ingredientsPreview,
    required this.allergens,
    required this.claims,
    required this.overallRisk,
    required this.status,
    required this.summary,
    required this.personalizedConsiderations,
    required this.topRiskIngredients,
    required this.saferAlternatives,
    required this.scientificBasis,
    required this.executionMetadata,
  });

  final String? productName;
  final String detectedLanguage;
  final int ingredientCount;
  final List<String> ingredientsPreview;
  final List<String> allergens;
  final List<String> claims;
  final String overallRisk;
  final String status;
  final String summary;
  final List<String> personalizedConsiderations;
  final List<RiskIngredient> topRiskIngredients;
  final List<AlternativeProduct> saferAlternatives;
  final List<String> scientificBasis;
  final List<ExecutionTrace> executionMetadata;

  factory AnalysisOverview.fromJson(Map<String, dynamic> json) {
    return AnalysisOverview(
      productName: json['product_name']?.toString(),
      detectedLanguage: json['detected_language']?.toString() ?? 'unknown',
      ingredientCount: _readInt(json['ingredient_count']),
      ingredientsPreview: _readStringList(json['ingredients_preview']),
      allergens: _readStringList(json['allergens']),
      claims: _readStringList(json['claims']),
      overallRisk: json['overall_risk']?.toString() ?? 'unknown',
      status: json['status']?.toString() ?? 'UNKNOWN',
      summary: json['summary']?.toString() ?? 'No summary available.',
      personalizedConsiderations: _readStringList(
        json['personalized_considerations'],
      ),
      topRiskIngredients: _readMapList(
        json['top_risk_ingredients'],
      ).map(RiskIngredient.fromJson).toList(),
      saferAlternatives: _readMapList(
        json['safer_alternatives'],
      ).map(AlternativeProduct.fromJson).toList(),
      scientificBasis: _readStringList(json['scientific_basis']),
      executionMetadata: _readMapList(
        json['execution_metadata'],
      ).map(ExecutionTrace.fromJson).toList(),
    );
  }

  bool get hasMeaningfulResult =>
      ingredientCount > 0 ||
      topRiskIngredients.isNotEmpty ||
      summary.isNotEmpty;
}

class AnalyzeResponse {
  AnalyzeResponse({
    required this.scanId,
    required this.shareToken,
    required this.result,
    required this.verbose,
  });

  final int scanId;
  final String shareToken;
  final AnalysisOverview result;
  final bool verbose;

  factory AnalyzeResponse.fromJson(Map<String, dynamic> json) {
    return AnalyzeResponse(
      scanId: _readInt(json['scan_id']),
      shareToken: json['share_token']?.toString() ?? '',
      result: AnalysisOverview.fromJson(
        (json['result'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      verbose: json['verbose'] == true,
    );
  }
}

class ScanHistoryItem {
  ScanHistoryItem({
    required this.id,
    required this.productName,
    required this.ingredientsRaw,
    required this.dangerLevel,
    required this.analysisResult,
    required this.shareToken,
    required this.createdAt,
  });

  final int id;
  final String? productName;
  final String ingredientsRaw;
  final String dangerLevel;
  final AnalysisOverview? analysisResult;
  final String? shareToken;
  final DateTime? createdAt;

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    final analysisJson = (json['analysis_result'] as Map?)
        ?.cast<String, dynamic>();
    return ScanHistoryItem(
      id: _readInt(json['id']),
      productName: json['product_name']?.toString(),
      ingredientsRaw: json['ingredients_raw']?.toString() ?? '',
      dangerLevel: json['danger_level']?.toString() ?? 'UNKNOWN',
      analysisResult: analysisJson == null
          ? null
          : AnalysisOverview.fromJson(analysisJson),
      shareToken: json['share_token']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class SavedProductItem {
  SavedProductItem({
    required this.id,
    required this.productName,
    required this.dangerLevel,
    required this.analysisResult,
    required this.createdAt,
  });

  final int id;
  final String productName;
  final String dangerLevel;
  final AnalysisOverview? analysisResult;
  final DateTime? createdAt;

  factory SavedProductItem.fromJson(Map<String, dynamic> json) {
    final analysisJson = (json['analysis_result'] as Map?)
        ?.cast<String, dynamic>();
    return SavedProductItem(
      id: _readInt(json['id']),
      productName: json['product_name']?.toString() ?? 'Saved product',
      dangerLevel: json['danger_level']?.toString() ?? 'UNKNOWN',
      analysisResult: analysisJson == null
          ? null
          : AnalysisOverview.fromJson(analysisJson),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

class SharedScanData {
  SharedScanData({
    required this.productName,
    required this.dangerLevel,
    required this.analysisResult,
    required this.createdAt,
  });

  final String? productName;
  final String dangerLevel;
  final AnalysisOverview? analysisResult;
  final DateTime? createdAt;

  factory SharedScanData.fromJson(Map<String, dynamic> json) {
    final analysisJson = (json['analysis_result'] as Map?)
        ?.cast<String, dynamic>();
    return SharedScanData(
      productName: json['product_name']?.toString(),
      dangerLevel: json['danger_level']?.toString() ?? 'UNKNOWN',
      analysisResult: analysisJson == null
          ? null
          : AnalysisOverview.fromJson(analysisJson),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

List<String> _readStringList(dynamic value) {
  final items = value as List?;
  if (items == null) {
    return const [];
  }
  return items
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

List<Map<String, dynamic>> _readMapList(dynamic value) {
  final items = value as List?;
  if (items == null) {
    return const [];
  }
  return items
      .whereType<Map>()
      .map((item) => item.cast<String, dynamic>())
      .toList();
}

int _readInt(dynamic value) {
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
