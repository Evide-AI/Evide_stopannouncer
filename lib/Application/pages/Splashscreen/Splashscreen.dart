import 'package:evide_dashboard/Application/Core/colors.dart';
import 'package:evide_dashboard/Application/pages/Splashscreen/bloc/splashscreen_bloc.dart';
import 'package:evide_dashboard/Application/pages/Splashscreen/stopaddtofirebase.dart';
import 'package:evide_dashboard/Application/pages/fetchstops/fetchstops.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SplashscreenWrapper extends StatelessWidget {
  const SplashscreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SplashscreenBloc(),
      child: Splashscreen(),
    );
  }
}

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  void initState() {
    // navigation();
    context.read<SplashscreenBloc>().add(IsLinkedEvent(''));
    super.initState();
  }

  // Future navigation() async {
  //   await Future.delayed(Duration(seconds: 5));
  //   Navigator.push(context, MaterialPageRoute(builder: (ctx) => StopBanner()));
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
      backgroundColor: backgroundColor,
      body: BlocConsumer<SplashscreenBloc, SplashscreenState>(
        listener: (context, state) async {
          if (state is ScreenLinked) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (state is ScreenNotLinked) {
            Navigator.pushReplacementNamed(context, '/link');
          }
        },
        builder: (context, state) {
          if (state is Loadingsplash) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DownloadProgressSplash) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Downloading: ${state.fileName}"),
                const SizedBox(height: 10),
                LinearProgressIndicator(value: state.progress),
                const SizedBox(height: 5),
                Text("${(state.progress * 100).toStringAsFixed(0)}%"),
              ],
            );
          }
          return Center(
            child: Image.asset(
              'asset/images/logos1.png',
              height: 300,
              width: 300,
            ),
          );
        },
      ),
    ),
    );
  }
}
