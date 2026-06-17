import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/exception.dart';
import '../../../../domain/auth/models/app_user.dart';
import '../../dtos/app_user_dto.dart';
import '../local/auth_prefutils.dart';

/// Firebase-backed auth + user-profile data source.
/// Keeps the same role as the example's remote data source, but talks to
/// Firebase Auth + Cloud Firestore instead of a REST API.
@injectable
class AuthRemoteDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final AuthPrefUtils prefUtils;

  AuthRemoteDataSource({
    required this.firebaseAuth,
    required this.firestore,
    required this.prefUtils,
  });

  CollectionReference<Map<String, dynamic>> get _users =>
      firestore.collection('users');

  Future<AppUser?> currentUser() async {
    final user = firebaseAuth.currentUser;
    if (user == null) return null;
    return _loadProfile(user.uid, fallbackEmail: user.email ?? '');
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required Gender gender,
    UserRole? role,
  }) async {
    try {
      final cred = await firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = cred.user!.uid;
      final appUser = AppUser(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone,
        gender: gender,
        role: role,
      );
      await _users.doc(uid).set(AppUserDto.toMap(appUser));
      await cred.user!.updateDisplayName(name.trim());
      _cache(appUser);
      return appUser;
    } on FirebaseAuthException catch (e) {
      throw BadRequestException(message: _authMessage(e));
    }
  }

  Future<AppUser> login(String email, String password) async {
    try {
      final cred = await firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return _loadProfile(cred.user!.uid, fallbackEmail: email.trim());
    } on FirebaseAuthException catch (e) {
      throw BadRequestException(message: _authMessage(e));
    }
  }

  Future<String> sendPhoneOtp(String phoneNumber) async {
    final completer = Completer<String>();
    await firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber.trim(),
      verificationCompleted: (_) {},
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.completeError(BadRequestException(message: _authMessage(e)));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (_) {},
    );
    return completer.future;
  }

  Future<AppUser> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final cred = await firebaseAuth.signInWithCredential(credential);
      final uid = cred.user!.uid;
      // First phone sign-in may have no profile doc yet — create a stub.
      final existing = await _users.doc(uid).get();
      if (!existing.exists) {
        final stub = AppUser(
          uid: uid,
          name: cred.user!.displayName ?? '',
          email: cred.user!.email ?? '',
          phone: cred.user!.phoneNumber,
        );
        await _users.doc(uid).set(AppUserDto.toMap(stub));
        _cache(stub);
        return stub;
      }
      return _loadProfile(uid, fallbackEmail: cred.user!.email ?? '');
    } on FirebaseAuthException catch (e) {
      throw BadRequestException(message: _authMessage(e));
    }
  }

  Future<void> setRole(UserRole role) async {
    final user = firebaseAuth.currentUser;
    if (user == null) throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    await _users.doc(user.uid).update({'role': role.name});
    prefUtils.setRole(role.name);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = firebaseAuth.currentUser;
    if (user == null || user.email == null) {
      throw UnauthorizedException(message: 'لا يوجد مستخدم مسجّل');
    }
    try {
      // Re-authenticate to prove identity before changing the password (US-37).
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw BadRequestException(message: _authMessage(e));
    }
  }

  Future<void> logout() async {
    await firebaseAuth.signOut();
    prefUtils.clear();
  }

  // --- helpers ---

  Future<AppUser> _loadProfile(String uid, {required String fallbackEmail}) async {
    final doc = await _users.doc(uid).get();
    final user = doc.exists
        ? AppUserDto.fromMap(uid, doc.data()!)
        : AppUser(uid: uid, name: '', email: fallbackEmail);
    _cache(user);
    return user;
  }

  void _cache(AppUser user) {
    prefUtils
      ..setUid(user.uid)
      ..setRole(user.role?.name)
      ..setGender(user.gender?.name);
  }

  String _authMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'بيانات الدخول غير صحيحة';
      case 'email-already-in-use':
        return 'البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'requires-recent-login':
        return 'يلزم تسجيل الدخول من جديد لإتمام العملية';
      default:
        return e.message ?? 'حدث خطأ غير متوقع';
    }
  }
}
