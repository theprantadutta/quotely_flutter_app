import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../services/author_page_service.dart';
import '../state_providers/scene_state.dart';

part '../generated/riverpods/followed_people_provider.g.dart';

/// "From people you follow": the newest quotes on this device by followed
/// authors. Local only, so it works offline; new quotes arrive with the
/// usual background refreshes, author pages and the offline library.
@riverpod
Future<List<FollowedQuote>> followedPeopleQuotes(Ref ref) async {
  final slugs = ref.watch(followedAuthorsProvider);
  return AuthorPageService.fromFollowed(slugs);
}
