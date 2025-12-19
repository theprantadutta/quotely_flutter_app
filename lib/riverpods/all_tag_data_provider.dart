import 'package:quotely_flutter_app/services/tag_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/tag_response_dto.dart';

part '../generated/riverpods/all_tag_data_provider.g.dart';

@Riverpod(keepAlive: true)
Future<TagResponseDto> fetchAllTags(
  Ref ref,
  int pageNumber,
  int pageSize,
  int? seed,
) async {
  return await TagService.getAllTags(
    pageNumber: pageNumber,
    pageSize: pageSize,
    seed: seed,
  );
}
