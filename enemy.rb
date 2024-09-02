require 'rubygems'
require 'gosu'

class Enemy
  attr_accessor :x, :y, :direction, :speed, :flyingimages, :firingimages, :current_image, :firing, :count

  def initialize(stage)
    @y = rand(stage.height * stage.tile_set[Tiles::Ground].height - 100)

    direction_int = rand(0..1)
    if direction_int == 0 
      @direction = LEFT
      @x = stage.width * stage.tile_set[Tiles::Ground].width
    else
      @direction = RIGHT
      @x = 0
    end
    
    @speed = rand(1..3)
    @flyingimages = Gosu::Image.load_tiles("media/flyingdragon.png", 205, 125)
    @firingimages = Gosu::Image.load_tiles("media/attackingdragon.png", 205, 125)
    @current_image = @flyingimages[0]
    @firing = false
    @count = 0
  end

  def update
    if @firing == true
      @current_image = @firingimages[Gosu.milliseconds / 175 % @firingimages.length]
    else
      @current_image = @flyingimages[Gosu.milliseconds / 175 % @flyingimages.length]
    end

    # Directional horizontal movement
    @x += @direction * @speed
  end

  def draw
    offs_x = -@direction * @current_image.width / 2
    offs_y = @current_image.height / 2
    @current_image.draw(@x + offs_x, @y - offs_y, ZOrder::ENEMY, @direction, 1.0)
  end
end

class Fireball
  attr_accessor :x, :y, :direction, :images, :current_image, :x_vel, :y_vel, :angle

  def initialize(enemy, volume)
    @x = enemy.x + enemy.current_image.width / 2
    @y = enemy.y
    @direction = enemy.direction
    @images = Gosu::Image.load_tiles("media/red_fireball.png", 32, 32)
    @x_vel = rand(3..4)
    @y_vel = rand(-3..3)
    @angle = ((Math.atan(@y_vel / @x_vel)) * 180.00 / 3.14159265359)

    sound = Gosu::Sample.new("media/fire.wav")
    sound.play(0.3 * volume)

    if @direction == LEFT
      @angle = -@angle - 180
      @x = enemy.x - enemy.current_image.width / 2
    end
  end

  def update
    @x += @direction * @x_vel
    @y += @y_vel
    @current_image = @images[Gosu.milliseconds / 150 % @images.length]
  end

  def draw
    @current_image.draw_rot(@x - @current_image.width / 2, @y - @current_image.height / 2, 0, @angle, ZOrder::ENEMY)
  end
end

class Explosion
  attr_accessor :x, :y, :images, :finished

  def initialize(fireball, volume)
    @x = fireball.x
    @y = fireball.y
    @images = Gosu::Image.load_tiles("media/boom.png", 51, 51)
    @finished = false
    sound = Gosu::Sample.new("media/boom.wav")
    sound.play(0.8 * volume)
  end

  def draw
    current_image = @images[Gosu.milliseconds / 200 % @images.length]
    current_image.draw(@x - current_image.width / 2, @y - current_image.height / 2, ZOrder::PLAYER)

    if current_image == @images[@images.length - 1]
      @finished = true
    end
  end
end
