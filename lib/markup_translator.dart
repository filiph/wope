library markup_translator;

import 'package:markdown/markdown.dart';
import 'package:wope/ast_renderer.dart';
import 'dart:async';

class MarkupTranslator {
  final String name;
  final StringProcessorFunction preprocessor;
  final ParserFunction parser;
  final AstRenderer renderer;
  final StringProcessorFunction postprocessor;
  final bool outputsHtml;

  MarkupTranslator(this.name,
      {StringProcessorFunction preprocessor,
      ParserFunction parser,
      AstRenderer renderer,
      StringProcessorFunction postprocessor,
      this.outputsHtml: true})
      : preprocessor = preprocessor ?? _defaultPreprocessor,
        parser = parser ?? _defaultAstParser,
        renderer = renderer ?? _defaultRenderer,
        postprocessor = postprocessor ?? _defaultPostprocessor;

  String translateSync(String text) {
    text = preprocessor(text);
    var nodes = parser(text);
    var result = renderer.render(nodes);
    result = postprocessor(result);
    return result;
  }

  Future<String> translate(String text) {
    return new Future(() => translateSync(text));
  }
}

typedef String StringProcessorFunction(String str);
typedef List<Node> ParserFunction(String str);

StringProcessorFunction _defaultPreprocessor = (str) => str;

final _superscriptBeforePunctuation =
    new RegExp(r"(\w+)([⁰¹²³⁴⁵⁶⁷⁸⁹]+)([\.!?,:;])(\s)");
StringProcessorFunction _defaultPostprocessor = (String str) {
  return str.replaceAllMapped(_superscriptBeforePunctuation,
      (Match m) => "${m.group(1)}${m.group(3)}${m.group(2)}${m.group(4)}");
};

ParserFunction _defaultAstParser = (String str) {
  Document doc = new Document(
      inlineSyntaxes: [new FootnoteInlineSyntax()],
      blockSyntaxes: [new FootnoteDefinitionBlockSyntax()]);
  return doc.parseLines(str.split("\n"));
};
AstRenderer _defaultRenderer = new HtmlAstRenderer();

final googlePlusTranslator = new MarkupTranslator("Google+",
    renderer: new GooglePlusRenderer(), outputsHtml: false);

class FootnoteInlineSyntax extends InlineSyntax {
  FootnoteInlineSyntax() : super(r"\[\^(\w+)\]");

  @override
  bool onMatch(InlineParser parser, Match match) {
    // TODO: actually create a <a href="#id-1234>1</a>.
    var supElement = new Element("sup", [new Text("footnote")]);
    supElement.attributes["data-type"] = "footnote";
    supElement.attributes["name"] = match[1];
    parser.addNode(supElement);
    return true;
  }
}

class FootnoteDefinitionBlockSyntax extends BlockSyntax {
  final _definitionStartPattern = new RegExp(r"\[\^(\w+)\]:\s.+");
  final _definitionFullPattern = new RegExp(r"\[\^(\w+)\]:\s+(.+)$");
  RegExp get pattern => _definitionStartPattern;

  @override
  Node parse(BlockParser parser) {
    // TODO: actually create a <p> with definition
    Match match = _definitionFullPattern.firstMatch(parser.current);
    var dfnElement = new Element("dfn", [new Text("definition")]);
    dfnElement.attributes["name"] = match[1];
    dfnElement.attributes["title"] = match[2];
    parser.advance();
    return dfnElement;
  }
}
