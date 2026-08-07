import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:runearn/feature/backup/domain/entities/backup_result.dart';
import 'package:runearn/feature/backup/domain/services/finance_backup_service.dart';

sealed class BackupState extends Equatable {
  const BackupState();
  @override
  List<Object?> get props => const [];
}

final class BackupIdle extends BackupState {
  const BackupIdle();
}

final class BackupWorking extends BackupState {
  const BackupWorking(this.operation);
  final String operation;
  @override
  List<Object?> get props => [operation];
}

final class BackupTextReady extends BackupState {
  const BackupTextReady(this.text, this.format);
  final String text;
  final String format;
  @override
  List<Object?> get props => [text, format];
}

final class BackupRestored extends BackupState {
  const BackupRestored(this.result);
  final BackupResult result;
  @override
  List<Object?> get props => [result];
}

final class BackupFailed extends BackupState {
  const BackupFailed(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}

class BackupCubit extends Cubit<BackupState> {
  BackupCubit(this.service) : super(const BackupIdle());
  final FinanceBackupService service;

  Future<void> createBackup(String password) async {
    emit(const BackupWorking('Encrypting backup...'));
    try {
      emit(
        BackupTextReady(
          await service.createBackup(password),
          'Encrypted backup',
        ),
      );
    } catch (error) {
      emit(BackupFailed(_message(error)));
    }
  }

  Future<void> exportCsv() async {
    emit(const BackupWorking('Creating CSV export...'));
    try {
      emit(
        BackupTextReady(
          await service.createTransactionsCsv(),
          'Transactions CSV',
        ),
      );
    } catch (error) {
      emit(BackupFailed(_message(error)));
    }
  }

  Future<void> restore(String source, String password) async {
    emit(const BackupWorking('Decrypting and validating...'));
    try {
      emit(BackupRestored(await service.restore(source, password)));
    } catch (error) {
      emit(BackupFailed(_message(error)));
    }
  }

  String _message(Object error) =>
      error is FormatException ? error.message : error.toString();
}
