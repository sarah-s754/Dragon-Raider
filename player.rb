require 'rubygems'
require 'gosu'

class Player
  attr_accessor :x, :y, :direction, :x_vel, :y_vel, :effect, :timer, :stage, :images, :current_image, :lives, :hp, :score

  def initialize(x, y, stage, lives=3, hp=100, score=0)
    @x = x
    @y = y
    @stage = stage
    @lives = lives
    @hp = hp
    @score = score
    @x_vel = 5
    @y_vel = @effect = @timer = 0
    @direction = LEFT
    @images = []
    @images[Sprite::Standing], @images[Sprite::Walk1], @images[Sprite::Walk2], @images[Sprite::Jump] = Gosu::Image.load_tiles("media/walk_sheet.png", 36, 49)
    @current_image = @images[Sprite::Standing]
  end

  def update
    if @y_vel < 0
      @current_image = @images[Sprite::Jump]
    end

    # Add 1 to player's y position to create jumping curve
    @y_vel += 1
    # Vertical movement
    if @y_vel > 0
      @y_vel.times { if would_fit(0, 1) then @y += 1 else @y_vel = 0 end }
    end
    if @y_vel < 0
      (-@y_vel).times { if would_fit(0, -1) then @y -= 1 else @y_vel = 0 end }
    end

    # Update mushroom effect
    if @timer == 1
      @effect = 0
    end
    if @timer > 0
      @timer -= 1
    end
  end

  # Directional walking, horizontal movement
  def move(direction)
    @direction = direction
    (@x_vel + @effect).times { if would_fit(direction, 0) then @x += direction end }
    @current_image = (Gosu.milliseconds / 175 % 2 == 0) ? @images[Sprite::Walk1] : @images[Sprite::Walk2]
  end

  # Allow player to start jumping if standing of ground, or start double jump if at top of jump arc
  def initiate_jump
    if solid?(@stage, @x, @y + @current_image.height / 2)
      @y_vel = -20
      @double_jump = false
    elsif !@double_jump and (@y_vel < 1 and @y_vel > -10)
      @y_vel = -20
      @double_jump = true
    end
  end

  # Check to see if collision with stage will occur
  def would_fit(offs_x, offs_y)
    not solid?(@stage, @x + offs_x, @y + offs_y + @current_image.height / 2 - 1) and
      not solid?(@stage, @x + offs_x, @y + offs_y - @current_image.height / 2) and
      not solid?(@stage, @x + offs_x, @y + offs_y + @current_image.height / 2 - @stage.tile_set[Tiles::Ground].height)
  end

  # Takes position and stage and returns true if there is a platform of ground in that position
  def solid?(stage, x, y)
    y < 0 || stage.tiles[x / stage.tile_set[Tiles::Platform].width][y / stage.tile_set[Tiles::Platform].height]
  end

  def collect_coins(coins, volume)
    coins.reject! do |c|
      if (c.x - @x).abs < @current_image.width / 2 + c.images[1].width / 2 and (c.y - @y).abs < @current_image.height / 2 + c.images[1].height / 2
        c.sound.play(volume)
        @score += 1
      end
    end
  end

  def collect_mushrooms(mushrooms, volume)
    mushrooms.reject! do |m|
      if (m.x - @x).abs < @current_image.width / 2 + m.images[m.type].width / 2 and (m.y - @y).abs < @current_image.height / 2 + m.images[m.type].height / 2
        m.sounds[m.type].play(volume)
        @effect = m.effects[m.type]
        @timer = 400
      end
    end
  end

  def draw
    offs_x = -@direction * @current_image.width / 2
    offs_y = -@current_image.height / 2
    @current_image.draw(@x + offs_x, @y + offs_y, ZOrder::PLAYER, @direction, 1.0)
  end
end
