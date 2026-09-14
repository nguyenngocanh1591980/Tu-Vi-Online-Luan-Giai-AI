class SavedChartModel {
  final int id;
  final int userId;
  final String chartName;
  final DateTime dob;
  final String gender;
  final String chartJsonData;
  final bool hasAiReport;
  final DateTime createdAt;

  SavedChartModel({
    required this.id,
    required this.userId,
    required this.chartName,
    required this.dob,
    required this.gender,
    required this.chartJsonData,
    required this.hasAiReport,
    required this.createdAt,
  });

  factory SavedChartModel.fromJson(Map<String, dynamic> json) {
    return SavedChartModel(
      id: json['id'],
      userId: json['userId'],
      chartName: json['chartName'] ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']).toLocal() : DateTime.now(),
      gender: json['gender'] ?? 'Male',
      chartJsonData: json['chartJsonData'] ?? '{}',
      hasAiReport: json['hasAiReport'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']).toLocal() : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'chartName': chartName,
      'dob': dob.toIso8601String(),
      'gender': gender,
      'chartJsonData': chartJsonData,
      'hasAiReport': hasAiReport,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
