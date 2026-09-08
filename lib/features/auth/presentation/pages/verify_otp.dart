import 'dart:async';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/email_verified.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/auth/presentation/pages/reset_password.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerifyOtp extends StatefulWidget {
  final String email;
  final bool isEmailVerification;

  const VerifyOtp({
    super.key,
    required this.email,
    this.isEmailVerification = false,
  });

  @override
  State<VerifyOtp> createState() => _VerifyOtpState();
}

class _VerifyOtpState extends State<VerifyOtp> {
  late final ForgotPasswordCubit _forgotPasswordCubit;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _focusNodes;
  Timer? _timer;
  int _remainingSeconds = 300; // 5 minutes timer
  bool _isAutoSubmitting = false;

  @override
  void initState() {
    super.initState();
    _forgotPasswordCubit = ForgotPasswordCubit();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        setState(() {});
      });
    }

    _startTimer();

    // Auto-focus first box
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _focusNodes.isNotEmpty) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = 300;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_remainingSeconds > 0) {
          setState(() {
            _remainingSeconds--;
          });
        } else {
          timer.cancel();
        }
      }
    });
  }

  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    final user = parts[0];
    final domain = parts[1];

    if (user.length <= 2) {
      return '${user[0]}***@$domain';
    } else {
      return '${user[0]}***${user[user.length - 1]}@$domain';
    }
  }

  void _onOtpChanged(int index, String value) {
    if (value.length > 1) {
      // Handle multi-digit paste
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < 6 && i < digits.length; i++) {
        _otpControllers[i].text = digits[i];
      }
      final targetIndex = digits.length >= 6 ? 5 : digits.length;
      if (targetIndex < 6) {
        _focusNodes[targetIndex].requestFocus();
      } else {
        _focusNodes[5].unfocus();
      }
      _checkAndAutoSubmit();
      return;
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
      _checkAndAutoSubmit();
    }
  }

  void _checkAndAutoSubmit() {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    if (otp.length == 6 && !_isAutoSubmitting) {
      _submitOtp();
    }
  }

  void _submitOtp() {
    final otp = _otpControllers.map((c) => c.text.trim()).join();
    final localizations = AppLocalizations.of(context);

    if (otp.length < 6) {
      CustomSnackBar.show(
        context: context,
        message: localizations?.pleaseEnterCompleteOtp ??
            'Please enter the complete 6-digit OTP',
      );
      return;
    }

    setState(() {
      _isAutoSubmitting = true;
    });

    FocusManager.instance.primaryFocus?.unfocus();
    _forgotPasswordCubit.verifyOtp(otp);
  }

  void _resendOtp() {
    if (_remainingSeconds == 0) {
      _forgotPasswordCubit.sendOtp(widget.email);
      for (final controller in _otpControllers) {
        controller.clear();
      }
      _startTimer();
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return BlocProvider.value(
      value: _forgotPasswordCubit,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
              listener: (BuildContext context, ForgotPasswordState state) {
                if (state is ForgotPasswordFailed) {
                  setState(() {
                    _isAutoSubmitting = false;
                  });
                } else if (state is ForgotPasswordOtpSent) {
                  CustomSnackBar.show(
                    context: context,
                    message: localizations?.otpSentToEmail ??
                        'OTP sent to your email',
                  );
                } else if (state is ForgotPasswordSuccess) {
                  CustomSnackBar.show(
                    context: context,
                    message: localizations?.otpVerifiedSuccess ??
                        'OTP verified successfully',
                  );
                  if (widget.isEmailVerification) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmailVerified(),
                      ),
                    );
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResetPassword(),
                      ),
                    );
                  }
                }
              },
              builder: (BuildContext context, ForgotPasswordState state) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      // Heading: VERIFY OTP
                      Text(
                        localizations?.verifyOtpHeading ?? 'VERIFY OTP',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 8.h),

                      // Below heading: 6-DIGIT VERIFICATION CODE
                      Text(
                        localizations?.sixDigitCodeSubheading ??
                            '6-DIGIT VERIFICATION CODE',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Sent to email (masked) with edit icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${localizations?.sentTo ?? 'Sent to'} ${_maskEmail(widget.email)}',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColor.text,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: EdgeInsets.all(5.r),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 16.sp,
                                color: AppColor.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Email successfully sent badge
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 14.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 16.sp,
                              color: Colors.green.shade700,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              localizations?.emailSuccessfullySent ??
                                  'Email successfully sent',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // Error message container
                      if (state is ForgotPasswordFailed) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.r),
                          margin: EdgeInsets.only(bottom: 20.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red, width: 1.5),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            state.errorMsg,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // ENTER 6-DIGIT OTP
                      Text(
                        localizations?.enterSixDigitOtp ?? 'ENTER 6-DIGIT OTP',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // 6-digit OTP input boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          final isFocused = _focusNodes[index].hasFocus;
                          final hasValue =
                              _otpControllers[index].text.isNotEmpty;

                          return Container(
                            width: 46.w,
                            height: 54.h,
                            margin: EdgeInsets.symmetric(horizontal: 4.w),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: isFocused
                                    ? AppColor.primary
                                    : (hasValue
                                        ? AppColor.text
                                        : Colors.grey.shade300),
                                width: isFocused ? 2.0 : 1.5,
                              ),
                            ),
                            child: Center(
                              child: KeyboardListener(
                                focusNode: FocusNode(),
                                onKeyEvent: (event) {
                                  if (event is KeyDownEvent &&
                                      event.logicalKey ==
                                          LogicalKeyboardKey.backspace) {
                                    if (_otpControllers[index].text.isEmpty &&
                                        index > 0) {
                                      _otpControllers[index - 1].clear();
                                      _focusNodes[index - 1].requestFocus();
                                    }
                                  }
                                },
                                child: TextField(
                                  controller: _otpControllers[index],
                                  focusNode: _focusNodes[index],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  maxLength: index == 0 ? 6 : 1,
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.text,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    counterText: '',
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (value) =>
                                      _onOtpChanged(index, value),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      SizedBox(height: 35.h),

                      // VERIFY OTP button
                      AuthBtn(
                        text: localizations?.verifyOtpButton ?? 'VERIFY OTP',
                        isLoading: state is ForgotPasswordLoading,
                        width: double.infinity,
                        bgColor: AppColor.primary,
                        textColor: AppColor.background,
                        onTap: _submitOtp,
                      ),
                      SizedBox(height: 20.h),

                      // Bottom Row: Left side timer / resend, Right side back to login
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: Resend OTP timer (5 min) / Resend button
                            if (_remainingSeconds > 0)
                              Text(
                                localizations?.resendOtpIn(_formattedTime) ??
                                    'Resend OTP in $_formattedTime',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            else
                              InkWell(
                                onTap: _resendOtp,
                                child: Text(
                                  localizations?.resendOtp ?? 'Resend OTP',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),

                            // Right side: Back to Login button
                            InkWell(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const Login(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 16.sp,
                                    color: AppColor.text,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    localizations?.backToLogin ??
                                        'Back to Login',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColor.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 25.h),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _forgotPasswordCubit.close();
    super.dispose();
  }
}
