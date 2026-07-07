class LatestSnapshotModel {
  final String id;
  final String snapshotType;
  final DateTime createdAt;
  final String? notes;
  final List<SnapshotTestModel> tests;

  LatestSnapshotModel({
    required this.id,
    required this.snapshotType,
    required this.createdAt,
    required this.notes,
    required this.tests,
  });

  factory LatestSnapshotModel.fromJson(Map<String, dynamic> json) {
    return LatestSnapshotModel(
      id: json["id"],
      snapshotType: json["snapshot_type"],
      createdAt: DateTime.parse(json["created_at"]),
      notes: json["notes"],
      tests: (json["test_values"] as List)
          .map((e) => SnapshotTestModel.fromJson(e))
          .toList(),
    );
  }
}

class SnapshotTestModel {
  final int attributeTestId;
  final String attributeName;
  final String testName;
  final double value;
  final String unit;

  SnapshotTestModel({
    required this.attributeTestId,
    required this.attributeName,
    required this.testName,
    required this.value,
    required this.unit,
  });

  factory SnapshotTestModel.fromJson(Map<String, dynamic> json) {
    return SnapshotTestModel(
      attributeTestId: json["attribute_test_id"],
      attributeName: json["attribute_name"],
      testName: json["test_name"],
      value: (json["value"] as num).toDouble(),
      unit: json["unit"],
    );
  }
}