import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../l10n/app_localizations.dart';

class ModuleDescription extends StatefulWidget {
  final String description;
  const ModuleDescription({super.key, required this.description});

  @override
  State<ModuleDescription> createState() => _ModuleDescriptionState();
}

class _ModuleDescriptionState extends State<ModuleDescription> {
  bool isHidden = true;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
        fontSize: 16.sp
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final span = TextSpan(text: widget.description, style: textStyle);
        final tp = TextPainter(
          text: span,
          maxLines: 2,
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: constraints.maxWidth);

        final isTruncated = tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: textStyle,
              maxLines: isHidden ? 2 : 100, // Show much more if expanded
              overflow: isHidden ? TextOverflow.ellipsis : TextOverflow.visible,
            ),
            if (isTruncated)
              GestureDetector(
                onTap: () {
                  setState(() {
                    isHidden = !isHidden;
                  });
                },
                child: Padding(
                  padding: EdgeInsets.only(top: 4.h),
                  child: Text(
                    isHidden ? localizations?.readMore ?? "Read more" : localizations?.readLess ?? "Read less",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 16.sp,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
