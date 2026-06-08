import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _emailKey = 'pendingSignInEmail';

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Whether a user is currently signed in.
  bool get isSignedIn => currentUser != null;

  /// Send a passwordless sign-in link to the given email.
  Future<void> sendSignInLink(String email) async {
    final actionCodeSettings = ActionCodeSettings(
      // Use an authorized Firebase hosting domain for the continue URL.
      url: 'https://matroh-7aac9.firebaseapp.com/finishSignIn',
      handleCodeInApp: true,
      androidPackageName: 'com.example.matroh',
      androidInstallApp: true,
      androidMinimumVersion: '23',
      iOSBundleId: 'com.example.matroh',
    );

    await _auth.sendSignInLinkToEmail(
      email: email,
      actionCodeSettings: actionCodeSettings,
    );

    // Store email locally so we can use it when the link is clicked.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_emailKey, email);
  }

  /// Retrieve the stored email for pending sign-in.
  Future<String?> getPendingEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  /// Complete sign-in with the email link.
  Future<UserCredential> signInWithEmailLink(String emailLink) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_emailKey);

    if (email == null) {
      throw Exception('No pending email found. Please request a new sign-in link.');
    }

    if (!_auth.isSignInWithEmailLink(emailLink)) {
      throw Exception('Invalid sign-in link.');
    }

    final credential = await _auth.signInWithEmailLink(
      email: email,
      emailLink: emailLink,
    );

    // Clear stored email after successful sign-in.
    await prefs.remove(_emailKey);

    // Create or update the user document in Firestore.
    await _ensureUserDocument(credential.user!);

    return credential;
  }

  /// Sign in with Google using Firebase Authentication.
  Future<UserCredential> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(userCredential.user!);
    return userCredential;
  }

  /// Check if a link is a valid sign-in link.
  bool isSignInLink(String link) {
    return _auth.isSignInWithEmailLink(link);
  }

  /// Ensure the user has a Firestore document. Creates one if it's their first time.
  Future<void> _ensureUserDocument(User user) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // First-time user — create document with default values.
      // Name will be updated on the verify screen.
      final newUser = AppUser(
        uid: user.uid,
        name: '',
        email: user.email ?? '',
        role: 'member',
      );
      await docRef.set(newUser.toFirestore());
    }
  }

  /// Update the user's display name (for first-time setup).
  Future<void> updateUserName(String name) async {
    final user = currentUser;
    if (user == null) return;

    final firestoreService = FirestoreService();

    await Future.wait([
      _firestore.collection('users').doc(user.uid).update({'name': name}),
      user.updateDisplayName(name),
    ]);

    await firestoreService.updateUserNameAcrossVacations(user.uid, name);
  }

  /// Get the current user's Firestore document.
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromFirestore(doc);
  }

  /// Stream of the current user's Firestore document.
  Stream<AppUser?> currentAppUserStream() {
    final user = currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) => doc.exists ? AppUser.fromFirestore(doc) : null);
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
