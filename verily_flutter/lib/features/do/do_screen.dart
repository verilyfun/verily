import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/core/user_message.dart';
import 'package:verily_flutter/features/do/do_filter.dart';
import 'package:verily_flutter/features/do/do_providers.dart';
import 'package:verily_flutter/features/do/widgets/action_card.dart';
import 'package:verily_flutter/features/do/widgets/actions_map.dart';
import 'package:verily_flutter/features/evidence/evidence_service.dart';
import 'package:verily_flutter/features/evidence/location_service.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';
import 'package:verily_flutter/features/places/places.dart';

enum _DoView { list, map }

/// The Do tab: nearby and available actions, as a list or a map.
class DoScreen extends HookConsumerWidget {
  const DoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final filter = useState(DoFilter.all);
    final view = useState(_DoView.list);
    final nearby = ref.watch(nearbyLocationProvider);
    final fix = switch (nearby) {
      NearbyLocationFound(:final fix) => fix,
      _ => null,
    };

    Future<void> selectFilter(DoFilter selected) async {
      filter.value = selected;
      if (selected != DoFilter.nearby ||
          ref.read(nearbyLocationProvider) is! NearbyLocationUnasked) {
        return;
      }
      await _askForApproximateLocation(context, ref);
    }

    void open(ActionOpportunity action) =>
        unawaited(context.push(VerilyLocations.action(action.id.toString())));

    final source = filter.value == DoFilter.nearby
        ? (fix == null ? null : ref.watch(nearbyActionsProvider(fix)))
        : ref.watch(actionFeedProvider);

    Future<void> refresh() async {
      if (filter.value == DoFilter.nearby) {
        if (fix != null) {
          return ref.refresh(nearbyActionsProvider(fix).future).then((_) {});
        }
        return;
      }
      return ref.refresh(actionFeedProvider.future).then((_) {});
    }

    final Widget content;
    if (source == null) {
      content = _NearbyLocationPanel(state: nearby);
    } else {
      content = source.when(
        loading: () => VerilyLoadingPanel(label: l10n.doLoading),
        error: (error, stackTrace) {
          debugPrint('Actions failed to load: $error');
          return VerilyStatePanel.problem(
            title: l10n.doLoadFailedTitle,
            message: userMessageFor(l10n, error),
            action: VerilyStateAction(
              label: l10n.dialogRetry,
              onPressed: () => unawaited(refresh()),
            ),
          );
        },
        data: (actions) {
          final shown = actions.where(filter.value.matches).toList();
          if (actions.isEmpty) {
            return filter.value == DoFilter.nearby
                ? VerilyStatePanel.empty(
                    title: l10n.doNearbyEmptyTitle,
                    message: l10n.doNearbyEmptyBody,
                    tone: VerilyTone.place,
                    action: VerilyStateAction(
                      label: l10n.doShowAll,
                      onPressed: () => filter.value = DoFilter.all,
                    ),
                  )
                : VerilyStatePanel.empty(
                    title: l10n.doEmptyTitle,
                    message: l10n.doEmptyBody,
                    action: VerilyStateAction(
                      label: l10n.doPostAction,
                      onPressed: () =>
                          unawaited(context.push(VerilyRoutePaths.actionNew)),
                    ),
                  );
          }
          if (shown.isEmpty) {
            return VerilyStatePanel.empty(
              title: l10n.doFilterEmptyTitle,
              message: l10n.doFilterEmptyBody,
              action: VerilyStateAction(
                label: l10n.doShowAll,
                onPressed: () => filter.value = DoFilter.all,
              ),
            );
          }
          return _DoResults(
            actions: shown,
            view: view.value,
            here: fix,
            onOpen: open,
          );
        },
      );
    }

    final isMap =
        view.value == _DoView.map &&
        source?.hasValue == true &&
        (source?.value?.where(filter.value.matches).isNotEmpty ?? false);

