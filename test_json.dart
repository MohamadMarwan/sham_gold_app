import 'dart:convert';

void main() {
  try {
    print("Testing empty string:");
    jsonDecode('');
  } catch(e) {
    print("Error: $e");
  }

  try {
    print("Testing bad string:");
    jsonDecode('{');
  } catch(e) {
    print("Error: $e");
  }

  try {
    print("Testing empty list:");
    [].first;
  } catch(e) {
    print("Error: $e");
  }
}
