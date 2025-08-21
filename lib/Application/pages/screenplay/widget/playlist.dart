import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class PlaylistPlayer extends StatefulWidget {
  final List<PlaylistItem> items;

  const PlaylistPlayer({super.key, required this.items});

  @override
  State<PlaylistPlayer> createState() => _PlaylistPlayerState();
}

class _PlaylistPlayerState extends State<PlaylistPlayer> {
  int _currentIndex = 0;
  VideoPlayerController? _videoController;
  Timer? _imageTimer;
  Timer? _videoProgressTimer;
  bool _isInitialized = false;

  PlaylistItem get currentItem => widget.items[_currentIndex];

  @override
  void initState() {
    super.initState();
    // Hide system UI for fullscreen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    _playCurrentItem();
  }

  void _playCurrentItem() {
    _disposeCurrent();
    _isInitialized = false;

    final item = currentItem;
    print('Playing item: ${item.type} - ${item.path}');

    if (item.type == "image") {
      // Show image for 5 seconds
      setState(() {
        _isInitialized = true;
      });
      _imageTimer = Timer(const Duration(seconds: 5), _nextItem);
    } else if (item.type == "video") {
      _initializeVideo(item);
    }
  }

  void _initializeVideo(PlaylistItem item) {
    final file = File(item.path);

    if (file.existsSync()) {
      print('✅ Playing local video: ${item.path}');
      _videoController = VideoPlayerController.file(file);
    } else if (item.url != null && item.url!.isNotEmpty) {
      print('⚠️ Local file missing, playing from URL: ${item.url}');
      _videoController = VideoPlayerController.networkUrl(Uri.parse(item.url!));
    } else {
      print('❌ No video source available for: ${item.path}');
      _nextItem();
      return;
    }

    _videoController!
        .initialize()
        .then((_) {
          if (!mounted) return;

          setState(() {
            _isInitialized = true;
          });

          _videoController!
            ..setVolume(0.0) // Muted as requested
            ..setLooping(false)
            ..play();

          print('Video initialized: ${_videoController!.value.duration}');

          // Start monitoring video progress manually instead of using listener
          _startVideoProgressMonitoring();
        })
        .catchError((error) {
          print('❌ Video initialization failed: $error');
          _nextItem();
        });
  }

  void _startVideoProgressMonitoring() {
    _videoProgressTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) {
      if (!mounted || _videoController == null) {
        timer.cancel();
        return;
      }

      final value = _videoController!.value;

      // Check if video has ended or is very close to ending
      if (value.position >= value.duration &&
          value.duration.inMilliseconds > 0) {
        timer.cancel();
        print('Video ended, moving to next item');
        _nextItem();
      }

      // Also check if video is not playing and should be
      if (!value.isPlaying &&
          value.position < value.duration &&
          value.duration.inMilliseconds > 0) {
        print('Video paused unexpectedly, attempting to resume...');
        _videoController?.play();
      }
    });
  }

  void _nextItem() {
    if (!mounted) return;

    _disposeCurrent();
    setState(() {
      _currentIndex = (_currentIndex + 1) % widget.items.length;
    });

    // Small delay to ensure cleanup before starting next item
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _playCurrentItem();
      }
    });
  }

  void _disposeCurrent() {
    _imageTimer?.cancel();
    _imageTimer = null;

    _videoProgressTimer?.cancel();
    _videoProgressTimer = null;

    if (_videoController != null) {
      // Don't use listener, just dispose directly
      _videoController!.dispose();
      _videoController = null;
    }
  }

  @override
  void dispose() {
    _disposeCurrent();
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = currentItem;

    // Show loading while initializing
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: AbsorbPointer(
        // ✅ This prevents ALL touch interactions with the video
        absorbing: true,
        child: SizedBox.expand(child: _buildCurrentMedia(item)),
      ),
    );
  }

  Widget _buildCurrentMedia(PlaylistItem item) {
    if (item.type == "image") {
      final file = File(item.path);

      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Failed to load local image: $error');
            _nextItem();
            return const SizedBox.shrink();
          },
        );
      } else if (item.url != null && item.url!.isNotEmpty) {
        return Image.network(
          item.url!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Failed to load network image: $error');
            _nextItem();
            return const SizedBox.shrink();
          },
        );
      } else {
        _nextItem();
        return const SizedBox.shrink();
      }
    } else if (item.type == "video" && _videoController != null) {
      // ✅ Simple video display without any controls or interactions
      return Center(
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class PlaylistItem {
  final String type; // "image" or "video"
  final String path; // local file path
  final String? url; // optional network fallback

  PlaylistItem({required this.type, required this.path, this.url});

  @override
  String toString() {
    return 'PlaylistItem(type: $type, path: $path, url: $url)';
  }
}
