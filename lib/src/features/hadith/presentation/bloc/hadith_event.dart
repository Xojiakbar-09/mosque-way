part of 'hadith_bloc.dart';

sealed class HadithEvent {
  const HadithEvent();
}

final class HadithLoadRequested extends HadithEvent {
  const HadithLoadRequested({
    this.nextPage = false,
    this.advanceSelection = false,
  });
  final bool nextPage, advanceSelection;
}

final class _HadithFeedReceived extends HadithEvent {
  const _HadithFeedReceived(this.feed, this.generation);
  final HadithFeed feed;
  final int generation;
}

final class _HadithFailed extends HadithEvent {
  const _HadithFailed(this.key, this.generation);
  final String key;
  final int generation;
}

final class HadithNextRequested extends HadithEvent {
  const HadithNextRequested();
}

final class HadithLikeToggled extends HadithEvent {
  const HadithLikeToggled(this.hadith);
  final Hadith hadith;
}
