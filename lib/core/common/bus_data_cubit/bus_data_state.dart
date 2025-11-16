part of 'bus_data_cubit.dart';
enum BusDataStatus { initial, loading, loaded, error }
class BusDataState extends Equatable {
  final BusDataEntity busData;
  final List<String> localVideoPaths;
  final BusDataStatus status;
  final String message;
  const BusDataState({
    this.busData = const BusDataEntity(),
    this.localVideoPaths = const [],
    this.status = BusDataStatus.initial,
    this.message = '',
  });

  BusDataState copyWith({
    BusDataEntity? busData,
    List<String>? localVideoPaths,
    BusDataStatus? status,
    String? message,
  }) {
    return BusDataState(
      busData: busData ?? this.busData,
      localVideoPaths: localVideoPaths ?? this.localVideoPaths,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }

  @override
  List<Object> get props => [busData, localVideoPaths, status, message];
}

final class BusDataCubitInitial extends BusDataState {}