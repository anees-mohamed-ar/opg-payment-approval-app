part of 'login_bloc.dart';

class LoginState extends Equatable {
  final bool isPasswordVisible;
  final bool isSubmitting;
  final bool isSuccess;
  final bool isFailure;

  const LoginState({
    required this.isPasswordVisible,
    required this.isSubmitting,
    required this.isSuccess,
    required this.isFailure,
  });

  factory LoginState.initial() {
    return LoginState(
      isPasswordVisible: false,
      isSubmitting: false,
      isSuccess: false,
      isFailure: false,
    );
  }

  LoginState update({
    bool? isPasswordVisible,
    bool? isSubmitting,
    bool? isSuccess,
    bool? isFailure,
  }) {
    return LoginState(
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      isFailure: isFailure ?? this.isFailure,
    );
  }

  @override
  List<Object> get props =>
      [isPasswordVisible, isSubmitting, isSuccess, isFailure];
}

class LoginSuccess extends LoginState {
  LoginSuccess()
      : super(
          isPasswordVisible: false,
          isSubmitting: false,
          isSuccess: true,
          isFailure: false,
        );
}

class LoginFailure extends LoginState {
  final String error;

  LoginFailure(this.error)
      : super(
            isPasswordVisible: false,
            isSubmitting: false,
            isSuccess: false,
            isFailure: true);
}

class LoginLoading extends LoginState {
  LoginLoading()
      : super(
            isPasswordVisible: false,
            isSubmitting: true,
            isSuccess: false,
            isFailure: false);
}
