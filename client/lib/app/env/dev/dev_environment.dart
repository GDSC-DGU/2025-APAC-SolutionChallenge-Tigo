// ignore_for_file: non_constant_identifier_names

import 'package:envied/envied.dart';
import 'package:tigo/app/env/common/environment.dart';

part 'dev_environment.g.dart';

@Envied(path: './assets/config/.dev.env')
class DevEnvironment implements Environment {
  @EnviedField(varName: 'API_SERVER_URL', defaultValue: '', obfuscate: true)
  static final String API_SERVER_URL = _DevEnvironment.API_SERVER_URL;

  @override
  String get apiServerUrl => API_SERVER_URL;
}
