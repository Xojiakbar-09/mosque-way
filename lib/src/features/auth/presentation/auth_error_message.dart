import 'package:firebase_auth/firebase_auth.dart';

String authErrorMessage(FirebaseAuthException error) {
  switch (error.code) {
    case 'invalid-email':
      return 'Email manzilini to‘g‘ri kiriting.';
    case 'invalid-credential':
    case 'user-not-found':
    case 'wrong-password':
      return 'Email yoki parol noto‘g‘ri.';
    case 'email-already-in-use':
    case 'credential-already-in-use':
      return 'Bu email bilan akkaunt mavjud. Kirish bo‘limidan foydalaning.';
    case 'weak-password':
      return 'Parol Firebase xavfsizlik talablariga mos emas. Kuchliroq parol kiriting.';
    case 'network-request-failed':
      return 'Internet aloqasini tekshiring.';
    case 'too-many-requests':
      return 'Urinishlar ko‘payib ketdi. Birozdan keyin qayta urinib ko‘ring.';
    case 'operation-not-allowed':
      return 'Bu kirish usuli Firebase sozlamalarida yoqilmagan.';
    case 'user-disabled':
      return 'Bu akkaunt bloklangan.';
    default:
      return 'Amal bajarilmadi. Qayta urinib ko‘ring.';
  }
}
