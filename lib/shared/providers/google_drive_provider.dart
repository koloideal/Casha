import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_drive_service.dart';

final googleDriveServiceProvider = Provider<GoogleDriveService>((ref) {
  final signIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/drive.appdata',
    ],
  );
  return GoogleDriveService(signIn);
});

final googleDriveUserProvider = StreamProvider<GoogleSignInAccount?>((ref) {
  final service = ref.watch(googleDriveServiceProvider);
  return service.onUserChanged;
});
