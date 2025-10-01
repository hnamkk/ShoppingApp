import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RegisterController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<String?> register(String email, String password) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user?.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return 'Email đã được sử dụng.';
      } else if (e.code == 'weak-password') {
        return 'Mật khẩu quá yếu.';
      } else if (e.code == 'invalid-email') {
        return 'Email không hợp lệ.';
      } else {
        return 'Đã xảy ra lỗi. Vui lòng thử lại: ${e.message}';
      }
    } catch (e) {
      return 'Đã xảy ra lỗi. Vui lòng thử lại: ${e.toString()}';
    }
  }

  Future<String> registerWithGoogle() async {
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
      return userCredential.user?.uid ?? "";

    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');

      if (e.code == 'account-exists-with-different-credential') {
        return 'Tài khoản đã tồn tại với phương thức đăng nhập khác.';
      } else if (e.code == 'invalid-credential') {
        return 'Thông tin xác thực không hợp lệ.';
      } else if (e.code == 'operation-not-allowed') {
        return 'Đăng nhập bằng Google chưa được kích hoạt.';
      } else if (e.code == 'user-disabled') {
        return 'Tài khoản này đã bị vô hiệu hóa.';
      } else {
        return 'Lỗi Firebase: ${e.message ?? "Không xác định"}';
      }
    } on Exception catch (e) {
      print('Google Sign In Error: ${e.toString()}');
      if (e.toString().contains('SIGN_IN_FAILED')) {
        return 'Đăng nhập Google thất bại. Vui lòng thử lại.';
      } else if (e.toString().contains('NETWORK_ERROR')) {
        return 'Lỗi kết nối mạng. Vui lòng kiểm tra Internet.';
      } else if (e.toString().contains('SIGN_IN_CANCELLED')) {
        return "";
      } else {
        return 'Lỗi đăng nhập Google: ${e.toString()}';
      }
    } catch (e) {
      print('Unexpected error: ${e.toString()}');
      return 'Đã xảy ra lỗi không mong muốn. Vui lòng thử lại.';
    }
  }

  Future<bool> isEmailRegistered(String email) async {
    try {
      final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
      return signInMethods.isNotEmpty;
    } catch (e) {
      print('Error checking email: $e');
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      return true;
    } catch (e) {
      print('Logout error: $e');
      try {
        await _auth.signOut();
      } catch (_) {}
      return false;
    }
  }
}