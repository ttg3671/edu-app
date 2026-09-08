import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ProfileDropdown extends StatelessWidget {
  final String title;
  final List<String> items;
  final void Function(String?) onSelected;
  final String? selectedValue;
  final String? icon;
  const ProfileDropdown({super.key, required this.title, required this.items, this.selectedValue, required this.onSelected, this.icon});

  @override
  Widget build(BuildContext context) {
    final textTheme= Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness==Brightness.light?
        Colors.black12 : Colors.white12,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w,vertical: 0.h),
      child: DropdownButtonHideUnderline(
        child: Row(
          children: [
            if(icon!=null)
              SvgPicture.asset(
                icon!,
                height: 20.h,
                width: 20.w,
              ),
            Expanded(
              child: DropdownButton2<String>(
                isExpanded: true,

                hint: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 14.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                items: items
                    .map((String item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: textTheme.titleSmall?.copyWith(
                      fontSize: 14.sp,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ))
                    .toList(),
                value: selectedValue,
                onChanged: onSelected,
                dropdownStyleData: DropdownStyleData(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
