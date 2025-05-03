import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/state_providers/favorite_fact_ids.g.dart';

@riverpod
class FavoriteFactIds extends _$FavoriteFactIds {
  @override
  List<int> build() {
    return [];
  }

  void addMultipleIds(List<int> ids) {
    state = [...state, ...ids];
  }

  void addId(int id) {
    state = [...state, id];
  }

  void removeId(int id) {
    state = state.where((element) => element != id).toList();
  }

  void addOrRemoveId(int id) {
    if (state.contains(id)) {
      removeId(id);
    } else {
      addId(id);
    }
  }

  void addOrUpdateId(int id) {
    if (!state.contains(id)) {
      addId(id);
    }
  }

  void addOrUpdateIdList(List<int> ids) {
    for (var id in ids) {
      addOrUpdateId(id);
    }
  }

  void addOrUpdateViaStatus(int id, bool status) {
    if (status) {
      addOrUpdateId(id);
    } else {
      removeId(id);
    }
  }
}
