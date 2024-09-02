require 'rubygems'
require 'gosu'

WIDTH, HEIGHT = 640, 480

module ZOrder
  BACKGROUND, MIDDLE, PLAYER, UI = *0..3
end

class GameMap
  attr_accessor :width, :height, :coins, :key, :tile_set, :tiles
end

class Player
  attr_accessor :x, :y, :score, :direction, :x_vel, :y_vel, :standing, :flap1, :flap2, :current_image, :jump_count

  def initialize(player)
    @x = @y = @x_vel = @y_vel = 0
    @direction = :left
    @score = @jump_count = 0
    @player.standing, @player.flap1, @player.flap2 = Gosu::Image.load_tiles("media/red_dragon.png", 144, 128)

  end
end

def move_left player
  player.x -= player.x_vel
end

def move_right player
  player.x += player.x_vel
end

def move_up player
  player.y -= player.y_vel
end

def move_down player
  player.y += player.y_vel
end

# CODE FROM HERE ON NOT ORDITED

class Collectible
  attr_accessor :type, :x, :y, :image, :sound
end

def setup_collectible(image, x, y)

end

def draw_coin(coin)

end

def setup_player(player, game_map, x, y)
  player = Player.new()
  player.x, player.y = x, y
  player.dir = :left
  player.vy = 0 # Vertical velocity
  player.game_map = game_map
  # Load all animation frames
  player.standing, player.walk1, player.walk2, player.jump = Gosu::Image.load_tiles("media/walk_sheet.png", 72, 98)
  # This always points to the frame that is currently drawn.
  # This is set in update, and used in draw.
  player.current_image = player.standing
  player
end

def draw_player(player)
  # Flip vertically when facing to the left.
  if player.dir == :left
    offs_x = -25
    factor = 1.0
  else
    offs_x = 25
    factor = -1.0
  end
  player.current_image.draw(player.x + offs_x, player.y - 49, 0, factor, 1.0)
end

# Could the object be placed at x + offs_x/y + offs_y without being stuck?
def would_fit(player, offs_x, offs_y)
  # Check at the center/top and center/bottom for game_map collisions
  not solid?(player.game_map, player.x + offs_x, player.y + offs_y) and
    not solid?(player.game_map, player.x + offs_x, player.y + offs_y - 45)
end

def update_player(player, move_x)
 
end

def jump(player)

end

def collect_coins(player, coins)

end

def setup_game_map(filename)
  game_map = GameMap.new

  game_map.tile_set = Gosu::Image.load_tiles("media/spritesheet.png", 40, 40, :tileable => true)

  coin_img = Gosu::Image.new("media/coin.png")
  game_map.coins = []

  lines = File.readlines(filename).map { |line| line.chomp }
  game_map.height = lines.size
  game_map.width = lines[0].size
  game_map.tiles = Array.new(game_map.width) do |x|
    Array.new(game_map.height) do |y|
      case lines[y][x, 1]
      when '"'
        Tiles::Grass
      when '#'
        Tiles::Earth
      when 'x'
        game_map.coins.push(setup_coin(coin_img, x * 40 + 20, y * 40 + 20))
        nil
      else
        nil
      end
    end
  end
  game_map
end

def draw_game_map(game_map)
  # Very primitive drawing function:
  # Draws all the tiles, some off-screen, some on-screen.
  game_map.height.times do |y|
    game_map.width.times do |x|
      tile = game_map.tiles[x][y]
      if tile
        game_map.tile_set[tile].draw(x * 40, y * 40, 0)
      end
    end
  end
  game_map.coins.each { |c| draw_coin(c) }
end

# Solid at a given pixel position?
def solid?(game_map, x, y)
  y < 0 || game_map.tiles[x / 40][y / 40]
end

class HuntingDragon < (Example rescue Gosu::Window)
  def initialize
    super WIDTH, HEIGHT

    self.caption = "Trial Game"

    @background = Gosu::Image.new("media/Mountains.png", :tileable => true)
    @game_map = setup_game_map("media/trial_game_map.txt")
    @player = setup_player(@player, @game_map, 400, 100)
    # The scrolling position is stored as top left corner of the screen.
    @camera_x = @camera_y = 0
  end

  def update
    move_x = 0
    move_x -= 5 if Gosu.button_down? Gosu::KB_LEFT
    move_x += 5 if Gosu.button_down? Gosu::KB_RIGHT
    update_player(@player, move_x)
    collect_coins(@player, @game_map.coins)
    # Scrolling follows player
    @camera_x = [[@player.x - WIDTH / 2, 0].max, @game_map.width * 40 - WIDTH].min
    @camera_y = [[@player.y - HEIGHT / 2, 0].max, @game_map.height * 40 - HEIGHT].min
  end

  def draw
    @background.draw 0, 0, 0, 0.5, 0.5
    Gosu.translate(-@camera_x, -@camera_y) do
      draw_game_map(@game_map)
      draw_player(@player)
    end
  end

  def button_down(id)
    case id
    when Gosu::KB_UP
      jump(@player)
    when Gosu::KB_ESCAPE
      close
    else
      super
    end
  end

end

window = HuntingDragon.new
window.show