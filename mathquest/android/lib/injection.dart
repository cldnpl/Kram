import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'features/auth/data/auth_service.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async {
  getIt.init();
  if (!getIt.isRegistered<AuthService>()) {
    getIt.registerLazySingleton<AuthService>(AuthService.new);
  }
}
