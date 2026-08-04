import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

final class LocalDataIsolationService {
  const LocalDataIsolationService([this._directoryLoader]);

  final Future<Directory> Function()? _directoryLoader;

  Future<Directory> _directory() =>
      (_directoryLoader ?? getApplicationDocumentsDirectory)();

  static String userFileKey(String userId) =>
      sha256.convert(userId.codeUnits).toString().substring(0, 24);

  Future<File> userDatabase(String userId) async => File(
    path.join(
      (await _directory()).path,
      'smart_ledger_${userFileKey(userId)}.sqlite',
    ),
  );

  Future<File> _decisionFile(String userId) async => File(
    path.join(
      (await _directory()).path,
      'smart_ledger_${userFileKey(userId)}.decision',
    ),
  );

  Future<File> _legacyDatabase() async =>
      File(path.join((await _directory()).path, 'smart_ledger.sqlite'));

  Future<bool> requiresBindingDecision(String userId) async {
    final legacy = await _legacyDatabase();
    final target = await userDatabase(userId);
    final decision = await _decisionFile(userId);
    return legacy.existsSync() &&
        !target.existsSync() &&
        !decision.existsSync();
  }

  Future<void> bindLegacy(String userId) async {
    final legacy = await _legacyDatabase();
    final target = await userDatabase(userId);
    if (target.existsSync()) return;
    if (!legacy.existsSync()) {
      await startFresh(userId);
      return;
    }
    final temporary = File('${target.path}.binding');
    if (temporary.existsSync()) await temporary.delete();
    await legacy.copy(temporary.path);
    await temporary.rename(target.path);
    await (await _decisionFile(userId)).writeAsString('bound', flush: true);
  }

  Future<void> startFresh(String userId) async {
    await (await _decisionFile(userId)).writeAsString('fresh', flush: true);
  }

  Future<void> deleteUserData(String userId) async {
    final database = await userDatabase(userId);
    for (final suffix in ['', '-wal', '-shm']) {
      final file = File('${database.path}$suffix');
      if (file.existsSync()) await file.delete();
    }
    final decision = await _decisionFile(userId);
    if (decision.existsSync()) await decision.delete();
  }
}
