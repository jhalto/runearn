import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:runearn/core/network/network_info.dart';
import 'package:runearn/feature/accounts/data/datasources/account_local_data_source.dart';
import 'package:runearn/feature/accounts/data/datasources/account_remote_data_source.dart';
import 'package:runearn/feature/accounts/data/repositories/account_repository_impl.dart';
import 'package:runearn/feature/accounts/domain/entities/account_type.dart';
import 'package:runearn/feature/accounts/domain/entities/finance_account.dart';

void main() {
  late _Local local;
  late _Remote remote;
  late _Auth auth;
  late _User user;
  late _Network network;
  late AccountRepositoryImpl repository;
  var online = false;
  final pending = <Map<String, dynamic>>[];

  setUp(() {
    local = _Local();
    remote = _Remote();
    auth = _Auth();
    user = _User();
    network = _Network();
    online = false;
    pending.clear();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('user-1');
    when(() => network.isConnected).thenAnswer((_) async => online);
    when(() => local.upsert(any())).thenAnswer((invocation) async {
      pending
        ..clear()
        ..add(Map<String, dynamic>.from(invocation.positionalArguments.first));
    });
    when(() => local.getPending('user-1')).thenAnswer((_) async => pending);
    when(() => local.getPendingTransfers('user-1')).thenAnswer((_) async => []);
    when(() => remote.upsert(any())).thenAnswer((_) async {});
    when(() => local.markSynced(any(), 'user-1')).thenAnswer((_) async {});
    repository = AccountRepositoryImpl(
      local: local,
      remote: remote,
      auth: auth,
      network: network,
    );
  });

  test(
    'persists offline and uploads pending account after reconnect',
    () async {
      final account = FinanceAccount(
        id: 'cash',
        name: 'Wallet',
        type: FinanceAccountType.cash,
        balance: 500,
        createdAt: DateTime(2026, 7, 1),
      );

      await repository.saveAccount(account);

      verify(() => local.upsert(any())).called(1);
      verifyNever(() => remote.upsert(any()));
      expect(pending.single['isSynced'], 0);

      online = true;
      await repository.syncPendingAccounts();

      final uploaded =
          verify(() => remote.upsert(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(uploaded['id'], 'cash');
      verify(() => local.markSynced('cash', 'user-1')).called(1);
    },
  );
}

class _Local extends Mock implements AccountLocalDataSource {}

class _Remote extends Mock implements AccountRemoteDataSource {}

class _Auth extends Mock implements FirebaseAuth {}

class _User extends Mock implements User {}

class _Network extends Mock implements NetworkInfo {}
