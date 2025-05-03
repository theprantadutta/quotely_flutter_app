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

  void addOrUpdateId(String id) {
    if (!state.contains(id)) {
      addId(id);
    }
  }

  void addOrUpdateIdList(List<String> ids) {
    for (var id in ids) {
      addOrUpdateId(id);
    }
  }

  void addOrUpdateViaStatus(String id, bool status) {
    if (status) {
      addOrUpdateId(id);
    } else {
      removeId(id);
    }
  }
}
