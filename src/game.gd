extends RefCounted

const NAMES = ["Xuất phát", "Phố Hoa", "Cơ hội", "Phố Mây", "Thuế", "Ga Nam", "Đường Tre", "Khí vận", "Đường Nắng", "Đường Biển", "Thăm tù", "Phố Đèn", "Điện lực", "Phố Sông", "Phố Vườn", "Ga Tây", "Đồi Cam", "Cơ hội", "Đồi Gió", "Đồi Sao", "Nghỉ chân", "Phố Hồng", "Khí vận", "Phố Đào", "Phố Sen", "Ga Bắc", "Đường Xanh", "Đường Lá", "Cấp nước", "Đường Rừng", "Vào tù", "Quảng trường", "Đại lộ", "Cơ hội", "Phố Trăng", "Ga Đông", "Khí vận", "Phố Ngọc", "Thuế", "Phố Vàng"]
const GROUPS = {1: 0, 3: 0, 6: 1, 8: 1, 9: 1, 11: 2, 13: 2, 14: 2, 16: 3, 18: 3, 19: 3, 21: 4, 23: 4, 24: 4, 26: 5, 27: 5, 29: 5, 31: 6, 32: 6, 34: 6, 37: 7, 39: 7}

var rng := RandomNumberGenerator.new()
var players: Array = []
var tiles: Array = []
var current := 0
var phase := "roll"
var message := "Đến lượt bạn. Hãy tung xúc xắc!"
var last_roll := [0, 0]
var doubles := 0
var extra_turn := false
var winner := -1
var turn_count := 0
var auction: Dictionary = {}
var theme := 0
var max_turns := 0

func setup(seed_value: int = 0, player_names: Array = []) -> void:
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	players = []
	for index in range(4):
		var player_name: String = player_names[index] if player_names.size() == 4 else ["Bạn", "Linh", "Hải", "Mây"][index]
		players.append({"name": player_name, "cash": 1500, "position": 0, "jail": 0, "alive": true, "risk": rng.randf_range(0.2, 0.8)})
	tiles = []
	for index in range(40):
		var group: int = GROUPS.get(index, -1)
		var special: bool = index in [5, 12, 15, 25, 28, 35]
		var price: int = 60 + group * 40 if group >= 0 else (200 if special else 0)
		tiles.append({"name": NAMES[index], "group": group, "price": price, "rent": maxi(10, price / 5), "owner": -1, "level": 0, "mortgaged": false})
	current = 0
	phase = "roll"
	doubles = 0
	last_roll = [0, 0]
	extra_turn = false
	winner = -1
	turn_count = 0
	auction = {}
	message = "Đến lượt bạn. Hãy tung xúc xắc!"

func roll() -> void:
	if phase != "roll" or winner >= 0:
		return
	var first := rng.randi_range(1, 6)
	var second := rng.randi_range(1, 6)
	last_roll = [first, second]
	var player: Dictionary = players[current]
	var rolled_double := first == second
	if player.jail > 0:
		if rolled_double:
			player.jail = 0
			extra_turn = false
		elif player.jail < 3:
			player.jail += 1
			message = "%s chưa ra khỏi tù (%d + %d)." % [player.name, first, second]
			phase = "end"
			return
		else:
			player.jail = 0
			if not pay(current, -1, 50):
				return
		extra_turn = false
	else:
		doubles = doubles + 1 if rolled_double else 0
		extra_turn = rolled_double
		if doubles == 3:
			go_to_jail()
			return
	var old_position: int = player.position
	player.position = (old_position + first + second) % 40
	if player.position < old_position:
		player.cash += 200
	land()

