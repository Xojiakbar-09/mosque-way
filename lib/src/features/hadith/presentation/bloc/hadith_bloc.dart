import 'dart:async';
import '../../repository/hadith_shuffle.dart';
import '../../repository/liked_hadith_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repository/hadith.dart';
import '../../repository/hadith_repository.dart';

part 'hadith_event.dart';
part 'hadith_state.dart';

class HadithBloc extends Bloc<HadithEvent, HadithState> {
  HadithBloc(this.repository, this.favorites) : super(const HadithState()) {
    on<HadithNextRequested>((event, emit) {
      if (state.loading || state.items.isEmpty) return;
      _emptyWrapAttempted = false;
      if (!_shuffle.hasRemaining && (state.hasMore || _hasPaged)) {
        _hasPaged = true;
        add(const HadithLoadRequested(nextPage: true));
      } else {
        emit(_state(current: _pick(state.items)));
      }
    });
    on<HadithLikeToggled>((event, emit) async {
      // Guard across asynchronous writes: keep disk and visible state in sync.
      if (state.saving) return;
      final liked = [...state.liked];
      if (state.isLiked(event.hadith.id)) {
        liked.removeWhere((item) => item.id == event.hadith.id);
      } else {
        liked.insert(0, event.hadith);
      }
      emit(_state(saving: true));
      try {
        await favorites.save(liked);
        if (!emit.isDone) {
          emit(_state(liked: liked, saving: false, favoritesError: false));
        }
      } catch (_) {
        if (!emit.isDone) emit(_state(favoritesError: true, saving: false));
      }
    });
    on<HadithLoadRequested>(_load);
    on<_HadithFeedReceived>((event, emit) {
      if (event.generation != _generation) return;
      final items = event.feed.items;
      if (items.isEmpty &&
          state.items.isNotEmpty &&
          _advancePage &&
          !_emptyWrapAttempted &&
          !event.feed.hasMore &&
          !event.feed.fromCache) {
        _emptyWrapAttempted = true;
        add(const HadithLoadRequested(advanceSelection: true));
        return;
      }
      if (items.isEmpty && event.feed.hasMore && !event.feed.fromCache) {
        add(const HadithLoadRequested(nextPage: true));
        return;
      }
      final current = items
          .where((item) => item.id == state.current?.id)
          .firstOrNull;
      emit(
        _state(
          items: items,
          current: _advancePage
              ? (items.isEmpty ? null : _pick(items))
              : current ?? (items.isEmpty ? null : _pick(items)),
          clearCurrent: items.isEmpty,
          loading: false,
          fromCache: event.feed.fromCache,
          hasMore: event.feed.hasMore,
        ),
      );
      _advancePage = false;
    });
    on<_HadithFailed>((event, emit) {
      if (event.generation != _generation) return;
      emit(_state(loading: false, errorKey: event.key));
    });
  }
  final HadithRepository repository;
  final LikedHadithRepository favorites;
  final HadithShuffle _shuffle = HadithShuffle();
  bool _hasPaged = false;
  Hadith _pick(List<Hadith> items) =>
      _shuffle.next(items, previousId: state.current?.id);

  HadithState _state({
    List<Hadith>? items,
    Hadith? current,
    bool clearCurrent = false,
    bool? loading,
    bool? fromCache,
    bool? hasMore,
    List<Hadith>? liked,
    bool? saving,
    bool? favoritesError,
    String? errorKey,
  }) => HadithState(
    items: items ?? state.items,
    current: clearCurrent ? null : current ?? state.current,
    loading: loading ?? state.loading,
    fromCache: fromCache ?? state.fromCache,
    hasMore: hasMore ?? state.hasMore,
    liked: List.unmodifiable(liked ?? state.liked),
    saving: saving ?? state.saving,
    favoritesError: favoritesError ?? state.favoritesError,
    errorKey: errorKey,
  );
  StreamSubscription<HadithFeed>? _subscription;
  int _generation = 0;
  bool _advancePage = false;
  bool _emptyWrapAttempted = false;

  Future<void> _load(
    HadithLoadRequested event,
    Emitter<HadithState> emit,
  ) async {
    if (isClosed) return;
    final generation = ++_generation;
    _advancePage = event.nextPage || event.advanceSelection;
    if (event.nextPage || event.advanceSelection) {
      _shuffle.clear();
    } else {
      _hasPaged = false;
    }
    await _subscription?.cancel();
    if (isClosed || emit.isDone || generation != _generation) return;
    try {
      emit(
        _state(loading: true, liked: favorites.read(), favoritesError: false),
      );
    } catch (_) {
      emit(_state(loading: true, favoritesError: true));
    }
    _subscription = repository
        .watch(nextPage: event.nextPage)
        .listen(
          (feed) {
            if (isClosed || generation != _generation) return;
            add(_HadithFeedReceived(feed, generation));
          },
          onError: (Object error, StackTrace stack) {
            if (isClosed || generation != _generation) return;
            final denied =
                error is FirebaseException &&
                (error.code == 'permission-denied' ||
                    error.code == 'unauthenticated');
            add(
              _HadithFailed(
                denied ? 'hadithAccessError' : 'hadithLoadError',
                generation,
              ),
            );
          },
        );
  }

  @override
  Future<void> close() async {
    ++_generation;
    await _subscription?.cancel();
    return super.close();
  }
}
