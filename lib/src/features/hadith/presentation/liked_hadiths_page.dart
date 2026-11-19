import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/localization/app_strings.dart';
import 'bloc/hadith_bloc.dart';
import 'hadith_card.dart';

class LikedHadithsPage extends StatelessWidget {
  const LikedHadithsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(t('hadithFavorites'))),
      body: BlocBuilder<HadithBloc, HadithState>(
        builder: (context, state) {
          return Column(
            children: [
              if (state.favoritesError)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(t('hadithSaveError')),
                ),
              Expanded(
                child: state.liked.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Text(
                            t('hadithFavoritesEmpty'),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: state.liked.length,
                        separatorBuilder: (_, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final hadith = state.liked[index];
                          return HadithCard(
                            key: ValueKey(hadith.id),
                            hadith: hadith,
                            language: language,
                            liked: true,
                            onLike: state.saving
                                ? null
                                : () => context.read<HadithBloc>().add(
                                    HadithLikeToggled(hadith),
                                  ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
