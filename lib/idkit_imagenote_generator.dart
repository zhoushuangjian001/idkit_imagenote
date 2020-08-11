import 'dart:io';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart'; // BuildStep
import 'package:idkit_imagenote/idkit_imagenote.dart';
import 'package:source_gen/source_gen.dart';

class IDKitImageNoteGenerator extends GeneratorForAnnotation<IDKitImageNote> {
  // Code of annotation generation file.
  String _codeContent = "";
  // This pubspec.yaml Content of the document.
  String _pubSpecContent = "";
  // Instructions for annotations.
  String _explainContent =
      "// **************************************************************************\n"
      "// 如果有图像资源需要更新，请先执行清除指令如下:\n"
      "// flutter packages pub run build_runner clean \n"
      "// \n"
      "// 然后，执行命令重新生成注解文件，执行指令如下:\n"
      "// flutter packages pub run build_runner build --delete-conflicting-outputs \n"
      "// **************************************************************************\n";

  @override
  generateForAnnotatedElement(
      Element element, ConstantReader annotation, BuildStep buildStep) {
    // Get file object.
    var _pubspecFile = File("pubspec.yaml");
    // Read file contents.
    for (var item in _pubspecFile.readAsLinesSync()) {
      // Remove added image resource references.
      if (item.trim() == "assets:") continue;
      if (item.trim().toUpperCase().endsWith(".PNG")) continue;
      if (item.trim().toUpperCase().endsWith(".JPG")) continue;
      if (item.trim().toUpperCase().endsWith(".JPEG")) continue;
      if (item.trim().toUpperCase().endsWith(".SVG")) continue;
      if (item.trim().toUpperCase().endsWith(".GIF")) continue;
      if (item.trim().endsWith("/") && !item.trim().startsWith("path:"))
        continue;
      // Build content.
      _pubSpecContent = "$_pubSpecContent\n$item";
    }
    // Add assets:.
    _pubSpecContent = _pubSpecContent.trim() + "\n\n  assets:";
    // Get resource path.
    var imagePath = annotation.peek("filePath").stringValue;
    if (!imagePath.trim().endsWith("/")) {
      imagePath = imagePath.trim() + "/";
    }
    // Add resource reference.
    _pubSpecContent = "$_pubSpecContent\n" + "    - $imagePath";
    // Processing image subfile references.
    _handleImageOfSource(imagePath);
    // Gets the name of the annotation object class.
    var className = annotation.peek("className").stringValue.trim();
    // Write content to file.
    _pubspecFile.writeAsString(_pubSpecContent);

    // Return code.
    return "$_explainContent\n\n"
        "class $className {\n"
        "   $className._();\n"
        "   $_codeContent\n"
        "}";
  }

  /// Processing image subfile references
  void _handleImageOfSource(String sourcePath) {
    // Determine whether it is a folder.
    var directory = Directory(sourcePath);
    if (directory == null) throw "$sourcePath isn't a directory.";
    // Traverse the contents under the file.
    for (var file in directory.listSync()) {
      // Get file type.
      var type = file.statSync().type;
      if (type == FileSystemEntityType.directory) {
        // Folder recursion.
        _handleImageOfSource("${file.path}/");
        // Resource quick reference.
        _pubSpecContent = "$_pubSpecContent\n    - ${file.path}/";
      } else if (type == FileSystemEntityType.file) {
        // Path of file.
        var filePath = file.path;
        var keyName = filePath.trim().toUpperCase();
        // Filtering files that are not pictures.
        if (!keyName.endsWith(".PNG") &&
            !keyName.endsWith(".JPEG") &&
            !keyName.endsWith(".SVG") &&
            !keyName.endsWith(".JPG") &&
            !keyName.endsWith(".GIF")) continue;

        // Replace suffix of picture resource.
        var key = keyName
            .replaceAll(RegExp(sourcePath.toUpperCase()), '')
            .replaceAll(RegExp('.PNG'), '')
            .replaceAll(RegExp('.JPEG'), '')
            .replaceAll(RegExp('.SVG'), '')
            .replaceAll(RegExp('.JPG'), '')
            .replaceAll(RegExp('.GIF'), '');

        // Code building.
        _codeContent = "$_codeContent\t\t\t\tstatic const $key = '$filePath';";
      }
    }
  }
}
