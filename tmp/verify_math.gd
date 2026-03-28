
func verify_sprite_math():
	var sprites_per_row = 7
	var max_rows = 8
	var total_available = sprites_per_row * min(2, max_rows - 5)
	print("Total Available: ", total_available)
	for i in range(total_available):
		var row_offset = 5 + int(float(i) / sprites_per_row)
		var col_offset = i % sprites_per_row
		print("Index %d -> Row %d, Col %d" % [i, row_offset + 1, col_offset])

