import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/account/presentation/widgets/account_details_container.dart';
import 'package:edu_gym/features/account/presentation/widgets/account_details_shimmer.dart';
import 'package:edu_gym/features/account/presentation/screens/connected_devices_screen.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/auth/presentation/pages/register.dart';
import 'package:edu_gym/features/auth/presentation/pages/profile.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../screens/webview/show_webview.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../../cubits/language_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class Account extends StatelessWidget {
  const Account({super.key});

  @override
  Widget build(BuildContext context) {
    UserDetails? userDetails;
    final localizations = AppLocalizations.of(context);
    final bool isLoggedIn = TokenApi.isUserLoggedIn();

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show user info only if logged in
            if(!isLoggedIn)
              // Not logged in - show message and login/signup buttons
              Container(
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 60.sp,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      localizations?.translate('user_not_logged_in') ?? 'User is not logged in',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (builder) => const Login()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text(localizations?.login ?? 'Login'),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (builder) => const Register()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue,
                              side: const BorderSide(color: Colors.blue),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                            ),
                            child: Text(localizations?.signUp ?? 'Sign Up'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              // Logged in - show user details
              BlocBuilder<AccountCubit,DataState>(
                builder: (BuildContext context, DataState state) {
                  if(state is DataLoading){
                    return const AccountDetailsShimmer();
                  }
                  else if(state is DataLoadFailed){
                    // Show error message and option to retry
                    return Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations?.translate('failed_to_load_account') ?? 'Failed to load account details',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            localizations?.translate('check_connection') ?? 'Please check your connection and try again',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          SizedBox(height: 12.h),
                          ElevatedButton(
                            onPressed: () {
                              context.read<AccountCubit>().getAccountDetails();
                            },
                            child: Text(localizations?.retry ?? 'Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  else if(state is DataLoaded<UserDetails>){
                    userDetails=state.data;
                    final String displayName = (userDetails?.name != null && userDetails!.name!.isNotEmpty)
                        ? userDetails!.name!
                        : TokenApi.getUsernameFromEmail(userDetails?.email);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        (userDetails?.image != null && userDetails!.image!.isNotEmpty)?
                        Container(
                          height: 60.h,
                          width: 60.w,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: NetworkImage(userDetails!.image!),
                                  fit: BoxFit.cover
                              ),
                              shape: BoxShape.circle
                          ),
                        ):
                        Container(
                          height: 60.h,
                          width: 60.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green.shade100,
                          ),
                          child: Center(
                            child: Icon(
                              Icons.person,
                              size: 30.sp,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ),
                        SizedBox(width: 15.w,),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                              Text(userDetails?.email ?? '',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade600
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 10.w,),
                        InkWell(
                          onTap: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (builder)=>Profile(userDetails: userDetails,)));
                            // Refresh account details after returning from profile
                            context.read<AccountCubit>().getAccountDetails();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 18.w),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99.r),
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppColor.gradient1,AppColor.gradient2,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.gradient1.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Text(localizations?.edit ?? 'Edit',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontSize: 14.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ),
                        )
                      ],
                    );
                  }
                  return const SizedBox();
                },
              ),
            SizedBox(height: 20.h,),

            // Only show Account section if logged in
            if(isLoggedIn) ...[
              AccountDetailsContainer(
                  title: localizations?.account ?? 'Account',
                  list: [
                    AccountDetailsModal(icon: Icons.person_2, title: localizations?.personalDetails ?? 'Personal Details', onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (builder)=>Profile(userDetails: userDetails,)));
                      // Refresh account details after returning from profile
                      context.read<AccountCubit>().getAccountDetails();
                    }),
                    AccountDetailsModal(icon: Icons.devices, title: 'Connected Devices', onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (builder)=>const ConnectedDevicesScreen()));
                    }),
                    AccountDetailsModal(icon: Icons.subscriptions, title: localizations?.subscription ?? 'Subscription', onTap: () {
                      print('object');
                    }),
                  ]
              ),

              SizedBox(height: 25.h,),
            ],

            AccountDetailsContainer(
                title: localizations?.followUs ?? 'Follow Us',
                list: [
                  AccountDetailsModal(customIcon: Image.asset(ImgConstant.youtube,height: 24.h,width: 24.w,color: Colors.white,), title: localizations?.translate('youtube') ?? 'Youtube', onTap: () {
                    _launchURL('');
                  }),
                  AccountDetailsModal(customIcon: Image.asset(ImgConstant.instagram,height: 24.h,width: 24.w,color: Colors.white,),
                      title: localizations?.translate('instagram') ?? 'Instagram', onTap: () {
                    _launchURL('');
                  }),

                  AccountDetailsModal(customIcon: Image.asset(ImgConstant.twitter,height: 24.h,width: 24.w,color: Colors.white,),
                      title: localizations?.translate('twitter') ?? 'X', onTap: () {
                    _launchURL('');
                  }),
                ]
            ),

            SizedBox(height: 25.h,),

            AccountDetailsContainer(
                title: localizations?.other ?? 'Other',
                list: [
                  // AccountDetailsModal(icon: Icons.email, title: localizations?.contactUs ?? 'Contact Us', onTap: () {
                  //   _launchEmail(subject: '', body: '');
                  // }),
                  AccountDetailsModal(icon: Icons.verified_user, title: localizations?.privacyPolicy ?? 'Privacy Policy', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (builder)=>const ShowWebView(link: 'https://www.edugarciamovimiento.com/politica-de-privacidad')));
                  }),
                  AccountDetailsModal(icon: Icons.policy_outlined, title: localizations?.termsConditions ?? 'T&C', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (builder)=>const ShowWebView(link: 'https://www.edugarciamovimiento.com/terminos-y-condiciones')));
                  }),
                  AccountDetailsModal(icon: Icons.lock, title: localizations?.cookiePolicy ?? 'Cookie Policy', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (builder)=>const ShowWebView(link: 'https://www.edugarciamovimiento.com/politica-de-cookies')));
                  }),
                  AccountDetailsModal(icon: Icons.privacy_tip_outlined, title: localizations?.legalNotice ?? 'Legal Notice', onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (builder)=>const ShowWebView(link: 'https://www.edugarciamovimiento.com/aviso-legal-y-condiciones-generales-de-uso')));
                  }),
                  AccountDetailsModal(
                    icon: Icons.language,
                    title: localizations?.language ?? 'Language',
                    onTap: () {
                      _showLanguageDialog(context);
                    },
                  ),
                  // Only show Delete Account and Logout if logged in
                  if(isLoggedIn) ...[
                    AccountDetailsModal(
                      icon: Icons.delete_forever,
                      title: localizations?.deleteAccount ?? 'Delete Account',
                      onTap: () async {
                        // Show confirmation dialog
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: Text(localizations?.translate('delete_account_title') ?? 'Delete Account'),
                            content: Text(
                              localizations?.translate('delete_account_message') ?? 'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently deleted.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, false),
                                child: Text(localizations?.cancel ?? 'Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext, true),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                child: Text(localizations?.delete ?? 'Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmed == true && context.mounted) {
                          // Show loading indicator while deleting account
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Call delete account API
                          final result = await Api.instance.deleteAccount();

                          // Close loading indicator
                          if (context.mounted) {
                            Navigator.pop(context);

                            result.fold(
                              (failure) {
                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(failure.message ?? localizations?.translate('failed_to_delete') ?? 'Failed to delete account'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              },
                              (success) {
                                // Navigate to login
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (builder) => const Login()),
                                );
                              },
                            );
                          }
                        }
                      },
                    ),
                    AccountDetailsModal(icon: Icons.logout, title: localizations?.logout ?? 'LogOut', onTap: () async {
                      // Show loading indicator while logging out
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );

                      // Call logout API
                      await Api.instance.logout();

                      // Close loading indicator
                      if (context.mounted) {
                        Navigator.pop(context);
                        // Navigate to login
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (builder) => const Login()),
                        );
                      }
                    }),
                  ],
                ]
            ),



            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceAround,
            //   children: [
            //     InkWell(
            //         onTap: ()=>_launchURL('https://www.instagram.com/theglowbalnetwork/'),
            //         child: Icon(Bootstrap.instagram,size: 35.sp,))
            //     ,
            //     InkWell(
            //         onTap: ()=>_launchURL('https://www.youtube.com/@theglowbalnetwork'),
            //         child: Icon(Bootstrap.youtube,size: 35.sp,)
            //     ),
            //     InkWell(
            //       onTap: ()=>_launchURL('https://www.tiktok.com/@theglowbalnetwork?_t=ZG-8sYz3lMN54D&_r=1'),
            //       child: Icon(
            //         Bootstrap.tiktok,size: 35.sp,),
            //     ),
            //     // Image.asset('assets/images/instagram.png',height: 35.h,width: 35.w,),
            //     // Image.asset('assets/images/youtube.png',height: 35.h,width: 35.w,),
            //     // Image.asset('assets/images/twitter.png',height: 35.h,width: 35.w,),
            //   ],
            // ),

            SizedBox(height: 10.h,),
            // BlocBuilder<AppVersionCubit,String>(
            //   builder: (BuildContext context, state) {
            //     return Align(
            //       alignment: Alignment.bottomCenter,
            //       child: Text('App Version: $state',
            //         style: Theme.of(context).textTheme.titleSmall!.copyWith(
            //           color: Theme.of(context).brightness==Brightness.dark ?
            //           Colors.white24 : Colors.black26,
            //         ),
            //       ),
            //     );
            //   },
            //
            // ),
            SizedBox(height: 10.h,),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail({required String subject,required String body}) async {
    final emailUrl = Uri.encodeFull('mailto:edugarciamovimiento@gmail.com?subject=$subject&body=$body');
    if (await canLaunchUrl(Uri.parse(emailUrl))) {
      await launchUrl(Uri.parse(emailUrl));
    } else {
      throw 'Could not launch $emailUrl';
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final languageCubit = context.read<LanguageCubit>();
    final currentLanguage = languageCubit.currentLanguageCode;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            AppLocalizations.of(context)?.selectLanguage ?? 'Select Language',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption(
                context: context,
                dialogContext: dialogContext,
                languageCode: 'en',
                languageName: 'English',
                isSelected: currentLanguage == 'en',
              ),
              SizedBox(height: 10.h),
              _buildLanguageOption(
                context: context,
                dialogContext: dialogContext,
                languageCode: 'es',
                languageName: 'Español',
                isSelected: currentLanguage == 'es',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context)?.cancel ?? 'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption({
    required BuildContext context,
    required BuildContext dialogContext,
    required String languageCode,
    required String languageName,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () async {
        final languageCubit = context.read<LanguageCubit>();
        await languageCubit.changeLanguage(languageCode);
        Navigator.pop(dialogContext);

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('language_changed') ??
                'Language changed successfully',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.blue : Colors.grey,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              languageName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected ? Colors.blue : Colors.black,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
