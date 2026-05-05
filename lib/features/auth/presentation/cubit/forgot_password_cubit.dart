import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit() : super(ForgotPasswordInitial());

  Future<void> sendOtp(String email) async {
    if (email.trim().isEmpty) {
      emit(ForgotPasswordFailed('Email cannot be empty'));
      return;
    }

    emit(ForgotPasswordLoading());
    final res = await Api.instance.sendOtp(email: email);

    res.fold(
      (failure) {
        String errorMsg = failure.message ?? 'Failed to send OTP';
        emit(ForgotPasswordFailed(errorMsg));
      },
      (token) {
        emit(ForgotPasswordOtpSent(token));
      },
    );
  }

  Future<void> verifyOtp(String otp) async {
    if (otp.trim().isEmpty) {
      emit(ForgotPasswordFailed('OTP cannot be empty'));
      return;
    }

    emit(ForgotPasswordLoading());
    final res = await Api.instance.verifyOtp(otp: otp);

    res.fold(
      (failure) {
        String errorMsg = failure.message ?? 'Invalid OTP';
        emit(ForgotPasswordFailed(errorMsg));
      },
      (success) {
        emit(ForgotPasswordSuccess());
      },
    );
  }
}

abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordOtpSent extends ForgotPasswordState {
  final String otpToken;

  ForgotPasswordOtpSent(this.otpToken);
}

class ForgotPasswordSuccess extends ForgotPasswordState {}

class ForgotPasswordFailed extends ForgotPasswordState {
  final String errorMsg;

  ForgotPasswordFailed(this.errorMsg);
}
