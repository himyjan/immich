import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:immich_mobile/constants/enums.dart';
import 'package:immich_mobile/entities/album.entity.dart';
import 'package:immich_mobile/entities/asset.entity.dart';
import 'package:immich_mobile/infrastructure/entities/user.entity.dart';
import 'package:immich_mobile/providers/db.provider.dart';
import 'package:immich_mobile/repositories/database.repository.dart';
import 'package:immich_mobile/utils/hash.dart';
import 'package:immich_mobile/widgets/asset_grid/asset_grid_data_structure.dart';
import 'package:isar/isar.dart';

final timelineRepositoryProvider = Provider((ref) => TimelineRepository(ref.watch(dbProvider)));

class TimelineRepository extends DatabaseRepository {
  const TimelineRepository(super.db);

  Future<List<String>> getTimelineUserIds(String id) {
    return db.users.filter().inTimelineEqualTo(true).or().idEqualTo(id).idProperty().findAll();
  }

  Stream<List<String>> watchTimelineUsers(String id) {
    return db.users.filter().inTimelineEqualTo(true).or().idEqualTo(id).idProperty().watch();
  }

  Stream<RenderList> watchArchiveTimeline(String userId) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isTrashedEqualTo(false)
        .visibilityEqualTo(AssetVisibilityEnum.archive)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  Stream<RenderList> watchFavoriteTimeline(String userId) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isFavoriteEqualTo(true)
        .not()
        .visibilityEqualTo(AssetVisibilityEnum.locked)
        .isTrashedEqualTo(false)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  Stream<RenderList> watchAlbumTimeline(Album album, GroupAssetsBy groupAssetByOption) {
    final query = album.assets.filter().isTrashedEqualTo(false).not().visibilityEqualTo(AssetVisibilityEnum.locked);

    final withSortedOption = switch (album.sortOrder) {
      SortOrder.asc => query.sortByFileCreatedAt(),
      SortOrder.desc => query.sortByFileCreatedAtDesc(),
    };

    return _watchRenderList(withSortedOption, groupAssetByOption);
  }

  Stream<RenderList> watchTrashTimeline(String userId) {
    final query = db.assets.filter().ownerIdEqualTo(fastHash(userId)).isTrashedEqualTo(true).sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  Stream<RenderList> watchAllVideosTimeline(String userId) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isTrashedEqualTo(false)
        .visibilityEqualTo(AssetVisibilityEnum.timeline)
        .typeEqualTo(AssetType.video)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  Stream<RenderList> watchHomeTimeline(String userId, GroupAssetsBy groupAssetByOption) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .isTrashedEqualTo(false)
        .stackPrimaryAssetIdIsNull()
        .visibilityEqualTo(AssetVisibilityEnum.timeline)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, groupAssetByOption);
  }

  Stream<RenderList> watchMultiUsersTimeline(List<String> userIds, GroupAssetsBy groupAssetByOption) {
    final isarUserIds = userIds.map(fastHash).toList();
    final query = db.assets
        .where()
        .anyOf(isarUserIds, (qb, id) => qb.ownerIdEqualToAnyChecksum(id))
        .filter()
        .isTrashedEqualTo(false)
        .visibilityEqualTo(AssetVisibilityEnum.timeline)
        .stackPrimaryAssetIdIsNull()
        .sortByFileCreatedAtDesc();
    return _watchRenderList(query, groupAssetByOption);
  }

  Future<RenderList> getTimelineFromAssets(List<Asset> assets, GroupAssetsBy getGroupByOption) {
    return RenderList.fromAssets(assets, getGroupByOption);
  }

  Stream<RenderList> watchAssetSelectionTimeline(String userId) {
    final query = db.assets
        .where()
        .remoteIdIsNotNull()
        .filter()
        .ownerIdEqualTo(fastHash(userId))
        .visibilityEqualTo(AssetVisibilityEnum.timeline)
        .isTrashedEqualTo(false)
        .stackPrimaryAssetIdIsNull()
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, GroupAssetsBy.none);
  }

  Stream<RenderList> watchLockedTimeline(String userId, GroupAssetsBy getGroupByOption) {
    final query = db.assets
        .where()
        .ownerIdEqualToAnyChecksum(fastHash(userId))
        .filter()
        .visibilityEqualTo(AssetVisibilityEnum.locked)
        .isTrashedEqualTo(false)
        .sortByFileCreatedAtDesc();

    return _watchRenderList(query, getGroupByOption);
  }

  Stream<RenderList> _watchRenderList(
    QueryBuilder<Asset, Asset, QAfterSortBy> query,
    GroupAssetsBy groupAssetsBy,
  ) async* {
    yield await RenderList.fromQuery(query, groupAssetsBy);
    await for (final _ in query.watchLazy()) {
      yield await RenderList.fromQuery(query, groupAssetsBy);
    }
  }
}
