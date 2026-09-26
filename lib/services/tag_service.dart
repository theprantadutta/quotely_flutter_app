import 'dart:convert';

import 'package:quotely_flutter_app/dtos/tag_dto.dart';
import 'package:quotely_flutter_app/services/drift_tag_service.dart';
import 'package:quotely_flutter_app/services/http_service.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';

import '../constants/urls.dart';
import '../dtos/pagination_dto.dart';
import '../dtos/tag_response_dto.dart';
import 'local_first.dart';

/// Tags, local first (see [LocalFirst]).
class TagService {
  /// A page of tags. Pass [getAllRows] for every tag in one response (the
  /// interests picker needs the full vocabulary).
  static Future<TagResponseDto> getAllTags({
    required int pageNumber,
    required int pageSize,
    int? seed,
    bool getAllRows = false,
  }) {
    final effectiveSeed = seed ?? PaginationSeed.current;
    return LocalFirst.load<TagResponseDto>(
      key: getAllRows ? 'tags:all' : 'tags:$pageNumber:$pageSize',
      local: () async => TagResponseDto(
        tags: TagDto.fromTagList(
          getAllRows
              ? await DriftTagService.getAllTags()
              : await DriftTagService.getLocalTagsWithPagination(
                  pageNumber: pageNumber,
                  pageSize: pageSize,
                ),
        ),
        pagination: PaginationDto(
          pageNumber: 0,
          pageSize: 0,
          totalItemCount: 0,
        ),
      ),
      remote: () async {
        final uri = Uri.parse('$kApiUrl/$kGetAllTags').replace(
          queryParameters: {
            'pageNumber': pageNumber.toString(),
            'pageSize': pageSize.toString(),
            'seed': effectiveSeed.toString(),
            if (getAllRows) 'getAllRows': 'true',
          },
        );
        final response = await HttpService.get(uri.toString());
        if (response.statusCode != 200) {
          throw Exception('Tags request failed: ${response.statusCode}');
        }
        final dto = TagResponseDto.fromJson(json.decode(response.data));
        if (dto.tags.isNotEmpty) {
          await DriftTagService.saveTagsToDatabase(dto.tags);
        }
        return dto;
      },
      isEmpty: (r) => r.tags.isEmpty,
    );
  }
}
