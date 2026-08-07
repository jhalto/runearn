import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/config/theme/theme_cubit.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/core/observability/app_observability.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_event.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/settings/presentation/widgets/app_update_tile.dart';
import 'package:runearn/feature/settings/presentation/widgets/delete_account_tile.dart';
import 'package:url_launcher/url_launcher.dart';

const _privacyPolicyUrl = 'https://jhalto.github.io/privacy_policy/';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthUnauthenticated,
      listener: (context, state) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          Routes.login,
          (route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const AppBackButton(),
          title: const Text('Settings'),
        ),
        body: const SafeArea(child: _SettingsContent()),
      ),
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Appearance', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              BlocBuilder<ThemeCubit, ThemeState>(
                buildWhen: (previous, current) =>
                    previous.isDark != current.isDark,
                builder: (context, state) {
                  return SwitchListTile(
                    value: state.isDark,
                    onChanged: (_) => context.read<ThemeCubit>().toggleTheme(),
                    secondary: Icon(
                      state.isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                    ),
                    title: const Text('Dark mode'),
                    subtitle: Text(
                      state.isDark
                          ? 'Using the dark appearance'
                          : 'Using the light appearance',
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              const AppUpdateTile(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Privacy', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Privacy policy'),
                subtitle: const Text(
                  'Learn how RunEarn handles and protects your data',
                ),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _openPrivacyPolicy(context),
              ),
              const Divider(height: 1),
              const _DiagnosticsTile(),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Finance', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: ListTile(
            leading: const Icon(Icons.currency_exchange_rounded),
            title: const Text('Currencies and exchange rates'),
            subtitle: const Text(
              'Choose your base currency and maintain conversion rates',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => Navigator.pushNamed(context, Routes.currencies),
          ),
        ),
        const SizedBox(height: 28),
        Text('Data', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.backup_outlined),
                title: const Text('Backup and export'),
                subtitle: const Text(
                  'Copy, export, or restore your financial records',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(context, Routes.backup),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: theme.colorScheme.error,
                ),
                title: const Text('Clear data'),
                subtitle: const Text(
                  'Choose which financial records to remove',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(context, Routes.clearData),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text('Account', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Profile'),
                subtitle: const Text('View and update your account details'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.pushNamed(context, Routes.profile),
              ),
              const Divider(height: 1),
              BlocBuilder<AuthBloc, AuthState>(
                buildWhen: (previous, current) => previous != current,
                builder: (context, state) {
                  final isLoggingOut = state is AuthLoading;
                  return ListTile(
                    leading: Icon(
                      Icons.logout_rounded,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Logout',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                    subtitle: const Text('Sign out of this device'),
                    trailing: isLoggingOut
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chevron_right_rounded),
                    enabled: !isLoggingOut,
                    onTap: () => context.read<AuthBloc>().add(LogoutEvent()),
                  );
                },
              ),
              const Divider(height: 1),
              const DeleteAccountTile(),
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> _openPrivacyPolicy(BuildContext context) async {
  try {
    final opened = await launchUrl(
      Uri.parse(_privacyPolicyUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the privacy policy.')),
      );
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the privacy policy.')),
      );
    }
  }
}

class _DiagnosticsTile extends StatefulWidget {
  const _DiagnosticsTile();

  @override
  State<_DiagnosticsTile> createState() => _DiagnosticsTileState();
}

class _DiagnosticsTileState extends State<_DiagnosticsTile> {
  late bool _enabled = AppObservability.instance.preferenceEnabled;
  bool _saving = false;

  Future<void> _setEnabled(bool value) async {
    setState(() {
      _enabled = value;
      _saving = true;
    });
    await AppObservability.instance.setEnabled(value);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: _enabled,
      onChanged: _saving ? null : _setEnabled,
      secondary: const Icon(Icons.monitor_heart_outlined),
      title: const Text('Diagnostics and analytics'),
      subtitle: const Text(
        'Share crashes, performance, and feature usage. Financial values, '
        'notes, names, and record IDs are never included.',
      ),
    );
  }
}
