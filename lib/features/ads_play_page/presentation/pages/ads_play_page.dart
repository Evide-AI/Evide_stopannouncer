import 'package:evide_stop_announcer_app/core/common/bus_data_cubit/bus_data_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdsPlayPage extends StatelessWidget {
  const AdsPlayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BusDataCubit, BusDataState>(
        builder: (context, state) {
          if (state is BustDataLoadingState) {
            return Center(child: CircularProgressIndicator());
          }else if (state is BusDataErrorState) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return Center(child: Text('Ads Play Page'));
        },
      ),
    );
  }
}
