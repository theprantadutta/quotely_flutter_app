import 'package:quotely_flutter_app/dtos/application_info_dto.dart';
import 'package:quotely_flutter_app/services/application_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/application_info_provider.g.dart';

@Riverpod(keepAlive: true)
Future<ApplicationInfoDto?> fetchApplicationInfo(Ref ref) async {
  return await ApplicationService.getApplicationInfo();
}
