class Offset {
  final double dx;
  final double dy;
  const Offset(this.dx, this.dy);
  static const Offset zero = Offset(0.0, 0.0);
}

class Size {
  final double width;
  final double height;
  const Size(this.width, this.height);
  static const Size zero = Size(0.0, 0.0);
}

class PdfDocument {
  PdfDocument({List<int>? inputBytes});
  dynamic pages = _StubPages();
  Future<List<int>> save() async => [];
  void dispose() {}
}

class _StubPages {
  int count = 0;
  dynamic operator [](int index) => _StubPage();
  dynamic add() => _StubPage();
}

class _StubPage {
  dynamic createTemplate() => null;
  dynamic graphics = _StubGraphics();
  _StubSize getClientSize() => _StubSize();
}

class _StubSize {
  double width = 0;
  double height = 0;
}

class _StubGraphics {
  void drawPdfTemplate(dynamic template, dynamic location, dynamic size) {}
}
