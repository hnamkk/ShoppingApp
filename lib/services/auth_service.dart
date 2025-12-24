import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng nhập bằng Email & Password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'uid': userCredential.user?.uid};
    } on FirebaseAuthException catch (e) {
      String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      if (e.code == 'user-not-found') {
        message = 'Không tìm thấy người dùng cho email đó.';
      } else if (e.code == 'wrong-password') {
        message = 'Mật khẩu cung cấp không chính xác.';
      } else if (e.code == 'invalid-credential') {
        message = 'Thông tin đăng nhập không hợp lệ hoặc đã hết hạn.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Đăng ký tài khoản mới
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return {'success': true, 'uid': userCredential.user?.uid};
    } on FirebaseAuthException catch (e) {
      String message = 'Đã xảy ra lỗi. Vui lòng thử lại.';
      if (e.code == 'email-already-in-use') {
        message = 'Email đã được sử dụng.';
      } else if (e.code == 'weak-password') {
        message = 'Mật khẩu quá yếu.';
      } else if (e.code == 'invalid-email') {
        message = 'Email không hợp lệ.';
      }
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Đăng nhập bằng Google
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return {'success': false, 'message': 'Hủy đăng nhập.'};

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      return {'success': true, 'uid': userCredential.user?.uid};
    } on FirebaseAuthException catch (e) {
      return {'success': false, 'message': e.message ?? 'Lỗi xác thực Google.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Đăng xuất
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Đặt lại mật khẩu
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {'success': true, 'message': 'Email đặt lại mật khẩu đã được gửi.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    User? user = _auth.currentUser;
    if (user == null) return {'success': false, 'message': 'Chưa đăng nhập.'};

    try {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      return {'success': true, 'message': 'Cập nhật mật khẩu thành công.'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
