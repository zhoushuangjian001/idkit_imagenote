import 'package:build/build.dart';
import 'package:idkit_imagenote/idkit_imagenote_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder imageSourceNoteBuilder(BuilderOptions options) =>
    LibraryBuilder(IDKitImageNoteGenerator());
