import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/state_providers/favorite_quote_ids.g.dart';

@riverpod
class FavoriteQuoteIds extends _$FavoriteQuoteIds {
  @override
  List<String> build() {
    return [];
  }

  void addMultipleIds(List<String> ids) {
    state = [...state, ...ids];
  }

  void addId(String id) {
    state = [...state, id];
  }

  void removeId(String id) {
    state = state.where((element) => element != id).toList();
  }

  void addOrRemoveId(String id) {
    if (state.contains(id)) {
      removeId(id);
    } else {
      addId(id);
    }
  }
}
