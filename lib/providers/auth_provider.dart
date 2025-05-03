import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mensa_scolastica/repositories/user_repository.dart';
import 'package:mensa_scolastica/models/user.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).currentUser;
});

final userProvider = FutureProvider<AppUser?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final userRepository = ref.watch(userRepositoryProvider);
  return await userRepository.getUser(user.uid);
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final appUser = await ref.watch(userProvider.future);
  return appUser?.role;
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final FirebaseAuth _auth;
  final UserRepository _userRepository;

  AuthNotifier(this._auth, this._userRepository)
      : super(const AsyncValue.data(null));

  // Login esistente
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Registrazione nuovo utente
  Future<void> register({
    required String email,
    required String password,
    required String displayName,
    String role = 'genitore', // Default ruolo genitore
    String? school,
  }) async {
    state = const AsyncValue.loading();
    try {
      // Crea l'utente in Firebase Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Aggiorna il displayName nel profilo utente
      await userCredential.user?.updateDisplayName(displayName);

      // Crea il documento utente in Firestore
      final newUser = AppUser(
        id: userCredential.user!.uid,
        email: email,
        role: role,
        displayName: displayName,
        school: school,
        linkedStudents: role == 'genitore' ? [] : null,
        createdAt: DateTime.now(),
      );

      await _userRepository.createUser(userCredential.user!.uid, newUser);

      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Recupera password
  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Cancella account
  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Elimina il documento utente da Firestore
        await _userRepository.deleteUser(user.uid);

        // Elimina l'utente da Firebase Authentication
        await user.delete();
      }
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Riautentica utente (necessario per operazioni sensibili come cambio password o eliminazione account)
  Future<bool> reauthenticate(String password) async {
    try {
      final user = _auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Aggiorna password
  Future<void> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  // Aggiorna profilo utente
  Future<void> updateProfile({String? displayName, String? email}) async {
    state = const AsyncValue.loading();
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (displayName != null) {
          await user.updateDisplayName(displayName);
          await _userRepository.updateUser(user.uid, {'displayName': displayName});
        }

        if (email != null && email != user.email) {
          await user.updateEmail(email);
          await _userRepository.updateUser(user.uid, {'email': email});
        }
      }
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateFcmToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _userRepository.updateFcmToken(user.uid, token);
      }
    } catch (e) {
      // Gestione degli errori
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
      (ref) => AuthNotifier(
    ref.watch(firebaseAuthProvider),
    ref.watch(userRepositoryProvider),
  ),
);