import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/account/presentation/widgets/account_details_container.dart';
import 'package:edu_gym/features/account/presentation/widgets/account_details_shimmer.dart';
import 'package:edu_gym/features/account/presentation/screens/subscription_screen.dart';
import 'package:edu_gym/features/account/presentation/screens/settings_screen.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/auth/presentation/pages/register.dart';
import 'package:edu_gym/features/auth/presentation/pages/profile.dart';
import 'package:edu_gym/features/auth/presentation/pages/starting_screen.dart';
import 'package:edu_gym/features/home/presentation/cubit/new_home_cubit.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_color.dart';
import '../../../../screens/webview/show_webview.dart';
import '../../../../cubits/language_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class Account extends StatefulWidget {
  const Account({super.key});

  @override
  State<Account> createState() => _AccountState();
}

class _AccountState extends State<Account> {
  String _maskEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    // annu123@gmail.com -> an*****3@gmail.com
    final match = RegExp(r'^([^@]{2})[^@]*([^@])(@.+)$').firstMatch(trimmed);
    if (match != null) {
      return '${match.group(1)}*****${match.group(2)}${match.group(3)}';
    }
    // Local part too short (or no "@"): keep the first char only
    final at = trimmed.indexOf('@');
    if (at > 0) return '${trimmed[0]}*****${trimmed.substring(at)}';
    return '${trimmed[0]}*****';
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.grey.withValues(alpha: 0.1),
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
                              backgroundColor: AppColor.primary,
                              foregroundColor: AppColor.background,
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
                              foregroundColor: AppColor.primary,
                              side: const BorderSide(color: AppColor.primary),
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
                  // Always prioritize the merged global user object
                  UserDetails? userDetails = TokenApi.user;
                  
                  if(state is DataLoaded<UserDetails>){
                    userDetails = state.data;
                  }

                  if(state is DataLoading && userDetails == null){
                    return const AccountDetailsShimmer();
                  }

                  if (userDetails != null) {
                    final user = userDetails!;
                    final String displayName = (user.name != null && user.name!.isNotEmpty)
                        ? user.name!
                        : TokenApi.getUsernameFromEmail(user.email);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          height: 60.h,
                          width: 60.w,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.primary,
                          ),
                          child: ClipOval(
                            child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                                ? CachedNetworkImage(
                                    imageUrl: user.fullAvatarUrl,
                                    fit: BoxFit.cover,
                                    width: 60.w,
                                    height: 60.h,
                                    placeholder: (context, url) => const Center(
                                      child: CircularProgressIndicator(color: AppColor.background, strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) => Center(
                                      child: Text(
                                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                        style: TextStyle(
                                          fontSize: 24.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColor.background,
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                                      style: TextStyle(
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColor.background,
                                      ),
                                    ),
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

                              Text(_maskEmail(user.email),
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
                              color: AppColor.primary,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColor.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            ),
                            child: Text(localizations?.edit ?? 'Edit',
                              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColor.background,
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
                    AccountDetailsModal(
                      icon: Icons.person_2, 
                      title: localizations?.profile ?? 'Profile', 
                      onTap: () async {
                        final userDetails = TokenApi.user;
                        await Navigator.push(context, MaterialPageRoute(builder: (builder)=>Profile(userDetails: userDetails,)));
                        // Refresh account details after returning from profile
                        context.read<AccountCubit>().getAccountDetails();
                      }
                    ),
                    AccountDetailsModal(
                      icon: Icons.settings, 
                      title: localizations?.translate('settings') ?? 'Settings', 
                      onTap: () {
                        final userDetails = TokenApi.user;
                        Navigator.push(context, MaterialPageRoute(builder: (builder)=>SettingsScreen(userDetails: userDetails!)));
                      }
                    ),
                  ]
              ),

              SizedBox(height: 25.h,),
            ],

            AccountDetailsContainer(
                title: localizations?.followUs ?? 'Follow Us',
                hideTrailingIcon: true,
                itemPadding: EdgeInsets.symmetric(vertical: 15.h),
                list: [
                  AccountDetailsModal(
                    customIcon: Image.asset(ImgConstant.youtube,height: 24.h,width: 24.w,), 
                    title: localizations?.translate('youtube') ?? 'Youtube', 
                    useMask: false,
                    onTap: () {
                      _launchURL('https://www.youtube.com/@edugarcia_trainer/featured');
                    }
                  ),
                  AccountDetailsModal(
                    customIcon: Image.asset(ImgConstant.instagram,height: 24.h,width: 24.w,),
                    title: localizations?.translate('instagram') ?? 'Instagram', 
                    useMask: false,
                    onTap: () {
                      _launchURL('https://www.instagram.com/edugarcia_trainer/');
                    }
                  ),
                  AccountDetailsModal(
                    icon: Icons.facebook, 
                    iconColor: const Color(0xFF1877F2),
                    title: 'Facebook', 
                    useMask: false,
                    onTap: () {
                      _launchURL('https://www.facebook.com/people/Edu-Garcia/61555837111324/#');
                    }
                  ),
                  AccountDetailsModal(
                    icon: Icons.music_note, 
                    iconColor: Colors.black,
                    title: 'TikTok', 
                    useMask: false,
                    onTap: () {
                      _launchURL('https://www.tiktok.com/@edugarcia_trainer');
                    }
                  ),
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
                  // Only show Logout if logged in
                  if(isLoggedIn) ...[
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
                        try {
                          context.read<AccountCubit>().reset();
                          context.read<NewHomeCubit>().loadHome();
                        } catch (_) {}
                        // Navigate to the first screen of the app (StartingScreen)
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (builder) => const StartingScreen()),
                          (route) => false,
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
    final uri = Uri.parse(url);
    try {
      // Try launching in external application first
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        // Fallback to platform default if external application fails
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      // If everything fails, try one last time with platform default directly
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch $url')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AppLocalizations? localizations) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(localizations?.translate('delete_account_title') ?? 'Delete Account'),
        content: Text(
          localizations?.translate('delete_account_message') ?? 'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(localizations?.cancel ?? 'No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(localizations?.delete ?? 'Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final result = await Api.instance.deleteAccount();

      if (context.mounted) {
        Navigator.pop(context);
        result.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(failure.message ?? 'Failed to delete account'),
                backgroundColor: Colors.red,
              ),
            );
          },
          (success) {
            try {
              context.read<AccountCubit>().reset();
              context.read<NewHomeCubit>().loadHome();
            } catch (_) {}
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (builder) => const StartingScreen()),
              (route) => false,
            );
          },
        );
      }
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
                languageCode: 'es',
                languageName: 'Español',
                isSelected: currentLanguage == 'es',
              ),
              SizedBox(height: 10.h),
              _buildLanguageOption(
                context: context,
                dialogContext: dialogContext,
                languageCode: 'en',
                languageName: 'English',
                isSelected: currentLanguage == 'en',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                AppLocalizations.of(context)?.cancel ?? 'Cancel',
                style: const TextStyle(color: Colors.grey),
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
          color: isSelected ? AppColor.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: isSelected ? AppColor.primary : AppColor.secondary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColor.primary : Colors.grey,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Text(
              languageName,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: isSelected ? AppColor.primary : AppColor.text,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
