// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $SessionsTable extends Sessions with TableInfo<$SessionsTable, Session> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryIdsMeta = const VerificationMeta(
    'countryIds',
  );
  @override
  late final GeneratedColumn<String> countryIds = GeneratedColumn<String>(
    'country_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentIndexMeta = const VerificationMeta(
    'currentIndex',
  );
  @override
  late final GeneratedColumn<int> currentIndex = GeneratedColumn<int>(
    'current_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('map'),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('map'),
  );
  static const VerificationMeta _questionDataMeta = const VerificationMeta(
    'questionData',
  );
  @override
  late final GeneratedColumn<String> questionData = GeneratedColumn<String>(
    'question_data',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _contentVersionMeta = const VerificationMeta(
    'contentVersion',
  );
  @override
  late final GeneratedColumn<String> contentVersion = GeneratedColumn<String>(
    'content_version',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('europe-location-0.2.0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    countryIds,
    currentIndex,
    createdAt,
    completedAt,
    topic,
    difficulty,
    questionData,
    contentVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Session> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('country_ids')) {
      context.handle(
        _countryIdsMeta,
        countryIds.isAcceptableOrUnknown(data['country_ids']!, _countryIdsMeta),
      );
    } else if (isInserting) {
      context.missing(_countryIdsMeta);
    }
    if (data.containsKey('current_index')) {
      context.handle(
        _currentIndexMeta,
        currentIndex.isAcceptableOrUnknown(
          data['current_index']!,
          _currentIndexMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('question_data')) {
      context.handle(
        _questionDataMeta,
        questionData.isAcceptableOrUnknown(
          data['question_data']!,
          _questionDataMeta,
        ),
      );
    }
    if (data.containsKey('content_version')) {
      context.handle(
        _contentVersionMeta,
        contentVersion.isAcceptableOrUnknown(
          data['content_version']!,
          _contentVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Session map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Session(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      countryIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_ids'],
      )!,
      currentIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_index'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      questionData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}question_data'],
      )!,
      contentVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_version'],
      )!,
    );
  }

  @override
  $SessionsTable createAlias(String alias) {
    return $SessionsTable(attachedDatabase, alias);
  }
}

class Session extends DataClass implements Insertable<Session> {
  final String id;
  final String countryIds;
  final int currentIndex;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String topic;
  final String difficulty;
  final String questionData;
  final String contentVersion;
  const Session({
    required this.id,
    required this.countryIds,
    required this.currentIndex,
    required this.createdAt,
    this.completedAt,
    required this.topic,
    required this.difficulty,
    required this.questionData,
    required this.contentVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['country_ids'] = Variable<String>(countryIds);
    map['current_index'] = Variable<int>(currentIndex);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['topic'] = Variable<String>(topic);
    map['difficulty'] = Variable<String>(difficulty);
    map['question_data'] = Variable<String>(questionData);
    map['content_version'] = Variable<String>(contentVersion);
    return map;
  }

  SessionsCompanion toCompanion(bool nullToAbsent) {
    return SessionsCompanion(
      id: Value(id),
      countryIds: Value(countryIds),
      currentIndex: Value(currentIndex),
      createdAt: Value(createdAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      topic: Value(topic),
      difficulty: Value(difficulty),
      questionData: Value(questionData),
      contentVersion: Value(contentVersion),
    );
  }

  factory Session.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Session(
      id: serializer.fromJson<String>(json['id']),
      countryIds: serializer.fromJson<String>(json['countryIds']),
      currentIndex: serializer.fromJson<int>(json['currentIndex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      topic: serializer.fromJson<String>(json['topic']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      questionData: serializer.fromJson<String>(json['questionData']),
      contentVersion: serializer.fromJson<String>(json['contentVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'countryIds': serializer.toJson<String>(countryIds),
      'currentIndex': serializer.toJson<int>(currentIndex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'topic': serializer.toJson<String>(topic),
      'difficulty': serializer.toJson<String>(difficulty),
      'questionData': serializer.toJson<String>(questionData),
      'contentVersion': serializer.toJson<String>(contentVersion),
    };
  }

  Session copyWith({
    String? id,
    String? countryIds,
    int? currentIndex,
    DateTime? createdAt,
    Value<DateTime?> completedAt = const Value.absent(),
    String? topic,
    String? difficulty,
    String? questionData,
    String? contentVersion,
  }) => Session(
    id: id ?? this.id,
    countryIds: countryIds ?? this.countryIds,
    currentIndex: currentIndex ?? this.currentIndex,
    createdAt: createdAt ?? this.createdAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    topic: topic ?? this.topic,
    difficulty: difficulty ?? this.difficulty,
    questionData: questionData ?? this.questionData,
    contentVersion: contentVersion ?? this.contentVersion,
  );
  Session copyWithCompanion(SessionsCompanion data) {
    return Session(
      id: data.id.present ? data.id.value : this.id,
      countryIds: data.countryIds.present
          ? data.countryIds.value
          : this.countryIds,
      currentIndex: data.currentIndex.present
          ? data.currentIndex.value
          : this.currentIndex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      topic: data.topic.present ? data.topic.value : this.topic,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      questionData: data.questionData.present
          ? data.questionData.value
          : this.questionData,
      contentVersion: data.contentVersion.present
          ? data.contentVersion.value
          : this.contentVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Session(')
          ..write('id: $id, ')
          ..write('countryIds: $countryIds, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('topic: $topic, ')
          ..write('difficulty: $difficulty, ')
          ..write('questionData: $questionData, ')
          ..write('contentVersion: $contentVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    countryIds,
    currentIndex,
    createdAt,
    completedAt,
    topic,
    difficulty,
    questionData,
    contentVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Session &&
          other.id == this.id &&
          other.countryIds == this.countryIds &&
          other.currentIndex == this.currentIndex &&
          other.createdAt == this.createdAt &&
          other.completedAt == this.completedAt &&
          other.topic == this.topic &&
          other.difficulty == this.difficulty &&
          other.questionData == this.questionData &&
          other.contentVersion == this.contentVersion);
}

class SessionsCompanion extends UpdateCompanion<Session> {
  final Value<String> id;
  final Value<String> countryIds;
  final Value<int> currentIndex;
  final Value<DateTime> createdAt;
  final Value<DateTime?> completedAt;
  final Value<String> topic;
  final Value<String> difficulty;
  final Value<String> questionData;
  final Value<String> contentVersion;
  final Value<int> rowid;
  const SessionsCompanion({
    this.id = const Value.absent(),
    this.countryIds = const Value.absent(),
    this.currentIndex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.topic = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.questionData = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionsCompanion.insert({
    required String id,
    required String countryIds,
    this.currentIndex = const Value.absent(),
    required DateTime createdAt,
    this.completedAt = const Value.absent(),
    this.topic = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.questionData = const Value.absent(),
    this.contentVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       countryIds = Value(countryIds),
       createdAt = Value(createdAt);
  static Insertable<Session> custom({
    Expression<String>? id,
    Expression<String>? countryIds,
    Expression<int>? currentIndex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? completedAt,
    Expression<String>? topic,
    Expression<String>? difficulty,
    Expression<String>? questionData,
    Expression<String>? contentVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (countryIds != null) 'country_ids': countryIds,
      if (currentIndex != null) 'current_index': currentIndex,
      if (createdAt != null) 'created_at': createdAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (topic != null) 'topic': topic,
      if (difficulty != null) 'difficulty': difficulty,
      if (questionData != null) 'question_data': questionData,
      if (contentVersion != null) 'content_version': contentVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionsCompanion copyWith({
    Value<String>? id,
    Value<String>? countryIds,
    Value<int>? currentIndex,
    Value<DateTime>? createdAt,
    Value<DateTime?>? completedAt,
    Value<String>? topic,
    Value<String>? difficulty,
    Value<String>? questionData,
    Value<String>? contentVersion,
    Value<int>? rowid,
  }) {
    return SessionsCompanion(
      id: id ?? this.id,
      countryIds: countryIds ?? this.countryIds,
      currentIndex: currentIndex ?? this.currentIndex,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      questionData: questionData ?? this.questionData,
      contentVersion: contentVersion ?? this.contentVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (countryIds.present) {
      map['country_ids'] = Variable<String>(countryIds.value);
    }
    if (currentIndex.present) {
      map['current_index'] = Variable<int>(currentIndex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (questionData.present) {
      map['question_data'] = Variable<String>(questionData.value);
    }
    if (contentVersion.present) {
      map['content_version'] = Variable<String>(contentVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionsCompanion(')
          ..write('id: $id, ')
          ..write('countryIds: $countryIds, ')
          ..write('currentIndex: $currentIndex, ')
          ..write('createdAt: $createdAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('topic: $topic, ')
          ..write('difficulty: $difficulty, ')
          ..write('questionData: $questionData, ')
          ..write('contentVersion: $contentVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts with TableInfo<$AttemptsTable, Attempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _questionIndexMeta = const VerificationMeta(
    'questionIndex',
  );
  @override
  late final GeneratedColumn<int> questionIndex = GeneratedColumn<int>(
    'question_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryIdMeta = const VerificationMeta(
    'countryId',
  );
  @override
  late final GeneratedColumn<String> countryId = GeneratedColumn<String>(
    'country_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _answerMeta = const VerificationMeta('answer');
  @override
  late final GeneratedColumn<String> answer = GeneratedColumn<String>(
    'answer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _typoAcceptedMeta = const VerificationMeta(
    'typoAccepted',
  );
  @override
  late final GeneratedColumn<bool> typoAccepted = GeneratedColumn<bool>(
    'typo_accepted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("typo_accepted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('map'),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('map'),
  );
  static const VerificationMeta _answeredAtMeta = const VerificationMeta(
    'answeredAt',
  );
  @override
  late final GeneratedColumn<DateTime> answeredAt = GeneratedColumn<DateTime>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    questionIndex,
    countryId,
    answer,
    correct,
    typoAccepted,
    topic,
    difficulty,
    answeredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('question_index')) {
      context.handle(
        _questionIndexMeta,
        questionIndex.isAcceptableOrUnknown(
          data['question_index']!,
          _questionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionIndexMeta);
    }
    if (data.containsKey('country_id')) {
      context.handle(
        _countryIdMeta,
        countryId.isAcceptableOrUnknown(data['country_id']!, _countryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_countryIdMeta);
    }
    if (data.containsKey('answer')) {
      context.handle(
        _answerMeta,
        answer.isAcceptableOrUnknown(data['answer']!, _answerMeta),
      );
    } else if (isInserting) {
      context.missing(_answerMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('typo_accepted')) {
      context.handle(
        _typoAcceptedMeta,
        typoAccepted.isAcceptableOrUnknown(
          data['typo_accepted']!,
          _typoAcceptedMeta,
        ),
      );
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('answered_at')) {
      context.handle(
        _answeredAtMeta,
        answeredAt.isAcceptableOrUnknown(data['answered_at']!, _answeredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_answeredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, questionIndex};
  @override
  Attempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attempt(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      questionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_index'],
      )!,
      countryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_id'],
      )!,
      answer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answer'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      typoAccepted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}typo_accepted'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}answered_at'],
      )!,
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class Attempt extends DataClass implements Insertable<Attempt> {
  final String sessionId;
  final int questionIndex;
  final String countryId;
  final String answer;
  final bool correct;
  final bool typoAccepted;
  final String topic;
  final String difficulty;
  final DateTime answeredAt;
  const Attempt({
    required this.sessionId,
    required this.questionIndex,
    required this.countryId,
    required this.answer,
    required this.correct,
    required this.typoAccepted,
    required this.topic,
    required this.difficulty,
    required this.answeredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['question_index'] = Variable<int>(questionIndex);
    map['country_id'] = Variable<String>(countryId);
    map['answer'] = Variable<String>(answer);
    map['correct'] = Variable<bool>(correct);
    map['typo_accepted'] = Variable<bool>(typoAccepted);
    map['topic'] = Variable<String>(topic);
    map['difficulty'] = Variable<String>(difficulty);
    map['answered_at'] = Variable<DateTime>(answeredAt);
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      sessionId: Value(sessionId),
      questionIndex: Value(questionIndex),
      countryId: Value(countryId),
      answer: Value(answer),
      correct: Value(correct),
      typoAccepted: Value(typoAccepted),
      topic: Value(topic),
      difficulty: Value(difficulty),
      answeredAt: Value(answeredAt),
    );
  }

  factory Attempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attempt(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      questionIndex: serializer.fromJson<int>(json['questionIndex']),
      countryId: serializer.fromJson<String>(json['countryId']),
      answer: serializer.fromJson<String>(json['answer']),
      correct: serializer.fromJson<bool>(json['correct']),
      typoAccepted: serializer.fromJson<bool>(json['typoAccepted']),
      topic: serializer.fromJson<String>(json['topic']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      answeredAt: serializer.fromJson<DateTime>(json['answeredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'questionIndex': serializer.toJson<int>(questionIndex),
      'countryId': serializer.toJson<String>(countryId),
      'answer': serializer.toJson<String>(answer),
      'correct': serializer.toJson<bool>(correct),
      'typoAccepted': serializer.toJson<bool>(typoAccepted),
      'topic': serializer.toJson<String>(topic),
      'difficulty': serializer.toJson<String>(difficulty),
      'answeredAt': serializer.toJson<DateTime>(answeredAt),
    };
  }

  Attempt copyWith({
    String? sessionId,
    int? questionIndex,
    String? countryId,
    String? answer,
    bool? correct,
    bool? typoAccepted,
    String? topic,
    String? difficulty,
    DateTime? answeredAt,
  }) => Attempt(
    sessionId: sessionId ?? this.sessionId,
    questionIndex: questionIndex ?? this.questionIndex,
    countryId: countryId ?? this.countryId,
    answer: answer ?? this.answer,
    correct: correct ?? this.correct,
    typoAccepted: typoAccepted ?? this.typoAccepted,
    topic: topic ?? this.topic,
    difficulty: difficulty ?? this.difficulty,
    answeredAt: answeredAt ?? this.answeredAt,
  );
  Attempt copyWithCompanion(AttemptsCompanion data) {
    return Attempt(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      questionIndex: data.questionIndex.present
          ? data.questionIndex.value
          : this.questionIndex,
      countryId: data.countryId.present ? data.countryId.value : this.countryId,
      answer: data.answer.present ? data.answer.value : this.answer,
      correct: data.correct.present ? data.correct.value : this.correct,
      typoAccepted: data.typoAccepted.present
          ? data.typoAccepted.value
          : this.typoAccepted,
      topic: data.topic.present ? data.topic.value : this.topic,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attempt(')
          ..write('sessionId: $sessionId, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('countryId: $countryId, ')
          ..write('answer: $answer, ')
          ..write('correct: $correct, ')
          ..write('typoAccepted: $typoAccepted, ')
          ..write('topic: $topic, ')
          ..write('difficulty: $difficulty, ')
          ..write('answeredAt: $answeredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    questionIndex,
    countryId,
    answer,
    correct,
    typoAccepted,
    topic,
    difficulty,
    answeredAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attempt &&
          other.sessionId == this.sessionId &&
          other.questionIndex == this.questionIndex &&
          other.countryId == this.countryId &&
          other.answer == this.answer &&
          other.correct == this.correct &&
          other.typoAccepted == this.typoAccepted &&
          other.topic == this.topic &&
          other.difficulty == this.difficulty &&
          other.answeredAt == this.answeredAt);
}

class AttemptsCompanion extends UpdateCompanion<Attempt> {
  final Value<String> sessionId;
  final Value<int> questionIndex;
  final Value<String> countryId;
  final Value<String> answer;
  final Value<bool> correct;
  final Value<bool> typoAccepted;
  final Value<String> topic;
  final Value<String> difficulty;
  final Value<DateTime> answeredAt;
  final Value<int> rowid;
  const AttemptsCompanion({
    this.sessionId = const Value.absent(),
    this.questionIndex = const Value.absent(),
    this.countryId = const Value.absent(),
    this.answer = const Value.absent(),
    this.correct = const Value.absent(),
    this.typoAccepted = const Value.absent(),
    this.topic = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttemptsCompanion.insert({
    required String sessionId,
    required int questionIndex,
    required String countryId,
    required String answer,
    required bool correct,
    this.typoAccepted = const Value.absent(),
    this.topic = const Value.absent(),
    this.difficulty = const Value.absent(),
    required DateTime answeredAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       questionIndex = Value(questionIndex),
       countryId = Value(countryId),
       answer = Value(answer),
       correct = Value(correct),
       answeredAt = Value(answeredAt);
  static Insertable<Attempt> custom({
    Expression<String>? sessionId,
    Expression<int>? questionIndex,
    Expression<String>? countryId,
    Expression<String>? answer,
    Expression<bool>? correct,
    Expression<bool>? typoAccepted,
    Expression<String>? topic,
    Expression<String>? difficulty,
    Expression<DateTime>? answeredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (questionIndex != null) 'question_index': questionIndex,
      if (countryId != null) 'country_id': countryId,
      if (answer != null) 'answer': answer,
      if (correct != null) 'correct': correct,
      if (typoAccepted != null) 'typo_accepted': typoAccepted,
      if (topic != null) 'topic': topic,
      if (difficulty != null) 'difficulty': difficulty,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttemptsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? questionIndex,
    Value<String>? countryId,
    Value<String>? answer,
    Value<bool>? correct,
    Value<bool>? typoAccepted,
    Value<String>? topic,
    Value<String>? difficulty,
    Value<DateTime>? answeredAt,
    Value<int>? rowid,
  }) {
    return AttemptsCompanion(
      sessionId: sessionId ?? this.sessionId,
      questionIndex: questionIndex ?? this.questionIndex,
      countryId: countryId ?? this.countryId,
      answer: answer ?? this.answer,
      correct: correct ?? this.correct,
      typoAccepted: typoAccepted ?? this.typoAccepted,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      answeredAt: answeredAt ?? this.answeredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (questionIndex.present) {
      map['question_index'] = Variable<int>(questionIndex.value);
    }
    if (countryId.present) {
      map['country_id'] = Variable<String>(countryId.value);
    }
    if (answer.present) {
      map['answer'] = Variable<String>(answer.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (typoAccepted.present) {
      map['typo_accepted'] = Variable<bool>(typoAccepted.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<DateTime>(answeredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('countryId: $countryId, ')
          ..write('answer: $answer, ')
          ..write('correct: $correct, ')
          ..write('typoAccepted: $typoAccepted, ')
          ..write('topic: $topic, ')
          ..write('difficulty: $difficulty, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryCardsTable extends MemoryCards
    with TableInfo<$MemoryCardsTable, MemoryCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _countryIdMeta = const VerificationMeta(
    'countryId',
  );
  @override
  late final GeneratedColumn<String> countryId = GeneratedColumn<String>(
    'country_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _topicMeta = const VerificationMeta('topic');
  @override
  late final GeneratedColumn<String> topic = GeneratedColumn<String>(
    'topic',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _introducedAtMeta = const VerificationMeta(
    'introducedAt',
  );
  @override
  late final GeneratedColumn<DateTime> introducedAt = GeneratedColumn<DateTime>(
    'introduced_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reviewCountMeta = const VerificationMeta(
    'reviewCount',
  );
  @override
  late final GeneratedColumn<int> reviewCount = GeneratedColumn<int>(
    'review_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    countryId,
    topic,
    difficulty,
    state,
    due,
    introducedAt,
    reviewCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('country_id')) {
      context.handle(
        _countryIdMeta,
        countryId.isAcceptableOrUnknown(data['country_id']!, _countryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_countryIdMeta);
    }
    if (data.containsKey('topic')) {
      context.handle(
        _topicMeta,
        topic.isAcceptableOrUnknown(data['topic']!, _topicMeta),
      );
    } else if (isInserting) {
      context.missing(_topicMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('introduced_at')) {
      context.handle(
        _introducedAtMeta,
        introducedAt.isAcceptableOrUnknown(
          data['introduced_at']!,
          _introducedAtMeta,
        ),
      );
    }
    if (data.containsKey('review_count')) {
      context.handle(
        _reviewCountMeta,
        reviewCount.isAcceptableOrUnknown(
          data['review_count']!,
          _reviewCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MemoryCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryCard(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      countryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}country_id'],
      )!,
      topic: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}topic'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      ),
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      ),
      introducedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}introduced_at'],
      ),
      reviewCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}review_count'],
      )!,
    );
  }

  @override
  $MemoryCardsTable createAlias(String alias) {
    return $MemoryCardsTable(attachedDatabase, alias);
  }
}

class MemoryCard extends DataClass implements Insertable<MemoryCard> {
  final String id;
  final String countryId;
  final String topic;
  final String difficulty;
  final String? state;
  final DateTime? due;
  final DateTime? introducedAt;
  final int reviewCount;
  const MemoryCard({
    required this.id,
    required this.countryId,
    required this.topic,
    required this.difficulty,
    this.state,
    this.due,
    this.introducedAt,
    required this.reviewCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['country_id'] = Variable<String>(countryId);
    map['topic'] = Variable<String>(topic);
    map['difficulty'] = Variable<String>(difficulty);
    if (!nullToAbsent || state != null) {
      map['state'] = Variable<String>(state);
    }
    if (!nullToAbsent || due != null) {
      map['due'] = Variable<DateTime>(due);
    }
    if (!nullToAbsent || introducedAt != null) {
      map['introduced_at'] = Variable<DateTime>(introducedAt);
    }
    map['review_count'] = Variable<int>(reviewCount);
    return map;
  }

  MemoryCardsCompanion toCompanion(bool nullToAbsent) {
    return MemoryCardsCompanion(
      id: Value(id),
      countryId: Value(countryId),
      topic: Value(topic),
      difficulty: Value(difficulty),
      state: state == null && nullToAbsent
          ? const Value.absent()
          : Value(state),
      due: due == null && nullToAbsent ? const Value.absent() : Value(due),
      introducedAt: introducedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(introducedAt),
      reviewCount: Value(reviewCount),
    );
  }

  factory MemoryCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryCard(
      id: serializer.fromJson<String>(json['id']),
      countryId: serializer.fromJson<String>(json['countryId']),
      topic: serializer.fromJson<String>(json['topic']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      state: serializer.fromJson<String?>(json['state']),
      due: serializer.fromJson<DateTime?>(json['due']),
      introducedAt: serializer.fromJson<DateTime?>(json['introducedAt']),
      reviewCount: serializer.fromJson<int>(json['reviewCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'countryId': serializer.toJson<String>(countryId),
      'topic': serializer.toJson<String>(topic),
      'difficulty': serializer.toJson<String>(difficulty),
      'state': serializer.toJson<String?>(state),
      'due': serializer.toJson<DateTime?>(due),
      'introducedAt': serializer.toJson<DateTime?>(introducedAt),
      'reviewCount': serializer.toJson<int>(reviewCount),
    };
  }

  MemoryCard copyWith({
    String? id,
    String? countryId,
    String? topic,
    String? difficulty,
    Value<String?> state = const Value.absent(),
    Value<DateTime?> due = const Value.absent(),
    Value<DateTime?> introducedAt = const Value.absent(),
    int? reviewCount,
  }) => MemoryCard(
    id: id ?? this.id,
    countryId: countryId ?? this.countryId,
    topic: topic ?? this.topic,
    difficulty: difficulty ?? this.difficulty,
    state: state.present ? state.value : this.state,
    due: due.present ? due.value : this.due,
    introducedAt: introducedAt.present ? introducedAt.value : this.introducedAt,
    reviewCount: reviewCount ?? this.reviewCount,
  );
  MemoryCard copyWithCompanion(MemoryCardsCompanion data) {
    return MemoryCard(
      id: data.id.present ? data.id.value : this.id,
      countryId: data.countryId.present ? data.countryId.value : this.countryId,
      topic: data.topic.present ? data.topic.value : this.topic,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      state: data.state.present ? data.state.value : this.state,
      due: data.due.present ? data.due.value : this.due,
      introducedAt: data.introducedAt.present
          ? data.introducedAt.value
          : this.introducedAt,
      reviewCount: data.reviewCount.present
          ? data.reviewCount.value
          : this.reviewCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCard(')
          ..write('id: $id, ')
          ..write('countryId: $countryId, ')
          ..write('topic: $topic, ')
          ..write('difficulty: $difficulty, ')
          ..write('state: $state, ')
          ..write('due: $due, ')
          ..write('introducedAt: $introducedAt, ')
          ..write('reviewCount: $reviewCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    countryId,
    topic,
    difficulty,
    state,
    due,
    introducedAt,
    reviewCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryCard &&
          other.id == this.id &&
          other.countryId == this.countryId &&
          other.topic == this.topic &&
          other.difficulty == this.difficulty &&
          other.state == this.state &&
          other.due == this.due &&
          other.introducedAt == this.introducedAt &&
          other.reviewCount == this.reviewCount);
}

class MemoryCardsCompanion extends UpdateCompanion<MemoryCard> {
  final Value<String> id;
  final Value<String> countryId;
  final Value<String> topic;
  final Value<String> difficulty;
  final Value<String?> state;
  final Value<DateTime?> due;
  final Value<DateTime?> introducedAt;
  final Value<int> reviewCount;
  final Value<int> rowid;
  const MemoryCardsCompanion({
    this.id = const Value.absent(),
    this.countryId = const Value.absent(),
    this.topic = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.state = const Value.absent(),
    this.due = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryCardsCompanion.insert({
    required String id,
    required String countryId,
    required String topic,
    required String difficulty,
    this.state = const Value.absent(),
    this.due = const Value.absent(),
    this.introducedAt = const Value.absent(),
    this.reviewCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       countryId = Value(countryId),
       topic = Value(topic),
       difficulty = Value(difficulty);
  static Insertable<MemoryCard> custom({
    Expression<String>? id,
    Expression<String>? countryId,
    Expression<String>? topic,
    Expression<String>? difficulty,
    Expression<String>? state,
    Expression<DateTime>? due,
    Expression<DateTime>? introducedAt,
    Expression<int>? reviewCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (countryId != null) 'country_id': countryId,
      if (topic != null) 'topic': topic,
      if (difficulty != null) 'difficulty': difficulty,
      if (state != null) 'state': state,
      if (due != null) 'due': due,
      if (introducedAt != null) 'introduced_at': introducedAt,
      if (reviewCount != null) 'review_count': reviewCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryCardsCompanion copyWith({
    Value<String>? id,
    Value<String>? countryId,
    Value<String>? topic,
    Value<String>? difficulty,
    Value<String?>? state,
    Value<DateTime?>? due,
    Value<DateTime?>? introducedAt,
    Value<int>? reviewCount,
    Value<int>? rowid,
  }) {
    return MemoryCardsCompanion(
      id: id ?? this.id,
      countryId: countryId ?? this.countryId,
      topic: topic ?? this.topic,
      difficulty: difficulty ?? this.difficulty,
      state: state ?? this.state,
      due: due ?? this.due,
      introducedAt: introducedAt ?? this.introducedAt,
      reviewCount: reviewCount ?? this.reviewCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (countryId.present) {
      map['country_id'] = Variable<String>(countryId.value);
    }
    if (topic.present) {
      map['topic'] = Variable<String>(topic.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (introducedAt.present) {
      map['introduced_at'] = Variable<DateTime>(introducedAt.value);
    }
    if (reviewCount.present) {
      map['review_count'] = Variable<int>(reviewCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryCardsCompanion(')
          ..write('id: $id, ')
          ..write('countryId: $countryId, ')
          ..write('topic: $topic, ')
          ..write('difficulty: $difficulty, ')
          ..write('state: $state, ')
          ..write('due: $due, ')
          ..write('introducedAt: $introducedAt, ')
          ..write('reviewCount: $reviewCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryReviewsTable extends MemoryReviews
    with TableInfo<$MemoryReviewsTable, MemoryReview> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _questionIndexMeta = const VerificationMeta(
    'questionIndex',
  );
  @override
  late final GeneratedColumn<int> questionIndex = GeneratedColumn<int>(
    'question_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _skillIdMeta = const VerificationMeta(
    'skillId',
  );
  @override
  late final GeneratedColumn<String> skillId = GeneratedColumn<String>(
    'skill_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES memory_cards (id)',
    ),
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<int> rating = GeneratedColumn<int>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _wasNewMeta = const VerificationMeta('wasNew');
  @override
  late final GeneratedColumn<bool> wasNew = GeneratedColumn<bool>(
    'was_new',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("was_new" IN (0, 1))',
    ),
  );
  static const VerificationMeta _appliedMeta = const VerificationMeta(
    'applied',
  );
  @override
  late final GeneratedColumn<bool> applied = GeneratedColumn<bool>(
    'applied',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("applied" IN (0, 1))',
    ),
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewLogMeta = const VerificationMeta(
    'reviewLog',
  );
  @override
  late final GeneratedColumn<String> reviewLog = GeneratedColumn<String>(
    'review_log',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    questionIndex,
    skillId,
    rating,
    reviewedAt,
    wasNew,
    applied,
    origin,
    reviewLog,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryReview> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('question_index')) {
      context.handle(
        _questionIndexMeta,
        questionIndex.isAcceptableOrUnknown(
          data['question_index']!,
          _questionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionIndexMeta);
    }
    if (data.containsKey('skill_id')) {
      context.handle(
        _skillIdMeta,
        skillId.isAcceptableOrUnknown(data['skill_id']!, _skillIdMeta),
      );
    } else if (isInserting) {
      context.missing(_skillIdMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewedAtMeta);
    }
    if (data.containsKey('was_new')) {
      context.handle(
        _wasNewMeta,
        wasNew.isAcceptableOrUnknown(data['was_new']!, _wasNewMeta),
      );
    } else if (isInserting) {
      context.missing(_wasNewMeta);
    }
    if (data.containsKey('applied')) {
      context.handle(
        _appliedMeta,
        applied.isAcceptableOrUnknown(data['applied']!, _appliedMeta),
      );
    } else if (isInserting) {
      context.missing(_appliedMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('review_log')) {
      context.handle(
        _reviewLogMeta,
        reviewLog.isAcceptableOrUnknown(data['review_log']!, _reviewLogMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId, questionIndex};
  @override
  MemoryReview map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryReview(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      questionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_index'],
      )!,
      skillId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}skill_id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rating'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      wasNew: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}was_new'],
      )!,
      applied: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}applied'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      reviewLog: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_log'],
      ),
    );
  }

  @override
  $MemoryReviewsTable createAlias(String alias) {
    return $MemoryReviewsTable(attachedDatabase, alias);
  }
}

class MemoryReview extends DataClass implements Insertable<MemoryReview> {
  final String sessionId;
  final int questionIndex;
  final String skillId;
  final int rating;
  final DateTime reviewedAt;
  final bool wasNew;
  final bool applied;
  final String origin;
  final String? reviewLog;
  const MemoryReview({
    required this.sessionId,
    required this.questionIndex,
    required this.skillId,
    required this.rating,
    required this.reviewedAt,
    required this.wasNew,
    required this.applied,
    required this.origin,
    this.reviewLog,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['question_index'] = Variable<int>(questionIndex);
    map['skill_id'] = Variable<String>(skillId);
    map['rating'] = Variable<int>(rating);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    map['was_new'] = Variable<bool>(wasNew);
    map['applied'] = Variable<bool>(applied);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || reviewLog != null) {
      map['review_log'] = Variable<String>(reviewLog);
    }
    return map;
  }

  MemoryReviewsCompanion toCompanion(bool nullToAbsent) {
    return MemoryReviewsCompanion(
      sessionId: Value(sessionId),
      questionIndex: Value(questionIndex),
      skillId: Value(skillId),
      rating: Value(rating),
      reviewedAt: Value(reviewedAt),
      wasNew: Value(wasNew),
      applied: Value(applied),
      origin: Value(origin),
      reviewLog: reviewLog == null && nullToAbsent
          ? const Value.absent()
          : Value(reviewLog),
    );
  }

  factory MemoryReview.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryReview(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      questionIndex: serializer.fromJson<int>(json['questionIndex']),
      skillId: serializer.fromJson<String>(json['skillId']),
      rating: serializer.fromJson<int>(json['rating']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      wasNew: serializer.fromJson<bool>(json['wasNew']),
      applied: serializer.fromJson<bool>(json['applied']),
      origin: serializer.fromJson<String>(json['origin']),
      reviewLog: serializer.fromJson<String?>(json['reviewLog']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'questionIndex': serializer.toJson<int>(questionIndex),
      'skillId': serializer.toJson<String>(skillId),
      'rating': serializer.toJson<int>(rating),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'wasNew': serializer.toJson<bool>(wasNew),
      'applied': serializer.toJson<bool>(applied),
      'origin': serializer.toJson<String>(origin),
      'reviewLog': serializer.toJson<String?>(reviewLog),
    };
  }

  MemoryReview copyWith({
    String? sessionId,
    int? questionIndex,
    String? skillId,
    int? rating,
    DateTime? reviewedAt,
    bool? wasNew,
    bool? applied,
    String? origin,
    Value<String?> reviewLog = const Value.absent(),
  }) => MemoryReview(
    sessionId: sessionId ?? this.sessionId,
    questionIndex: questionIndex ?? this.questionIndex,
    skillId: skillId ?? this.skillId,
    rating: rating ?? this.rating,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    wasNew: wasNew ?? this.wasNew,
    applied: applied ?? this.applied,
    origin: origin ?? this.origin,
    reviewLog: reviewLog.present ? reviewLog.value : this.reviewLog,
  );
  MemoryReview copyWithCompanion(MemoryReviewsCompanion data) {
    return MemoryReview(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      questionIndex: data.questionIndex.present
          ? data.questionIndex.value
          : this.questionIndex,
      skillId: data.skillId.present ? data.skillId.value : this.skillId,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      wasNew: data.wasNew.present ? data.wasNew.value : this.wasNew,
      applied: data.applied.present ? data.applied.value : this.applied,
      origin: data.origin.present ? data.origin.value : this.origin,
      reviewLog: data.reviewLog.present ? data.reviewLog.value : this.reviewLog,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryReview(')
          ..write('sessionId: $sessionId, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('skillId: $skillId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('wasNew: $wasNew, ')
          ..write('applied: $applied, ')
          ..write('origin: $origin, ')
          ..write('reviewLog: $reviewLog')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    questionIndex,
    skillId,
    rating,
    reviewedAt,
    wasNew,
    applied,
    origin,
    reviewLog,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryReview &&
          other.sessionId == this.sessionId &&
          other.questionIndex == this.questionIndex &&
          other.skillId == this.skillId &&
          other.rating == this.rating &&
          other.reviewedAt == this.reviewedAt &&
          other.wasNew == this.wasNew &&
          other.applied == this.applied &&
          other.origin == this.origin &&
          other.reviewLog == this.reviewLog);
}

class MemoryReviewsCompanion extends UpdateCompanion<MemoryReview> {
  final Value<String> sessionId;
  final Value<int> questionIndex;
  final Value<String> skillId;
  final Value<int> rating;
  final Value<DateTime> reviewedAt;
  final Value<bool> wasNew;
  final Value<bool> applied;
  final Value<String> origin;
  final Value<String?> reviewLog;
  final Value<int> rowid;
  const MemoryReviewsCompanion({
    this.sessionId = const Value.absent(),
    this.questionIndex = const Value.absent(),
    this.skillId = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.wasNew = const Value.absent(),
    this.applied = const Value.absent(),
    this.origin = const Value.absent(),
    this.reviewLog = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryReviewsCompanion.insert({
    required String sessionId,
    required int questionIndex,
    required String skillId,
    required int rating,
    required DateTime reviewedAt,
    required bool wasNew,
    required bool applied,
    required String origin,
    this.reviewLog = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       questionIndex = Value(questionIndex),
       skillId = Value(skillId),
       rating = Value(rating),
       reviewedAt = Value(reviewedAt),
       wasNew = Value(wasNew),
       applied = Value(applied),
       origin = Value(origin);
  static Insertable<MemoryReview> custom({
    Expression<String>? sessionId,
    Expression<int>? questionIndex,
    Expression<String>? skillId,
    Expression<int>? rating,
    Expression<DateTime>? reviewedAt,
    Expression<bool>? wasNew,
    Expression<bool>? applied,
    Expression<String>? origin,
    Expression<String>? reviewLog,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (questionIndex != null) 'question_index': questionIndex,
      if (skillId != null) 'skill_id': skillId,
      if (rating != null) 'rating': rating,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (wasNew != null) 'was_new': wasNew,
      if (applied != null) 'applied': applied,
      if (origin != null) 'origin': origin,
      if (reviewLog != null) 'review_log': reviewLog,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryReviewsCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? questionIndex,
    Value<String>? skillId,
    Value<int>? rating,
    Value<DateTime>? reviewedAt,
    Value<bool>? wasNew,
    Value<bool>? applied,
    Value<String>? origin,
    Value<String?>? reviewLog,
    Value<int>? rowid,
  }) {
    return MemoryReviewsCompanion(
      sessionId: sessionId ?? this.sessionId,
      questionIndex: questionIndex ?? this.questionIndex,
      skillId: skillId ?? this.skillId,
      rating: rating ?? this.rating,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      wasNew: wasNew ?? this.wasNew,
      applied: applied ?? this.applied,
      origin: origin ?? this.origin,
      reviewLog: reviewLog ?? this.reviewLog,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (questionIndex.present) {
      map['question_index'] = Variable<int>(questionIndex.value);
    }
    if (skillId.present) {
      map['skill_id'] = Variable<String>(skillId.value);
    }
    if (rating.present) {
      map['rating'] = Variable<int>(rating.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (wasNew.present) {
      map['was_new'] = Variable<bool>(wasNew.value);
    }
    if (applied.present) {
      map['applied'] = Variable<bool>(applied.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (reviewLog.present) {
      map['review_log'] = Variable<String>(reviewLog.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryReviewsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('skillId: $skillId, ')
          ..write('rating: $rating, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('wasNew: $wasNew, ')
          ..write('applied: $applied, ')
          ..write('origin: $origin, ')
          ..write('reviewLog: $reviewLog, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MemoryMetaTable extends MemoryMeta
    with TableInfo<$MemoryMetaTable, MemoryMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MemoryMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memory_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<MemoryMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  MemoryMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MemoryMetaData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $MemoryMetaTable createAlias(String alias) {
    return $MemoryMetaTable(attachedDatabase, alias);
  }
}

class MemoryMetaData extends DataClass implements Insertable<MemoryMetaData> {
  final String key;
  final String value;
  const MemoryMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  MemoryMetaCompanion toCompanion(bool nullToAbsent) {
    return MemoryMetaCompanion(key: Value(key), value: Value(value));
  }

  factory MemoryMetaData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MemoryMetaData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  MemoryMetaData copyWith({String? key, String? value}) =>
      MemoryMetaData(key: key ?? this.key, value: value ?? this.value);
  MemoryMetaData copyWithCompanion(MemoryMetaCompanion data) {
    return MemoryMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MemoryMetaData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MemoryMetaData &&
          other.key == this.key &&
          other.value == this.value);
}

class MemoryMetaCompanion extends UpdateCompanion<MemoryMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const MemoryMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MemoryMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<MemoryMetaData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MemoryMetaCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return MemoryMetaCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MemoryMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MapGuessesTable extends MapGuesses
    with TableInfo<$MapGuessesTable, MapGuess> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MapGuessesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sessions (id)',
    ),
  );
  static const VerificationMeta _questionIndexMeta = const VerificationMeta(
    'questionIndex',
  );
  @override
  late final GeneratedColumn<int> questionIndex = GeneratedColumn<int>(
    'question_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _guessIndexMeta = const VerificationMeta(
    'guessIndex',
  );
  @override
  late final GeneratedColumn<int> guessIndex = GeneratedColumn<int>(
    'guess_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _selectedCountryIdMeta = const VerificationMeta(
    'selectedCountryId',
  );
  @override
  late final GeneratedColumn<String> selectedCountryId =
      GeneratedColumn<String>(
        'selected_country_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _correctMeta = const VerificationMeta(
    'correct',
  );
  @override
  late final GeneratedColumn<bool> correct = GeneratedColumn<bool>(
    'correct',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("correct" IN (0, 1))',
    ),
  );
  static const VerificationMeta _assistedMeta = const VerificationMeta(
    'assisted',
  );
  @override
  late final GeneratedColumn<bool> assisted = GeneratedColumn<bool>(
    'assisted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("assisted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _guessedAtMeta = const VerificationMeta(
    'guessedAt',
  );
  @override
  late final GeneratedColumn<DateTime> guessedAt = GeneratedColumn<DateTime>(
    'guessed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sessionId,
    questionIndex,
    guessIndex,
    selectedCountryId,
    correct,
    assisted,
    guessedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'map_guesses';
  @override
  VerificationContext validateIntegrity(
    Insertable<MapGuess> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('question_index')) {
      context.handle(
        _questionIndexMeta,
        questionIndex.isAcceptableOrUnknown(
          data['question_index']!,
          _questionIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_questionIndexMeta);
    }
    if (data.containsKey('guess_index')) {
      context.handle(
        _guessIndexMeta,
        guessIndex.isAcceptableOrUnknown(data['guess_index']!, _guessIndexMeta),
      );
    } else if (isInserting) {
      context.missing(_guessIndexMeta);
    }
    if (data.containsKey('selected_country_id')) {
      context.handle(
        _selectedCountryIdMeta,
        selectedCountryId.isAcceptableOrUnknown(
          data['selected_country_id']!,
          _selectedCountryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_selectedCountryIdMeta);
    }
    if (data.containsKey('correct')) {
      context.handle(
        _correctMeta,
        correct.isAcceptableOrUnknown(data['correct']!, _correctMeta),
      );
    } else if (isInserting) {
      context.missing(_correctMeta);
    }
    if (data.containsKey('assisted')) {
      context.handle(
        _assistedMeta,
        assisted.isAcceptableOrUnknown(data['assisted']!, _assistedMeta),
      );
    }
    if (data.containsKey('guessed_at')) {
      context.handle(
        _guessedAtMeta,
        guessedAt.isAcceptableOrUnknown(data['guessed_at']!, _guessedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_guessedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    sessionId,
    questionIndex,
    guessIndex,
  };
  @override
  MapGuess map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MapGuess(
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      questionIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}question_index'],
      )!,
      guessIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}guess_index'],
      )!,
      selectedCountryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_country_id'],
      )!,
      correct: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}correct'],
      )!,
      assisted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}assisted'],
      )!,
      guessedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}guessed_at'],
      )!,
    );
  }

  @override
  $MapGuessesTable createAlias(String alias) {
    return $MapGuessesTable(attachedDatabase, alias);
  }
}

class MapGuess extends DataClass implements Insertable<MapGuess> {
  final String sessionId;
  final int questionIndex;
  final int guessIndex;
  final String selectedCountryId;
  final bool correct;
  final bool assisted;
  final DateTime guessedAt;
  const MapGuess({
    required this.sessionId,
    required this.questionIndex,
    required this.guessIndex,
    required this.selectedCountryId,
    required this.correct,
    required this.assisted,
    required this.guessedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['question_index'] = Variable<int>(questionIndex);
    map['guess_index'] = Variable<int>(guessIndex);
    map['selected_country_id'] = Variable<String>(selectedCountryId);
    map['correct'] = Variable<bool>(correct);
    map['assisted'] = Variable<bool>(assisted);
    map['guessed_at'] = Variable<DateTime>(guessedAt);
    return map;
  }

  MapGuessesCompanion toCompanion(bool nullToAbsent) {
    return MapGuessesCompanion(
      sessionId: Value(sessionId),
      questionIndex: Value(questionIndex),
      guessIndex: Value(guessIndex),
      selectedCountryId: Value(selectedCountryId),
      correct: Value(correct),
      assisted: Value(assisted),
      guessedAt: Value(guessedAt),
    );
  }

  factory MapGuess.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MapGuess(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      questionIndex: serializer.fromJson<int>(json['questionIndex']),
      guessIndex: serializer.fromJson<int>(json['guessIndex']),
      selectedCountryId: serializer.fromJson<String>(json['selectedCountryId']),
      correct: serializer.fromJson<bool>(json['correct']),
      assisted: serializer.fromJson<bool>(json['assisted']),
      guessedAt: serializer.fromJson<DateTime>(json['guessedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'questionIndex': serializer.toJson<int>(questionIndex),
      'guessIndex': serializer.toJson<int>(guessIndex),
      'selectedCountryId': serializer.toJson<String>(selectedCountryId),
      'correct': serializer.toJson<bool>(correct),
      'assisted': serializer.toJson<bool>(assisted),
      'guessedAt': serializer.toJson<DateTime>(guessedAt),
    };
  }

  MapGuess copyWith({
    String? sessionId,
    int? questionIndex,
    int? guessIndex,
    String? selectedCountryId,
    bool? correct,
    bool? assisted,
    DateTime? guessedAt,
  }) => MapGuess(
    sessionId: sessionId ?? this.sessionId,
    questionIndex: questionIndex ?? this.questionIndex,
    guessIndex: guessIndex ?? this.guessIndex,
    selectedCountryId: selectedCountryId ?? this.selectedCountryId,
    correct: correct ?? this.correct,
    assisted: assisted ?? this.assisted,
    guessedAt: guessedAt ?? this.guessedAt,
  );
  MapGuess copyWithCompanion(MapGuessesCompanion data) {
    return MapGuess(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      questionIndex: data.questionIndex.present
          ? data.questionIndex.value
          : this.questionIndex,
      guessIndex: data.guessIndex.present
          ? data.guessIndex.value
          : this.guessIndex,
      selectedCountryId: data.selectedCountryId.present
          ? data.selectedCountryId.value
          : this.selectedCountryId,
      correct: data.correct.present ? data.correct.value : this.correct,
      assisted: data.assisted.present ? data.assisted.value : this.assisted,
      guessedAt: data.guessedAt.present ? data.guessedAt.value : this.guessedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MapGuess(')
          ..write('sessionId: $sessionId, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('guessIndex: $guessIndex, ')
          ..write('selectedCountryId: $selectedCountryId, ')
          ..write('correct: $correct, ')
          ..write('assisted: $assisted, ')
          ..write('guessedAt: $guessedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sessionId,
    questionIndex,
    guessIndex,
    selectedCountryId,
    correct,
    assisted,
    guessedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MapGuess &&
          other.sessionId == this.sessionId &&
          other.questionIndex == this.questionIndex &&
          other.guessIndex == this.guessIndex &&
          other.selectedCountryId == this.selectedCountryId &&
          other.correct == this.correct &&
          other.assisted == this.assisted &&
          other.guessedAt == this.guessedAt);
}

class MapGuessesCompanion extends UpdateCompanion<MapGuess> {
  final Value<String> sessionId;
  final Value<int> questionIndex;
  final Value<int> guessIndex;
  final Value<String> selectedCountryId;
  final Value<bool> correct;
  final Value<bool> assisted;
  final Value<DateTime> guessedAt;
  final Value<int> rowid;
  const MapGuessesCompanion({
    this.sessionId = const Value.absent(),
    this.questionIndex = const Value.absent(),
    this.guessIndex = const Value.absent(),
    this.selectedCountryId = const Value.absent(),
    this.correct = const Value.absent(),
    this.assisted = const Value.absent(),
    this.guessedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MapGuessesCompanion.insert({
    required String sessionId,
    required int questionIndex,
    required int guessIndex,
    required String selectedCountryId,
    required bool correct,
    this.assisted = const Value.absent(),
    required DateTime guessedAt,
    this.rowid = const Value.absent(),
  }) : sessionId = Value(sessionId),
       questionIndex = Value(questionIndex),
       guessIndex = Value(guessIndex),
       selectedCountryId = Value(selectedCountryId),
       correct = Value(correct),
       guessedAt = Value(guessedAt);
  static Insertable<MapGuess> custom({
    Expression<String>? sessionId,
    Expression<int>? questionIndex,
    Expression<int>? guessIndex,
    Expression<String>? selectedCountryId,
    Expression<bool>? correct,
    Expression<bool>? assisted,
    Expression<DateTime>? guessedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (questionIndex != null) 'question_index': questionIndex,
      if (guessIndex != null) 'guess_index': guessIndex,
      if (selectedCountryId != null) 'selected_country_id': selectedCountryId,
      if (correct != null) 'correct': correct,
      if (assisted != null) 'assisted': assisted,
      if (guessedAt != null) 'guessed_at': guessedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MapGuessesCompanion copyWith({
    Value<String>? sessionId,
    Value<int>? questionIndex,
    Value<int>? guessIndex,
    Value<String>? selectedCountryId,
    Value<bool>? correct,
    Value<bool>? assisted,
    Value<DateTime>? guessedAt,
    Value<int>? rowid,
  }) {
    return MapGuessesCompanion(
      sessionId: sessionId ?? this.sessionId,
      questionIndex: questionIndex ?? this.questionIndex,
      guessIndex: guessIndex ?? this.guessIndex,
      selectedCountryId: selectedCountryId ?? this.selectedCountryId,
      correct: correct ?? this.correct,
      assisted: assisted ?? this.assisted,
      guessedAt: guessedAt ?? this.guessedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (questionIndex.present) {
      map['question_index'] = Variable<int>(questionIndex.value);
    }
    if (guessIndex.present) {
      map['guess_index'] = Variable<int>(guessIndex.value);
    }
    if (selectedCountryId.present) {
      map['selected_country_id'] = Variable<String>(selectedCountryId.value);
    }
    if (correct.present) {
      map['correct'] = Variable<bool>(correct.value);
    }
    if (assisted.present) {
      map['assisted'] = Variable<bool>(assisted.value);
    }
    if (guessedAt.present) {
      map['guessed_at'] = Variable<DateTime>(guessedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MapGuessesCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('questionIndex: $questionIndex, ')
          ..write('guessIndex: $guessIndex, ')
          ..write('selectedCountryId: $selectedCountryId, ')
          ..write('correct: $correct, ')
          ..write('assisted: $assisted, ')
          ..write('guessedAt: $guessedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SessionsTable sessions = $SessionsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $MemoryCardsTable memoryCards = $MemoryCardsTable(this);
  late final $MemoryReviewsTable memoryReviews = $MemoryReviewsTable(this);
  late final $MemoryMetaTable memoryMeta = $MemoryMetaTable(this);
  late final $MapGuessesTable mapGuesses = $MapGuessesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sessions,
    attempts,
    memoryCards,
    memoryReviews,
    memoryMeta,
    mapGuesses,
  ];
}

typedef $$SessionsTableCreateCompanionBuilder = SessionsCompanion Function({
  required String id,
  required String countryIds,
  Value<int> currentIndex,
  required DateTime createdAt,
  Value<DateTime?> completedAt,
  Value<String> topic,
  Value<String> difficulty,
  Value<String> questionData,
  Value<String> contentVersion,
  Value<int> rowid,
});
typedef $$SessionsTableUpdateCompanionBuilder = SessionsCompanion Function({
  Value<String> id,
  Value<String> countryIds,
  Value<int> currentIndex,
  Value<DateTime> createdAt,
  Value<DateTime?> completedAt,
  Value<String> topic,
  Value<String> difficulty,
  Value<String> questionData,
  Value<String> contentVersion,
  Value<int> rowid,
});

final class $$SessionsTableReferences
    extends BaseReferences<_$AppDatabase, $SessionsTable, Session> {
  $$SessionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AttemptsTable, List<Attempt>> _attemptsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.attempts,
    aliasName: 'sessions__id__attempts__session_id',
  );

  $$AttemptsTableProcessedTableManager get attemptsRefs {
    final manager = $$AttemptsTableTableManager(
      $_db,
      $_db.attempts,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_attemptsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MemoryReviewsTable, List<MemoryReview>>
  _memoryReviewsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.memoryReviews,
    aliasName: 'sessions__id__memory_reviews__session_id',
  );

  $$MemoryReviewsTableProcessedTableManager get memoryReviewsRefs {
    final manager = $$MemoryReviewsTableTableManager(
      $_db,
      $_db.memoryReviews,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_memoryReviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MapGuessesTable, List<MapGuess>>
  _mapGuessesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mapGuesses,
    aliasName: 'sessions__id__map_guesses__session_id',
  );

  $$MapGuessesTableProcessedTableManager get mapGuessesRefs {
    final manager = $$MapGuessesTableTableManager(
      $_db,
      $_db.mapGuesses,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mapGuessesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionsTableFilterComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryIds => $composableBuilder(
    column: $table.countryIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get questionData => $composableBuilder(
    column: $table.questionData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> attemptsRefs(
    Expression<bool> Function($$AttemptsTableFilterComposer f) f,
  ) {
    final $$AttemptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableFilterComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> memoryReviewsRefs(
    Expression<bool> Function($$MemoryReviewsTableFilterComposer f) f,
  ) {
    final $$MemoryReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryReviews,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryReviewsTableFilterComposer(
            $db: $db,
            $table: $db.memoryReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> mapGuessesRefs(
    Expression<bool> Function($$MapGuessesTableFilterComposer f) f,
  ) {
    final $$MapGuessesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mapGuesses,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MapGuessesTableFilterComposer(
            $db: $db,
            $table: $db.mapGuesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryIds => $composableBuilder(
    column: $table.countryIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get questionData => $composableBuilder(
    column: $table.questionData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionsTable> {
  $$SessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get countryIds => $composableBuilder(
    column: $table.countryIds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentIndex => $composableBuilder(
    column: $table.currentIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get questionData => $composableBuilder(
    column: $table.questionData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentVersion => $composableBuilder(
    column: $table.contentVersion,
    builder: (column) => column,
  );

  Expression<T> attemptsRefs<T extends Object>(
    Expression<T> Function($$AttemptsTableAnnotationComposer a) f,
  ) {
    final $$AttemptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.attempts,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AttemptsTableAnnotationComposer(
            $db: $db,
            $table: $db.attempts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> memoryReviewsRefs<T extends Object>(
    Expression<T> Function($$MemoryReviewsTableAnnotationComposer a) f,
  ) {
    final $$MemoryReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryReviews,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.memoryReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> mapGuessesRefs<T extends Object>(
    Expression<T> Function($$MapGuessesTableAnnotationComposer a) f,
  ) {
    final $$MapGuessesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mapGuesses,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MapGuessesTableAnnotationComposer(
            $db: $db,
            $table: $db.mapGuesses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionsTable,
          Session,
          $$SessionsTableFilterComposer,
          $$SessionsTableOrderingComposer,
          $$SessionsTableAnnotationComposer,
          $$SessionsTableCreateCompanionBuilder,
          $$SessionsTableUpdateCompanionBuilder,
          (Session, $$SessionsTableReferences),
          Session,
          PrefetchHooks Function({
            bool attemptsRefs,
            bool memoryReviewsRefs,
            bool mapGuessesRefs,
          })
        > {
  $$SessionsTableTableManager(_$AppDatabase db, $SessionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> countryIds = const Value.absent(),
                Value<int> currentIndex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> questionData = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion(
                id: id,
                countryIds: countryIds,
                currentIndex: currentIndex,
                createdAt: createdAt,
                completedAt: completedAt,
                topic: topic,
                difficulty: difficulty,
                questionData: questionData,
                contentVersion: contentVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String countryIds,
                Value<int> currentIndex = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String> questionData = const Value.absent(),
                Value<String> contentVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionsCompanion.insert(
                id: id,
                countryIds: countryIds,
                currentIndex: currentIndex,
                createdAt: createdAt,
                completedAt: completedAt,
                topic: topic,
                difficulty: difficulty,
                questionData: questionData,
                contentVersion: contentVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionsTable, Session>(table),
                  $$SessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                attemptsRefs = false,
                memoryReviewsRefs = false,
                mapGuessesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (attemptsRefs) db.attempts,
                    if (memoryReviewsRefs) db.memoryReviews,
                    if (mapGuessesRefs) db.mapGuesses,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (attemptsRefs)
                        await $_getPrefetchedDataByColumns<
                          Session,
                          $SessionsTable,
                          Attempt,
                          $AttemptsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._attemptsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).attemptsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (memoryReviewsRefs)
                        await $_getPrefetchedDataByColumns<
                          Session,
                          $SessionsTable,
                          MemoryReview,
                          $MemoryReviewsTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._memoryReviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).memoryReviewsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                      if (mapGuessesRefs)
                        await $_getPrefetchedDataByColumns<
                          Session,
                          $SessionsTable,
                          MapGuess,
                          $MapGuessesTable
                        >(
                          currentTable: table,
                          referencedTable: $$SessionsTableReferences
                              ._mapGuessesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionsTableReferences(
                                db,
                                table,
                                p0,
                              ).mapGuessesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'session_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionsTable,
      Session,
      $$SessionsTableFilterComposer,
      $$SessionsTableOrderingComposer,
      $$SessionsTableAnnotationComposer,
      $$SessionsTableCreateCompanionBuilder,
      $$SessionsTableUpdateCompanionBuilder,
      (Session, $$SessionsTableReferences),
      Session,
      PrefetchHooks Function({
        bool attemptsRefs,
        bool memoryReviewsRefs,
        bool mapGuessesRefs,
      })
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  required String sessionId,
  required int questionIndex,
  required String countryId,
  required String answer,
  required bool correct,
  Value<bool> typoAccepted,
  Value<String> topic,
  Value<String> difficulty,
  required DateTime answeredAt,
  Value<int> rowid,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<String> sessionId,
  Value<int> questionIndex,
  Value<String> countryId,
  Value<String> answer,
  Value<bool> correct,
  Value<bool> typoAccepted,
  Value<String> topic,
  Value<String> difficulty,
  Value<DateTime> answeredAt,
  Value<int> rowid,
});

final class $$AttemptsTableReferences
    extends BaseReferences<_$AppDatabase, $AttemptsTable, Attempt> {
  $$AttemptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('attempts__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AttemptsTableFilterComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryId => $composableBuilder(
    column: $table.countryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get typoAccepted => $composableBuilder(
    column: $table.typoAccepted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryId => $composableBuilder(
    column: $table.countryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get answer => $composableBuilder(
    column: $table.answer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get typoAccepted => $composableBuilder(
    column: $table.typoAccepted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get countryId =>
      $composableBuilder(column: $table.countryId, builder: (column) => column);

  GeneratedColumn<String> get answer =>
      $composableBuilder(column: $table.answer, builder: (column) => column);

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<bool> get typoAccepted => $composableBuilder(
    column: $table.typoAccepted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get answeredAt => $composableBuilder(
    column: $table.answeredAt,
    builder: (column) => column,
  );

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttemptsTable,
          Attempt,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (Attempt, $$AttemptsTableReferences),
          Attempt,
          PrefetchHooks Function({bool sessionId})
        > {
  $$AttemptsTableTableManager(_$AppDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> questionIndex = const Value.absent(),
                Value<String> countryId = const Value.absent(),
                Value<String> answer = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<bool> typoAccepted = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<DateTime> answeredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion(
                sessionId: sessionId,
                questionIndex: questionIndex,
                countryId: countryId,
                answer: answer,
                correct: correct,
                typoAccepted: typoAccepted,
                topic: topic,
                difficulty: difficulty,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int questionIndex,
                required String countryId,
                required String answer,
                required bool correct,
                Value<bool> typoAccepted = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                required DateTime answeredAt,
                Value<int> rowid = const Value.absent(),
              }) => AttemptsCompanion.insert(
                sessionId: sessionId,
                questionIndex: questionIndex,
                countryId: countryId,
                answer: answer,
                correct: correct,
                typoAccepted: typoAccepted,
                topic: topic,
                difficulty: difficulty,
                answeredAt: answeredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, Attempt>(table),
                  $$AttemptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$AttemptsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$AttemptsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttemptsTable,
      Attempt,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (Attempt, $$AttemptsTableReferences),
      Attempt,
      PrefetchHooks Function({bool sessionId})
    >;
typedef $$MemoryCardsTableCreateCompanionBuilder =
    MemoryCardsCompanion Function({
      required String id,
      required String countryId,
      required String topic,
      required String difficulty,
      Value<String?> state,
      Value<DateTime?> due,
      Value<DateTime?> introducedAt,
      Value<int> reviewCount,
      Value<int> rowid,
    });
typedef $$MemoryCardsTableUpdateCompanionBuilder =
    MemoryCardsCompanion Function({
      Value<String> id,
      Value<String> countryId,
      Value<String> topic,
      Value<String> difficulty,
      Value<String?> state,
      Value<DateTime?> due,
      Value<DateTime?> introducedAt,
      Value<int> reviewCount,
      Value<int> rowid,
    });

final class $$MemoryCardsTableReferences
    extends BaseReferences<_$AppDatabase, $MemoryCardsTable, MemoryCard> {
  $$MemoryCardsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MemoryReviewsTable, List<MemoryReview>>
  _memoryReviewsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.memoryReviews,
    aliasName: 'memory_cards__id__memory_reviews__skill_id',
  );

  $$MemoryReviewsTableProcessedTableManager get memoryReviewsRefs {
    final manager = $$MemoryReviewsTableTableManager(
      $_db,
      $_db.memoryReviews,
    ).filter((f) => f.skillId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_memoryReviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MemoryCardsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryCardsTable> {
  $$MemoryCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get countryId => $composableBuilder(
    column: $table.countryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> memoryReviewsRefs(
    Expression<bool> Function($$MemoryReviewsTableFilterComposer f) f,
  ) {
    final $$MemoryReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryReviews,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryReviewsTableFilterComposer(
            $db: $db,
            $table: $db.memoryReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemoryCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryCardsTable> {
  $$MemoryCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get countryId => $composableBuilder(
    column: $table.countryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get topic => $composableBuilder(
    column: $table.topic,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryCardsTable> {
  $$MemoryCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get countryId =>
      $composableBuilder(column: $table.countryId, builder: (column) => column);

  GeneratedColumn<String> get topic =>
      $composableBuilder(column: $table.topic, builder: (column) => column);

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get introducedAt => $composableBuilder(
    column: $table.introducedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reviewCount => $composableBuilder(
    column: $table.reviewCount,
    builder: (column) => column,
  );

  Expression<T> memoryReviewsRefs<T extends Object>(
    Expression<T> Function($$MemoryReviewsTableAnnotationComposer a) f,
  ) {
    final $$MemoryReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memoryReviews,
      getReferencedColumn: (t) => t.skillId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.memoryReviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MemoryCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryCardsTable,
          MemoryCard,
          $$MemoryCardsTableFilterComposer,
          $$MemoryCardsTableOrderingComposer,
          $$MemoryCardsTableAnnotationComposer,
          $$MemoryCardsTableCreateCompanionBuilder,
          $$MemoryCardsTableUpdateCompanionBuilder,
          (MemoryCard, $$MemoryCardsTableReferences),
          MemoryCard,
          PrefetchHooks Function({bool memoryReviewsRefs})
        > {
  $$MemoryCardsTableTableManager(_$AppDatabase db, $MemoryCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> countryId = const Value.absent(),
                Value<String> topic = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<String?> state = const Value.absent(),
                Value<DateTime?> due = const Value.absent(),
                Value<DateTime?> introducedAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryCardsCompanion(
                id: id,
                countryId: countryId,
                topic: topic,
                difficulty: difficulty,
                state: state,
                due: due,
                introducedAt: introducedAt,
                reviewCount: reviewCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String countryId,
                required String topic,
                required String difficulty,
                Value<String?> state = const Value.absent(),
                Value<DateTime?> due = const Value.absent(),
                Value<DateTime?> introducedAt = const Value.absent(),
                Value<int> reviewCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryCardsCompanion.insert(
                id: id,
                countryId: countryId,
                topic: topic,
                difficulty: difficulty,
                state: state,
                due: due,
                introducedAt: introducedAt,
                reviewCount: reviewCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemoryCardsTable, MemoryCard>(table),
                  $$MemoryCardsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({memoryReviewsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (memoryReviewsRefs) db.memoryReviews,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (memoryReviewsRefs)
                    await $_getPrefetchedDataByColumns<
                      MemoryCard,
                      $MemoryCardsTable,
                      MemoryReview,
                      $MemoryReviewsTable
                    >(
                      currentTable: table,
                      referencedTable: $$MemoryCardsTableReferences
                          ._memoryReviewsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MemoryCardsTableReferences(
                            db,
                            table,
                            p0,
                          ).memoryReviewsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'skill_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MemoryCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryCardsTable,
      MemoryCard,
      $$MemoryCardsTableFilterComposer,
      $$MemoryCardsTableOrderingComposer,
      $$MemoryCardsTableAnnotationComposer,
      $$MemoryCardsTableCreateCompanionBuilder,
      $$MemoryCardsTableUpdateCompanionBuilder,
      (MemoryCard, $$MemoryCardsTableReferences),
      MemoryCard,
      PrefetchHooks Function({bool memoryReviewsRefs})
    >;
typedef $$MemoryReviewsTableCreateCompanionBuilder =
    MemoryReviewsCompanion Function({
      required String sessionId,
      required int questionIndex,
      required String skillId,
      required int rating,
      required DateTime reviewedAt,
      required bool wasNew,
      required bool applied,
      required String origin,
      Value<String?> reviewLog,
      Value<int> rowid,
    });
typedef $$MemoryReviewsTableUpdateCompanionBuilder =
    MemoryReviewsCompanion Function({
      Value<String> sessionId,
      Value<int> questionIndex,
      Value<String> skillId,
      Value<int> rating,
      Value<DateTime> reviewedAt,
      Value<bool> wasNew,
      Value<bool> applied,
      Value<String> origin,
      Value<String?> reviewLog,
      Value<int> rowid,
    });

final class $$MemoryReviewsTableReferences
    extends BaseReferences<_$AppDatabase, $MemoryReviewsTable, MemoryReview> {
  $$MemoryReviewsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('memory_reviews__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MemoryCardsTable _skillIdTable(_$AppDatabase db) =>
      db.memoryCards.createAlias('memory_reviews__skill_id__memory_cards__id');

  $$MemoryCardsTableProcessedTableManager get skillId {
    final $_column = $_itemColumn<String>('skill_id')!;

    final manager = $$MemoryCardsTableTableManager(
      $_db,
      $_db.memoryCards,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_skillIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MemoryReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryReviewsTable> {
  $$MemoryReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get wasNew => $composableBuilder(
    column: $table.wasNew,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get applied => $composableBuilder(
    column: $table.applied,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewLog => $composableBuilder(
    column: $table.reviewLog,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemoryCardsTableFilterComposer get skillId {
    final $$MemoryCardsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.memoryCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryCardsTableFilterComposer(
            $db: $db,
            $table: $db.memoryCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemoryReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryReviewsTable> {
  $$MemoryReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get wasNew => $composableBuilder(
    column: $table.wasNew,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get applied => $composableBuilder(
    column: $table.applied,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewLog => $composableBuilder(
    column: $table.reviewLog,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemoryCardsTableOrderingComposer get skillId {
    final $$MemoryCardsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.memoryCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryCardsTableOrderingComposer(
            $db: $db,
            $table: $db.memoryCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemoryReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryReviewsTable> {
  $$MemoryReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get wasNew =>
      $composableBuilder(column: $table.wasNew, builder: (column) => column);

  GeneratedColumn<bool> get applied =>
      $composableBuilder(column: $table.applied, builder: (column) => column);

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get reviewLog =>
      $composableBuilder(column: $table.reviewLog, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MemoryCardsTableAnnotationComposer get skillId {
    final $$MemoryCardsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.skillId,
      referencedTable: $db.memoryCards,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MemoryCardsTableAnnotationComposer(
            $db: $db,
            $table: $db.memoryCards,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MemoryReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryReviewsTable,
          MemoryReview,
          $$MemoryReviewsTableFilterComposer,
          $$MemoryReviewsTableOrderingComposer,
          $$MemoryReviewsTableAnnotationComposer,
          $$MemoryReviewsTableCreateCompanionBuilder,
          $$MemoryReviewsTableUpdateCompanionBuilder,
          (MemoryReview, $$MemoryReviewsTableReferences),
          MemoryReview,
          PrefetchHooks Function({bool sessionId, bool skillId})
        > {
  $$MemoryReviewsTableTableManager(_$AppDatabase db, $MemoryReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> questionIndex = const Value.absent(),
                Value<String> skillId = const Value.absent(),
                Value<int> rating = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<bool> wasNew = const Value.absent(),
                Value<bool> applied = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> reviewLog = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryReviewsCompanion(
                sessionId: sessionId,
                questionIndex: questionIndex,
                skillId: skillId,
                rating: rating,
                reviewedAt: reviewedAt,
                wasNew: wasNew,
                applied: applied,
                origin: origin,
                reviewLog: reviewLog,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int questionIndex,
                required String skillId,
                required int rating,
                required DateTime reviewedAt,
                required bool wasNew,
                required bool applied,
                required String origin,
                Value<String?> reviewLog = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MemoryReviewsCompanion.insert(
                sessionId: sessionId,
                questionIndex: questionIndex,
                skillId: skillId,
                rating: rating,
                reviewedAt: reviewedAt,
                wasNew: wasNew,
                applied: applied,
                origin: origin,
                reviewLog: reviewLog,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemoryReviewsTable, MemoryReview>(table),
                  $$MemoryReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false, skillId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$MemoryReviewsTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$MemoryReviewsTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (skillId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.skillId,
                        referencedTable: $$MemoryReviewsTableReferences
                            ._skillIdTable(db),
                        referencedColumn: $$MemoryReviewsTableReferences
                            ._skillIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MemoryReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryReviewsTable,
      MemoryReview,
      $$MemoryReviewsTableFilterComposer,
      $$MemoryReviewsTableOrderingComposer,
      $$MemoryReviewsTableAnnotationComposer,
      $$MemoryReviewsTableCreateCompanionBuilder,
      $$MemoryReviewsTableUpdateCompanionBuilder,
      (MemoryReview, $$MemoryReviewsTableReferences),
      MemoryReview,
      PrefetchHooks Function({bool sessionId, bool skillId})
    >;
typedef $$MemoryMetaTableCreateCompanionBuilder = MemoryMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$MemoryMetaTableUpdateCompanionBuilder = MemoryMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$MemoryMetaTableFilterComposer
    extends Composer<_$AppDatabase, $MemoryMetaTable> {
  $$MemoryMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$MemoryMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $MemoryMetaTable> {
  $$MemoryMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MemoryMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $MemoryMetaTable> {
  $$MemoryMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$MemoryMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MemoryMetaTable,
          MemoryMetaData,
          $$MemoryMetaTableFilterComposer,
          $$MemoryMetaTableOrderingComposer,
          $$MemoryMetaTableAnnotationComposer,
          $$MemoryMetaTableCreateCompanionBuilder,
          $$MemoryMetaTableUpdateCompanionBuilder,
          (
            MemoryMetaData,
            BaseReferences<_$AppDatabase, $MemoryMetaTable, MemoryMetaData>,
          ),
          MemoryMetaData,
          PrefetchHooks Function()
        > {
  $$MemoryMetaTableTableManager(_$AppDatabase db, $MemoryMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MemoryMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MemoryMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MemoryMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => MemoryMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => MemoryMetaCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MemoryMetaTable, MemoryMetaData>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $MemoryMetaTable,
                    MemoryMetaData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MemoryMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MemoryMetaTable,
      MemoryMetaData,
      $$MemoryMetaTableFilterComposer,
      $$MemoryMetaTableOrderingComposer,
      $$MemoryMetaTableAnnotationComposer,
      $$MemoryMetaTableCreateCompanionBuilder,
      $$MemoryMetaTableUpdateCompanionBuilder,
      (
        MemoryMetaData,
        BaseReferences<_$AppDatabase, $MemoryMetaTable, MemoryMetaData>,
      ),
      MemoryMetaData,
      PrefetchHooks Function()
    >;
typedef $$MapGuessesTableCreateCompanionBuilder = MapGuessesCompanion Function({
  required String sessionId,
  required int questionIndex,
  required int guessIndex,
  required String selectedCountryId,
  required bool correct,
  Value<bool> assisted,
  required DateTime guessedAt,
  Value<int> rowid,
});
typedef $$MapGuessesTableUpdateCompanionBuilder = MapGuessesCompanion Function({
  Value<String> sessionId,
  Value<int> questionIndex,
  Value<int> guessIndex,
  Value<String> selectedCountryId,
  Value<bool> correct,
  Value<bool> assisted,
  Value<DateTime> guessedAt,
  Value<int> rowid,
});

final class $$MapGuessesTableReferences
    extends BaseReferences<_$AppDatabase, $MapGuessesTable, MapGuess> {
  $$MapGuessesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionsTable _sessionIdTable(_$AppDatabase db) =>
      db.sessions.createAlias('map_guesses__session_id__sessions__id');

  $$SessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$SessionsTableTableManager(
      $_db,
      $_db.sessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MapGuessesTableFilterComposer
    extends Composer<_$AppDatabase, $MapGuessesTable> {
  $$MapGuessesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get guessIndex => $composableBuilder(
    column: $table.guessIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get selectedCountryId => $composableBuilder(
    column: $table.selectedCountryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get assisted => $composableBuilder(
    column: $table.assisted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get guessedAt => $composableBuilder(
    column: $table.guessedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionsTableFilterComposer get sessionId {
    final $$SessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableFilterComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MapGuessesTableOrderingComposer
    extends Composer<_$AppDatabase, $MapGuessesTable> {
  $$MapGuessesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get guessIndex => $composableBuilder(
    column: $table.guessIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get selectedCountryId => $composableBuilder(
    column: $table.selectedCountryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get correct => $composableBuilder(
    column: $table.correct,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get assisted => $composableBuilder(
    column: $table.assisted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get guessedAt => $composableBuilder(
    column: $table.guessedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionsTableOrderingComposer get sessionId {
    final $$SessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableOrderingComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MapGuessesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MapGuessesTable> {
  $$MapGuessesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get questionIndex => $composableBuilder(
    column: $table.questionIndex,
    builder: (column) => column,
  );

  GeneratedColumn<int> get guessIndex => $composableBuilder(
    column: $table.guessIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get selectedCountryId => $composableBuilder(
    column: $table.selectedCountryId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get correct =>
      $composableBuilder(column: $table.correct, builder: (column) => column);

  GeneratedColumn<bool> get assisted =>
      $composableBuilder(column: $table.assisted, builder: (column) => column);

  GeneratedColumn<DateTime> get guessedAt =>
      $composableBuilder(column: $table.guessedAt, builder: (column) => column);

  $$SessionsTableAnnotationComposer get sessionId {
    final $$SessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.sessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.sessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MapGuessesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MapGuessesTable,
          MapGuess,
          $$MapGuessesTableFilterComposer,
          $$MapGuessesTableOrderingComposer,
          $$MapGuessesTableAnnotationComposer,
          $$MapGuessesTableCreateCompanionBuilder,
          $$MapGuessesTableUpdateCompanionBuilder,
          (MapGuess, $$MapGuessesTableReferences),
          MapGuess,
          PrefetchHooks Function({bool sessionId})
        > {
  $$MapGuessesTableTableManager(_$AppDatabase db, $MapGuessesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MapGuessesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MapGuessesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MapGuessesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sessionId = const Value.absent(),
                Value<int> questionIndex = const Value.absent(),
                Value<int> guessIndex = const Value.absent(),
                Value<String> selectedCountryId = const Value.absent(),
                Value<bool> correct = const Value.absent(),
                Value<bool> assisted = const Value.absent(),
                Value<DateTime> guessedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MapGuessesCompanion(
                sessionId: sessionId,
                questionIndex: questionIndex,
                guessIndex: guessIndex,
                selectedCountryId: selectedCountryId,
                correct: correct,
                assisted: assisted,
                guessedAt: guessedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sessionId,
                required int questionIndex,
                required int guessIndex,
                required String selectedCountryId,
                required bool correct,
                Value<bool> assisted = const Value.absent(),
                required DateTime guessedAt,
                Value<int> rowid = const Value.absent(),
              }) => MapGuessesCompanion.insert(
                sessionId: sessionId,
                questionIndex: questionIndex,
                guessIndex: guessIndex,
                selectedCountryId: selectedCountryId,
                correct: correct,
                assisted: assisted,
                guessedAt: guessedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MapGuessesTable, MapGuess>(table),
                  $$MapGuessesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (sessionId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionId,
                        referencedTable: $$MapGuessesTableReferences
                            ._sessionIdTable(db),
                        referencedColumn: $$MapGuessesTableReferences
                            ._sessionIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MapGuessesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MapGuessesTable,
      MapGuess,
      $$MapGuessesTableFilterComposer,
      $$MapGuessesTableOrderingComposer,
      $$MapGuessesTableAnnotationComposer,
      $$MapGuessesTableCreateCompanionBuilder,
      $$MapGuessesTableUpdateCompanionBuilder,
      (MapGuess, $$MapGuessesTableReferences),
      MapGuess,
      PrefetchHooks Function({bool sessionId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db, _db.sessions);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$MemoryCardsTableTableManager get memoryCards =>
      $$MemoryCardsTableTableManager(_db, _db.memoryCards);
  $$MemoryReviewsTableTableManager get memoryReviews =>
      $$MemoryReviewsTableTableManager(_db, _db.memoryReviews);
  $$MemoryMetaTableTableManager get memoryMeta =>
      $$MemoryMetaTableTableManager(_db, _db.memoryMeta);
  $$MapGuessesTableTableManager get mapGuesses =>
      $$MapGuessesTableTableManager(_db, _db.mapGuesses);
}
