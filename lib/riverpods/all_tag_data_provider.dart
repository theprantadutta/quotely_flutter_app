import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/services/tag_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/tag_response_dto.dart';

part '../generated/riverpods/all_tag_data_provider.g.dart';

@Riverpod(keepAlive: true)
Future<TagResponseDto> fetchAllTags(
  Ref ref,
  int pageNumber,
  int pageSize,
) async {
  return await TagService().getAllTagsFromDatabase(
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