func land() -> void:
	var player: Dictionary = players[current]
	var tile: Dictionary = tiles[player.position]
	message = "%s tung %d + %d, đến %s." % [player.name, last_roll[0], last_roll[1], tile.name]
	if player.position == 30:
		go_to_jail()
	elif player.position in [4, 38]:
		message += " Nộp thuế 100."
		if pay(current, -1, 100):
			phase = "end"
	elif player.position in [2, 7, 17, 22, 33, 36]:
		var amount := (150 if theme == 1 else 100) if rng.randi_range(0, 1) == 0 else (-75 if theme == 1 else -50)
		message += " Sự kiện: %s%d." % ["+" if amount > 0 else "", amount]
		if amount > 0:
			player.cash += amount
			phase = "end"
		elif pay(current, -1, -amount):
			phase = "end"
	elif tile.price > 0 and tile.owner == -1:
		phase = "buy"
		message += " Giá mua: %d." % tile.price
	elif tile.owner >= 0 and tile.owner != current:
		var fee := rent_for(player.position)
		message += " Trả %d cho %s." % [fee, players[tile.owner].name]
		if pay(current, tile.owner, fee):
			phase = "end"
	else:
		phase = "end"

func buy() -> void:
	if phase != "buy":
		return
	var tile: Dictionary = tiles[players[current].position]
	if players[current].cash >= tile.price:
		players[current].cash -= tile.price
		tile.owner = current
		message = "%s mua %s với giá %d." % [players[current].name, tile.name, tile.price]
	else:
		message = "%s không đủ tiền mua %s." % [players[current].name, tile.name]
	phase = "end"

func skip_buy() -> void:
	if phase == "buy":
		var active: Array = []
		for index in range(4):
			if players[index].alive: active.append(index)
		auction = {"tile": players[current].position, "bid": 0, "leader": -1, "turn": current, "active": active}
		phase = "auction"
		message = "Đấu giá %s. Giá tối thiểu: 10." % tiles[auction.tile].name

func auction_action(bid: bool) -> void:
	if phase != "auction": return
	var actor: int = auction.turn
	if bid and players[actor].cash >= auction.bid + 10:
		auction.bid += 10
		auction.leader = actor
	else:
		auction.active.erase(actor)
	if auction.active.is_empty() or (auction.active.size() == 1 and auction.leader == auction.active[0]):
		if auction.leader >= 0:
			players[auction.leader].cash -= auction.bid
			tiles[auction.tile].owner = auction.leader
			message = "%s thắng đấu giá %s với %d." % [players[auction.leader].name, tiles[auction.tile].name, auction.bid]
		else:
			message = "Không có người đấu giá."
		phase = "end"
		return
	var next: int = (actor + 1) % 4
	while next not in auction.active or next == auction.leader:
		next = (next + 1) % 4
	auction.turn = next
	message = "Đấu giá %s · %d · Đến %s" % [tiles[auction.tile].name, auction.bid, players[next].name]

func rent_for(index: int) -> int:
	var tile: Dictionary = tiles[index]
	if tile.owner < 0 or tile.mortgaged: return 0
	var multiplier: int = [1, 3, 7, 12, 18, 25][tile.level]
	if tile.level == 0 and owns_group(tile.owner, tile.group): multiplier = 2
	return tile.rent * multiplier

func owns_group(owner: int, group: int) -> bool:
	if group < 0: return false
	for tile in tiles:
		if tile.group == group and (tile.owner != owner or tile.mortgaged): return false
	return true

func build_cost(index: int) -> int:
	return 50 + maxi(0, tiles[index].group) * 25

func can_build(index: int, owner: int) -> bool:
	var tile: Dictionary = tiles[index]
	if tile.owner != owner or tile.level >= 5 or not owns_group(owner, tile.group): return false
	if players[owner].cash < build_cost(index): return false
	var houses := 0
	var hotels := 0
	for other in tiles:
		if other.level == 5: hotels += 1
		else: houses += other.level
		if other.group == tile.group and other.level < tile.level: return false
	return hotels < 12 if tile.level == 4 else houses < 32

func build(index: int, owner: int) -> bool:
	if not can_build(index, owner): return false
	players[owner].cash -= build_cost(index)
	tiles[index].level += 1
	message = "%s nâng cấp %s lên cấp %d." % [players[owner].name, tiles[index].name, tiles[index].level]
	return true

