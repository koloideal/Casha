import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/google_auth_service.dart';

final googleAuthProvider = Provider<GoogleAuthService>((ref) {
  return GoogleAuthService();
});

final googleCurrentUserProvider = StreamProvider<GoogleSignInAccount?>((ref) {
  final service = ref.watch(googleAuthProvider);
  return service.onCurrentUserChanged;
});
