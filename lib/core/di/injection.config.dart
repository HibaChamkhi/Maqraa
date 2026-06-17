// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _firestore;
import 'package:firebase_auth/firebase_auth.dart' as _fbauth;
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:maqraa/core/di/core_module.dart' as _core;
import 'package:maqraa/core/interceptor/AuthInterceptor.dart' as _authInt;
import 'package:maqraa/core/interceptor/HttpInterceptor.dart' as _httpInt;
import 'package:maqraa/core/network/network_info.dart' as _net;
import 'package:maqraa/core/notifications/notification_service.dart' as _notif;
import 'package:maqraa/data/announcement/data_sources/remote/announcement_data_source.dart'
    as _annDs;
import 'package:maqraa/data/announcement/repositories/announcement_repository_imp.dart'
    as _annRepoImp;
import 'package:maqraa/data/achievement/data_sources/remote/achievement_data_source.dart'
    as _achDs;
import 'package:maqraa/data/achievement/repositories/achievement_repository_imp.dart'
    as _achRepoImp;
import 'package:maqraa/data/auth/data_sources/local/auth_prefutils.dart'
    as _authPref;
import 'package:maqraa/data/auth/data_sources/remote/auth_data_source.dart'
    as _authDs;
import 'package:maqraa/data/auth/repositories/auth_repository_imp.dart'
    as _authRepoImp;
import 'package:maqraa/data/calendar/data_sources/remote/calendar_data_source.dart'
    as _calDs;
import 'package:maqraa/data/calendar/repositories/calendar_repository_imp.dart'
    as _calRepoImp;
import 'package:maqraa/data/call/data_sources/remote/call_data_source.dart'
    as _callDs;
import 'package:maqraa/data/call/repositories/call_repository_imp.dart'
    as _callRepoImp;
import 'package:maqraa/data/circle/data_sources/remote/circle_data_source.dart'
    as _circleDs;
import 'package:maqraa/data/circle/repositories/circle_repository_imp.dart'
    as _circleRepoImp;
import 'package:maqraa/data/exam/data_sources/remote/exam_data_source.dart'
    as _examDs;
import 'package:maqraa/data/exam/repositories/exam_repository_imp.dart'
    as _examRepoImp;
import 'package:maqraa/data/name_feature/data_sources/local/name_feature_prefutils.dart'
    as _namePref;
import 'package:maqraa/data/name_feature/data_sources/remote/name_feature_data_source.dart'
    as _nameDs;
import 'package:maqraa/data/name_feature/repositories/name_feature_repository_imp.dart'
    as _nameRepoImp;
import 'package:maqraa/data/partner/data_sources/remote/partner_data_source.dart'
    as _partnerDs;
import 'package:maqraa/data/partner/repositories/partner_repository_imp.dart'
    as _partnerRepoImp;
import 'package:maqraa/data/profile/data_sources/remote/profile_data_source.dart'
    as _profileDs;
import 'package:maqraa/data/profile/repositories/profile_repository_imp.dart'
    as _profileRepoImp;
import 'package:maqraa/data/progress/data_sources/remote/progress_data_source.dart'
    as _progressDs;
import 'package:maqraa/data/progress/repositories/progress_repository_imp.dart'
    as _progressRepoImp;
import 'package:maqraa/data/reminder/data_sources/local/reminder_prefutils.dart'
    as _remPref;
import 'package:maqraa/data/reminder/repositories/reminder_repository_imp.dart'
    as _remRepoImp;
import 'package:maqraa/data/schedule/data_sources/remote/schedule_data_source.dart'
    as _schedDs;
import 'package:maqraa/data/schedule/repositories/schedule_repository_imp.dart'
    as _schedRepoImp;
import 'package:maqraa/data/session/data_sources/remote/session_data_source.dart'
    as _sessDs;
import 'package:maqraa/data/session/repositories/session_repository_imp.dart'
    as _sessRepoImp;
import 'package:maqraa/data/task/data_sources/remote/task_data_source.dart'
    as _taskDs;
import 'package:maqraa/data/task/repositories/task_repository_imp.dart'
    as _taskRepoImp;
import 'package:maqraa/domain/announcement/repositories/announcement_repository.dart'
    as _annRepo;
