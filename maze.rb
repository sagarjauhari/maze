require "chunky_png"

# A maze is made of several cells arranged in a lattice structure.
class Cell
  def initialize(border)
    @border = border
    @walls = [true, true, true, true] # N, E, S, W
    @visited = false
  end
  attr_accessor :border, :walls, :visited
end


# Creates an empty size X size square grid with border cells defined
def create_empty_grid(size)
  grid = []

  # create top row
  top_row = []
  size.times { top_row << Cell.new(true) }
  grid << top_row

  (size - 2).times do
    row = []
    size.times { row << Cell.new(false) }
    [0, -1].each do |i|
      row[i].border = true
    end
    grid << row
  end

  # create bottom row
  bot_row = []
  size.times { bot_row << Cell.new(true) }
  grid << bot_row
end

# For coordinates (x, y) in the grid find a random neighbor of that cell which
# is not a border cell and hasn't been visited
def rand_unvisited_neighbor(grid, x, y)
  coords = [[x-1, y], [x, y+1], [x+1, y], [x, y-1]].shuffle
  coords.reject! do |c|
    cell = grid[c[0]][c[1]]
    cell.border || cell.visited
  end
  coords.first
end

# If the cells at coord1 and coord2 are neighbors, then break the walls between
# them
def break_walls(grid, coord1, coord2)
  x1 = coord1[0]
  y1 = coord1[1]
  x2 = coord2[0]
  y2 = coord2[1]

  cell1 = grid[x1][y1]
  cell2 = grid[x2][y2]

  xx = x1 - x2
  yy = y1 - y2

  if yy == -1
    cell1.walls[1] = false
    cell2.walls[3] = false
  elsif yy == 1
    cell1.walls[3] = false
    cell2.walls[1] = false
  elsif xx == -1
    cell1.walls[2] = false
    cell2.walls[0] = false
  elsif xx == 1
    cell1.walls[0] = false
    cell2.walls[2] = false
  else
    raise "Cannot break wall of non neighbor"
  end
end

# Recursive DFS to knock down walls between cells of the grid
def build_maze!(grid, x, y)
  cell = grid[x][y]
  cell.visited = true

  if cell.border
    return
  end

  while coord = rand_unvisited_neighbor(grid, x, y)
    break_walls(grid, [x, y], coord)
    build_maze!(grid, *coord)
  end
end

# Convert walls of a cell into the int used for tileset
def walls_to_num(walls)
  num = 0
  walls.each_with_index do |wall, idx| # N, E, S, W
    num += (2 ** idx) * (wall ? 0 : 1)
  end
  num
end

# Render the grid in a PNG using a tileset
def paint(grid, tile_file, out_file)
  tileset = ChunkyPNG::Image.from_file(tile_file)
  tile_size = tileset.height

  maze_png = ChunkyPNG::Image.new(tile_size * grid.count, tile_size * grid.count)
  grid.each_with_index do |row, i|
    row.each_with_index do |cell, j|
      num = walls_to_num(cell.walls)
      tile = tileset.crop(num * tile_size, 0, tile_size, tile_size)
      maze_png.replace!(tile, tile_size * j, tile_size * i)
    end
  end

  maze_png.save(out_file)
end

grid = create_empty_grid(10)
build_maze!(grid, 1, 1)

tileset_files = [
  "black.png",
  "cave.png",
  "diagonal.png",
  "dungeon.png",
  "garden.png",
  "pillars.png",
  "tracks.png"
]

tileset_files.each do |file|
  paint(grid, "./tileset/" + file, "./out/small_" + file)
end
