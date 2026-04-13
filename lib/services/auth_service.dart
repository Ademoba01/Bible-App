import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─── Auth State ─────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final User? user;
  final UserProfile? profile;
  final String? error;

  const AuthState({
    this.status = AuthStatus.loading,
    this.user,
    this.profile,
    this.error,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    UserProfile? profile,
    String? error,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        profile: profile ?? this.profile,
        error: error,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

// ─── User Profile ───────────────────────────────────────────────

class UserProfile {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final DateTime createdAt;
  final String role; // 'user' or 'admin'
  final Map<String, dynamic> preferences;

  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    required this.createdAt,
    this.role = 'user',
    this.preferences = const {},
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserProfile(
      uid: uid,
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      role: data['role'] ?? 'user',
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'role': role,
        'preferences': preferences,
      };

  bool get isAdmin => role == 'admin';
}

// ─── Auth Notifier ──────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  void _init() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        final profile = await _loadProfile(user.uid);
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          profile: profile,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    });
  }

  Future<UserProfile?> _loadProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc.data()!, uid);
      }
    } catch (_) {}
    return null;
  }

  Future<void> _createProfile(User user, String displayName) async {
    final profile = UserProfile(
      uid: user.uid,
      displayName: displayName,
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );
    await _firestore.collection('users').doc(user.uid).set(profile.toFirestore());
    state = state.copyWith(profile: profile);
  }

  // ── Sign Up ──

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      state = state.copyWith(error: null);
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName(displayName);
      if (cred.user != null) {
        await _createProfile(cred.user!, displayName);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _friendlyError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Sign In ──

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = state.copyWith(error: null);
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _friendlyError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Password Reset ──

  Future<bool> resetPassword(String email) async {
    try {
      state = state.copyWith(error: null);
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _friendlyError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  // ── Sign Out ──

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ── Update Profile ──

  Future<void> updateProfile({String? displayName}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    if (displayName != null) {
      await user.updateDisplayName(displayName);
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });
      final profile = await _loadProfile(user.uid);
      state = state.copyWith(profile: profile);
    }
  }

  void clearError() => state = state.copyWith(error: null);

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// ─── Providers ──────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
