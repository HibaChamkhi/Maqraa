import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../../data/notification/data_sources/remote/notification_data_source.dart';
import '../../data/notification/repositories/notification_repository_imp.dart';
import '../../domain/notification/repositories/notification_repository.dart';
import '../../presentation/notification/bloc/notification_bloc.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<GetIt> configureDependencies() async {
  await getIt.init();
  _registerNotifications();
  return getIt;
}

/// Manual registration for the notifications feature (kept out of the
/// generated config so no build_runner step is required).
void _registerNotifications() {
  if (getIt.isRegistered<NotificationRepository>()) return;
  getIt.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSource(
      firestore: getIt<FirebaseFirestore>(),
      firebaseAuth: getIt<FirebaseAuth>(),
    ),
  );
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(remoteDataSource: getIt()),
  );
  getIt.registerFactory<NotificationBloc>(
    () => NotificationBloc(getIt()),
  );
}
