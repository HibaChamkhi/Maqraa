// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:maqraa/core/di/core_module.dart' as _i919;
import 'package:maqraa/core/interceptor/auth_interceptor.dart' as _i577;
import 'package:maqraa/core/interceptor/http_interceptor.dart' as _i185;
import 'package:maqraa/core/network/network_info.dart' as _i293;
import 'package:maqraa/core/notifications/notification_service.dart' as _i529;
import 'package:maqraa/data/achievement/data_sources/remote/achievement_data_source.dart'
    as _i79;
import 'package:maqraa/data/achievement/repositories/achievement_repository_imp.dart'
    as _i809;
import 'package:maqraa/data/announcement/data_sources/remote/announcement_data_source.dart'
    as _i670;
import 'package:maqraa/data/announcement/repositories/announcement_repository_imp.dart'
    as _i976;
import 'package:maqraa/data/auth/data_sources/local/auth_prefutils.dart'
    as _i560;
import 'package:maqraa/data/auth/data_sources/remote/auth_data_source.dart'
    as _i372;
import 'package:maqraa/data/auth/repositories/auth_repository_imp.dart' as _i10;
import 'package:maqraa/data/calendar/data_sources/remote/calendar_data_source.dart'
    as _i926;
import 'package:maqraa/data/calendar/repositories/calendar_repository_imp.dart'
    as _i628;
import 'package:maqraa/data/call/data_sources/remote/call_data_source.dart'
    as _i712;
import 'package:maqraa/data/call/repositories/call_repository_imp.dart' as _i77;
import 'package:maqraa/data/circle/data_sources/remote/circle_data_source.dart'
    as _i619;
import 'package:maqraa/data/circle/repositories/circle_repository_imp.dart'
    as _i616;
import 'package:maqraa/data/exam/data_sources/remote/exam_data_source.dart'
    as _i80;
import 'package:maqraa/data/exam/repositories/exam_repository_imp.dart'
    as _i992;
import 'package:maqraa/data/name_feature/data_sources/local/name_feature_prefutils.dart'
    as _i525;
import 'package:maqraa/data/name_feature/data_sources/remote/name_feature_data_source.dart'
    as _i577;
import 'package:maqraa/data/name_feature/repositories/name_feature_repository_imp.dart'
    as _i713;
import 'package:maqraa/data/partner/data_sources/remote/partner_data_source.dart'
    as _i238;
import 'package:maqraa/data/partner/repositories/partner_repository_imp.dart'
    as _i771;
import 'package:maqraa/data/profile/data_sources/remote/profile_data_source.dart'
    as _i601;
import 'package:maqraa/data/profile/repositories/profile_repository_imp.dart'
    as _i368;
import 'package:maqraa/data/progress/data_sources/remote/progress_data_source.dart'
    as _i403;
import 'package:maqraa/data/progress/repositories/progress_repository_imp.dart'
    as _i578;
import 'package:maqraa/data/reminder/data_sources/local/reminder_prefutils.dart'
    as _i793;
import 'package:maqraa/data/reminder/repositories/reminder_repository_imp.dart'
    as _i881;
import 'package:maqraa/data/schedule/data_sources/remote/schedule_data_source.dart'
    as _i120;
import 'package:maqraa/data/schedule/repositories/schedule_repository_imp.dart'
    as _i1038;
import 'package:maqraa/data/session/data_sources/remote/session_data_source.dart'
    as _i672;
import 'package:maqraa/data/session/repositories/session_repository_imp.dart'
    as _i591;
import 'package:maqraa/data/task/data_sources/remote/task_data_source.dart'
    as _i165;
import 'package:maqraa/data/task/repositories/task_repository_imp.dart'
    as _i170;
import 'package:maqraa/domain/achievement/repositories/achievement_repository.dart'
    as _i266;
import 'package:maqraa/domain/announcement/repositories/announcement_repository.dart'
    as _i741;
import 'package:maqraa/domain/auth/repositories/auth_repository.dart' as _i278;
import 'package:maqraa/domain/calendar/repositories/calendar_repository.dart'
    as _i894;
import 'package:maqraa/domain/call/repositories/call_repository.dart' as _i433;
import 'package:maqraa/domain/circle/repositories/circle_repository.dart'
    as _i504;
import 'package:maqraa/domain/exam/repositories/exam_repository.dart' as _i311;
import 'package:maqraa/domain/name_feature/repositories/feature_name_repository.dart'
    as _i652;
import 'package:maqraa/domain/partner/repositories/partner_repository.dart'
    as _i766;
import 'package:maqraa/domain/profile/repositories/profile_repository.dart'
    as _i509;
import 'package:maqraa/domain/progress/repositories/progress_repository.dart'
    as _i365;
import 'package:maqraa/domain/reminder/repositories/reminder_repository.dart'
    as _i747;
import 'package:maqraa/domain/schedule/repositories/schedule_repository.dart'
    as _i180;
