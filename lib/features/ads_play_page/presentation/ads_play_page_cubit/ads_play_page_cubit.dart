import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'ads_play_page_state.dart';

class AdsPlayPageCubit extends Cubit<AdsPlayPageState> {
  AdsPlayPageCubit() : super(AdsPlayPageInitial());
}
