import 'package:flutter/material.dart';

class FieldMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = const Color(0xFFDDE8D9);
    canvas.drawRect(Offset.zero & size, base);

    final water = Paint()..color = const Color(0xFF9FC9D2);
    final waterPath = Path()
      ..moveTo(size.width * .70, 0)
      ..cubicTo(
        size.width * .62,
        size.height * .16,
        size.width * .88,
        size.height * .27,
        size.width * .72,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .58,
        size.height * .57,
        size.width * .83,
        size.height * .72,
        size.width * .69,
        size.height,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(waterPath, water);

    final wetland = Paint()..color = const Color(0xFFB7D7B4);
    canvas.drawOval(
      Rect.fromLTWH(
        -size.width * .18,
        size.height * .28,
        size.width * .72,
        size.height * .48,
      ),
      wetland,
    );

    final parcelPaint = Paint()
      ..color = const Color(0x3389A97F)
      ..style = PaintingStyle.fill;
    final parcelLine = Paint()
      ..color = const Color(0x66829D7A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final parcels = [
      Path()..addPolygon([
        Offset(0, size.height * .10),
        Offset(size.width * .34, size.height * .02),
        Offset(size.width * .45, size.height * .22),
        Offset(size.width * .08, size.height * .29),
      ], true),
      Path()..addPolygon([
        Offset(size.width * .03, size.height * .54),
        Offset(size.width * .42, size.height * .43),
        Offset(size.width * .55, size.height * .70),
        Offset(size.width * .12, size.height * .82),
      ], true),
      Path()..addPolygon([
        Offset(size.width * .42, size.height * .70),
        Offset(size.width * .66, size.height * .56),
        Offset(size.width * .68, size.height),
        Offset(size.width * .28, size.height),
      ], true),
    ];
    for (final parcel in parcels) {
      canvas.drawPath(parcel, parcelPaint);
      canvas.drawPath(parcel, parcelLine);
    }

    final road = Paint()
      ..color = const Color(0xFFE5D8B9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final roadEdge = Paint()
      ..color = const Color(0x99B39F79)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final accessRoad = Path()
      ..moveTo(-20, size.height * .78)
      ..cubicTo(
        size.width * .20,
        size.height * .66,
        size.width * .30,
        size.height * .48,
        size.width * .52,
        size.height * .42,
      )
      ..cubicTo(
        size.width * .69,
        size.height * .37,
        size.width * .72,
        size.height * .18,
        size.width + 20,
        size.height * .12,
      );
    canvas.drawPath(accessRoad, road);
    canvas.drawPath(accessRoad, roadEdge);

    final minorRoad = Paint()
      ..color = const Color(0x99E9DFCA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7;
    final minorRoadPath = Path()
      ..moveTo(size.width * .10, size.height)
      ..cubicTo(
        size.width * .16,
        size.height * .78,
        size.width * .22,
        size.height * .68,
        size.width * .31,
        size.height * .55,
      );
    canvas.drawPath(minorRoadPath, minorRoad);

    final grove = Paint()..color = const Color(0x5590B889);
    for (final point in [
      Offset(size.width * .12, size.height * .20),
      Offset(size.width * .20, size.height * .25),
      Offset(size.width * .31, size.height * .15),
      Offset(size.width * .16, size.height * .38),
      Offset(size.width * .37, size.height * .30),
    ]) {
      canvas.drawCircle(point, 18, grove);
      canvas.drawCircle(point.translate(10, 4), 12, grove);
    }

    final boundary = Paint()
      ..color = const Color(0x66819B7B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double x = size.width * .08; x < size.width * .60; x += 48) {
      canvas.drawLine(
        Offset(x, size.height * .05),
        Offset(x + 20, size.height * .54),
        boundary,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