import 'package:maqraa/domain/session/repositories/session_repository.dart'
    as _i617;
import 'package:maqraa/domain/task/repositories/task_repository.dart' as _i482;
import 'package:maqraa/presentation/achievement/bloc/achievement_bloc.dart'
    as _i313;
import 'package:maqraa/presentation/announcement/bloc/announcement_bloc.dart'
    as _i563;
import 'package:maqraa/presentation/auth/bloc/auth_bloc.dart' as _i90;
import 'package:maqraa/presentation/calendar/bloc/calendar_bloc.dart' as _i1047;
import 'package:maqraa/presentation/call/bloc/call_bloc.dart' as _i546;
import 'package:maqraa/presentation/circle/bloc/circle_bloc.dart' as _i695;
import 'package:maqraa/presentation/exam/bloc/exam_bloc.dart' as _i830;
import 'package:maqraa/presentation/name_feature/bloc/name_bloc.dart' as _i908;
import 'package:maqraa/presentation/partner/bloc/partner_bloc.dart' as _i35;
import 'package:maqraa/presentation/profile/bloc/profile_bloc.dart' as _i669;
import 'package:maqraa/presentation/progress/bloc/progress_bloc.dart' as _i523;
import 'package:maqraa/presentation/reminder/bloc/reminder_bloc.dart' as _i943;
import 'package:maqraa/presentation/schedule/bloc/schedule_bloc.dart' as _i198;
import 'package:maqraa/presentation/session/bloc/session_bloc.dart' as _i886;
import 'package:maqraa/presentation/task/bloc/task_bloc.dart' as _i671;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreModule = _$CoreModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i519.Client>(() => coreModule.httpClient);
    gh.lazySingleton<_i59.FirebaseAuth>(() => coreModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(() => coreModule.firestore);
    gh.lazySingleton<_i529.NotificationService>(
      () => _i529.NotificationService(),
    );
    gh.factory<_i293.NetworkInfo>(() => _i293.NetworkInfoImpl());
    gh.singleton<_i577.AuthenticatedHttpClient>(
      () => _i577.AuthenticatedHttpClient(
        sharedPref: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i185.HttpInterceptor>(
      () => _i185.HttpInterceptorImpl(
        httpClient: gh<_i577.AuthenticatedHttpClient>(),
      ),
    );
    gh.factory<_i560.AuthPrefUtils>(
      () => _i560.AuthPrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i372.AuthRemoteDataSource>(
      () => _i372.AuthRemoteDataSource(
        firebaseAuth: gh<_i59.FirebaseAuth>(),
        firestore: gh<_i974.FirebaseFirestore>(),
        prefUtils: gh<_i560.AuthPrefUtils>(),
      ),
    );
    gh.factory<_i601.ProfileRemoteDataSource>(
      () => _i601.ProfileRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.factory<_i120.ScheduleRemoteDataSource>(
      () => _i120.ScheduleRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
      ),
    );
    gh.factory<_i165.TaskRemoteDataSource>(
      () =>
          _i165.TaskRemoteDataSource(firestore: gh<_i974.FirebaseFirestore>()),
    );
    gh.factory<_i278.AuthRepository>(
      () => _i10.AuthRepositoryImpl(
        remoteDataSource: gh<_i372.AuthRemoteDataSource>(),
      ),
    );
    gh.factory<_i90.AuthBloc>(() => _i90.AuthBloc(gh<_i278.AuthRepository>()));
    gh.factory<_i79.AchievementRemoteDataSource>(
      () => _i79.AchievementRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i670.AnnouncementRemoteDataSource>(
      () => _i670.AnnouncementRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i926.CalendarRemoteDataSource>(
      () => _i926.CalendarRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i712.CallRemoteDataSource>(
      () => _i712.CallRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i619.CircleRemoteDataSource>(
      () => _i619.CircleRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i80.ExamRemoteDataSource>(
      () => _i80.ExamRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i238.PartnerRemoteDataSource>(
      () => _i238.PartnerRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i403.ProgressRemoteDataSource>(
      () => _i403.ProgressRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i672.SessionRemoteDataSource>(
      () => _i672.SessionRemoteDataSource(
        firestore: gh<_i974.FirebaseFirestore>(),
        firebaseAuth: gh<_i59.FirebaseAuth>(),
      ),
    );
    gh.factory<_i482.TaskRepository>(
      () => _i170.TaskRepositoryImpl(
        remoteDataSource: gh<_i165.TaskRemoteDataSource>(),
      ),
    );
    gh.factory<_i793.ReminderPrefUtils>(
      () => _i793.ReminderPrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_i741.AnnouncementRepository>(
      () => _i976.AnnouncementRepositoryImpl(
        remoteDataSource: gh<_i670.AnnouncementRemoteDataSource>(),
      ),
    );
    gh.factory<_i365.ProgressRepository>(
      () => _i578.ProgressRepositoryImpl(
        remoteDataSource: gh<_i403.ProgressRemoteDataSource>(),
      ),
    );
    gh.factory<_i766.PartnerRepository>(
      () => _i771.PartnerRepositoryImpl(
        remoteDataSource: gh<_i238.PartnerRemoteDataSource>(),
      ),
    );
    gh.factory<_i35.PartnerBloc>(
      () => _i35.PartnerBloc(gh<_i766.PartnerRepository>()),
    );
    gh.factory<_i509.ProfileRepository>(
      () => _i368.ProfileRepositoryImpl(
        remoteDataSource: gh<_i601.ProfileRemoteDataSource>(),
      ),
    );
    gh.factory<_i617.SessionRepository>(
      () => _i591.SessionRepositoryImpl(
        remoteDataSource: gh<_i672.SessionRemoteDataSource>(),
      ),
    );
    gh.factory<_i525.PrefUtils>(
      () => _i525.PrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
        httpClientInterceptor: gh<_i577.AuthenticatedHttpClient>(),
      ),
    );
    gh.factory<_i523.ProgressBloc>(
      () => _i523.ProgressBloc(gh<_i365.ProgressRepository>()),
    );
    gh.factory<_i180.ScheduleRepository>(
      () => _i1038.ScheduleRepositoryImpl(
        remoteDataSource: gh<_i120.ScheduleRemoteDataSource>(),
      ),
    );
    gh.factory<_i577.NameFeatureRemoteDataSource>(
      () => _i577.NameFeatureRemoteDataSource(
        httpClient: gh<_i185.HttpInterceptor>(),
        prefUtils: gh<_i525.PrefUtils>(),
        networkInfo: gh<_i293.NetworkInfo>(),
      ),
    );
    gh.factory<_i671.TaskBloc>(
      () => _i671.TaskBloc(gh<_i482.TaskRepository>()),
    );
    gh.factory<_i747.ReminderRepository>(
      () => _i881.ReminderRepositoryImpl(
        prefUtils: gh<_i793.ReminderPrefUtils>(),
        notificationService: gh<_i529.NotificationService>(),
      ),
    );
    gh.factory<_i652.NameFeatureRepository>(
      () => _i713.NameFeatureRepositoryImpl(
        remoteDataSource: gh<_i577.NameFeatureRemoteDataSource>(),
        networkInfo: gh<_i293.NetworkInfo>(),
      ),
    );
    gh.factory<_i198.ScheduleBloc>(
      () => _i198.ScheduleBloc(gh<_i180.ScheduleRepository>()),
    );
    gh.factory<_i886.SessionBloc>(
      () => _i886.SessionBloc(gh<_i617.SessionRepository>()),
    );
    gh.factory<_i563.AnnouncementBloc>(
      () => _i563.AnnouncementBloc(gh<_i741.AnnouncementRepository>()),
    );
    gh.factory<_i894.CalendarRepository>(
      () => _i628.CalendarRepositoryImpl(
        remoteDataSource: gh<_i926.CalendarRemoteDataSource>(),
      ),
    );
    gh.factory<_i908.NameBloc>(
      () => _i908.NameBloc(gh<_i652.NameFeatureRepository>()),
    );
    gh.factory<_i669.ProfileBloc>(
      () => _i669.ProfileBloc(gh<_i509.ProfileRepository>()),
    );
    gh.factory<_i266.AchievementRepository>(
      () => _i809.AchievementRepositoryImpl(
        remoteDataSource: gh<_i79.AchievementRemoteDataSource>(),
      ),
    );
    gh.factory<_i1047.CalendarBloc>(
      () => _i1047.CalendarBloc(gh<_i894.CalendarRepository>()),
    );
    gh.factory<_i943.ReminderBloc>(
      () => _i943.ReminderBloc(gh<_i747.ReminderRepository>()),
    );
    gh.factory<_i504.CircleRepository>(
      () => _i616.CircleRepositoryImpl(
        remoteDataSource: gh<_i619.CircleRemoteDataSource>(),
      ),
    );
    gh.factory<_i311.ExamRepository>(
      () => _i992.ExamRepositoryImpl(
        remoteDataSource: gh<_i80.ExamRemoteDataSource>(),
      ),
    );
    gh.factory<_i433.CallRepository>(
      () => _i77.CallRepositoryImpl(
        remoteDataSource: gh<_i712.CallRemoteDataSource>(),
      ),
    );
    gh.factory<_i313.AchievementBloc>(
      () => _i313.AchievementBloc(gh<_i266.AchievementRepository>()),
    );
    gh.factory<_i695.CircleBloc>(
      () => _i695.CircleBloc(gh<_i504.CircleRepository>()),
    );
    gh.factory<_i546.CallBloc>(
      () => _i546.CallBloc(gh<_i433.CallRepository>()),
    );
    gh.factory<_i830.ExamBloc>(
      () => _i830.ExamBloc(gh<_i311.ExamRepository>()),
    );
    return this;
  }
}

class _$CoreModule extends _i919.CoreModule {}
