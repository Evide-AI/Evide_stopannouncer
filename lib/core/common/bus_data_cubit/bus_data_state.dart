part of 'bus_data_cubit.dart';
enum BusDataStatus { initial, loading, loaded, error }
class BusDataState extends Equatable {
  final BusDataEntity busData;
  final List<String> localVideoPaths;
  final BusDataStatus status;
  const BusDataState({
    this.busData = const BusDataEntity(),
    this.localVideoPaths = const [],
    this.status = BusDataStatus.initial,
  });

  BusDataState copyWith({
    BusDataEntity? busData,
    List<String>? localVideoPaths,
    BusDataStatus? status,
  }) {
    return BusDataState(
      busData: busData ?? this.busData,
      localVideoPaths: localVideoPaths ?? this.localVideoPaths,
      status: status ?? this.status,
    );
  }

  @override
  List<Object> get props => [busData, localVideoPaths, status];
}

final class BusDataCubitInitial extends BusDataState {}
// class BustDataLoadingState extends BusDataState {}

// class BusDataLoadedState extends BusDataState {
//   final BusDataEntity busData;
//   final List<String> localVideoPaths;

//   const BusDataLoadedState({required this.busData, this.localVideoPaths = const []});

//   @override
//   List<Object> get props => [busData, localVideoPaths];
// }

class BusDataErrorState extends BusDataState {
  final String message;

  const BusDataErrorState({required this.message});

  @override
  List<Object> get props => [message];
}
