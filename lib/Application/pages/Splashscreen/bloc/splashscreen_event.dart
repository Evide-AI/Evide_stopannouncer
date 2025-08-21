part of 'splashscreen_bloc.dart';

sealed class SplashscreenEvent extends Equatable {
  const SplashscreenEvent();

  @override
  List<Object> get props => [];
}

class IsLinkedEvent extends SplashscreenEvent {
  final String pairingCode;

  const IsLinkedEvent(this.pairingCode);

  @override
  List<Object> get props => [pairingCode];
}
