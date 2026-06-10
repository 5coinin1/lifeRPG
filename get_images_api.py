import urllib.request
import json

weapons = [
    'Giant-Crusher', 'Dragon Greatclaw', 'Beastclaw Greathammer', 'Rusted Anchor',
    'Staff of the Guilty', 'Meteorite Staff', "Prince of Death's Staff",
    'Dragon Communion Seal', 'Frenzied Flame Seal', "Godslayer's Seal", 'Golden Order Seal',
    'Erdtree Bow', 'Serpent Bow', 'Black Knife', 'Magma Blade'
]
# "Ancient Meteoric Ore Greatsword", "Staff of the Great Beyond" are DLC and might not be in the fan API

for w in weapons:
    url = f'https://eldenring.fanapis.com/api/weapons?name={urllib.parse.quote(w)}'
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        res = urllib.request.urlopen(req).read().decode('utf-8')
        data = json.loads(res)
        if data['data']:
            print(f"{w}: {data['data'][0]['image']}")
        else:
            print(f"{w}: Not found")
    except Exception as e:
        print(f"{w}: Error {e}")
