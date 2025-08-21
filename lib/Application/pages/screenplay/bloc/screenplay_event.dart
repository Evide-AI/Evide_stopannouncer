part of 'screenplay_bloc.dart';

sealed class ScreenplayEvent extends Equatable {
  const ScreenplayEvent();

  @override
  List<Object> get props => [];
}
class LoadContents extends ScreenplayEvent{}
