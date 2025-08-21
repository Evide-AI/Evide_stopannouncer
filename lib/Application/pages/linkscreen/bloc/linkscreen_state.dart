part of 'linkscreen_bloc.dart';

sealed class LinkscreenState extends Equatable {
  const LinkscreenState();

  @override
  List<Object> get props => [];
}

final class LinkscreenInitial extends LinkscreenState {}

final class LinkingLoading extends LinkscreenState {}

final class LinkingSuccess extends LinkscreenState {
  // final Map<String, dynamic> documentData;
  // final Map<String, String> localFiles;

  // const LinkingSuccess({required this.localFiles, required this.documentData});
}

final class LinkingFailed extends LinkscreenState {
  final String? error;

  const LinkingFailed(this.error);
}

class DownloadProgress extends LinkscreenState {
  final String fileName;
  final double progress; // 0.0 -> 1.0

  const DownloadProgress({required this.fileName, required this.progress});

  @override
  List<Object> get props => [fileName, progress];
}
