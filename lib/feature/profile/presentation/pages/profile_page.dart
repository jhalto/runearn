import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:runearn/config/route/route_names.dart';
import 'package:runearn/core/global_widgets/app_back_button.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_event.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_state.dart';
import 'package:runearn/feature/currency/domain/entities/currency_definition.dart';
import 'package:runearn/feature/currency/presentation/cubit/currency_cubit.dart';
import 'package:runearn/feature/currency/presentation/widgets/currency_picker_sheet.dart';
import 'package:runearn/feature/profile/domain/entities/user_entity.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_bloc.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_event.dart';
import 'package:runearn/feature/profile/presentation/bloc/profile_state.dart';
import 'package:runearn/feature/profile/presentation/cubit/account_deletion_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, current) => current is AuthUnauthenticated,
      listener: (context, state) {
        Navigator.pushNamedAndRemoveUntil(context, Routes.login, (_) => false);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          leading: const AppBackButton(),
          title: const Text('Profile'),
        ),
        body: const SafeArea(child: _ProfileContent()),
      ),
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is ProfileFailure) {
          return _ProfileFailure(message: state.message);
        }
        if (state is ProfileEmpty) {
          return const _ProfileFailure(
            message: 'No profile was found for this account.',
          );
        }

        final user = (state as ProfileLoaded).user;
        return RefreshIndicator(
          onRefresh: () async {
            context.read<ProfileBloc>().add(LoadCurrentUserProfileEvent());
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _ProfileHeader(user: user),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'Personal information'),
                      const SizedBox(height: 10),
                      Card(
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.badge_outlined,
                              label: 'Name',
                              value: user.name,
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: user.email ?? 'Not available',
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.payments_outlined,
                              label: 'Currency',
                              value: user.currency,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionLabel(label: 'Account'),
                      const SizedBox(height: 10),
                      Card(
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.verified_user_outlined,
                              label: 'Account type',
                              value: user.isGuest ? 'Guest' : 'Registered',
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.login_rounded,
                              label: 'Sign-in provider',
                              value: _providerLabel(user.provider),
                            ),
                            if (user.lastLoginAt != null) ...[
                              const Divider(height: 1),
                              _InfoTile(
                                icon: Icons.schedule_rounded,
                                label: 'Last login',
                                value: DateFormat(
                                  'd MMM yyyy, h:mm a',
                                ).format(user.lastLoginAt!.toLocal()),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _providerLabel(String provider) {
    switch (provider) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email and password';
      case 'anonymous':
        return 'Guest';
      default:
        return provider;
    }
  }
}

// Kept temporarily for backward-compatible profile deep links.
// ignore: unused_element
class _DeleteAccountCard extends StatelessWidget {
  const _DeleteAccountCard({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.error),
                const SizedBox(width: 10),
                Text(
                  'Delete RunEarn account',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Permanently deletes your profile, cloud finance records, '
              'local databases, receipts, reminders, and encryption key. '
              'This cannot be undone.',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              onPressed: () => _showDeleteAccountDialog(context, user),
              icon: const Icon(Icons.person_remove_outlined),
              label: const Text('Delete my account'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showDeleteAccountDialog(
  BuildContext context,
  UserEntity user,
) async {
  const confirmationPhrase = 'DELETE MY ACCOUNT';
  final deletionCubit = context.read<AccountDeletionCubit>();
  final confirmationController = TextEditingController();
  final passwordController = TextEditingController();
  final requiresPassword = user.provider == 'password';
  var confirmation = '';
  var password = '';
  var obscurePassword = true;

  try {
    final deleted = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: deletionCubit,
        child: BlocConsumer<AccountDeletionCubit, AccountDeletionState>(
          listener: (context, state) {
            if (state is AccountDeletionSucceeded) {
              Navigator.pop(dialogContext, true);
            }
          },
          builder: (context, state) {
            final deleting = state is AccountDeletionInProgress;
            final failure = state is AccountDeletionFailed
                ? state.message
                : null;
            return StatefulBuilder(
              builder: (context, setDialogState) {
                final canDelete =
                    confirmation == confirmationPhrase &&
                    (!requiresPassword || password.isNotEmpty) &&
                    !deleting;
                return PopScope(
                  canPop: !deleting,
                  child: AlertDialog(
                    scrollable: true,
                    icon: Icon(
                      Icons.delete_forever_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 36,
                    ),
                    title: const Text('Permanently delete account?'),
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'All cloud and device data for this account will be '
                          'permanently removed. Create a backup first if you '
                          'need to retain anything.',
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Type $confirmationPhrase to continue.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: confirmationController,
                          enabled: !deleting,
                          autocorrect: false,
                          enableSuggestions: false,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (value) =>
                              setDialogState(() => confirmation = value.trim()),
                          decoration: const InputDecoration(
                            labelText: 'Confirmation phrase',
                            prefixIcon: Icon(Icons.edit_outlined),
                          ),
                        ),
                        if (requiresPassword) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: passwordController,
                            enabled: !deleting,
                            obscureText: obscurePassword,
                            autocorrect: false,
                            enableSuggestions: false,
                            autofillHints: const [AutofillHints.password],
                            onChanged: (value) =>
                                setDialogState(() => password = value),
                            decoration: InputDecoration(
                              labelText: 'Current password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                onPressed: deleting
                                    ? null
                                    : () => setDialogState(
                                        () =>
                                            obscurePassword = !obscurePassword,
                                      ),
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 14),
                          Text(
                            user.isGuest
                                ? 'Your guest session will be verified before deletion.'
                                : 'Google will ask you to verify your account.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        if (failure != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            failure,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: deleting
                            ? null
                            : () => Navigator.pop(dialogContext, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.error,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onError,
                        ),
                        onPressed: canDelete
                            ? () => deletionCubit.delete(
                                password: requiresPassword ? password : null,
                              )
                            : null,
                        icon: deleting
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_forever_rounded),
                        label: Text(
                          deleting ? 'Deleting account…' : 'Delete permanently',
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
    if (deleted == true && context.mounted) {
      context.read<AuthBloc>().add(AccountDeletedEvent());
    }
  } finally {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    confirmationController.dispose();
    passwordController.dispose();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final photoUrl = user.photoUrl?.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.primaryContainer,
              colors.secondaryContainer.withValues(alpha: 0.65),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 520;
            final avatar = CircleAvatar(
              radius: 42,
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              backgroundImage: photoUrl?.isNotEmpty == true
                  ? NetworkImage(photoUrl!)
                  : null,
              child: photoUrl?.isNotEmpty == true
                  ? null
                  : Text(
                      _initials(user.name),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            );
            final details = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email ?? (user.isGuest ? 'Guest account' : 'No email'),
                  textAlign: compact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _showEditProfileSheet(context, user),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                ),
              ],
            );

            if (compact) {
              return Column(
                children: [avatar, const SizedBox(height: 16), details],
              );
            }
            return Row(
              children: [
                avatar,
                const SizedBox(width: 22),
                Expanded(child: details),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return 'U';
    return words.take(2).map((word) => word[0].toUpperCase()).join();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label, style: Theme.of(context).textTheme.titleMedium);
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ProfileFailure extends StatelessWidget {
  const _ProfileFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 18),
            FilledButton.tonalIcon(
              onPressed: () => context.read<ProfileBloc>().add(
                LoadCurrentUserProfileEvent(),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _showEditProfileSheet(
  BuildContext context,
  UserEntity user,
) async {
  final profileBloc = context.read<ProfileBloc>();
  final currencyCubit = context.read<CurrencyCubit>();
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController(text: user.name);
  var currency = user.currency;
  var saving = false;

  try {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  4,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 20,
                ),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit profile',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                        validator: (value) {
                          final name = value?.trim() ?? '';
                          if (name.isEmpty) return 'Enter your name';
                          if (name.length < 2) {
                            return 'Name must contain at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final value = await showCurrencyPickerSheet(
                            context,
                            currencies: CurrencyCatalog.supported,
                            selectedCode: currency,
                            title: 'Select default currency',
                          );
                          if (value != null && context.mounted) {
                            setState(() => currency = value);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Default currency',
                            prefixIcon: Icon(Icons.payments_outlined),
                            suffixIcon: Icon(Icons.search_rounded),
                          ),
                          child: Text(_profileCurrencyLabel(currency)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: saving
                            ? null
                            : () async {
                                if (!(formKey.currentState?.validate() ??
                                    false)) {
                                  return;
                                }
                                setState(() => saving = true);
                                try {
                                  final ready = await _setProfileBaseCurrency(
                                    context,
                                    currencyCubit,
                                    currency,
                                  );
                                  if (!ready) {
                                    if (context.mounted) {
                                      setState(() => saving = false);
                                    }
                                    return;
                                  }
                                  profileBloc.add(
                                    UpdateUserProfileEvent(
                                      user.copyWith(
                                        name: nameController.text.trim(),
                                        currency: currency,
                                      ),
                                    ),
                                  );
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                  }
                                } catch (error) {
                                  if (!context.mounted) return;
                                  setState(() => saving = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error.toString().replaceFirst(
                                          'Bad state: ',
                                          '',
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(saving ? 'Saving...' : 'Save changes'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    nameController.dispose();
  }
}

Future<bool> _setProfileBaseCurrency(
  BuildContext context,
  CurrencyCubit cubit,
  String selectedCurrency,
) async {
  final code = selectedCurrency.toUpperCase();
  if (code == cubit.state.baseCurrency) return true;

  if (!cubit.state.rates.containsKey(code)) {
    final oldBase = cubit.state.baseCurrency;
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final rate = await showDialog<double>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text('Exchange rate for $code'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,8}')),
            ],
            decoration: InputDecoration(
              labelText: '1 $code equals',
              suffixText: oldBase,
              helperText: 'Required to convert your dashboard totals.',
            ),
            validator: (value) {
              final parsed = double.tryParse(value ?? '');
              return parsed == null || parsed <= 0
                  ? 'Enter a rate greater than zero'
                  : null;
            },
            onFieldSubmitted: (_) {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, double.parse(controller.text));
              }
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, double.parse(controller.text));
              }
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (rate == null) return false;
    await cubit.setRate(code, rate);
  }

  await cubit.setBaseCurrency(code);
  return true;
}

String _profileCurrencyLabel(String code) {
  final currency = CurrencyCatalog.find(code);
  return '${currency.code} — ${currency.name}';
}
