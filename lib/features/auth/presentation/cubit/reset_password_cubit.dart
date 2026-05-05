import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit() : super(ResetPasswordInitial());

  Future<void> resetPassword(String newPassword) async {
    if (newPassword.trim().isEmpty) {
      emit(ResetPasswordFailed('Password cannot be empty'));
      return;
    }

    emit(ResetPasswordLoading());
    final res = await Api.instance.resetPassword(newPassword: newPassword);

    res.fold(
      (failure) {
        String errorMsg = failure.message ?? 'Failed to reset password';
        emit(ResetPasswordFailed(errorMsg));
      },
      (success) {
        emit(ResetPasswordSuccess());
      },
    );
  }
}

abstract class ResetPasswordState {}

class ResetPasswordInitial extends ResetPasswordState {}

class ResetPasswordLoading extends ResetPasswordState {}

class ResetPasswordSuccess extends ResetPasswordState {}

class ResetPasswordFailed extends ResetPasswordState {
  final String errorMsg;

  ResetPasswordFailed(this.errorMsg);
}
