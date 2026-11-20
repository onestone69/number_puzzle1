import 'package:material_ui/material_ui.dart';

class CustomButton extends StatelessWidget {
  final String number;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  final double borderRadius;
  final bool isOutlined;
  final bool isDraggable;

  const CustomButton({
    super.key,
    required this.number,
    required this.onPressed,
    this.backgroundColor,
    this.textColor,
    this.size = 60.0,
    this.borderRadius = 8.0,
    this.isOutlined = false,
    this.isDraggable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 텍스트 크기를 버튼 크기에 따라 자동 조절
    double fontSize = size * 0.4;

    // 내부 텍스트 위젯
    Widget textWidget = FittedBox(
      fit: BoxFit.contain,
      child: Padding(
        padding: EdgeInsets.all(size * 0.15),
        child: Text(
          number,
          style: TextStyle(
            color:
                isOutlined
                    ? (textColor ?? theme.primaryColor)
                    : (textColor ?? Colors.white),
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
      ),
    );

    // 버튼 위젯
    Widget buttonWidget = SizedBox(
      width: size,
      height: size,
      child:
          isOutlined
              ? OutlinedButton(
                onPressed: onPressed,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  side: BorderSide(
                    color: backgroundColor ?? theme.primaryColor,
                    width: size * 0.03,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: Center(child: textWidget),
              )
              : ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: backgroundColor ?? theme.primaryColor,
                  foregroundColor: textColor ?? Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(borderRadius),
                  ),
                ),
                child: Center(child: textWidget),
              ),
    );

    // 드래그 가능 여부에 따라 Draggable 또는 일반 버튼 반환
    if (isDraggable) {
      return Draggable<String>(
        data: number, // 드래그하는 데이터 (숫자)
        feedback: Material(
          color: Colors.transparent,
          elevation: 4.0,
          child: Opacity(opacity: 0.8, child: buttonWidget),
        ),
        childWhenDragging: Opacity(opacity: 0.5, child: buttonWidget),
        child: buttonWidget,
      );
    } else {
      return buttonWidget;
    }
  }
}
