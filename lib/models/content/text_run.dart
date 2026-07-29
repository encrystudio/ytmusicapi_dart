// ignore_for_file: public_member_api_docs

sealed class TextRun {
  final String text;

  const TextRun({required this.text});
}

class HyperLink extends TextRun {
  final String url;

  const HyperLink({required super.text, required this.url});
}

class PlainText extends TextRun {
  const PlainText({required super.text});
}
