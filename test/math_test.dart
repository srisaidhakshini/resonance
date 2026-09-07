import 'package:echo/utils/math_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Math formatter test', () {
    const raw = r'''1. Key Terminology
$a - b = c
• Minuend (a): The initial quantity from which another is subtracted.
• Subtrahend (b): The quantity being taken away.
• Difference (c): The final remaining quantity

2. Regrouping (Borrowing) Method
Consider 72 - 38:
1. In the ones column: 2 - 8 cannot be done in positive whole numbers.
2. Borrow 1 ten from 7 tens, turning 7 into 6 tens.
3. The 2 ones becomes 12 ones: 12 - 8 = 4
4. In the tens column: 6 - 3 = 3
5. Result: \mathbf{72 - 38 = 34}
Check by addition: 34 + 38 = 72$''';

    final result = MathFormatter.format(raw);
    print('FORMATTED RESULT:\n$result');
    expect(result.contains(r'\mathbf'), isFalse);
    expect(result.contains(r'$'), isFalse);
  });
}
