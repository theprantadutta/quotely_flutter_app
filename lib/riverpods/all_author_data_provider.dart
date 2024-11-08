import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quotely_flutter_app/dtos/author_response_dto.dart';
import 'package:quotely_flutter_app/services/author_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/riverpods/all_author_data_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AuthorResponseDto> fetchAllAuthors(
  Ref ref,
  String search,
  int pageNumber,
  int pageSize,
) async {
  return await AuthorService().getAllAuthorsFromDatabase(
    search: search,
    pageNumber: pageNumber,
    pageSize: pageSize,
  );
}
