import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart';

import '../../../core/localization/app_strings.dart';
import '../repository/hadith_repository.dart';
import '../repository/liked_hadith_repository.dart';
import 'bloc/hadith_bloc.dart';
import 'hadith_card.dart';

class HadithPage extends StatelessWidget {
  const HadithPage({super.key, this.repository, this.favorites});
  final HadithRepository? repository;
  final LikedHadithRepository? favorites;

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => HadithBloc(
      repository ?? HadithRepository(),
      favorites ??
          LikedHadithRepository(
            Hive.box<String>('liked_hadiths_v1'),
            FirebaseAuth.instance.currentUser!.uid,
          ),
    )..add(const HadithLoadRequested()),
    child: const _HadithView(),
  );
}

class _HadithView extends StatelessWidget {
  const _HadithView();

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('hadith')),
        actions: [
          IconButton(
            tooltip: t('hadithFavorites'),
            icon: const Icon(Icons.favorite_rounded),
            onPressed: () => Navigator.pushNamed(
              context,
              '/liked-hadiths',
              arguments: context.read<HadithBloc>(),
            ),
          ),
          IconButton(
            tooltip: t('retry'),
            onPressed: () =>
                context.read<HadithBloc>().add(const HadithLoadRequested()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<HadithBloc, HadithState>(
        builder: (context, state) {
          if (state.loading && state.current == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final hadith = state.current;
          return Column(
            children: [
              if (state.loading) const LinearProgressIndicator(),
              if (state.errorKey != null || state.fromCache)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t(state.errorKey ?? 'hadithCached')),
                ),
              if (state.favoritesError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t('hadithSaveError')),
                ),
              Expanded(
                child: hadith == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            t(
                              state.errorKey ??
                                  (state.fromCache
                                      ? 'hadithNoCache'
                                      : 'hadithEmpty'),
                            ),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: HadithCard(
                          key: ValueKey(hadith.id),
                          hadith: hadith,
                          language: language,
                          liked: state.isLiked(hadith.id),
                          onLike: state.saving
                              ? null
                              : () => context.read<HadithBloc>().add(
                                  HadithLikeToggled(hadith),
                                ),
                        ),
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          state.loading ||
                              (state.items.length < 2 && !state.hasMore)
                          ? null
                          : () => context.read<HadithBloc>().add(
                              const HadithNextRequested(),
                            ),
                      icon: const Icon(Icons.shuffle_rounded),
                      label: Text(t('hadithNext')),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
