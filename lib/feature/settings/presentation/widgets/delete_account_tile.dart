import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_bloc.dart';
import 'package:runearn/feature/auth/presentation/bloc/auth_event.dart';
import 'package:runearn/feature/profile/presentation/cubit/account_deletion_cubit.dart';

class DeleteAccountTile extends StatelessWidget {
  const DeleteAccountTile({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.person_remove_outlined, color: colors.error),
      title: Text(
        'Delete account',
        style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
      ),
      subtitle: const Text('Permanently remove your account and all data'),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => _showDeleteAccountDialog(context),
    );
  }
}

Future<void> _showDeleteAccountDialog(BuildContext context) async {
  const confirmationPhrase = 'DELETE MY ACCOUNT';
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No authenticated account was found.')),
    );
    return;
  }

  final providers = user.providerData.map((item) => item.providerId).toSet();
  final requiresPassword = providers.contains(EmailAuthProvider.PROVIDER_ID);
  final usesGoogle = providers.contains(GoogleAuthProvider.PROVIDER_ID);
  final deletionCubit = context.read<AccountDeletionCubit>();
  final confirmationController = TextEditingController();
  final passwordController = TextEditingController();
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
                          'Your profile, cloud finance records, local data, '
                          'receipts, reminders, and encryption key will be '
                          'permanently removed. This cannot be undone.',
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
                            user.isAnonymous
                                ? 'Your guest session will be verified before deletion.'
                                : usesGoogle
                                ? 'Google will ask you to verify the same account.'
                                : 'Your sign-in provider will be verified before deletion.',
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
