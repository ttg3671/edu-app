import 'dart:async';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/socket_service.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/features/home/presentation/cubit/new_home_cubit.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/subscription_details.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountCubit extends Cubit<DataState>{
  StreamSubscription? _paymentSubscription;

  AccountCubit():super(DataInitial()) {
    _listenToPaymentEvents();
  }

  void reset() {
    emit(DataInitial());
  }

  void _listenToPaymentEvents() {
    _paymentSubscription?.cancel();
    _paymentSubscription = SocketService().paymentEvents.listen((event) async {
      if (event == 'payment_success') {
        // print('🔄 Refreshing account details due to payment success');
        
        // 1. Fetch latest subscription data
        final subResult = await Api.instance.getLatestSubscription();
        
        subResult.fold(
          (failure) {}, // print('❌ Failed to fetch latest subscription: ${failure.message}'),
          (data) async {
            if (data['isSuccess'] == true && data['data']?['subscription'] != null) {
              // 2. Parse and surgically update local storage
              final subDetails = SubscriptionDetails.fromJson(data['data']['subscription']);
              await TokenApi().updateSubscriptionDetails(subDetails);
            }
          }
        );

        // 3. Refresh full account details to update UI components
        getAccountDetails();
        
        // 4. Refresh Home Cubit to unlock content
        try {
          final context = navigatorKey.currentContext;
          if (context != null) {
            context.read<NewHomeCubit>().loadHome();
          }
        } catch (e) {
          // print('⚠️ AccountCubit: Could not refresh NewHomeCubit: $e');
        }
      } else if (event == 'subscription_canceled') {
        // print('📉 Subscription canceled notification received');
        // Wipe local subscription data surgically
        await TokenApi().clearSubscriptionData();
        // Refresh UI to show non-subscribed state
        getAccountDetails();
        } else if (event == 'payment_failed') {

        // print('❌ Payment failed notification received');
        // Handle failed payment if needed
      }
    });
  }

  @override
  Future<void> close() {
    _paymentSubscription?.cancel();
    return super.close();
  }

  Future<void> getAccountDetails() async {
    emit(DataLoading());
    final response = await Api.instance.userDetails();
    response.fold(
      (failure) {
        // print('Failed to load account details: ${failure.message}');
        emit(DataLoadFailed(failure));
      },
      (data) {
        // Ensure active subscription details & isSubscribed are never wiped out
        final cachedUser = TokenApi.user;
        final sub = cachedUser?.subscriptionDetails ?? data.subscriptionDetails;
        final subStatus = sub?.status?.toLowerCase();
        final bool hasActiveSub = subStatus == 'active' || 
                                  subStatus == 'trialing' || 
                                  subStatus == 'praemium' || 
                                  subStatus == 'processing';

        final bool isCancelledOrExpired = subStatus == 'expired' || subStatus == 'canceled';
        final int resolvedIsSubscribed = hasActiveSub
            ? 1
            : (isCancelledOrExpired
                ? 0
                : (cachedUser?.isSubscribed == 1 ? 1 : data.isSubscribed));

        final int? resolvedMaxDevices = isCancelledOrExpired
            ? 1
            : ((data.subscriptionDetails?.maxDevices != null && data.subscriptionDetails!.maxDevices! > 0)
                ? data.subscriptionDetails!.maxDevices
                : ((cachedUser?.subscriptionDetails?.maxDevices != null && cachedUser!.subscriptionDetails!.maxDevices! > 0)
                    ? cachedUser.subscriptionDetails!.maxDevices
                    : (TokenApi.maxDevices != null && TokenApi.maxDevices! > 0 ? TokenApi.maxDevices : null)));

        final resolvedSub = isCancelledOrExpired
            ? (sub?.copyWith(maxDevices: 1, status: 'expired') ?? sub)
            : (resolvedMaxDevices != null && resolvedMaxDevices > 0
                ? (sub?.copyWith(maxDevices: resolvedMaxDevices) ?? sub)
                : sub);

        if (resolvedMaxDevices != null && resolvedMaxDevices > 0 && !isCancelledOrExpired) {
          TokenApi().updateMaxDevices(resolvedMaxDevices);
        }

        final resolvedUser = data.copyWith(
          isSubscribed: resolvedIsSubscribed,
          subscriptionDetails: resolvedSub,
        );

        emit(DataLoaded<UserDetails>(resolvedUser));
      },
    );
  }

}