// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:http/http.dart' as _i519;
import 'package:injectable/injectable.dart' as _i526;
import 'package:maqraa/core/di/core_module.dart' as _i919;
import 'package:maqraa/core/interceptor/AuthInterceptor.dart' as _i577;
import 'package:maqraa/core/interceptor/HttpInterceptor.dart' as _i185;
import 'package:maqraa/core/network/network_info.dart' as _i293;
import 'package:maqraa/data/auth/data_sources/local/auth_prefutils.dart'
    as _i560;
import 'package:maqraa/data/auth/data_sources/remote/auth_data_source.dart'
    as _i372;
import 'package:maqraa/data/auth/repositories/auth_repository_imp.dart' as _i10;
import 'package:maqraa/data/name_feature/data_sources/local/name_feature_prefutils.dart'
    as _i525;
import 'package:maqraa/data/name_feature/data_sources/remote/name_feature_data_source.dart'
    as _i577;
import 'package:maqraa/data/name_feature/repositories/name_feature_repository_imp.dart'
    as _i713;
import 'package:maqraa/domain/auth/repositories/auth_repository.dart' as _i278;
import 'package:maqraa/domain/name_feature/repositories/feature_name_repository.dart'
    as _i652;
import 'package:maqraa/presentation/auth/bloc/login_bloc/login_bloc.dart'
    as _i307;
import 'package:maqraa/presentation/auth/bloc/register_bloc/register_bloc.dart'
    as _i838;
import 'package:maqraa/presentation/name_feature/bloc/name_bloc.dart' as _i908;
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
    gh.factory<_i525.PrefUtils>(
      () => _i525.PrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
        httpClientInterceptor: gh<_i577.AuthenticatedHttpClient>(),
      ),
    );
    gh.factory<_i577.NameFeatureRemoteDataSource>(
      () => _i577.NameFeatureRemoteDataSource(
        httpClient: gh<_i185.HttpInterceptor>(),
        prefUtils: gh<_i525.PrefUtils>(),
        networkInfo: gh<_i293.NetworkInfo>(),
      ),
    );
    gh.factory<_i652.NameFeatureRepository>(
      () => _i713.NameFeatureRepositoryImpl(
        remoteDataSource: gh<_i577.NameFeatureRemoteDataSource>(),
        networkInfo: gh<_i293.NetworkInfo>(),
      ),
    );
    gh.factory<_i560.AuthPrefUtils>(
      () => _i560.PrefUtilsImpl(
        sharedPreferences: gh<_i460.SharedPreferences>(),
        httpClientInterceptor: gh<_i577.AuthenticatedHttpClient>(),
      ),
    );
    gh.factory<_i908.NameBloc>(
      () => _i908.NameBloc(gh<_i652.NameFeatureRepository>()),
    );
    gh.factory<_i372.AuthRemoteDataSource>(
      () => _i372.AuthRemoteDataSource(
        httpClient: gh<_i185.HttpInterceptor>(),
        prefUtils: gh<_i560.AuthPrefUtils>(),
        networkInfo: gh<_i293.NetworkInfo>(),
      ),
    );
    gh.factory<_i278.AuthRepository>(
      () => _i10.AuthRepositoryImpl(
        remoteDataSource: gh<_i372.AuthRemoteDataSource>(),
        networkInfo: gh<_i293.NetworkInfo>(),
      ),
    );
    gh.factory<_i838.RegisterBloc>(
      () => _i838.RegisterBloc(gh<_i278.AuthRepository>()),
    );
    gh.factory<_i307.LoginBloc>(
      () => _i307.LoginBloc(authRepository: gh<_i278.AuthRepository>()),
    );
    return this;
  }
}

class _$CoreModule extends _i919.CoreModule {}
