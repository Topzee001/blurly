enum BlurMode { background, person, bokeh }

extension BlurModeLabel on BlurMode {
  String get label {
    return switch (this) {
      BlurMode.background => 'Background',
      BlurMode.person => 'Person',
      BlurMode.bokeh => 'Bokeh',
    };
  }
}
