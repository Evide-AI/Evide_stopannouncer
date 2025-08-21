part of 'linkscreen_bloc.dart';

sealed class LinkscreenEvent extends Equatable {
  const LinkscreenEvent();

  @override
  List<Object> get props => [];
}

class CheckPairingCode extends LinkscreenEvent {
  final String pairingCode;

  const CheckPairingCode({required this.pairingCode});
}
