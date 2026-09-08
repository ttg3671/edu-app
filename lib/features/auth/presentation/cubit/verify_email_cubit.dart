import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class VerifyEmailState {}

class VerifyEmailInitial extends VerifyEmailState {}

class VerifyEmailLoading extends VerifyEmailState {}

class VerifyEmailSentSuccess extends VerifyEmailState {
  final String message;

  VerifyEmailSentSuccess(this.message);
}

class VerifyEmailFailed extends VerifyEmailState {
  final String errorMsg;

  VerifyEmailFailed(this.errorMsg);
}

class VerifyEmailCubit extends Cubit<VerifyEmailState> {
  VerifyEmailCubit() : super(VerifyEmailInitial());

  Future<void> sendVerificationEmail(String email) async {
    if (email.trim().isEmpty) {
      emit(VerifyEmailFailed('Email cannot be empty'));
      return;
    }

    emit(VerifyEmailLoading());
    final res = await Api.instance.sendVerificationEmail(email: email.trim());

    res.fold(
      (failure) {
        emit(VerifyEmailFailed(failure.message ?? 'Failed to send verification email'));
      },
      (message) {
        emit(VerifyEmailSentSuccess(message));
      },
    );
  }
}
