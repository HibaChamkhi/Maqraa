import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/di/injection.dart';
import '../../../core/model /ui_state.dart';
import '../bloc/name_bloc.dart';
import '../widgets/name_widget.dart';

class NamePage extends StatefulWidget {
  const NamePage({super.key});

  @override
  State<NamePage> createState() => _NamePageState();
}

class _NamePageState extends State<NamePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<NameBloc>(),
      child: _buildBody(),
    );
  }

  Widget _buildBody() {
    return BlocConsumer<NameBloc, NameState>(listener: (context, state) {
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
                color: Colors.black,
              ),
            ),
          ),
        );
      }
    }, builder: (context, state) {
      return const NameWidget();
    });
  }
}
