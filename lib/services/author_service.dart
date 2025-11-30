// import 'dart:convert';

// import '../constants/urls.dart';
// import '../dtos/author_dto.dart';
// import '../dtos/author_response_dto.dart';
// import 'http_service.dart';

// class AuthorService {
//   Future<AuthorResponseDto> getAllAuthorsFromDatabase({
//     required String search,
//     required int pageNumber,
//     required int pageSize,
//   }) async {
//     final response = await HttpService.get(
//         '$kApiUrl/$kGetAllAuthors?search=$search&pageNumber=$pageNumber&pageSize=$pageSize');
//     if (response.statusCode == 200) {
//       return AuthorResponseDto.fromJson(json.decode(response.data));
//     }
//     throw Exception('Failed to get authors');
//   }

//   Future<AuthorDto?> getAuthorDetails({
//     required String authorSlug,
//   }) async {
//     final response = await HttpService.get(
//         '$kApiUrl/$kGetAuthorDetails?authorSlug=$authorSlug');
//     if (response.statusCode == 200) {
//       final data = json.decode(response.data);
//       return data != null ? AuthorDto.fromJson(data) : null;
//     }
//     throw Exception('Failed to get authors');
//   }
// }

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:quotely_flutter_app/dtos/author_dto.dart';
import 'package:quotely_flutter_app/dtos/author_response_dto.dart';
import 'package:quotely_flutter_app/dtos/pagination_dto.dart';
import 'package:quotely_flutter_app/services/drift_author_service.dart';

import '../constants/urls.dart';
import 'http_service.dart';

class AuthorService {
  /// Fetches a paginated list of authors. Tries the API first and falls
  /// back to the local database on failure.
  Future<AuthorResponseDto> getAllAuthors({
    required String search,
    required int pageNumber,
    required int pageSize,
  }) async {
    try {
      // --- ONLINE PATH ---
      final url =
          '$kApiUrl/$kGetAllAuthors?search=$search&pageNumber=$pageNumber&pageSize=$pageSize';
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        final authorResponseDto = AuthorResponseDto.fromJson(
          json.decode(response.data),
        );

        // Cache the fresh data for offline use
        if (authorResponseDto.authors.isNotEmpty) {
          await DriftAuthorService.saveAuthorsToDatabase(
            authorResponseDto.authors,
          );
        }

        return authorResponseDto;
      }
      throw Exception(
        'Failed to get authors with status code: ${response.statusCode}',
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          'API call for authors failed, falling back to local database. Error: $e',
        );
      }

      // --- OFFLINE FALLBACK ---
      final localAuthors =
          await DriftAuthorService.getLocalAuthorsWithPagination(
            pageNumber: pageNumber,
            pageSize: pageSize,
            searchTerm: search,
          );

      final authorDtos = AuthorDto.fromAuthorList(localAuthors);

      return AuthorResponseDto(
        authors: authorDtos,
        pagination: PaginationDto(
          pageNumber: 0,
          pageSize: 0,
          totalItemCount: 0,
        ),
      );
    }
  }

  /// Fetches details for a single author. Tries the API first and falls
  /// back to the local database on failure.
  Future<AuthorDto?> getAuthorDetails({required String authorSlug}) async {
    try {
      // --- ONLINE PATH ---
      final url = '$kApiUrl/$kGetAuthorDetails?authorSlug=$authorSlug';
      final response = await HttpService.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.data);
        if (data == null) return null;

        final authorDto = AuthorDto.fromJson(data);

        // Cache the fresh detail data
        await DriftAuthorService.saveAuthorsToDatabase([authorDto]);

        return authorDto;
      }
      throw Exception(
        'Failed to get author details with status code: ${response.statusCode}',
      );
    } catch (e) {
      if (kDebugMode) {
        print(
          'API call for author details failed, falling back to local database. Error: $e',
        );
      }

      // --- OFFLINE FALLBACK ---
      final localAuthor = await DriftAuthorService.getLocalAuthorBySlug(
        authorSlug,
      );

      if (localAuthor != null) {
        return AuthorDto.fromDrift(localAuthor);
      }

      // Return null if not found online or offline
      return null;
    }
  }
}
