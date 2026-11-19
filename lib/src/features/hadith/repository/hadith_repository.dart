import 'package:cloud_firestore/cloud_firestore.dart';

import 'hadith.dart';

class HadithFeed {
  const HadithFeed(this.items, {required this.fromCache, this.hasMore = false});
  final List<Hadith> items;
  final bool fromCache, hasMore;
}

class HadithRepository {
  HadithRepository({FirebaseFirestore? firestore})
    : _providedFirestore = firestore;

  final FirebaseFirestore? _providedFirestore;
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  static const pageSize = 50;
  DocumentSnapshot<Map<String, dynamic>>? _nextCursor;

  Stream<HadithFeed> watch({bool nextPage = false}) {
    Query<Map<String, dynamic>> query = _firestore
        .collection('hadiths')
        .orderBy(FieldPath.documentId)
        .limit(pageSize);
    if (nextPage && _nextCursor != null) {
      query = query.startAfterDocument(_nextCursor!);
    }
    return query.snapshots(includeMetadataChanges: true).map((snapshot) {
      // Sort locally so old string orders and missing order fields remain
      // readable alongside the recommended numeric order field.
      final items =
          snapshot.docs
              .map((doc) => Hadith.fromMap(doc.id, doc.data()))
              .where((hadith) => hadith.hasText)
              .toList()
            ..sort((a, b) {
              final order = a.order.compareTo(b.order);
              return order != 0 ? order : a.id.compareTo(b.id);
            });
      final hasMore = snapshot.docs.length == pageSize;
      _nextCursor = hasMore ? snapshot.docs.last : null;
      return HadithFeed(
        List.unmodifiable(items),
        fromCache: snapshot.metadata.isFromCache,
        hasMore: hasMore,
      );
    });
  }
}