import 'package:maqraa/domain/achievement/repositories/achievement_repository.dart'
    as _achRepo;
import 'package:maqraa/domain/auth/repositories/auth_repository.dart'
    as _authRepo;
import 'package:maqraa/domain/calendar/repositories/calendar_repository.dart'
    as _calRepo;
import 'package:maqraa/domain/call/repositories/call_repository.dart' as _callRepo;
import 'package:maqraa/domain/circle/repositories/circle_repository.dart'
    as _circleRepo;
import 'package:maqraa/domain/exam/repositories/exam_repository.dart' as _examRepo;
import 'package:maqraa/domain/name_feature/repositories/feature_name_repository.dart'
    as _nameRepo;
import 'package:maqraa/domain/partner/repositories/partner_repository.dart'
    as _partnerRepo;
import 'package:maqraa/domain/profile/repositories/profile_repository.dart'
    as _profileRepo;
import 'package:maqraa/domain/progress/repositories/progress_repository.dart'
    as _progressRepo;
import 'package:maqraa/domain/reminder/repositories/reminder_repository.dart'
    as _remRepo;
import 'package:maqraa/domain/schedule/repositories/schedule_repository.dart'
    as _schedRepo;
import 'package:maqraa/domain/session/repositories/session_repository.dart'
    as _sessRepo;
import 'package:maqraa/domain/task/repositories/task_repository.dart' as _taskRepo;
import 'package:maqraa/presentation/announcement/bloc/announcement_bloc.dart'
    as _annBloc;
import 'package:maqraa/presentation/achievement/bloc/achievement_bloc.dart'
    as _achBloc;
import 'package:maqraa/presentation/auth/bloc/auth_bloc.dart' as _authBloc;
import 'package:maqraa/presentation/calendar/bloc/calendar_bloc.dart' as _calBloc;
import 'package:maqraa/presentation/call/bloc/call_bloc.dart' as _callBloc;
import 'package:maqraa/presentation/circle/bloc/circle_bloc.dart' as _circleBloc;
import 'package:maqraa/presentation/exam/bloc/exam_bloc.dart' as _examBloc;
import 'package:maqraa/presentation/name_feature/bloc/name_bloc.dart' as _nameBloc;
import 'package:maqraa/presentation/partner/bloc/partner_bloc.dart' as _partnerBloc;
import 'package:maqraa/presentation/profile/bloc/profile_bloc.dart' as _profileBloc;
import 'package:maqraa/presentation/progress/bloc/progress_bloc.dart'
    as _progressBloc;
