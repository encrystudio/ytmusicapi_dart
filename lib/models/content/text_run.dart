// ignore_for_file: public_member_api_docs

sealed class TextRun {
  final String text;

  const TextRun({required this.text});

  Map<String, dynamic> asJson() => {'text': text};
}

class HyperLink extends TextRun {
  final String url;

  const HyperLink({required super.text, required this.url});

  @override
  Map<String, dynamic> asJson() => {
    ...super.asJson(),
    'type': 'hyperLink',
    'url': url,
  };
}

class PlainText extends TextRun {
  const PlainText({required super.text});

  @override
  Map<String, dynamic> asJson() => {...super.asJson(), 'type': 'plainText'};
}
