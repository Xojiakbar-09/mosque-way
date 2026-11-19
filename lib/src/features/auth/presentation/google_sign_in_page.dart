import '../../../core/localization/app_strings.dart';
import 'widgets/auth_language_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';

import '../../../core/consts/app_colors.dart';
import '../../../core/widgets/entrance_transition.dart';
import '../../../core/widgets/glass_panel.dart';
import '../../../core/widgets/location_halo.dart';
import '../../../core/widgets/mosque_icon.dart';
import 'painters/google_mark_painter.dart';
import 'painters/map_artwork_painter.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});
  @override
  State<GoogleSignInPage> createState() => _GoogleSignInPageState();
}

class _GoogleSignInPageState extends State<GoogleSignInPage> {
  bool get _isSigningIn => context.watch<AuthBloc>().state.busy;
  String? get _error => context.watch<AuthBloc>().state.errorKey;
  void _handleSignIn() =>
      context.read<AuthBloc>().add(const AuthGoogleRequested());
  void _handleGuestSignIn() =>
      context.read<AuthBloc>().add(const AuthGitHubRequested());

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE9F3EB), Color(0xFFFAFCF8), Color(0xFFEDF3EE)],
        ),
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - 48).clamp(
                  0.0,
                  double.infinity,
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: AuthLanguagePicker(),
                      ),
                      SizedBox(height: 12),
                      EntranceTransition(
                        child: Row(
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                AppStrings.of(context)('MASJIDLAR XARITASI'),
                                style: TextStyle(
                                  fontSize: 11,
                                  letterSpacing: 2.1,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 26),
                      const _MapIllustration(),
                      SizedBox(height: 32),
                      EntranceTransition(
                        delay: Duration(milliseconds: 100),
                        child: Text(
                          AppStrings.of(context)(
                            'Yaqiningizdagi\nmasjidni toping.',
                          ),
                          style: TextStyle(
                            fontSize: 36,
                            height: 1.10,
                            letterSpacing: -1.6,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: 14),
                      EntranceTransition(
                        delay: Duration(milliseconds: 180),
                        child: Text(
                          AppStrings.of(context)(
                            'Manzilni izlang. Yo‘lni tanlang.\nQolganini xaritaga qo‘yib bering.',
                          ),
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      SizedBox(height: 22),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Feature(
                            icon: Icons.location_on_outlined,
                            label: AppStrings.of(context)('Yaqin masjidlar'),
                          ),
                          _Feature(
                            icon: Icons.alt_route_rounded,
                            label: AppStrings.of(context)('Qulay marshrut'),
                          ),
                        ],
                      ),
                      SizedBox(height: 30),
                      EntranceTransition(
                        delay: Duration(milliseconds: 260),
                        child: GlassPanel(
                          radius: 24,
                          padding: EdgeInsets.all(8),
                          child: OutlinedButton.icon(
                            onPressed: _isSigningIn ? null : _handleSignIn,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.textPrimary,
                              minimumSize: Size(double.infinity, 56),
                              side: BorderSide(color: Color(0xFFDCE5DE)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            icon: AnimatedSwitcher(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : Duration(milliseconds: 180),
                              child: _isSigningIn
                                  ? SizedBox.square(
                                      key: ValueKey('loading'),
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : CustomPaint(
                                      key: ValueKey('google'),
                                      size: Size.square(20),
                                      painter: GoogleMarkPainter(),
                                    ),
                            ),
                            label: Text(
                              _isSigningIn
                                  ? AppStrings.of(context)('Kirilmoqda…')
                                  : AppStrings.of(context)(
                                      'Google orqali davom etish',
                                    ),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _isSigningIn
                            ? null
                            : () => Navigator.pushNamed(context, '/email-auth'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          minimumSize: Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: Icon(Icons.mail_outline_rounded),
                        label: Text(
                          AppStrings.of(context)('Email orqali davom etish'),
                        ),
                      ),
                      SizedBox(height: 6),
                      TextButton(
                        onPressed: _isSigningIn ? null : _handleGuestSignIn,
                        child: Text(
                          AppStrings.of(context)('GIt hub orqali davom etish'),
                        ),
                      ),
                      AnimatedSize(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : Duration(milliseconds: 220),
                        child: _error == null
                            ? SizedBox.shrink()
                            : Padding(
                                padding: EdgeInsets.only(top: 14),
                                child: Text(
                                  AppStrings.of(context)(_error!),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppColors.error,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                      ),
                      SizedBox(height: 18),
                      Text(
                        AppStrings.of(context)(
                          'Sizga yaqin manzil. Sizga qulay yo‘l.',
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _Feature extends StatelessWidget {
  const _Feature({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            AppStrings.of(context)(label),
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}

class _MapIllustration extends StatelessWidget {
  const _MapIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: GlassPanel(
        radius: 36,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: MapArtworkPainter()),
            Align(
              alignment: Alignment(0.18, -0.18),
              child: LocationHalo(size: 142, child: MosqueIcon(size: 86)),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: GlassPanel(
                radius: 18,
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.near_me_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.of(context)('Masjidlar xaritasi'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
