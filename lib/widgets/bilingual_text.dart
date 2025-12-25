import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class BilingualText extends StatelessWidget {
  final String textKey;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const BilingualText({
    required this.textKey,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      textKey.tr(),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
