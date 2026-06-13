// Smoke test cơ bản. Các unit test chính của ứng dụng nằm ở:
//   - test/leveling_logic_test.dart       (logic EXP / lên cấp)
//   - test/models_serialization_test.dart (ORM toMap/fromMap các model)
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('môi trường test hoạt động', () {
    expect(1 + 1, 2);
  });
}
