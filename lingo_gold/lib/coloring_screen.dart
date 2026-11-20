import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import 'theme.dart';
import 'widgets.dart';

class ColoringCanvas extends StatefulWidget {
  final String imageAsset;

  /// صورة مرفوعة من لوحة التحكم. عند وجودها تُستخدم بدل الأصل المحلي.
  final String? imageUrl;
  final String prompt;
  final String? promptAr;
  final String? pageLabel;
  final VoidCallback onDone;

  /// تلوين موجّه: نقطة داخل المنطقة المطلوب تلوينها (0..1) واللون المطلوب.
  /// عند ضبطها يلوّن التطبيق المنطقة تلقائيًا بدل الانتظار لتلوين يدوي.
  final double? guideX;
  final double? guideY;
  final String? guideColorHex;
  final List<Offset> guideExtraPoints;
  final double zoom;

  const ColoringCanvas({
    super.key,
    required this.imageAsset,
    this.imageUrl,
    required this.prompt,
    this.promptAr,
    this.pageLabel,
    required this.onDone,
    this.guideX,
    this.guideY,
    this.guideColorHex,
    this.guideExtraPoints = const [],
    this.zoom = 1.0,
  });

  @override
  State<ColoringCanvas> createState() => _ColoringCanvasState();
}

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke(this.points, this.color, this.width);
}

class _ColoringCanvasState extends State<ColoringCanvas> {
  final List<_Stroke> _strokes = [];
  Color _color = const Color(0xFFE53935);
  double _width = 18;
  bool _showPalette = true;
  ui.Image? _guidedImage;
  bool _guideLoading = false;
  String? _guideError;

  @override
  void initState() {
    super.initState();
    if (widget.guideX != null &&
        widget.guideY != null &&
        (widget.guideColorHex ?? '').trim().isNotEmpty) {
      _buildGuidedImage();
    }
  }

  @override
  void dispose() {
    _guidedImage?.dispose();
    super.dispose();
  }

