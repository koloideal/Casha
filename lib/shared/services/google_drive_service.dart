import 'dart:typed_data';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

class DriveBackupResult {
  final bool success;
  final String? error;
  final String? fileId;
  final DateTime? modifiedTime;

  const DriveBackupResult({this.success = false, this.error, this.fileId, this.modifiedTime});

  factory DriveBackupResult.ok(String fileId, DateTime modifiedTime) =>
      DriveBackupResult(success: true, fileId: fileId, modifiedTime: modifiedTime);

  factory DriveBackupResult.failed(String error) =>
      DriveBackupResult(success: false, error: error);
}

class GoogleDriveService {
  static const _fileName = 'casha_backup.json';
  static const _appDataFolder = 'appDataFolder';

  final GoogleSignIn _googleSignIn;

  GoogleDriveService(this._googleSignIn);

  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;
  Stream<GoogleSignInAccount?> get onUserChanged => _googleSignIn.onCurrentUserChanged;

  Future<void> signIn() async {
    await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
  }

  Future<drive.DriveApi?> _getDriveApi() async {
    if (_googleSignIn.currentUser == null) return null;
    final httpClient = await _googleSignIn.authenticatedClient();
    if (httpClient == null) return null;
    return drive.DriveApi(httpClient);
  }

  Future<String?> _findExistingFile(drive.DriveApi api) async {
    final list = await api.files.list(
      spaces: _appDataFolder,
      q: "name = '$_fileName' and trashed = false",
      $fields: 'files(id, name, modifiedTime)',
    );
    return list.files?.isNotEmpty == true ? list.files!.first.id : null;
  }

  Future<DriveBackupResult> uploadBackup(Uint8List data) async {
    final api = await _getDriveApi();
    if (api == null) {
      return DriveBackupResult.failed('Not authenticated');
    }

    try {
      final existingId = await _findExistingFile(api);

      final media = drive.Media(
        Stream<List<int>>.fromIterable([data.toList()]),
        data.length,
      );

      if (existingId != null) {
        final file = drive.File(
          name: _fileName,
          modifiedTime: DateTime.now(),
        );
        final updated = await api.files.update(
          file,
          existingId,
          uploadMedia: media,
          $fields: 'id, modifiedTime',
        );
        return DriveBackupResult.ok(
          updated.id!,
          updated.modifiedTime!,
        );
      } else {
        final file = drive.File(
          name: _fileName,
          parents: [_appDataFolder],
          modifiedTime: DateTime.now(),
        );
        final created = await api.files.create(
          file,
          uploadMedia: media,
          $fields: 'id, modifiedTime',
        );
        return DriveBackupResult.ok(
          created.id!,
          created.modifiedTime!,
        );
      }
    } catch (e) {
      return DriveBackupResult.failed(e.toString());
    }
  }

  Future<Uint8List?> downloadBackup() async {
    final api = await _getDriveApi();
    if (api == null) return null;

    try {
      final fileId = await _findExistingFile(api);
      if (fileId == null) return null;

      final media = await api.files.get(
        fileId,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media;

      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }
      return Uint8List.fromList(bytes);
    } catch (e) {
      return null;
    }
  }

  Future<DateTime?> getLastBackupTime() async {
    final api = await _getDriveApi();
    if (api == null) return null;

    try {
      final list = await api.files.list(
        spaces: _appDataFolder,
        q: "name = '$_fileName' and trashed = false",
        $fields: 'files(id, name, modifiedTime)',
      );
      if (list.files?.isNotEmpty == true) {
        return list.files!.first.modifiedTime;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
