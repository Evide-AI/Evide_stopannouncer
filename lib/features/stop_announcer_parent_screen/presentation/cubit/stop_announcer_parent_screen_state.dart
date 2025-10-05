part of 'stop_announcer_parent_screen_cubit.dart';

@immutable
class StopAnnouncerParentScreenState extends Equatable{
  final String? pairingCode;
  const StopAnnouncerParentScreenState({
    this.pairingCode,
  });
  
  @override
  List<Object?> get props => [pairingCode ?? ''];
}


class StopAnnouncerParentScreenErrorState extends StopAnnouncerParentScreenState{
  final String errorMessage;

  const StopAnnouncerParentScreenErrorState({required this.errorMessage});
  @override
  List<Object?> get props => [errorMessage];
}