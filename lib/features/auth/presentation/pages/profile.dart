import 'dart:io';

import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/welcome.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/profile_dropdown.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/custom_snackbar.dart';
import '../cubit/image_cubit.dart';
import '../widgets/auth_textfields.dart';
import '../../../../l10n/app_localizations.dart';

class Profile extends StatefulWidget {
  final String? email,password;
  final UserDetails? userDetails;
  const Profile({super.key, this.email, this.password,this.userDetails});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? gender;

  @override
  Widget build(BuildContext context) {
    final textTheme= Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    UserDetails? userDetails=widget.userDetails;

    String profileImg='';
    if(userDetails!=null && userDetails.image!=null && userDetails.image!.isNotEmpty){
      profileImg = userDetails.image!;
    }
    
    // Only set initial text if they are empty to avoid resetting while typing
    if (_nameController.text.isEmpty && userDetails != null) {
      _nameController.text = userDetails.name ?? '';
    }
    if (_bioController.text.isEmpty && userDetails != null) {
      _bioController.text = userDetails.bio ?? '';
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create)=>ImageCubit()),
        BlocProvider(create: (create)=>AuthCubit()),
      ],
      child: Scaffold(
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Stack(
              children: [
                Positioned.fill(
                  left: 20.w,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: SafeArea(
                        child: InkWell(
                            onTap: (){
                              Navigator.pop(context);
                            },
                            child: Icon(Icons.arrow_back_ios,size: 24.sp,))
                    ),
                  ),
                ),
                if(widget.userDetails == null)
                  Positioned.fill(
                    right: 20.w,
                    child: Align(
                      alignment: Alignment.topRight,
                      child: SafeArea(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(builder: (builder) => MyHomePage()),
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
                      ),
                    ),
                  ),
                Column(
                  children: [
                    Center(
                      child: Lottie.asset('assets/animation/workout.json',
                          height: 300.h
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        spacing: 20.h,
                        children: [
                          Text(
                            localizations?.translate('profile_picture_optional') ?? 'Profile Picture (Optional)',
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          BlocBuilder<ImageCubit,ImageState>(
                            builder: (context,state){
                              bool isOnline=userDetails!=null && userDetails.image!=null && userDetails.image!.isNotEmpty;
                              String displayImg = profileImg;

                              if(state is ImageLoaded){
                                displayImg=state.path;
                                isOnline=state.isOnline;
                              }

                              return InkWell(
                                onTap: context.read<ImageCubit>().pickImage,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 100.h,
                                      width: 100.w,
                                      decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade200,
                                          image: DecorationImage(
                                              image: displayImg.isNotEmpty?
                                              (isOnline?
                                              Image.network(displayImg).image
                                                  :
                                              Image.file(File(displayImg)).image)
                                                  :
                                              Image.asset('assets/images/person.png').image,
                                              fit: displayImg.isNotEmpty? BoxFit.cover: BoxFit.contain
                                          )
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: Align(
                                          alignment: Alignment.topRight,
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                                color: Colors.black,
                                                shape: BoxShape.circle
                                            ),
                                            child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    shape: BoxShape.circle
                                                ),
                                                child: const Icon(Icons.edit,color: Colors.black,size: 18,)),
                                          )),
                                    ),
                                    Positioned.fill(
                                        child: Align(
                                          alignment: Alignment.center,
                                          child: state is ImageLoading ? const CircularProgressIndicator(color: Colors.black,):
                                          Container(),
                                        )
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                          AuthTextFields(
                            text: localizations?.name ?? 'Name',
                            textEditingController: _nameController,
                            keyboardType: TextInputType.text,
                            prefixIcon: SvgConstant.profile,
                          ),
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
                      // Get the current image from ImageCubit state
                      String? imageToUpload;
                      final imageState = context.read<ImageCubit>().state;
                      if (imageState is ImageLoaded && imageState.path.isNotEmpty) {
                        imageToUpload = imageState.path;
                      } else if (userDetails?.image != null && userDetails!.image!.isNotEmpty) {
                        imageToUpload = userDetails.image;
                      }

                      // User is updating their profile
                      context.read<AuthCubit>().updateProfile(
                        fullName: _nameController.text.trim(),
                        profileImage: imageToUpload,
                        bio: _bioController.text.trim(),
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
                    Navigator.pop(context);
                  } else {
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (builder) => Welcome(
                      name: _nameController.text,
                    )),
                    (Route<dynamic> route) => false);
                  }
                } else if (state is AuthFailed) {
                  CustomSnackBar.show(context: context, message: state.errorMsg);
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
