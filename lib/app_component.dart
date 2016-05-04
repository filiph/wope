// Copyright (c) 2016, <your name>. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

import 'package:angular2/angular2.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:html';
import 'package:wope/output/output_component.dart';

@Component(
    selector: 'my-app',
    templateUrl: 'app_component.html',
    directives: const [OutputComponent])
class AppComponent {
  final PLACEHOLDER_TEXT = "Write *markup* here.\n\n"
      "For example, you can [do this](http://google.com).";

  update(OutputComponent output, String text, [bool ignore = false]) {
    if (ignore) return;
    if (text.isEmpty) text = PLACEHOLDER_TEXT;
    output.update(text);
  }
}