func mortgage(index: int, owner: int) -> bool:
	var tile: Dictionary = tiles[index]
	if tile.owner != owner: return false
	for other in tiles:
		if tile.group >= 0 and other.group == tile.group and other.level > 0: return false
	if tile.mortgaged:
		var price := ceili(tile.price * 0.55)
		if players[owner].cash < price: return false
		players[owner].cash -= price
	else:
		players[owner].cash += tile.price / 2
	tile.mortgaged = not tile.mortgaged
	return true

func sell_level(index: int, owner: int) -> bool:
	var tile: Dictionary = tiles[index]
	if tile.owner != owner or tile.level == 0: return false
	for other in tiles:
		if other.group == tile.group and other.level > tile.level: return false
	tile.level -= 1
	players[owner].cash += build_cost(index) / 2
	return true

func trade_price(index: int) -> int:
	var tile: Dictionary = tiles[index]
	var price: int = tile.price * 1.35
	if owns_group(tile.owner, tile.group): price = tile.price * 4.5
	if tile.group >= 0:
		var needed := 0
		for other in tiles:
			if other.group == tile.group and other.owner != 0: needed += 1
		if needed == 1: price = maxi(price, tile.price * 2.5)
	return price

func buy_from_bot(index: int, amount: int) -> bool:
	var tile: Dictionary = tiles[index]
	if tile.owner <= 0 or amount < trade_price(index) or players[0].cash < amount or tile.mortgaged: return false
	for other in tiles:
		if tile.group >= 0 and other.group == tile.group and other.level > 0: return false
	players[tile.owner].cash += amount
	players[0].cash -= amount
	tile.owner = 0
	message = "Giao dịch thành công: %s với giá %d." % [tile.name, amount]
	return true

func pay(debtor: int, creditor: int, amount: int) -> bool:
	var attempts := 0
	while players[debtor].cash < amount and attempts < 240:
		attempts += 1
		var sold := false
		for index in range(40):
			if sell_level(index, debtor):
				sold = true
				break
		if sold: continue
		for index in range(40):
			if tiles[index].owner == debtor and not tiles[index].mortgaged and mortgage(index, debtor):
				sold = true
				break
		if not sold: break
	if players[debtor].cash >= amount:
		players[debtor].cash -= amount
		if creditor >= 0:
			players[creditor].cash += amount
		return true
	if creditor >= 0:
		players[creditor].cash += players[debtor].cash
	players[debtor].cash = 0
	players[debtor].alive = false
	for tile in tiles:
		if tile.owner == debtor:
			tile.owner = creditor
			if creditor < 0:
				tile.level = 0
				tile.mortgaged = false
	message = "%s phá sản!" % players[debtor].name
	extra_turn = false
	phase = "end"
	var survivors: Array = []
	for index in range(4):
		if players[index].alive:
			survivors.append(index)
	if survivors.size() == 1:
		winner = survivors[0]
		message += " %s chiến thắng!" % players[winner].name
	return false

func go_to_jail() -> void:
	players[current].position = 10
	players[current].jail = 1
	doubles = 0
	extra_turn = false
	phase = "end"
	message = "%s phải vào tù!" % players[current].name

func end_turn() -> void:
	if phase != "end" or winner >= 0:
		return
	if not extra_turn or not players[current].alive:
		if current > 0 and players[current].alive: bot_invest()
		doubles = 0
		current = (current + 1) % 4
		while not players[current].alive:
			current = (current + 1) % 4
	extra_turn = false
	turn_count += 1
	if max_turns > 0 and turn_count >= max_turns:
		winner = -1
		var best := -1
		for index in range(4):
			if players[index].alive and net_worth(index) > best:
				best = net_worth(index)
				winner = index
		message = "%s thắng ván giới hạn với tổng tài sản %d." % [players[winner].name, best]
		return
	phase = "roll"
	message = "Đến lượt %s." % players[current].name

