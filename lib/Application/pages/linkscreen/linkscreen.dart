import 'package:evide_dashboard/Application/Core/colors.dart';
import 'package:evide_dashboard/Application/pages/linkscreen/bloc/linkscreen_bloc.dart';
import 'package:evide_dashboard/Application/widgets/custom_Textfield_widget.dart';
import 'package:evide_dashboard/Application/widgets/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';

class HomeScreenWrapper extends StatelessWidget {
  const HomeScreenWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LinkscreenBloc(),
      child: Homescreen(),
    );
  }
}

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  late TextEditingController _pairingCode;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _pairingCode = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<LinkscreenBloc, LinkscreenState>(
        listener: (context, state) {
          if (state is LinkingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Screen linked successfully ✅')),
            );
            Navigator.pushNamed(context, '/home');
          } else if (state is LinkingFailed) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error!)));
          }
        },
        builder: (context, state) {
          if (state is LinkingLoading) {
            // show spinner while checking Firestore
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DownloadProgress) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.asset('asset/images/logos1.png'),
                ),
              ],
            );
          }

          return Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(38.0),
                  child: CustomTextformWidget(
                    controller: _pairingCode,
                    hinttext: 'Enter the Pairing Code',
                    labelText: 'Pairing Code',
                    keyboardType: TextInputType.number,
                    isPassword: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                        return 'Pairing code must be exactly 5 digits';
                      }
                      return null; // valid
                    },
                  ),
                ),
                Gap(10),
                CustomButton(
                  onTap: () {
                    final pairingCode = _pairingCode.text.trim();
                    context.read<LinkscreenBloc>().add(
                      CheckPairingCode(pairingCode: pairingCode),
                    );
                    print(
                      'the pairing code is sharing to bloc......${pairingCode}',
                    );
                  },
                  text: 'Pair Screen',
                  boxDecoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  height: 40,
                  width: 130,
                  textStyle: TextStyle(color: texColor, fontSize: 22),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
