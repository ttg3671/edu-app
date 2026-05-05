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
    return GestureDetector(
      onTap: (){
        setState(() {
          isHidden = !isHidden;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.description,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16.sp
            ),
            maxLines: isHidden? 2 : 10,
          ),

          Text(isHidden? localizations?.readMore ?? "Read more" : localizations?.readLess ?? "Read less",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontSize: 16.sp,
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}
