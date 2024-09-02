require 'rubygems'
require 'gosu'

class Level
  attr_accessor :max_level_index, :backgrounds, :platform_set, :ground_set, :maps, :num_enemies, :fireball_freq

  def initialize()
    @max_level_index = 2
    @backgrounds = Array.new()
    @backgrounds << Gosu::Image.new("media/Mountains.png", :tileable => true)
    @backgrounds << Gosu::Image.new("media/Snow.png", :tileable => true)
    @backgrounds << Gosu::Image.new("media/Rock.png", :tileable => true)

    @platform_set = Array.new()
    @platform_set << Gosu::Image.new("media/ground_sand.png", :tileable => true)
    @platform_set << Gosu::Image.new("media/ground.png", :tileable => true)
    @platform_set << Gosu::Image.new("media/ground_rock.png", :tileable => true)

    @ground_set = Array.new()
    @ground_set << Gosu::Image.new("media/ground.png", :tileable => true)
    @ground_set << Gosu::Image.new("media/ground_rock.png", :tileable => true)
    @ground_set << Gosu::Image.new("media/ground_sand.png", :tileable => true)

    @maps = ["media/level1.txt", "media/level2.txt", "media/level3.txt"]

    @num_enemies = [4, 5, 6]
    @fireball_freq = [20, 18, 16]
  end
end

class Stage
  attr_accessor :width, :height, :coins, :mushrooms, :tile_set, :tiles

  def initialize(filename, platform, ground)
    @tile_set = [platform, ground]

    @coins = Array.new()
    @mushrooms = Array.new()

    lines = File.readlines(filename).map { |line| line.chomp }
    @height = lines.size
    @width = lines[0].size
    @tiles = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case lines[y][x, 1]
        when '"'
          Tiles::Platform
        when '#'
          Tiles::Ground
        when 'x'
          @coins.push(Coin.new(x * @tile_set[Tiles::Ground].width + @tile_set[Tiles::Ground].width / 2, y * @tile_set[Tiles::Ground].height + @tile_set[Tiles::Ground].height / 2))
          nil
        when 'r'
          @mushrooms.push(Mushroom.new(x * @tile_set[Tiles::Platform].width + @tile_set[Tiles::Platform].width / 2, y * @tile_set[Tiles::Platform].height + @tile_set[Tiles::Platform].height / 2, Mushrooms::Red))
          nil
        when 'b'
          @mushrooms.push(Mushroom.new(x * @tile_set[Tiles::Platform].width + @tile_set[Tiles::Platform].width / 2, y * @tile_set[Tiles::Platform].height + @tile_set[Tiles::Platform].height / 2, Mushrooms::Blue))
          nil
        else
          nil
        end
      end
    end
  end

  def draw
    @height.times do |y|
      @width.times do |x|
        tile = @tiles[x][y]
        if tile
          @tile_set[tile].draw(x * @tile_set[tile].width, y * @tile_set[tile].height, ZOrder::MIDDLE)
        end
      end
    end
    @coins.each { |c| draw_coin(c) }
    @mushrooms.each { |m| draw_mushroom(m) }
  end

  def draw_coin(coin)
    current_image = coin.images[Gosu.milliseconds / 150 % coin.images.length]
    current_image.draw(coin.x - current_image.width / 2, coin.y - current_image.height / 2, ZOrder::MIDDLE)
  end

  def draw_mushroom(mushroom)
    mushroom.images[mushroom.type].draw(mushroom.x - mushroom.images[mushroom.type].width / 2, mushroom.y - (@tile_set[Tiles::Platform].height - mushroom.images[mushroom.type].height), ZOrder::MIDDLE)
  end
end

class Coin
  attr_accessor :x, :y, :images, :sound

  def initialize(x, y)
    @x = x
    @y = y
    @images = Gosu::Image.load_tiles("media/spinningcoin.png", 34, 34)
    @sound = Gosu::Sample.new("media/coin.wav")
  end
end

class Mushroom
  attr_accessor :x, :y, :type, :effects, :images, :sounds

  def initialize(x, y, type)
    @x = x
    @y = y
    @type = type
    @effects = [3, -3]
    @images = Array.new()
    @images << Gosu::Image.new("media/redmushroom.png")
    @images << Gosu::Image.new("media/bluemushroom.png")
    @sounds = Array.new()
    @sounds << Gosu::Sample.new("media/collect.wav")
    @sounds << Gosu::Sample.new("media/collect2.wav")
  end
end
