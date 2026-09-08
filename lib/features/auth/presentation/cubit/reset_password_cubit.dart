import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit() : super(ResetPasswordInitial());

  Future<void> resetPassword({
    required String newPassword,
    String? confirmPassword,
  }) async {
    if (newPassword.trim().isEmpty) {
      emit(ResetPasswordFailed('Password cannot be empty'));
      return;
    }

    emit(ResetPasswordLoading());
    final res = await Api.instance.resetPassword(
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );

    res.fold(
      (failure) {
        String errorMsg = failure.message ?? 'Failed to reset password';
        emit(ResetPasswordFailed(errorMsg));
      },
      (authModel) {
        emit(ResetPasswordSuccess(
          emailVerified: authModel.emailVerified,
          email: authModel.user?.email ?? '',
        ));
      },
    );
  }
}

abstract class ResetPasswordState {}

class ResetPasswordInitial extends ResetPasswordState {}

class ResetPasswordLoading extends ResetPasswordState {}

class ResetPasswordSuccess extends ResetPasswordState {
  final bool emailVerified;
  final String email;

  ResetPasswordSuccess({this.emailVerified = true, this.email = ''});
}

class ResetPasswordFailed extends ResetPasswordState {
  final String errorMsg;

  ResetPasswordFailed(this.errorMsg);
}
