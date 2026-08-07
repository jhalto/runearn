import 'package:equatable/equatable.dart';

class LoginCredentialEntity extends Equatable {
  final String email;
  final String password;

  const LoginCredentialEntity({required this.email,required this.password});

  @override
  List<Object?> get props => [email, password];
}
