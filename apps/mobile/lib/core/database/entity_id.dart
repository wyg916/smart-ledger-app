import 'package:uuid/uuid.dart';

abstract interface class EntityIdGenerator {
  String next();
}

final class UuidEntityIdGenerator implements EntityIdGenerator {
  const UuidEntityIdGenerator();

  @override
  String next() => const Uuid().v4().toLowerCase();
}

final class SequenceEntityIdGenerator implements EntityIdGenerator {
  SequenceEntityIdGenerator(this._values);

  final List<String> _values;
  int _index = 0;

  @override
  String next() {
    if (_index >= _values.length) {
      throw StateError('No deterministic UUID remains');
    }
    return _values[_index++];
  }
}
