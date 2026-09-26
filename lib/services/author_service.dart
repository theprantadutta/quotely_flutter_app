import 'dart:convert';

import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/dtos/author_response_dto.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:quotely_flutter_app/services/drift_author_service.dart';
import 'package:quotely_flutter_app/util/pagination_seed.dart';

import '../constants/urls.dart';
import 'http_service.dart';
import 'local_first.dart';

/// Authors, local first (see [LocalFirst]).
class AuthorService {
  /// A page of authors (optionally matching [search]).
  Future<AuthorResponseDto> getAllAuthors({
    required String search,
    required int pageNumber,
    required int pageSize,
    int? seed,
  }) {
    final effectiveSeed = seed ?? PaginationSeed.current;
    return LocalFirst.load<AuthorResponseDto>(
      key: 'authors:$search:$pageNumber:$pageSize',
      local: () async => AuthorResponseDto(
        authors: AuthorDto.fromAuthorList(
          await DriftAuthorService.getLocalAuthorsWithPagination(
            pageNumber: pageNumber,
            pageSize: pageSize,
            searchTerm: search,
          ),
        ),
        pagination: PaginationDto(
          pageNumber: 0,
          pageSize: 0,
          totalItemCount: 0,
        ),
      ),
      remote: () async {
        final uri = Uri.parse('$kApiUrl/$kGetAllAuthors').replace(
          queryParameters: {
            'search': search,
            'pageNumber': pageNumber.toString(),
            'pageSize': pageSize.toString(),
            'seed': effectiveSeed.toString(),
          },
        );
        final response = await HttpService.get(uri.toString());
        if (response.statusCode != 200) {
          throw Exception('Authors request failed: ${response.statusCode}');
        }
        final dto = AuthorResponseDto.fromJson(json.decode(response.data));
        if (dto.authors.isNotEmpty) {
          await DriftAuthorService.saveAuthorsToDatabase(dto.authors);
        }
        return dto;
      },
      isEmpty: (r) => r.authors.isEmpty,
    );
  }

  /// One author's details, or null if unknown both locally and remotely.
  Future<AuthorDto?> getAuthorDetails({required String authorSlug}) {
    return LocalFirst.load<AuthorDto?>(
      key: 'author:$authorSlug',
      local: () async {
        final row = await DriftAuthorService.getLocalAuthorBySlug(authorSlug);
        return row == null ? null : AuthorDto.fromDrift(row);
      },
      remote: () async {
        final response = await HttpService.get(
          '$kApiUrl/$kGetAuthorDetails?authorSlug=$authorSlug',
        );
        if (response.statusCode != 200) {
          throw Exception('Author request failed: ${response.statusCode}');
        }
        final data = json.decode(response.data);
        if (data == null) return null;
        final dto = AuthorDto.fromJson(data);
        await DriftAuthorService.saveAuthorsToDatabase([dto]);
        return dto;
      },
      isEmpty: (a) => a == null,
    );
  }
}
