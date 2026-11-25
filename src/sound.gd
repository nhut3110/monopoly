extends RefCounted

static func tone(frequency: float, duration: float, noisy := false) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = 22050
	var length := int(duration * stream.mix_rate)
	var data := PackedByteArray()
	data.resize(length)
	var random := RandomNumberGenerator.new()
	random.randomize()
	for index in range(length):
		var progress := float(index) / length
		var sample := sin(TAU * frequency * index / stream.mix_rate)
		if noisy: sample = sample * 0.25 + random.randf_range(-0.75, 0.75)
		var envelope := pow(1.0 - progress, 2.0)
		data[index] = int(clampf(sample * envelope * 38, -127, 127)) & 255
	stream.data = data
	return stream
