import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BilingualText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final List<String>? args;
  final Map<String, String>? namedArgs;

  const BilingualText({
    required this.textKey,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.args,
    this.namedArgs,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      textKey.tr(args: args, namedArgs: namedArgs),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
