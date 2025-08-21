part of 'splashscreen_bloc.dart';

sealed class SplashscreenState extends Equatable {
  const SplashscreenState();

  @override
  List<Object> get props => [];
}

final class SplashscreenInitial extends SplashscreenState {}

final class Loadingsplash extends SplashscreenState {}

final class ScreenLinked extends SplashscreenState {}

final class ScreenNotLinked extends SplashscreenState {}

final class SplashError extends SplashscreenState {
  final String error;

  const SplashError({required this.error});
  @override
  List<Object> get props => [error];
}

final class DownloadProgressSplash extends SplashscreenState {
  final String fileName;
  final double progress;

  const DownloadProgressSplash({
    required this.fileName,
    required this.progress,
  });
  @override
  List<Object> get props => [fileName, progress];
}
