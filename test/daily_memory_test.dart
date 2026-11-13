import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geokuna/core/database/database.dart';
import 'package:geokuna/features/atlas/catalog.dart';
import 'package:geokuna/features/learning/capitals.dart';
import 'package:geokuna/features/learning/session_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AppDatabase db;
  late SessionRepository repository;
  late Catalog catalog;
  late CapitalCatalog capitals;
  late DateTime now;

  setUpAll(() async {
    catalog = await Catalog.load();
    capitals = await CapitalCatalog.load();
  });
  setUp(() {
    now = DateTime(2026, 11, 12, 12);
    db = AppDatabase(NativeDatabase.memory());
    repository = SessionRepository(db, clock: () => now);
  });
  tearDown(() => db.close());

  Future<LearningSession> answerCorrect(LearningSession session) {
    if (!session.isCapital) {
      return repository.answer(
        session.row.id,
        session.index,
        session.targetId,
        catalog.countries.map((c) => c.id).toSet(),
      );
    }
    final fact = session.capitalQuestion.fact;
    final input = session.difficulty == CapitalDifficulty.firstLetter
        ? fact.name.substring(1)
        : fact.name;
    return repository.answerCapital(session.row.id, session.index, input);
  }

  test('four independent skills per country and a duplicate answer reviews once', () async {
    await repository.memoryOverview(catalog, capitals);
    final rows = await db
        .customSelect("SELECT id FROM memory_cards WHERE country_id = 'POL'")
        .get();
    expect(rows.map((r) => r.read<String>('id')).toSet(), {
      'map:POL:map',
      'capitals:POL:choice',
      'capitals:POL:firstLetter',
      'capitals:POL:write',
    });
    final session = await repository.start(['POL']);
    await answerCorrect(session);
    await answerCorrect(session);
    final reviews = await db
        .customSelect('SELECT skill_id FROM memory_reviews')
        .get();
    expect(reviews, hasLength(1));
    expect(reviews.single.read<String>('skill_id'), 'map:POL:map');
    final counts = await db
        .customSelect(
          "SELECT id, review_count FROM memory_cards WHERE country_id = 'POL'",
        )
        .get();
    expect(counts.where((r) => r.read<int>('review_count') == 1), hasLength(1));
  });

  test(
    'daily session resumes its snapshot and limits new cards per local day',
    () async {
      final before = await repository.memoryOverview(catalog, capitals);
      expect(before.newRemainingToday, 3);
      var session = (await repository.startDaily(catalog, capitals))!;
      expect(session.isDaily, isTrue);
      expect(session.countryIds, hasLength(3));
      expect(session.countryIds.toSet(), hasLength(session.countryIds.length));
      final originalId = session.row.id;
      final originalOrder = List<String>.of(session.countryIds);
      session = await answerCorrect(session);
      final resumed = (await repository.startDaily(catalog, capitals))!;
      expect(resumed.row.id, originalId);
      expect(resumed.countryIds, originalOrder);
      expect(resumed.currentAttempt, isNotNull);
      session = await repository.advance(session.row.id, session.index);
      while (!session.completed) {
        session = await answerCorrect(session);
        session = await repository.advance(session.row.id, session.index);
      }
      final after = await repository.memoryOverview(catalog, capitals);
      expect(after.newRemainingToday, 0);
      now = DateTime(2026, 11, 13, 12);
      final tomorrow = await repository.memoryOverview(catalog, capitals);
      expect(tomorrow.newRemainingToday, 3);
    },
  );

  test(
    'early correct leaves due unchanged; an early error reschedules',
    () async {
      await repository.memoryOverview(catalog, capitals);
      var session = await repository.start(['POL']);
      await answerCorrect(session);
      await repository.advance(session.row.id, 0);
      final first = await db
          .customSelect("SELECT due FROM memory_cards WHERE id = 'map:POL:map'")
          .getSingle();
      final firstDue = first.data['due'];
      session = await repository.start(['POL']);
      await answerCorrect(session);
      await repository.advance(session.row.id, 0);
      final early = await db
          .customSelect("SELECT due FROM memory_cards WHERE id = 'map:POL:map'")
          .getSingle();
      expect(early.data['due'], firstDue);
      session = await repository.start(['POL']);
      await repository.answer(session.row.id, 0, 'DEU', {'POL', 'DEU'});
      final wrong = await db
          .customSelect("SELECT due FROM memory_cards WHERE id = 'map:POL:map'")
          .getSingle();
      expect(wrong.data['due'], isNot(firstDue));
      final reviews = await db
          .customSelect(
            "SELECT applied, rating FROM memory_reviews WHERE skill_id = 'map:POL:map' ORDER BY rowid",
          )
          .get();
      expect(reviews.map((r) => r.read<int>('applied')), [1, 0, 1]);
      expect(reviews.last.read<int>('rating'), 1);
    },
  );

  test('historical attempts import once and preserve their skill', () async {
    await db.customStatement(
      "INSERT INTO sessions (id, country_ids, current_index, created_at, completed_at, topic, difficulty, question_data, content_version) VALUES ('old', '[\"POL\"]', 0, 1794000000, 1794000100, 'capitals', 'choice', '[]', 'legacy')",
    );
    await db.customStatement(
      "INSERT INTO attempts (session_id, question_index, country_id, answer, correct, answered_at, topic, difficulty) VALUES ('old', 0, 'POL', 'Warszawa', 1, 1794000001, 'capitals', 'choice')",
    );
    await repository.memoryOverview(catalog, capitals);
    await repository.memoryOverview(catalog, capitals);
    final reviews = await db
        .customSelect('SELECT skill_id FROM memory_reviews')
        .get();
    expect(reviews, hasLength(1));
    expect(reviews.single.read<String>('skill_id'), 'capitals:POL:choice');
    final cards = await db
        .customSelect(
          "SELECT id, review_count FROM memory_cards WHERE country_id = 'POL'",
        )
        .get();
    expect(
      cards
          .where((row) => row.read<int>('review_count') > 0)
          .map((row) => row.read<String>('id')),
      ['capitals:POL:choice'],
    );
    expect(await repository.history(), hasLength(1));
  });

  test('due cards precede new cards and countries do not repeat', () async {
    await repository.memoryOverview(catalog, capitals);
    final manual = await repository.start(['POL']);
    await answerCorrect(manual);
    await repository.advance(manual.row.id, 0);
    // Copy a valid scheduler state to ten cards belonging to different countries.
    final countries = catalog.countries.take(10).map((c) => c.id).toList();
    for (final id in countries) {
      await db.customStatement(
        "UPDATE memory_cards SET state = (SELECT state FROM memory_cards WHERE id = 'map:POL:map'), due = ? WHERE id = ?",
        [
          now
                  .subtract(const Duration(days: 1))
                  .toUtc()
                  .millisecondsSinceEpoch ~/
              1000,
          'map:$id:map',
        ],
      );
    }
    final overview = await repository.memoryOverview(catalog, capitals);
    expect(overview.dueCount, greaterThanOrEqualTo(10));
    expect(overview.plannedNewCount, 0);
    final daily = (await repository.startDaily(catalog, capitals))!;
    expect(daily.countryIds, hasLength(10));
    expect(daily.countryIds.toSet(), hasLength(10));
    expect(daily.countryIds.toSet(), countries.toSet());
    for (var i = 0; i < daily.countryIds.length; i++) {
      expect(daily.isCapitalAt(i), isFalse);
    }
  });
}
