// import 'package:evide_dashboard/Application/pages/login/login_bloc/login_event.dart';
// import 'package:evide_dashboard/Application/pages/login/login_bloc/login_state.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:formz/formz.dart';

// import '../pages/login/login_bloc/login_bloc.dart';


// class LoginForm extends StatelessWidget {
//   const LoginForm({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<LoginBloc, LoginState>(
//       listener: (context, state) {
//         if (state.status.isFailure) {
//           ScaffoldMessenger.of(context)
//             ..hideCurrentSnackBar()
//             ..showSnackBar(
//               SnackBar(
//                 content: Text(state.errorMessage ?? 'Authentication Failure'),
//                 backgroundColor: Colors.red,
//               ),
//             );
//         }
//         if (state.status.isSuccess) {
//           Navigator.of(context).pop();
//         }
//       },
//       child: Align(
//         alignment: const Alignment(0, -1 / 3),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const SizedBox(height: 16),
//             _EmailInput(),
//             const Padding(padding: EdgeInsets.all(12)),
//             _PasswordInput(),
//             const Padding(padding: EdgeInsets.all(12)),
//             _LoginButton(),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _EmailInput extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<LoginBloc, LoginState>(
//       buildWhen: (previous, current) => previous.email != current.email,
//       builder: (context, state) {
//         return TextField(
//           key: const Key('loginForm_emailInput_textField'),
//           onChanged: (email) => context.read<LoginBloc>().add(LoginEmailChanged(email)),
//           keyboardType: TextInputType.emailAddress,
//           decoration: InputDecoration(
//             labelText: 'Email',
//             helperText: '',
//             errorText: state.email.displayError != null ? 'Invalid email' : null,
//             prefixIcon: const Icon(Icons.email),
//             border: const OutlineInputBorder(),
//           ),
//         );
//       },
//     );
//   }
// }

// class _PasswordInput extends StatefulWidget {
//   @override
//   __PasswordInputState createState() => __PasswordInputState();
// }

// class __PasswordInputState extends State<_PasswordInput> {
//   bool _isPasswordVisible = false;

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<LoginBloc, LoginState>(
//       buildWhen: (previous, current) => previous.password != current.password,
//       builder: (context, state) {
//         return TextField(
//           key: const Key('loginForm_passwordInput_textField'),
//           onChanged: (password) =>
//               context.read<LoginBloc>().add(LoginPasswordChanged(password)),
//           obscureText: !_isPasswordVisible,
//           decoration: InputDecoration(
//             labelText: 'Password',
//             helperText: '',
//             errorText: state.password.displayError != null ? 'Password too short' : null,
//             prefixIcon: const Icon(Icons.lock),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
//               ),
//               onPressed: () {
//                 setState(() {
//                   _isPasswordVisible = !_isPasswordVisible;
//                 });
//               },
//             ),
//             border: const OutlineInputBorder(),
//           ),
//         );
//       },
//     );
//   }
// }

// class _LoginButton extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<LoginBloc, LoginState>(
//       builder: (context, state) {
//         return state.status.isInProgress
//             ? const CircularProgressIndicator()
//             : SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   key: const Key('loginForm_continue_raisedButton'),
//                   onPressed: state.isValid
//                       ? () => context.read<LoginBloc>().add(const LoginSubmitted())
//                       : null,
//                   style: ElevatedButton.styleFrom(
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: const Text(
//                     'LOGIN',
//                     style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               );
//       },
//     );
//   }
// }