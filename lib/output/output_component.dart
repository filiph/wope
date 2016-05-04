// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';

import 'package:angular2/angular2.dart';

import 'package:wope/markup_translator.dart';
import 'package:wope/ast_renderer.dart';
import 'dart:async';

@Component(
    selector: 'wope-output',
    templateUrl: 'output_component.html',
    styleUrls: const ['output_component.css'])
class OutputComponent {
  String latestInput = "";
  String plainOutput = "";

  List<MarkupTranslator> get translators => _translators;

  MarkupTranslator currentTranslator = _translators.first;

  update(String text, {MarkupTranslator translator}) async {
    latestInput = text;
    translator ??= currentTranslator;
    var result = await translator.translate(text);
    if (translator.outputsHtml) {
      var output = querySelector("#output");
      output.setInnerHtml(result);
    } else {
      plainOutput = result;
    }
  }

  Future setTranslator(MarkupTranslator translator) async {
    // First update, only then switch (to prevent visual glitches).
    await update(latestInput, translator: translator);
    currentTranslator = translator;
  }
}

List<MarkupTranslator> _translators = [
  new MarkupTranslator("Full"),
  new MarkupTranslator("Medium.com"),
  googlePlusTranslator,
  new MarkupTranslator("Facebook"),
  new MarkupTranslator("HTML", outputsHtml: false)
];
