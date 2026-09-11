from PIL import Image

RES = r'c:/flutter_workspace/ecotrace/android/app/src/main/res'
SPLASH = r'c:/flutter_workspace/ecotrace/lib/assets/icons/ecotrace_icon.png'


def analyze(path):
    im = Image.open(path).convert('RGBA')
    a = im.split()[3].load()
    p = im.load()
    w, h = im.size
    # opaque bbox
    minx, miny, maxx, maxy = w, h, -1, -1
    for y in range(h):
        for x in range(w):
            if a[x, y] > 8:
                minx = min(minx, x); maxx = max(maxx, x)
                miny = min(miny, y); maxy = max(maxy, y)
    # top edge growth vs bottom edge growth (symmetric rounding check)
    def row_width(y):
        l, r = w, -1
        for x in range(w):
            if a[x, y] > 8:
                l = min(l, x); r = max(r, x)
        return r - l + 1 if r >= l else 0
    return im, a, p, (minx, miny, maxx, maxy), row_width


print('=== Adaptive foregrounds (new art) ===')
for den in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']:
    path = RES + '/mipmap-%s/ic_launcher_foreground.png' % den
    im, a, p, bbox, rw = analyze(path)
    w, h = im.size
    mid = bbox[1] + (bbox[3] - bbox[1]) // 2
    print('%s %dx%d bbox=%s corner(2,2)=%d center=%s' % (
        den, w, h, bbox, a[2, 2], p[w // 2, h // 2]))
    print('   top rows: %s' % [rw(y) for y in range(bbox[1], bbox[1] + 5)])
    print('   bottom rows: %s' % [rw(y) for y in range(bbox[3] - 4, bbox[3] + 1)])

print()
print('=== Legacy ic_launcher.png ===')
for den in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']:
    path = RES + '/mipmap-%s/ic_launcher.png' % den
    im, a, p, bbox, rw = analyze(path)
    w, h = im.size
    print('%s %dx%d bbox=%s corner(2,2)=%d center=%s' % (
        den, w, h, bbox, a[2, 2], p[w // 2, h // 2]))

print()
print('=== In-app splash icon ecotrace_icon.png ===')
im, a, p, bbox, rw = analyze(SPLASH)
w, h = im.size
print('%dx%d bbox=%s corner(2,2)=%d center=%s' % (w, h, bbox, a[2, 2], p[w // 2, h // 2]))
print('   top rows: %s' % [rw(y) for y in range(bbox[1], bbox[1] + 5)])
print('   bottom rows: %s' % [rw(y) for y in range(bbox[3] - 4, bbox[3] + 1)])

print()
print('=== Composite seam check (xxxhdpi fg over bg) ===')
bg = Image.open(RES + '/mipmap-xxxhdpi/ic_launcher_background.png').convert('RGBA')
fg = Image.open(RES + '/mipmap-xxxhdpi/ic_launcher_foreground.png').convert('RGBA')
comp = Image.alpha_composite(bg, fg)
px = comp.load()
from collections import Counter
c = Counter()
for y in range(0, 432, 2):
    for x in range(0, 432, 2):
        c[px[x, y]] += 1
print('top colors:', c.most_common(4))
comp.save(r'c:/flutter_workspace/ecotrace/tools/icon_composite_preview.png')
print('preview saved to tools/icon_composite_preview.png')