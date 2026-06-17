import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../bloc/login_bloc/login_bloc.dart';
import '../widgets/login_widget.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoginBloc>(),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<LoginBloc, LoginState>(listener: (context, state) {
      if (state.status == UIStatus.error) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
            content: Text(state.message),
          ),
        );
      } else if (state.status == UIStatus.loading) {
        Center(
          child: SizedBox(
            height: 60.h,
            child: const Center(
              child: CircularProgressIndicator(
                color: Colors.black
              ),
            ),
          ),
        );
      }
    }, builder: (context, state) {
      return const LoginWidget();
    });
  }
}
