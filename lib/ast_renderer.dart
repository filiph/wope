library ast_renderer;

import 'package:markdown/markdown.dart';
import 'dart:collection';
import 'dart:developer';

abstract class AstRenderer implements NodeVisitor {
  String render(List<Node> nodes);
}

class HtmlAstRenderer implements AstRenderer {
  final _renderer = new HtmlRenderer();

  @override
  String render(List<Node> nodes) => _renderer.render(nodes);

  @override
  void visitElementAfter(Element element) =>
      _renderer.visitElementAfter(element);

  @override
  bool visitElementBefore(Element element) =>
      _renderer.visitElementBefore(element);

  @override
  void visitText(Text text) => _renderer.visitText(text);
}

String unicodeSuperscript(int n) {
  final lookupTable = "⁰¹²³⁴⁵⁶⁷⁸⁹";
  final zeroCodeUnit = "0".codeUnitAt(0);

  assert(n != null);

  return n
      .toString()
      .split("")
      .map((digit) => digit.codeUnitAt(0) - zeroCodeUnit)
      .map((codeUnit) => lookupTable[codeUnit])
      .join();
}

/// Translates a parsed AST to a Google+-friendly text.
class GooglePlusRenderer implements AstRenderer {
  static final _blockTags = new RegExp('^(h1|h2|h3|h4|h5|h6|hr|p|pre)');
  static final _headlineTags = new RegExp('h[0-6]');

  /// When `true`, footnotes will be sprinkled between block-level elements.
  /// Otherwise, they will be gathered at the very end of the output.
  final footnotesBetweenBlockElements;
  StringBuffer buffer;
  Set<String> uniqueIds;
  List<String> footnotes;
  Map<String, int> _footnoteDefinitionIndexes;
  Queue<String> _encapsulationStack;
  int olIndex;

  GooglePlusRenderer({this.footnotesBetweenBlockElements: false});

  String render(List<Node> nodes) {
    buffer = new StringBuffer();
    uniqueIds = new LinkedHashSet<String>();
    footnotes = new List();
    _footnoteDefinitionIndexes = new Map();
    _encapsulationStack = new Queue();
    olIndex = 0;

    for (final node in nodes) node.accept(this);

    if (!footnotesBetweenBlockElements && footnotes.isNotEmpty) {
      buffer.write("\n\n_____\n");
      for (int i = 0; i < footnotes.length; i++) {
        buffer.write("[${i+1}]: ${footnotes[i]}\n");
      }
    }

    return buffer.toString();
  }

  void visitText(Text text) {
    buffer.write(text.text);
  }

  bool visitElementBefore(Element element) {
    // Hackish. Separate block-level elements with newlines.
    if (!buffer.isEmpty && _blockTags.firstMatch(element.tag) != null) {
      buffer.write('\n\n');
    }

    if (element.tag == "p" && _encapsulatingTag == "blockquote") {
      buffer.write("> ");
    }

    if (element.tag == "ul" || element.tag == "ol") {
      buffer.write("\n");
      olIndex = 1;
    }

    if (element.tag == "b" ||
        element.tag == "strong" ||
        _headlineTags.hasMatch(element.tag)) {
      buffer.write("*");
    }

    if (element.tag == "i" || element.tag == "em") {
      buffer.write("_");
    }

    if (element.tag == "hr") {
      buffer.write("-------------------------------");
    }

    if (element.tag == "li") {
      if (_encapsulatingTag == "ul") {
        buffer.write("\n● ");
      } else if (_encapsulatingTag == "ol") {
        buffer.write("$olIndex) ");
        olIndex++;
      }
    }

    bool shouldProcessChildren = true;

    if (element.tag == "sup" && element.attributes["data-type"] == "footnote") {
      var id = element.attributes["name"];
      footnotes.add("");
      var currentNumber = footnotes.length;
      _footnoteDefinitionIndexes[id] = currentNumber - 1;
      buffer.write(unicodeSuperscript(currentNumber));
      shouldProcessChildren = false;
    }

    if (element.tag == "dfn") {
      var id = element.attributes["name"];
      var text = element.attributes["title"];
      if (_footnoteDefinitionIndexes.containsKey(id)) {
        footnotes[_footnoteDefinitionIndexes[id]] = text;
      }
      shouldProcessChildren = false;
    }

    // TODO: table, blockquote, ul, ol, li, sup[footnote]

    if (element.isEmpty || !shouldProcessChildren) {
      return false;
    } else {
      _encapsulationStack.add(element.tag.toLowerCase());
      return true;
    }
  }

  String get _encapsulatingTag {
    if (_encapsulationStack.isEmpty) return null;
    return _encapsulationStack.last;
  }

  void visitElementAfter(Element element) {
    if (element.tag == "a") {
      // If the link is a `<http://link.com>` style, don't add a footnote.
      var textEnsurer = new OnlyTextEnsurer();
      element.children.first?.accept(textEnsurer);
      if (!textEnsurer.onlyText ||
          textEnsurer.value != element.attributes["href"]) {
        footnotes.add(element.attributes["href"]);
        buffer.write(unicodeSuperscript(footnotes.length));
      }
    }

    if (element.tag == "b" ||
        element.tag == "strong" ||
        _headlineTags.hasMatch(element.tag)) {
      buffer.write("*");
    }

    if (element.tag == "i" || element.tag == "em") {
      buffer.write("_");
    }

    assert(_encapsulationStack.last == element.tag);
    _encapsulationStack.removeLast();
  }

  /// Uniquifies an id generated from text.
  String uniquifyId(String id) {
    if (!uniqueIds.contains(id)) {
      uniqueIds.add(id);
      return id;
    }

    int suffix = 2;
    String suffixedId = '$id-$suffix';
    while (uniqueIds.contains(suffixedId)) {
      suffixedId = '$id-${suffix++}';
    }
    uniqueIds.add(suffixedId);
    return suffixedId;
  }
}

class OnlyTextEnsurer implements NodeVisitor {
  bool onlyText = true;
  String value;

  @override
  void visitElementAfter(Element element) {}

  @override
  bool visitElementBefore(Element element) {
    onlyText = false;
    return false;
  }

  @override
  void visitText(Text text) {
    value = text.text;
  }
}
