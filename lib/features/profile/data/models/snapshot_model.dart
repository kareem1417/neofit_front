class SnapshotModel {
  final String id;
  final String snapshotType;
  final DateTime createdAt;
  final String? notes;
  final List<TestValueModel> testValues;

  SnapshotModel({
    required this.id,
    required this.snapshotType,
    required this.createdAt,
    this.notes,
    required this.testValues,
  });

  factory SnapshotModel.fromJson(Map<String, dynamic> json) {
    return SnapshotModel(
      id: json["id"],
      snapshotType: json["snapshot_type"],
      createdAt: DateTime.parse(json["created_at"]),
      notes: json["notes"],
      testValues: (json["test_values"] as List)
          .map((e) => TestValueModel.fromJson(e))
          .toList(),
    );
  }
}

class TestValueModel {
  final int attributeTestId;
  final String attributeName;
  final String testName;
  final num value;
  final String unit;

  TestValueModel({
    required this.attributeTestId,
    required this.attributeName,
    required this.testName,
    required this.value,
    required this.unit,
  });

  factory TestValueModel.fromJson(Map<String, dynamic> json) {
    return TestValueModel(
      attributeTestId: json["attribute_test_id"],
      attributeName: json["attribute_name"],
      testName: json["test_name"],
      value: json["value"],
      unit: json["unit"],
    );
  }
}