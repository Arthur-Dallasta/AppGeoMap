import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/area.dart';
import '../data/area_repository.dart';

final areasProvider = FutureProvider.family<AreaListResponse, String>(
  (ref, propertyId) => AreaRepository().getAreas(propertyId),
);
