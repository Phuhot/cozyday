import json, sys, collections
S = sys.argv[1]
d = json.load(open(f"{S}/catalog.json"))
items = d["items"]
nondef = [i for i in items if not i["isDefault"]]
def grp(name, sel):
    xs = [i for i in nondef if sel(i)]
    free = sum(1 for i in xs if i["price"] == 0)
    return name, len(xs), free, sum(i["price"] for i in xs), max([i["requiredLevel"] for i in xs] or [0])
print("Tổng món:", len(items), "mặc định:", len(items)-len(nondef), "không mặc định:", len(nondef))
print("biến thể:", sum(1 for i in items if i["variantOf"]))
rows = []
for r in ["study","bedroom","kitchen","bath","garden"]:
    rows.append(grp(f"room:{r} (không gồm sàn)", lambda i, r=r: i["room"]==r and not i["isFloor"]))
rows.append(grp("sàn (5 phòng)", lambda i: i["isFloor"]))
for s in ["species","fur","hat","glasses","neck","outfit","back"]:
    rows.append(grp(f"pet:{s} shop", lambda i, s=s: i["slot"]==s and not i["gachaOnly"]))
    rows.append(grp(f"pet:{s} gachaOnly", lambda i, s=s: i["slot"]==s and i["gachaOnly"]))
for r in rows: print("%-32s n=%3d free=%2d sum=%6d maxLv=%d" % r)
shop = [i for i in nondef if not i["gachaOnly"]]
go = [i for i in nondef if i["gachaOnly"]]
print("SHOP: n=%d sum=%d maxLv=%d" % (len(shop), sum(i["price"] for i in shop), max(i["requiredLevel"] for i in shop)))
print("shop room n=%d sum=%d; shop pet n=%d sum=%d" % (
  sum(1 for i in shop if i["room"]!="pet"), sum(i["price"] for i in shop if i["room"]!="pet"),
  sum(1 for i in shop if i["room"]=="pet"), sum(i["price"] for i in shop if i["room"]=="pet")))
print("gachaOnly by rarity:", collections.Counter(i["rarity"] for i in go), "slots:", collections.Counter(i["slot"] for i in go))
print("gachaOnly 'price' sum:", sum(i["price"] for i in go), "maxLv", max(i["requiredLevel"] for i in go))
print("POOL sizes:", {k: len(v) for k,v in d["pool"].items()})
byid = {i["id"]: i for i in items}
for k,v in d["pool"].items():
    print(" pool", k, "shop-buyable:", sum(1 for x in v if not byid[x]["gachaOnly"]), "gachaOnly:", sum(1 for x in v if byid[x]["gachaOnly"]),
          "shop price sum:", sum(byid[x]["price"] for x in v if not byid[x]["gachaOnly"]))
print("level histogram (shop):", sorted(collections.Counter(i["requiredLevel"] for i in shop).items()))
print("rarity (shop items with explicit rarity):", collections.Counter(i["rarity"] for i in shop))
print("price histogram:", sorted(collections.Counter((i["price"]//25)*25 for i in shop).items()))
print("max price shop:", max(shop, key=lambda i:i["price"])["id"], max(i["price"] for i in shop))
print("fur gacha? fur in pool:", any(byid[x]["slot"]=="fur" for v in d["pool"].values() for x in v))
print("looks:", len(d["looks"]), "sum cost", sum(l["cost"] for l in d["looks"]), "maxLv", max(l["requiredLevel"] for l in d["looks"]))
glooks=[l["id"] for l in d["looks"] if any(byid[x]["gachaOnly"] for x in l["items"])]
print("looks containing gachaOnly:", glooks)
print("foods:", d["foods"]); print("reward:", d["reward"]); print("gacha:", d["gacha"])
# list gachaOnly
for i in sorted(go, key=lambda i:(i["rarity"],i["slot"])): print("  GO", i["rarity"], i["slot"], i["id"], i["price"], i["requiredLevel"])
