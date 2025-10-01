import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'Không tìm thấy người dùng cho email đó.';
      } else if (e.code == 'wrong-password') {
        return 'Mật khẩu cung cấp không chính xác.';
      } else if (e.code == 'invalid-credential') {
        return 'Thông tin đăng nhập không hợp lệ hoặc đã hết hạn.';
      } else {
        return 'Đã xảy ra lỗi. Vui lòng thử lại: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại: ${e.toString()}';
    }
  }

  Future<String> loginWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return "";
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      String uid = userCredential.user!.uid;
      return uid;
    } catch (e) {
      print('Lỗi đăng nhập: ${e.toString()}');
      return '';
    }
  }

  // ✅ LOGOUT với DEBUG LOG
  Future<bool> logout() async {
    print('🟢 LoginController: logout() called');

    try {
      print('🟢 LoginController: Signing out from Google...');
      await _googleSignIn.signOut();
      print('🟢 LoginController: Google sign out SUCCESS');

      print('🟢 LoginController: Signing out from Firebase...');
      await _auth.signOut();
      print('🟢 LoginController: Firebase sign out SUCCESS');

      // Verify logout
      final user = _auth.currentUser;
      print('🟢 LoginController: Current user after logout: ${user?.email ?? "NULL"}');

      return true;
    } catch (e, stackTrace) {
      print('🔴 LoginController ERROR: $e');
      print('🔴 LoginController STACKTRACE: $stackTrace');

      // Vẫn cố gắng đăng xuất Firebase nếu Google fail
      try {
        print('🟡 LoginController: Attempting Firebase signout as fallback...');
        await _auth.signOut();
        print('🟡 LoginController: Fallback Firebase signout SUCCESS');
      } catch (e2) {
        print('🔴 LoginController: Fallback also failed: $e2');
      }

      return false;
    }
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    User? user = _auth.currentUser;

    if (user == null) {
      return 'No user is currently signed in.';
    }

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return 'Mật khẩu đã được cập nhật thành công.';
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      return 'An error occurred: ${e.toString()}';
    }
  }

  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return 'Password reset email has been sent.';
    } on FirebaseAuthException catch (e) {
      return 'Error: ${e.message}';
    } catch (e) {
      return 'An error occurred: ${e.toString()}';
    }
  }
}