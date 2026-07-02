// ignore_for_file: unused_element, document_ignores

import 'package:cryptokb_scanner/product/cache/hive_v2/model/app_cache_model.dart';
import 'package:hive_ce/hive.dart';

@GenerateAdapters([
  AdapterSpec<AppCacheModel>(),
])
part 'hive_adapters.g.dart';
