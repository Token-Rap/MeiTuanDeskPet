"""Render the project's own dual-cat icon (no Flutter branding). Requires Pillow."""
from pathlib import Path
from PIL import Image, ImageDraw

root = Path(__file__).resolve().parents[1]
im = Image.new('RGBA', (1024, 1024))
d = ImageDraw.Draw(im)
d.rounded_rectangle((24, 24, 1000, 1000), radius=210, fill='#485B80')
for cx, cy, color, tabby in [(370, 500, '#FAF6ED', False), (680, 590, '#B4A28E', True)]:
    d.polygon([(cx-200, cy-40), (cx-200, cy-290), (cx-60, cy-175), (cx+60, cy-175), (cx+200, cy-290), (cx+200, cy-40)], fill=color)
    d.ellipse((cx-210,cy-200,cx+210,cy+220),fill=color)
    d.polygon([(cx-166,cy-130),(cx-166,cy-225),(cx-97,cy-167)],fill='#E5ADB0')
    d.polygon([(cx+166,cy-130),(cx+166,cy-225),(cx+97,cy-167)],fill='#E5ADB0')
    if tabby:
        d.polygon([(cx-35,cy-200),(cx,cy-90),(cx+35,cy-200)],fill='#5C554F')
        d.line([(cx-100,cy-175),(cx-70,cy-105)],fill='#5C554F',width=22)
        d.line([(cx+100,cy-175),(cx+70,cy-105)],fill='#5C554F',width=22)
        d.ellipse((cx-130,cy-10,cx+130,cy+180),fill='#FAF6ED')
    for x in [cx-78,cx+78]:
        d.ellipse((x-21,cy-20,x+21,cy+32),fill='#283142')
    d.polygon([(cx-24,cy+67),(cx+24,cy+67),(cx,cy+90)],fill='#D18C91')
    d.arc((cx-43,cy+72,cx,cy+115),0,170,fill='#665F63',width=9)
    d.arc((cx,cy+72,cx+43,cy+115),10,180,fill='#665F63',width=9)
path = root/'assets/icons/meituan.png'
im.resize((512,512),Image.Resampling.LANCZOS).save(path)
im.save(root/'windows/runner/resources/app_icon.ico', sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
for path in (root/'macos/Runner/Assets.xcassets/AppIcon.appiconset').glob('app_icon_*.png'):
    size = int(path.stem.split('_')[-1])
    im.resize((size,size),Image.Resampling.LANCZOS).save(path)

(root/'assets/icons/meituan.ico').write_bytes((root/'windows/runner/resources/app_icon.ico').read_bytes())
