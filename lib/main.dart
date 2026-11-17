import 'package:flutter/material.dart';

import 'app/store_app.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/realtime/catalog_events.dart';
import 'features/auth/application/admin_session.dart';
import 'features/catalog/data/store_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final session = AdminSession();
  final api = ApiClient(config, session);
  runApp(
    StoreApp(
      repository: StoreRepository(api),
      session: session,
      events: CatalogEvents(config),
    ),
  );
}