func bot_buy() -> bool:
	var player: Dictionary = players[current]
	var tile: Dictionary = tiles[player.position]
	var reserve: float = 180.0 + (1.0 - player.risk) * 320.0
	if tile.group >= 0:
		for other in tiles:
			if other.group == tile.group and other.owner == current: reserve *= 0.75
	var expected_risk := 0.0
	for first in range(1, 7):
		for second in range(1, 7):
			var position: int = (player.position + first + second) % 40
			if tiles[position].owner >= 0 and tiles[position].owner != current:
				expected_risk += rent_for(position) / 36.0
	return player.cash - tile.price >= maxf(reserve, expected_risk * 2.0)

func bot_invest() -> void:
	for index in range(40):
		var tile: Dictionary = tiles[index]
		if tile.owner == current and tile.group >= 0:
			var missing: Array = []
			for other in range(40):
				if tiles[other].group == tile.group and tiles[other].owner != current: missing.append(other)
			if missing.size() == 1:
				var target: Dictionary = tiles[missing[0]]
				var price: int = target.price * 2
				if target.owner > 0 and not target.mortgaged and not owns_group(target.owner, target.group) and players[current].cash - price > 300:
					players[target.owner].cash += price
					players[current].cash -= price
					target.owner = current
	for repeat in range(12):
		var candidate := -1
		for index in range(40):
			if can_build(index, current) and players[current].cash - build_cost(index) > 220 + (1 - players[current].risk) * 250:
				if candidate < 0 or float(tiles[index].rent) / build_cost(index) > float(tiles[candidate].rent) / build_cost(candidate): candidate = index
		if candidate < 0: break
		build(candidate, current)

func net_worth(owner: int) -> int:
	var total: int = players[owner].cash
	for index in range(40):
		var tile: Dictionary = tiles[index]
		if tile.owner == owner: total += int(tile.price * (0.5 if tile.mortgaged else 1.0)) + tile.level * build_cost(index)
	return total

func snapshot() -> Dictionary:
	return {"version": 1, "players": players.duplicate(true), "tiles": tiles.duplicate(true), "current": current, "phase": phase, "message": message, "last_roll": last_roll.duplicate(), "doubles": doubles, "extra_turn": extra_turn, "winner": winner, "turn_count": turn_count, "auction": auction.duplicate(true), "theme": theme, "max_turns": max_turns, "rng_state": str(rng.state)}

func restore(data: Dictionary) -> bool:
	if not data.has_all(["version", "players", "tiles", "current", "phase", "message", "last_roll", "doubles", "extra_turn", "winner", "turn_count", "auction", "theme", "rng_state"]): return false
	if not data.last_roll is Array or data.last_roll.size() != 2 or not data.auction is Dictionary: return false
	if not data.rng_state is String or not data.rng_state.is_valid_int(): return false
	for value in data.last_roll:
		if not value is int or value not in range(7): return false
	if data.get("version") != 1 or not data.get("players") is Array or not data.get("tiles") is Array: return false
	if data.players.size() != 4 or data.tiles.size() != 40 or data.get("current", -1) not in range(4): return false
	if data.get("phase", "") not in ["roll", "buy", "end", "auction"]: return false
	for player in data.players:
		if not player is Dictionary or not player.has_all(["name", "cash", "position", "jail", "alive", "risk"]): return false
		if player.cash < 0 or player.position not in range(40): return false
	for tile in data.tiles:
		if not tile is Dictionary or not tile.has_all(["name", "group", "price", "rent", "owner", "level", "mortgaged"]): return false
		if tile.owner not in range(-1, 4) or tile.level not in range(6): return false
	if data.phase == "auction" and not data.get("auction", {}).has_all(["tile", "bid", "leader", "turn", "active"]): return false
	players = data.players.duplicate(true)
	tiles = data.tiles.duplicate(true)
	current = data.current
	phase = data.phase
	message = data.message
	last_roll = data.last_roll.duplicate()
	doubles = data.doubles
	extra_turn = data.extra_turn
	winner = data.winner
	turn_count = data.turn_count
	auction = data.auction.duplicate(true)
	theme = data.theme
	max_turns = data.get("max_turns", 0)
	rng.state = int(data.rng_state)
	return true
