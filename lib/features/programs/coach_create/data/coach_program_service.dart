import '../../../../core/api/api_client.dart';
import '../models/program_builder_data.dart';

class CoachProgramService {
  final ApiClient apiClient;

  CoachProgramService({required this.apiClient});

  Future<Map<String, dynamic>> publishProgram(ProgramBuilderData data) async {
    final response = await apiClient.dio.post(
      '/api/programs',
      data: data.toApiPayload(publish: true),
    );

    final responseData = response.data;

    if (responseData is Map<String, dynamic>) {
      return responseData;
    }

    return {'data': responseData};
  }
}
