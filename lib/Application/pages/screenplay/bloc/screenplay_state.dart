part of 'screenplay_bloc.dart';

sealed class ScreenplayState extends Equatable {
  const ScreenplayState();

  @override
  List<Object> get props => [];
}

final class ScreenplayInitial extends ScreenplayState {}

class ContentsLoading extends ScreenplayState {}

class ContentsLoaded extends ScreenplayState {
  final String? pairingCode;
  final String? documentId;
  final Map<String, dynamic> documentData;
  final Map<String, String> localFiles;
  final DateTime updatedAt;

  const ContentsLoaded({
    this.pairingCode,
    this.documentId,
    required this.documentData,
    required this.localFiles,
    required this.updatedAt,
  });

  @override
  List<Object> get props => [
    ?pairingCode,
    ?documentId,
    documentData,
    localFiles,
    updatedAt,
  ];
}

class ContentsFailed extends ScreenplayState {
  final String message;
  const ContentsFailed(this.message);
}