  static Color _parseHexColor(String? raw) {
    final s = (raw ?? '').trim().replaceAll('#', '');
    if (s.length == 6) {
      final v = int.tryParse(s, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    if (s.length == 8) {
      final v = int.tryParse(s, radix: 16);
      if (v != null) return Color(v);
    }
    return const Color(0xFF43A047);
  }

  Future<Uint8List> _loadImageBytes() async {
    final url = (widget.imageUrl ?? '').trim();
    if (url.isNotEmpty) {
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw StateError('HTTP ${res.statusCode}');
      return res.bodyBytes;
    }
    final data = await rootBundle.load(widget.imageAsset);
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  bool _isFillable(Uint8List pixels, int index) {
    if (index < 0 || index + 3 >= pixels.length) return false;
    if (pixels[index + 3] < 128) return false;
    final r = pixels[index];
    final g = pixels[index + 1];
    final b = pixels[index + 2];
    final luminance = 0.299 * r + 0.587 * g + 0.114 * b;
    return luminance > 200;
  }

  void _floodFill(Uint8List pixels, int width, int height, int startX, int startY, Color color) {
    if (width <= 0 || height <= 0) return;
    final sx = startX.clamp(0, width - 1);
    final sy = startY.clamp(0, height - 1);
    final start = sy * width + sx;
    if (!_isFillable(pixels, start * 4)) return;
    final fillR = (color.r * 255.0).round();
    final fillG = (color.g * 255.0).round();
    final fillB = (color.b * 255.0).round();
    final visited = Uint8List(width * height);
    final stack = <int>[start];
    while (stack.isNotEmpty) {
      final pixel = stack.removeLast();
      if (visited[pixel] != 0) continue;
      visited[pixel] = 1;
      final index = pixel * 4;
      if (!_isFillable(pixels, index)) continue;
      pixels[index] = fillR;
      pixels[index + 1] = fillG;
      pixels[index + 2] = fillB;
      pixels[index + 3] = 255;
      final x = pixel % width;
      final y = pixel ~/ width;
      if (x > 0) stack.add(pixel - 1);
      if (x < width - 1) stack.add(pixel + 1);
      if (y > 0) stack.add(pixel - width);
      if (y < height - 1) stack.add(pixel + width);
    }
  }

  Future<ui.Image> _decodePixels(Uint8List pixels, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  Future<void> _buildGuidedImage() async {
    setState(() {
      _guideLoading = true;
      _guideError = null;
    });
    try {
      final bytes = await _loadImageBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 900);
      final frame = await codec.getNextFrame();
      codec.dispose();
      final image = frame.image;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) {
        image.dispose();
        throw StateError('Could not read image pixels');
      }
      final pixels = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );
      final w = image.width;
      final h = image.height;
      final color = _parseHexColor(widget.guideColorHex);
      final points = <Offset>[
        Offset(widget.guideX!.clamp(0.0, 1.0), widget.guideY!.clamp(0.0, 1.0)),
        ...widget.guideExtraPoints.map(
          (p) => Offset(p.dx.clamp(0.0, 1.0), p.dy.clamp(0.0, 1.0)),
        ),
      ];
      for (final p in points) {
        _floodFill(pixels, w, h, (p.dx * w).floor(), (p.dy * h).floor(), color);
      }
      final done = await _decodePixels(Uint8List.fromList(pixels), w, h);
      image.dispose();
      if (!mounted) {
        done.dispose();
        return;
      }
      setState(() {
        _guidedImage?.dispose();
        _guidedImage = done;
        _guideLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _guideLoading = false;
        _guideError = '$e';
      });
    }
  }

  static const List<Color> _palette = [
    Color(0xFFE53935),
    Color(0xFFFB8C00),
    Color(0xFFFDD835),
    Color(0xFF43A047),
    Color(0xFF1E88E5),
    Color(0xFF8E24AA),
    Color(0xFF8D6E63),
    Color(0xFF212121),
  ];

  void _start(Offset p) {
    setState(() {
      _strokes.add(_Stroke([p], _color, _width));
    });
  }

  void _extend(Offset p) {
    if (_strokes.isEmpty) return;
    setState(() {
      _strokes.last.points.add(p);
    });
  }

  void _clear() {
    setState(() => _strokes.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Prompt
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kSoftGreen,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.brush_rounded, color: kPrimary),
                  const SizedBox(width: 8),
                  if (widget.pageLabel != null)
                    Pill(
                      text: widget.pageLabel!,
                      background: Colors.white,
                      foreground: kPrimaryDark,
                    ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 8),
              Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  widget.prompt,
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: kInk,
                  ),
                ),
              ),
              if (widget.promptAr != null) ...[
                const SizedBox(height: 4),
                Text(
                  widget.promptAr!,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: kMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Canvas
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kLine, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (d) => _start(d.localPosition),
                  onPanUpdate: (d) => _extend(d.localPosition),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Transform.scale(
                        scale: widget.zoom,
                        alignment: Alignment.center,
                        child: _guidedImage != null
                            ? RawImage(image: _guidedImage, fit: BoxFit.contain)
                            : (widget.imageUrl != null &&
                                    widget.imageUrl!.trim().isNotEmpty)
                                ? Image.network(
                                    widget.imageUrl!.trim(),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.image_outlined,
                                          size: 64, color: Color(0xFFCBD5E1)),
                                    ),
                                  )
                                : Image.asset(
                                    widget.imageAsset,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Center(
                                      child: Icon(Icons.image_outlined,
                                          size: 64, color: Color(0xFFCBD5E1)),
                                    ),
                                  ),
                      ),
                      if (_guideLoading)
                        const Center(child: CircularProgressIndicator()),
                      if (_guideError != null)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'تعذر التلوين التلقائي: $_guideError',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: kMuted,
                              ),
                            ),
                          ),
                        ),
                      CustomPaint(
                        painter: _PaintPainter(_strokes),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        // Palette + actions
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kLine),
          ),
          child: Column(
            children: [
              if (_showPalette)
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    for (final c in _palette)
                      GestureDetector(
                        onTap: () => setState(() => _color = c),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == c
                                  ? kPrimary
                                  : Colors.white,
                              width: _color == c ? 4 : 2,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clear,
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('مسح'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kPrimary,
                        side: const BorderSide(color: kLine),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: widget.onDone,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('تم'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaintPainter extends CustomPainter {
  final List<_Stroke> strokes;
  _PaintPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      if (s.points.isEmpty) continue;
      final paint = Paint()
        ..color = s.color.withValues(alpha: 0.75)
        ..strokeWidth = s.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
      for (var i = 1; i < s.points.length; i++) {
        path.lineTo(s.points[i].dx, s.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaintPainter oldDelegate) => true;
}
