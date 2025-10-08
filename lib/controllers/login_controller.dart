import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';

class LoginController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> login(
      String email, String password, BuildContext context) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null && context.mounted) {
        final cartService = Provider.of<CartService>(context, listen: false);
        await cartService.initialize();
      }

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

      if (userCredential.user != null && context.mounted) {
        final cartService = Provider.of<CartService>(context, listen: false);
        await cartService.initialize();
      }

      String uid = userCredential.user!.uid;
      return uid;
    } catch (e) {
      print('Lỗi đăng nhập: ${e.toString()}');
      return '';
    }
  }

  Future<bool> logout(BuildContext context) async {
    try {
      if (context.mounted) {
        final cartService = Provider.of<CartService>(context, listen: false);
        cartService.reset();
      }

      await _googleSignIn.signOut();
      await _auth.signOut();
      return true;
    } catch (e) {
      try {
        await _auth.signOut();
      } catch (e2) {
        print('LoginController: Fallback also failed: $e2');
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
