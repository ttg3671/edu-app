import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common/widgets/elevated_container.dart';
import '../../../../core/common/widgets/linear_gradient_mask.dart';

class AccountDetailsContainer extends StatelessWidget {
  final String title;
  final List<AccountDetailsModal> list;
  final bool hideTrailingIcon;
  final EdgeInsetsGeometry? itemPadding;
  const AccountDetailsContainer({
    super.key, 
    required this.title, 
    required this.list,
    this.hideTrailingIcon = false,
    this.itemPadding,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedContainer(
      padding: EdgeInsets.all(20.r),
      borderRadius: BorderRadius.circular(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
            style: Theme.of(context).textTheme.titleMedium!.copyWith(fontSize: 22.sp),
          ),
          SizedBox(height: 10.h,),

          ...List.generate(list.length, (index){
            final item = list[index];
            Widget iconWidget = item.customIcon ??
                Icon(item.icon, size: 26.sp, color: item.iconColor ?? Colors.white);
            
            if (item.useMask) {
              iconWidget = LinearGradientMask(child: iconWidget);
            }

            return InkWell(
              onTap: item.onTap,
              child: Padding(
                padding: itemPadding ?? EdgeInsets.symmetric(vertical: 10.h),
                child: Row(
                  spacing: 10.w,
                  children: [
                    iconWidget,
                    Expanded(
                      child: Text(item.title,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(fontSize: 16.sp,),
                        maxLines: 1,
                      ),
                    ),
                    const Spacer(),
                    if (!hideTrailingIcon)
                      Icon(Icons.arrow_forward_ios,size: 26.sp,color: Colors.black54,),
                  ],
                ),
              ),
            );
          })

        ],
      ),
    );
  }
}

class AccountDetailsModal{
  final IconData? icon;
  final String title;
  final VoidCallback onTap;
  final Widget? customIcon;
  final Color? iconColor;
  final bool useMask;

  AccountDetailsModal({
    this.icon, 
    required this.title,
    required this.onTap,
    this.customIcon, 
    this.iconColor,
    this.useMask = true,
  });
}
