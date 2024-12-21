import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  get currentUser => null;

  // Đăng ký người dùng mới
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String confirmPassword) async {
    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ thông tin!');
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      throw Exception('Định dạng email không hợp lệ!');
    }
    if (password.length < 6) {
      throw Exception('Mật khẩu phải có ít nhất 6 ký tự!');
    }
    if (password != confirmPassword) {
      throw Exception('Mật khẩu xác nhận không khớp!');
    }
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Email này đã được đăng ký.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email không hợp lệ.');
      } else if (e.code == 'weak-password') {
        throw Exception('Mật khẩu quá yếu.');
      } else {
        throw Exception('Đăng ký thất bại: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi không xác định: ${e.toString()}');
    }
  }

  // Đăng nhập người dùng hiện có
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Vui lòng nhập đầy đủ thông tin!');
    }
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return result.user;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('Email này chưa được đăng ký.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Sai Email hoặc mật khẩu.');
      } else if (e.code == 'invalid-email') {
        throw Exception('Email không hợp lệ.');
      } else {
        throw Exception('Đăng nhập thất bại: ${e.message}');
      }
    } catch (e) {
      throw Exception('Lỗi không xác định: ${e.toString()}');
    }
  }
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.isEmpty) {
      throw Exception('Vui lòng nhập email của bạn!');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception('Lỗi gửi email đặt lại mật khẩu: ${e.message}');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  bool isUserSignedIn() {
    return _auth.currentUser != null;
  }
}
