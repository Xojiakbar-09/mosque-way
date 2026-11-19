import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/localization/app_strings.dart';
import 'bloc/qibla_bloc.dart';
import 'widgets/compass_dial.dart';
import 'widgets/qibla_bearing_card.dart';
import 'widgets/qibla_calibration_hint.dart';
import 'widgets/qibla_compass_fallback_note.dart';
import 'widgets/qibla_error_section.dart';
import 'widgets/qibla_heading_status.dart';
import 'widgets/qibla_loading_indicator.dart';

class QiblaPage extends StatelessWidget {
  const QiblaPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => QiblaBloc()..add(const QiblaStarted()),
    child: const _QiblaView(),
  );
}

class _QiblaView extends StatefulWidget {
  const _QiblaView();

  @override
  State<_QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends State<_QiblaView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final bloc = context.read<QiblaBloc>();
    if (state == AppLifecycleState.resumed) {
      bloc.add(const QiblaStarted());
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      bloc.add(const QiblaPaused());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(t('qibla')),
        actions: [
          IconButton(
            tooltip: t('qiblaRestart'),
            onPressed: () =>
                context.read<QiblaBloc>().add(const QiblaStarted()),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: BlocBuilder<QiblaBloc, QiblaState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            Text(
              t('qiblaHold'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 32),
            CompassDial(state: state),
            const SizedBox(height: 28),
            if (state.loading)
              QiblaLoadingIndicator(
                messageKey: state.bearing == null
                    ? 'locating'
                    : 'compassWaiting',
              ),
            if (state.heading != null)
              QiblaHeadingStatus(
                heading: state.heading!,
                aligned: state.aligned,
                approximate: state.approximate,
              ),
            if (state.bearing != null) ...[
              const SizedBox(height: 20),
              QiblaBearingCard(bearing: state.bearing!),
            ],
            if (state.calibrate) const QiblaCalibrationHint(),
            if (state.message == 'compassUnsupported')
              QiblaCompassFallbackNote(showMoveHint: state.heading == null)
            else if (state.message != null)
              QiblaErrorSection(messageKey: state.message!),
          ],
        ),
      ),
    );
  }
}
