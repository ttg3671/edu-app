import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/welcome.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../core/utils/custom_snackbar.dart';
import '../widgets/auth_textfields.dart';
import '../../../../l10n/app_localizations.dart';

class Profile extends StatefulWidget {
  final String? email, password;
  final UserDetails? userDetails;
  const Profile({super.key, this.email, this.password, this.userDetails});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _avatarUrl;
  bool _isUploadingImage = false;
  String? gender;

  @override
  void initState() {
    super.initState();
    final user = TokenApi.user ?? widget.userDetails;
    if (user != null) {
      _nameController.text = user.name ?? '';
      _bioController.text = user.bio ?? '';
      _avatarUrl = user.avatarUrl;
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  localizations?.translate('choose_profile_photo') ?? 'Choose Profile Photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                SizedBox(height: 20.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final xFile = await picker.pickImage(
                          source: ImageSource.camera,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (xFile != null) {
                          _uploadImage(xFile.path);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.camera_alt, color: AppColor.primary, size: 30.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(localizations?.translate('camera') ?? 'Camera'),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () async {
                        Navigator.pop(ctx);
                        final xFile = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1024,
                          maxHeight: 1024,
                          imageQuality: 85,
                        );
                        if (xFile != null) {
                          _uploadImage(xFile.path);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: AppColor.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.photo_library, color: AppColor.primary, size: 30.sp),
                          ),
                          SizedBox(height: 8.h),
                          Text(localizations?.translate('gallery') ?? 'Gallery'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadImage(String filePath) async {
    setState(() {
      _isUploadingImage = true;
    });

    final result = await Api.instance.uploadImageToCloudinary(filePath);

    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isUploadingImage = false;
        });
        CustomSnackBar.show(context: context, message: failure.message ?? 'Failed to upload image');
      },
      (imageUrl) {
        setState(() {
          _avatarUrl = imageUrl;
          _isUploadingImage = false;
        });
        CustomSnackBar.show(
          context: context,
          message: AppLocalizations.of(context)?.translate('image_uploaded_successfully') ?? 'Image uploaded successfully',
          color: Colors.green,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (context) => AuthCubit(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations?.profile ?? 'Profile'),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: widget.userDetails != null ? IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ) : null,
          actions: [
            if (widget.userDetails == null)
              TextButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => const MyHomePage()),
                    (Route<dynamic> route) => false
                  );
                },
                child: Text(
                  localizations?.translate('skip') ?? 'Skip',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: Lottie.asset('assets/animation/workout.json',
                      height: 250.h
                  ),
                ),
                SizedBox(height: 20.h,),
                Text(localizations?.translate('lets_complete_profile') ?? 'Let\'s complete your profile',
                  style: textTheme.titleMedium?.copyWith(
                      fontSize: 21.sp
                  ),
                ),
                SizedBox(height: 5.h,),
                Text(localizations?.translate('help_know_more') ?? 'It will help us to know more about you!',
                  style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp
                  ),
                ),
                SizedBox(height: 30.h,),

                // Error message container
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthFailed && state.errorMsg.isNotEmpty) {
                        return Container(
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
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickAndUploadImage,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 100.h,
                              width: 100.w,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.primary,
                              ),
                              child: ClipOval(
                                child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: Api.getFullImageUrl(_avatarUrl),
                                        fit: BoxFit.cover,
                                        width: 100.w,
                                        height: 100.h,
                                        placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator(color: AppColor.background, strokeWidth: 2),
                                        ),
                                        errorWidget: (context, url, error) => ValueListenableBuilder<TextEditingValue>(
                                          valueListenable: _nameController,
                                          builder: (context, value, _) {
                                            final name = value.text.trim();
                                            return Center(
                                              child: Text(
                                                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                                style: TextStyle(
                                                  fontSize: 40.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColor.background,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : ValueListenableBuilder<TextEditingValue>(
                                        valueListenable: _nameController,
                                        builder: (context, value, _) {
                                          final name = value.text.trim();
                                          return Center(
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                                              style: TextStyle(
                                                fontSize: 40.sp,
                                                fontWeight: FontWeight.bold,
                                                color: AppColor.background,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                            ),
                            if (_isUploadingImage)
                              Container(
                                height: 100.h,
                                width: 100.w,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(alpha: 0.5),
                                ),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.all(6.r),
                                decoration: BoxDecoration(
                                  color: AppColor.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.camera_alt,
                                  color: AppColor.background,
                                  size: 16.sp,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h,),
                      AuthTextFields(
                        text: localizations?.name ?? 'Name',
                        textEditingController: _nameController,
                        keyboardType: TextInputType.text,
                        prefixIcon: SvgConstant.profile,
                      ),
                      SizedBox(height: 20.h,),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: TextField(
                          controller: _bioController,
                          keyboardType: TextInputType.multiline,
                          maxLines: 4,
                          maxLength: 200,
                          decoration: InputDecoration(
                            hintText: localizations?.translate('bio_optional') ?? 'Bio (Optional)',
                            hintStyle: textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            counterStyle: textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          ),
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
            child: BlocConsumer<AuthCubit, AuthState>(
              builder: (BuildContext context, AuthState state) {
                return AuthBtn(
                  text: widget.userDetails != null ? (localizations?.update ?? 'Update') : (localizations?.next ?? 'Next'),
                  isLoading: state is AuthLoading,
                  width: double.infinity,
                  onTap: () async {
                    FocusManager.instance.primaryFocus?.unfocus();

                    // Validation
                    if (_nameController.text.trim().isEmpty) {
                      CustomSnackBar.show(context: context, message: localizations?.translate('enter_name') ?? 'Please enter your name');
                      return;
                    }

                    if (TokenApi.isUserLoggedIn()) {
                      // User is updating their profile
                      context.read<AuthCubit>().updateProfile(
                        fullName: _nameController.text.trim(),
                        bio: _bioController.text.trim(),
                        avatarUrl: _avatarUrl,
                      );
                    } else {
                      // Profile setup - just navigate to welcome screen
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (builder) => Welcome(
                          name: _nameController.text.isEmpty ? 'User' : _nameController.text,
                        )),
                        (Route<dynamic> route) => false
                      );
                    }
                  },
                );
              },
              listener: (BuildContext context, AuthState state) {
                if (state is AuthSuccess) {
                  if (widget.userDetails != null) {
                    CustomSnackBar.show(context: context, message: localizations?.translate('profile_updated') ?? 'Profile updated successfully');
                    context.read<AccountCubit>().getAccountDetails();
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (builder) => Welcome(
                      name: _nameController.text,
                    )),
                    (Route<dynamic> route) => false);
                  }
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
