import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';

void loadNativeLibraries() {
  if (!kIsWeb && Platform.isAndroid) {
    try {
      DynamicLibrary.open('libomp.so');
      DynamicLibrary.open('libggml-base.so');
      DynamicLibrary.open('libggml-cpu.so');
      DynamicLibrary.open('libggml.so');
      DynamicLibrary.open('libllama.so');
      if (kDebugMode) print('✅ Native libraries loaded successfully');
    } catch (e) {
      if (kDebugMode) print('❌ Error loading native libraries: $e');
    }
  }
}
