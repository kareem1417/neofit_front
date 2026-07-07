class ProfileService {
  final ApiClient apiClient;

  ProfileService({required this.apiClient});

  Future<SnapshotModel> getLatestSnapshot() async {
    final response = await apiClient.dio.get(
      '/api/users/snapshots/latest',
    );

    return SnapshotModel.fromJson(response.data["data"]);
  }

  Future<void> createSnapshot(
      List<Map<String, dynamic>> testValues) async {
    await apiClient.dio.post(
      '/api/users/snapshots',
      data: {
        "snapshot_type": "manual_update",
        "test_values": testValues,
      },
    );
  }
}