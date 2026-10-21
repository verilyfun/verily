import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:skribble/skribble.dart' show SkribbleIcon;
import 'package:verily_client/verily_client.dart';

import 'package:verily_flutter/app/router/verily_routes.dart';
import 'package:verily_flutter/app/theme/verily_icons.g.dart';
import 'package:verily_flutter/app/theme/verily_theme.dart';
import 'package:verily_flutter/app/widgets/verily_action_button.dart';
import 'package:verily_flutter/app/widgets/verily_app_header.dart';
import 'package:verily_flutter/app/widgets/verily_state_panel.dart';
import 'package:verily_flutter/features/apps/apps_providers.dart';
import 'package:verily_flutter/features/apps/apps_repository.dart';
import 'package:verily_flutter/features/apps/widgets/app_key_dialog.dart';
import 'package:verily_flutter/features/apps/widgets/apps_common.dart';
import 'package:verily_flutter/l10n/l10n.dart';
import 'package:verily_flutter/testing/verily_test_keys.dart';

/// The longest App name the server accepts.
const appNameMaxLength = 80;

/// The longest website address the server accepts.
const appWebsiteMaxLength = 200;

/// Your Verily Apps: software that confirms actions on its own.
///
/// Register an App, take its key once, and open an App to manage keys, read
/// its confirmations, and copy a working request.
class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final palette = Theme.of(context).verily;
    final apps = ref.watch(verilyAppsProvider);

    return Scaffold(
      backgroundColor: palette.canvas,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          VerilyAppHeader(
            title: l10n.appsTitle,
            subtitle: l10n.appsSubtitle,
            leading: const _BackButton(),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final gutter = math.max(
                    appsPageGutter,
                    (constraints.maxWidth - appsMaxContentWidth) / 2,
                  );
                  return ListView(
                    padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 32),
                    children: [
                      _RegisterAppPanel(
                        onRegistered: () => ref.invalidate(verilyAppsProvider),
                      ),
                      const SizedBox(height: 24),
                      AppsSectionHeading(l10n.appsListHeading),
                      const SizedBox(height: 12),
                      ...apps.when(
                        loading: () => [
                          VerilyLoadingPanel(label: l10n.appsLoading),
                        ],
                        error: (error, _) => [
                          VerilyStatePanel.problem(
                            title: l10n.appsLoadFailedTitle,
                            message: l10n.errorGeneric,
                            action: VerilyStateAction(
                              label: l10n.dialogRetry,
                              onPressed: () =>
                                  ref.invalidate(verilyAppsProvider),
                            ),
                          ),
                        ],
                        data: (items) => [
                          if (items.isEmpty)
                            VerilyStatePanel.empty(
                              title: l10n.appsEmptyTitle,
                              message: l10n.appsEmptyBody,
                            ),
                          for (final app in items) ...[
                            _AppCard(app: app),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        final router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else {
          router.goNamed(VerilyRouteNames.create);
        }
      },
      icon: const SkribbleIcon(data: VerilyIcons.back),
    );
  }
}

/// Names a new App and hands over its first key.
class _RegisterAppPanel extends HookConsumerWidget {
  const _RegisterAppPanel({required this.onRegistered});

  final VoidCallback onRegistered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final name = useTextEditingController();
    final website = useTextEditingController();
    final saving = useState(false);
    final failed = useState(false);

    Future<void> register() async {
      if (formKey.currentState?.validate() != true) return;
      saving.value = true;
      failed.value = false;
      final VerilyAppCredential credential;
      try {
        final websiteText = website.text.trim();
        credential = await ref
            .read(appsRepositoryProvider)
            .createApp(
              name: name.text.trim(),
              websiteUrl: websiteText.isEmpty ? null : websiteText,
            );
      } on Object catch (error) {
        debugPrint('Registering an App failed: $error');
        if (!context.mounted) return;
        failed.value = true;
        saving.value = false;
        return;
      }
      if (!context.mounted) return;
      saving.value = false;
      name.clear();
      website.clear();
      onRegistered();
      await showAppKeyOnce(context, credential);
    }

    return AppsPanel(
      color: palette.highlight,
      seed: 269,
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppsSectionHeading(l10n.appsIntroTitle),
            const SizedBox(height: 6),
            Text(
              l10n.appsIntroBody,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.ink),
            ),
            const SizedBox(height: 16),
            Semantics(
              headingLevel: 3,
              child: Text(
                l10n.appsRegisterHeading,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: palette.ink,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: VerilyTestKeys.appsName,
              controller: name,
              enabled: !saving.value,
              maxLength: appNameMaxLength,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.appsNameLabel,
                hintText: l10n.appsNameHint,
              ),
              validator: (value) => validateAppName(l10n, value),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: VerilyTestKeys.appsWebsite,
              controller: website,
              enabled: !saving.value,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => unawaited(register()),
              decoration: InputDecoration(
                labelText: l10n.appsWebsiteLabel,
                hintText: l10n.appsWebsiteHint,
              ),
              validator: (value) => validateAppWebsite(l10n, value),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: VerilyActionButton(
                key: VerilyTestKeys.appsRegister,
                label: l10n.appsRegister,
                expand: false,
                isLoading: saving.value,
                leading: const SkribbleIcon(data: VerilyIcons.plus),
                onPressed: () => unawaited(register()),
              ),
            ),
            if (failed.value) ...[
              const SizedBox(height: 8),
              Semantics(
                liveRegion: true,
                child: Text(
                  l10n.appsRegisterFailed,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.ink,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The same name rules as the server: required, at most 80 characters.
String? validateAppName(AppLocalizations l10n, String? value) {
  final normalized = (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  if (normalized.isEmpty) return l10n.appsNameRequired;
  if (normalized.length > appNameMaxLength) return l10n.appsNameTooLong;
  return null;
}

/// The same website rules as the server: optional, but when given a plain
/// `https://` address with a host, at most 200 characters.
String? validateAppWebsite(AppLocalizations l10n, String? value) {
  final normalized = (value ?? '').trim();
  if (normalized.isEmpty) return null;
  final uri = Uri.tryParse(normalized);
  final valid =
      normalized.length <= appWebsiteMaxLength &&
      uri != null &&
      uri.isScheme('https') &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty &&
      !uri.hasFragment;
  return valid ? null : l10n.appsWebsiteInvalid;
}

class _AppCard extends StatelessWidget {
  const _AppCard({required this.app});

  final VerilyAppView app;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final palette = theme.verily;
    final active = app.status == VerilyAppStatus.active;

    return Semantics(
      button: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: VerilyTestKeys.appsCard(app.id.toString()),
          borderRadius: BorderRadius.circular(VerilyRadius.card),
          onTap: () => context.push(VerilyLocations.app(app.id.toString())),
          child: AppsPanel(
            seed: app.id.hashCode & 0x7fffffff,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Semantics(
                            headingLevel: 3,
                            child: Text(
                              app.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: palette.ink,
                              ),
                            ),
                          ),
                          AppsStatusPill(
                            label: active
                                ? l10n.appsStatusActive
                                : l10n.appsStatusRevoked,
                            muted: !active,
                          ),
                        ],
                      ),
                      if (app.websiteUrl case final website?) ...[
                        const SizedBox(height: 2),
                        Text(
                          website,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: palette.mutedInk,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Text(
                        l10n.appsBoundActions(app.boundActionCount),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                      Text(
                        l10n.appsActiveKeys(activeKeysOf(app).length),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: palette.mutedInk,
                        ),
                      ),
                    ],
                  ),
                ),
                SkribbleIcon(
                  data: VerilyIcons.chevronRight,
                  color: palette.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
