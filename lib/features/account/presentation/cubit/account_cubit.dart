import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/features/auth/domain/entities/user.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AccountCubit extends Cubit<DataState>{
  AccountCubit():super(DataInitial());

  Future<void> getAccountDetails() async {
    emit(DataLoading());
    final response= await Api.instance.userDetails();
    response.fold(
            (failure){
              print('Failed to load account details: ${failure.message}');
              emit(DataLoadFailed(failure));
            },
        (data){
            print('Account details loaded successfully');
            emit(DataLoaded<UserDetails>(data));
        }
    );
  }

}