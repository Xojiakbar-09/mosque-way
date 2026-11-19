part of 'hadith_bloc.dart';

class HadithState {
  const HadithState({
    this.items = const [],
    this.loading = true,
    this.fromCache = false,
    this.hasMore = false,
    this.errorKey,
    this.current,
    this.liked = const [],
    this.saving = false,
    this.favoritesError = false,
  });

  final List<Hadith> items;
  final bool loading, fromCache, hasMore;
  final String? errorKey;
  final Hadith? current;
  final List<Hadith> liked;
  final bool saving, favoritesError;
  bool isLiked(String id) => liked.any((item) => item.id == id);
}
