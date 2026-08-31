import 'dart:async';

void main() async {
  try {
    print("Testing empty stream.first:");
    await Stream.empty().first;
  } catch(e) {
    print("Error1: $e");
  }

  try {
    print("Testing empty stream.last:");
    await Stream.empty().last;
  } catch(e) {
    print("Error2: $e");
  }
}
