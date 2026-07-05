abstract class AuthState {}

// 1. الحالة الافتراضية أول ما الشاشة تفتح
class AuthInitial extends AuthState {}

// 2. لما اليوزر يدوس على الزرار والريكويست يروح للباك إيند
class AuthLoading extends AuthState {}

// 3. لما الباك إيند يرد بنجاح 200/201
class AuthSuccess extends AuthState {
  final String message;
  AuthSuccess({required this.message});
}

// 4. لو الباك إيند رجع إيرور 400/401/409
class AuthError extends AuthState {
  final String error;
  AuthError({required this.error});
}
class SportsLoaded extends AuthState {
  final List<dynamic> sports;
  
  SportsLoaded({required this.sports});
}