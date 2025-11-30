import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../dtos/author_dto.dart';
import '../services/author_service.dart';

part '../generated/riverpods/get_author_detail_provider.g.dart';

@Riverpod(keepAlive: true)
Future<AuthorDto?> fetchAuthorDetail(Ref ref, String authorSlug) async {
  return await AuthorService().getAuthorDetails(authorSlug: authorSlug);
}
