import 'package:fpdart/fpdart.dart';
import 'package:evide_stop_announcer_app/core/failure/failure.dart';

abstract interface class StreamUsecase<SuccessType, Params> {
  Stream<Either<Failure, SuccessType>> call({required Params params});
}