    return ColoredBox(
      color: palette.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: l10n.doTitle,
            subtitle: l10n.doSubtitle,
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SegmentedButton<_DoView>(
                  key: VerilyTestKeys.doViewToggle,
                  segments: [
                    ButtonSegment(
                      value: _DoView.list,
                      label: Text(l10n.doViewList),
                      icon: const SkribbleIcon(
                        data: VerilyIcons.checklist,
                        size: 18,
                      ),
                    ),
                    ButtonSegment(
                      value: _DoView.map,
                      label: Text(l10n.doViewMap),
                      icon: const SkribbleIcon(data: VerilyIcons.map, size: 18),
                    ),
                  ],
                  selected: {view.value},
                  showSelectedIcon: false,
                  onSelectionChanged: (selection) =>
                      view.value = selection.single,
                ),
                const SizedBox(height: 12),
                _FilterChips(
                  selected: filter.value,
                  onSelected: (selected) => unawaited(selectFilter(selected)),
                ),
              ],
            ),
          ),
          Expanded(
            child: isMap
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: content,
                  )
                : RefreshIndicator(
                    onRefresh: refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [content],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Explains, once per session, why Nearby needs the approximate location,
/// then reads it if the person agrees.
Future<void> _askForApproximateLocation(
  BuildContext context,
  WidgetRef ref,
) async {
  final allowed = await showDialog<bool>(
    context: context,
    builder: (context) {
      final l10n = context.l10n;
      return AlertDialog(
        icon: const SkribbleIcon(data: VerilyIcons.nearby),
        title: Text(l10n.doNearbyExplainTitle),
        content: Text(l10n.doNearbyExplainBody),
        actions: [
          TextButton(
            key: VerilyTestKeys.doNearbyNotNow,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.doNearbyNotNow),
          ),
          FilledButton(
            key: VerilyTestKeys.doNearbyContinue,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.doNearbyContinue),
          ),
        ],
      );
    },
  );
  if (!context.mounted) return;
  final controller = ref.read(nearbyLocationProvider.notifier);
  if (allowed ?? false) {
    await controller.locate();
  } else {
    controller.decline();
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selected, required this.onSelected});

  final DoFilter selected;
  final ValueChanged<DoFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Chips run on past the page gutter to the screen edge, so a cut-off
      // chip reads as "there's more this way".
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final filter in DoFilter.values) ...[
            FilterChip(
              key: VerilyTestKeys.doFilter(filter.name),
              selected: selected == filter,
              showCheckmark: false,
              onSelected: (_) => onSelected(filter),
              avatar: SkribbleIcon(data: filter.icon, size: 17),
              label: Text(filter.label(l10n)),
            ),
            if (filter != DoFilter.values.last) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _DoResults extends StatelessWidget {
  const _DoResults({
    required this.actions,
    required this.view,
    required this.here,
    required this.onOpen,
  });

  final List<ActionOpportunity> actions;
  final _DoView view;
  final LocationFix? here;
  final ValueChanged<ActionOpportunity> onOpen;

  @override
  Widget build(BuildContext context) {
    if (view == _DoView.map) {
      return ActionsMap(actions: actions, here: here, onOpen: onOpen);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, action) in actions.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          ActionCard(
            action: action,
            distanceMeters: _distanceTo(action),
            onTap: () => onOpen(action),
          ),
        ],
      ],
    );
  }

  double? _distanceTo(ActionOpportunity action) {
    final from = here;
    final place = placeOf(action);
    if (from == null || place == null) return null;
    return distanceMeters(
      from.latitude,
      from.longitude,
      place.latitude!,
      place.longitude!,
    );
  }
}

/// What Nearby shows before it has a position: the reason it needs one, a
/// wait, or what went wrong and how to fix it.
class _NearbyLocationPanel extends ConsumerWidget {
  const _NearbyLocationPanel({required this.state});

  final NearbyLocation state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final controller = ref.read(nearbyLocationProvider.notifier);
    final useLocation = VerilyStateAction(
      label: l10n.doNearbyUseLocation,
      onPressed: () => unawaited(controller.locate()),
    );
    return switch (state) {
      NearbyLocationLocating() => VerilyLoadingPanel(
        label: l10n.doNearbyLocating,
      ),
      NearbyLocationUnasked() => VerilyStatePanel.empty(
        title: l10n.doNearbyExplainTitle,
        message: l10n.doNearbyExplainBody,
        tone: VerilyTone.place,
        action: VerilyStateAction(
          label: l10n.doNearbyUseLocation,
          onPressed: () => unawaited(_askForApproximateLocation(context, ref)),
        ),
      ),
      NearbyLocationDeclined() => VerilyStatePanel.empty(
        title: l10n.doNearbyDeclinedTitle,
        message: l10n.doNearbyDeclinedBody,
        tone: VerilyTone.place,
        action: useLocation,
      ),
      NearbyLocationFailed(:final failure) => switch (failure) {
        LocationFailure.deniedForever => VerilyStatePanel.problem(
          title: l10n.doNearbyBlockedTitle,
          message: l10n.doNearbyBlockedBody,
          action: VerilyStateAction(
            label: l10n.doOpenSettings,
            onPressed: () =>
                unawaited(ref.read(locationServiceProvider).openSettings()),
          ),
          secondaryAction: useLocation,
        ),
        LocationFailure.servicesOff => VerilyStatePanel.problem(
          title: l10n.doNearbyServicesOffTitle,
          message: l10n.doNearbyServicesOffBody,
          action: useLocation,
        ),
        LocationFailure.denied => VerilyStatePanel.problem(
          title: l10n.doNearbyDeniedTitle,
          message: l10n.doNearbyDeniedBody,
          action: useLocation,
        ),
        LocationFailure.timedOut => VerilyStatePanel.problem(
          title: l10n.doNearbyTimedOutTitle,
          message: l10n.doNearbyTimedOutBody,
          action: useLocation,
        ),
      },
      // A found position never reaches this panel.
      NearbyLocationFound() => const SizedBox.shrink(),
    };
  }
}
