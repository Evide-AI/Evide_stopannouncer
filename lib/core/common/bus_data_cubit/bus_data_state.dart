part of 'bus_data_cubit.dart';

sealed class BusDataState extends Equatable {
  const BusDataState();

  @override
  List<Object> get props => [];
}

final class BusDataCubitInitial extends BusDataState {}
class BustDataLoadingState extends BusDataState {}

class BusDataLoadedState extends BusDataState {
  final BusDataEntity busData;
  final List<String> localVideoPaths;

  const BusDataLoadedState({required this.busData, this.localVideoPaths = const []});

  @override
  List<Object> get props => [busData];
}

class BusDataErrorState extends BusDataState {
  final String message;

  const BusDataErrorState({required this.message});

  @override
  List<Object> get props => [message];
}
