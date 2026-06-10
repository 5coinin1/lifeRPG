import urllib.request
import re

weapons = [
    'Ancient Meteoric Ore Greatsword', 'Giant-Crusher', 'Dragon Greatclaw', 'Beastclaw Greathammer', 'Rusted Anchor',
    'Staff of the Great Beyond', 'Staff of the Guilty', 'Meteorite Staff', 'Prince of Death\'s Staff',
    'Dragon Communion Seal', 'Frenzied Flame Seal', 'Godslayer\'s Seal', 'Golden Order Seal',
    'Erdtree Bow', 'Serpent Bow', 'Black Knife', 'Magma Blade'
]

for w in weapons:
    url = f'https://eldenring.wiki.fextralife.com/{urllib.parse.quote(w)}'
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        html = urllib.request.urlopen(req).read().decode('utf-8')
        m = re.search(r'\"(/file/Elden-Ring/[^\"]+?200px\.png)\"', html)
        if m:
            print(f'{w}: https://eldenring.wiki.fextralife.com{m.group(1)}')
        else:
            m2 = re.search(r'\"(/file/Elden-Ring/[^\"]+?200px\.webp)\"', html)
            if m2:
                print(f'{w}: https://eldenring.wiki.fextralife.com{m2.group(1)}')
            else:
                m3 = re.search(r'\"(/file/Elden-Ring/[^\"]+\.(?:png|webp))\"', html)
                if m3:
                    print(f'{w}: https://eldenring.wiki.fextralife.com{m3.group(1)}')
                else:
                    print(f'{w}: Not found')
    except Exception as e:
        print(f'{w}: Error {e}')