import 'package:maqraa/presentation/reminder/bloc/reminder_bloc.dart' as _remBloc;
import 'package:maqraa/presentation/schedule/bloc/schedule_bloc.dart' as _schedBloc;
import 'package:maqraa/presentation/session/bloc/session_bloc.dart' as _sessBloc;
import 'package:maqraa/presentation/task/bloc/task_bloc.dart' as _taskBloc;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final coreModule = _$CoreModule();

    // --- core ---
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => coreModule.sharedPreferences,
      preResolve: true,
    );
    gh.lazySingleton<_i519.Client>(() => coreModule.httpClient);
    gh.lazySingleton<_fbauth.FirebaseAuth>(() => coreModule.firebaseAuth);
    gh.lazySingleton<_firestore.FirebaseFirestore>(() => coreModule.firestore);
    gh.lazySingleton<_notif.NotificationService>(() => _notif.NotificationService());
    gh.factory<_net.NetworkInfo>(() => _net.NetworkInfoImpl());
    gh.singleton<_authInt.AuthenticatedHttpClient>(
      () => _authInt.AuthenticatedHttpClient(
        sharedPref: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_httpInt.HttpInterceptor>(
      () => _httpInt.HttpInterceptorImpl(
        httpClient: gh<_authInt.AuthenticatedHttpClient>(),
      ),
    );

    // --- name_feature (example) ---
    gh.factory<_namePref.PrefUtils>(
      () => _namePref.PrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
        httpClientInterceptor: gh<_authInt.AuthenticatedHttpClient>(),
      ),
    );
    gh.factory<_nameDs.NameFeatureRemoteDataSource>(
      () => _nameDs.NameFeatureRemoteDataSource(
        httpClient: gh<_httpInt.HttpInterceptor>(),
        prefUtils: gh<_namePref.PrefUtils>(),
        networkInfo: gh<_net.NetworkInfo>(),
      ),
    );
    gh.factory<_nameRepo.NameFeatureRepository>(
      () => _nameRepoImp.NameFeatureRepositoryImpl(
        remoteDataSource: gh<_nameDs.NameFeatureRemoteDataSource>(),
        networkInfo: gh<_net.NetworkInfo>(),
      ),
    );
    gh.factory<_nameBloc.NameBloc>(
      () => _nameBloc.NameBloc(gh<_nameRepo.NameFeatureRepository>()),
    );

    // --- auth ---
    gh.factory<_authPref.AuthPrefUtils>(
      () => _authPref.AuthPrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_authDs.AuthRemoteDataSource>(
      () => _authDs.AuthRemoteDataSource(
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
        firestore: gh<_firestore.FirebaseFirestore>(),
        prefUtils: gh<_authPref.AuthPrefUtils>(),
      ),
    );
    gh.factory<_authRepo.AuthRepository>(
      () => _authRepoImp.AuthRepositoryImpl(
        remoteDataSource: gh<_authDs.AuthRemoteDataSource>(),
      ),
    );
    gh.factory<_authBloc.AuthBloc>(
      () => _authBloc.AuthBloc(gh<_authRepo.AuthRepository>()),
    );

    // --- profile ---
    gh.factory<_profileDs.ProfileRemoteDataSource>(
      () => _profileDs.ProfileRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
      ),
    );
    gh.factory<_profileRepo.ProfileRepository>(
      () => _profileRepoImp.ProfileRepositoryImpl(
        remoteDataSource: gh<_profileDs.ProfileRemoteDataSource>(),
      ),
    );
    gh.factory<_profileBloc.ProfileBloc>(
      () => _profileBloc.ProfileBloc(gh<_profileRepo.ProfileRepository>()),
    );

    // --- circle ---
    gh.factory<_circleDs.CircleRemoteDataSource>(
      () => _circleDs.CircleRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_circleRepo.CircleRepository>(
      () => _circleRepoImp.CircleRepositoryImpl(
        remoteDataSource: gh<_circleDs.CircleRemoteDataSource>(),
      ),
    );
    gh.factory<_circleBloc.CircleBloc>(
      () => _circleBloc.CircleBloc(gh<_circleRepo.CircleRepository>()),
    );

    // --- schedule ---
    gh.factory<_schedDs.ScheduleRemoteDataSource>(
      () => _schedDs.ScheduleRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
      ),
    );
    gh.factory<_schedRepo.ScheduleRepository>(
      () => _schedRepoImp.ScheduleRepositoryImpl(
        remoteDataSource: gh<_schedDs.ScheduleRemoteDataSource>(),
      ),
    );
    gh.factory<_schedBloc.ScheduleBloc>(
      () => _schedBloc.ScheduleBloc(gh<_schedRepo.ScheduleRepository>()),
    );

    // --- task ---
    gh.factory<_taskDs.TaskRemoteDataSource>(
      () => _taskDs.TaskRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
      ),
    );
    gh.factory<_taskRepo.TaskRepository>(
      () => _taskRepoImp.TaskRepositoryImpl(
        remoteDataSource: gh<_taskDs.TaskRemoteDataSource>(),
      ),
    );
    gh.factory<_taskBloc.TaskBloc>(
      () => _taskBloc.TaskBloc(gh<_taskRepo.TaskRepository>()),
    );

    // --- progress ---
    gh.factory<_progressDs.ProgressRemoteDataSource>(
      () => _progressDs.ProgressRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_progressRepo.ProgressRepository>(
      () => _progressRepoImp.ProgressRepositoryImpl(
        remoteDataSource: gh<_progressDs.ProgressRemoteDataSource>(),
      ),
    );
    gh.factory<_progressBloc.ProgressBloc>(
      () => _progressBloc.ProgressBloc(gh<_progressRepo.ProgressRepository>()),
    );

    // --- session ---
    gh.factory<_sessDs.SessionRemoteDataSource>(
      () => _sessDs.SessionRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_sessRepo.SessionRepository>(
      () => _sessRepoImp.SessionRepositoryImpl(
        remoteDataSource: gh<_sessDs.SessionRemoteDataSource>(),
      ),
    );
    gh.factory<_sessBloc.SessionBloc>(
      () => _sessBloc.SessionBloc(gh<_sessRepo.SessionRepository>()),
    );

    // --- calendar ---
    gh.factory<_calDs.CalendarRemoteDataSource>(
      () => _calDs.CalendarRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_calRepo.CalendarRepository>(
      () => _calRepoImp.CalendarRepositoryImpl(
        remoteDataSource: gh<_calDs.CalendarRemoteDataSource>(),
      ),
    );
    gh.factory<_calBloc.CalendarBloc>(
      () => _calBloc.CalendarBloc(gh<_calRepo.CalendarRepository>()),
    );

    // --- exam ---
    gh.factory<_examDs.ExamRemoteDataSource>(
      () => _examDs.ExamRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_examRepo.ExamRepository>(
      () => _examRepoImp.ExamRepositoryImpl(
        remoteDataSource: gh<_examDs.ExamRemoteDataSource>(),
      ),
    );
    gh.factory<_examBloc.ExamBloc>(
      () => _examBloc.ExamBloc(gh<_examRepo.ExamRepository>()),
    );

    // --- partner ---
    gh.factory<_partnerDs.PartnerRemoteDataSource>(
      () => _partnerDs.PartnerRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_partnerRepo.PartnerRepository>(
      () => _partnerRepoImp.PartnerRepositoryImpl(
        remoteDataSource: gh<_partnerDs.PartnerRemoteDataSource>(),
      ),
    );
    gh.factory<_partnerBloc.PartnerBloc>(
      () => _partnerBloc.PartnerBloc(gh<_partnerRepo.PartnerRepository>()),
    );

    // --- call ---
    gh.factory<_callDs.CallRemoteDataSource>(
      () => _callDs.CallRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_callRepo.CallRepository>(
      () => _callRepoImp.CallRepositoryImpl(
        remoteDataSource: gh<_callDs.CallRemoteDataSource>(),
      ),
    );
    gh.factory<_callBloc.CallBloc>(
      () => _callBloc.CallBloc(gh<_callRepo.CallRepository>()),
    );

    // --- announcement ---
    gh.factory<_annDs.AnnouncementRemoteDataSource>(
      () => _annDs.AnnouncementRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_annRepo.AnnouncementRepository>(
      () => _annRepoImp.AnnouncementRepositoryImpl(
        remoteDataSource: gh<_annDs.AnnouncementRemoteDataSource>(),
      ),
    );
    gh.factory<_annBloc.AnnouncementBloc>(
      () => _annBloc.AnnouncementBloc(gh<_annRepo.AnnouncementRepository>()),
    );

    // --- achievement ---
    gh.factory<_achDs.AchievementRemoteDataSource>(
      () => _achDs.AchievementRemoteDataSource(
        firestore: gh<_firestore.FirebaseFirestore>(),
        firebaseAuth: gh<_fbauth.FirebaseAuth>(),
      ),
    );
    gh.factory<_achRepo.AchievementRepository>(
      () => _achRepoImp.AchievementRepositoryImpl(
        remoteDataSource: gh<_achDs.AchievementRemoteDataSource>(),
      ),
    );
    gh.factory<_achBloc.AchievementBloc>(
      () => _achBloc.AchievementBloc(gh<_achRepo.AchievementRepository>()),
    );

    // --- reminder ---
    gh.factory<_remPref.ReminderPrefUtils>(
      () => _remPref.ReminderPrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
      ),
    );
    gh.factory<_remRepo.ReminderRepository>(
      () => _remRepoImp.ReminderRepositoryImpl(
        prefUtils: gh<_remPref.ReminderPrefUtils>(),
        notificationService: gh<_notif.NotificationService>(),
      ),
    );
    gh.factory<_remBloc.ReminderBloc>(
      () => _remBloc.ReminderBloc(gh<_remRepo.ReminderRepository>()),
    );

    return this;
  }
}

class _$CoreModule extends _core.CoreModule {}
