require 'rubygems'
require 'gosu'
require './level'
require './player'
require './enemy'

WIDTH, HEIGHT = 800, 540

LEFT, RIGHT = -1, 1

module ZOrder
  BACKGROUND, ENEMY, MIDDLE, PLAYER, UI = *0..4
end

module Sprite
  Standing, Walk1, Walk2, Walk3, Jump = *0..4
end

module Tiles
  Platform, Ground = *0..1
end

module Mushrooms
  Red, Blue = *0..1
end

class DragonRaider < Gosu::Window
  # Initializes the start menu
  def initialize()
    super WIDTH, HEIGHT
    self.caption = "Dragon Raider"

    @font = Gosu::Font.new(20)
    @title = Gosu::Font.new(88)
    @intro = true
  end

  # Initializes up the game the first time gameplay begins
  def initialize_game
    @coin_icon = Gosu::Image.new("media/coin_icon.png")
    @full_life = Gosu::Image.new("media/full_life.png")
    @empty_life = Gosu::Image.new("media/empty_life.png")
    @unlocked = Gosu::Image.new("media/unlocked.png")
    @unlocked_white = Gosu::Image.new("media/unlocked_white.png")
    @locked = Gosu::Image.new("media/locked.png")
    @pause_button = Gosu::Image.new("media/pause.png")
    @restart_button = Gosu::Image.new("media/restart.png")
    @restart_icon = Gosu::Image.new("media/restart_small.png")
    @play_button = Gosu::Image.new("media/play.png")
    @info_icon = Gosu::Image.new("media/info.png")
    @music_on_symbol = Gosu::Image.new("media/music_on.png")
    @music_off_symbol = Gosu::Image.new("media/music_off.png")
    @effect_images = Array.new()
    @effect_images << Gosu::Image.new("media/red_potion.png")
    @effect_images << Gosu::Image.new("media/blue_potion.png")

    @label = Gosu::Font.new(9)
    @message = Gosu::Font.new(100)

    @level = Level.new()
    @level_index = 0
    @stage = Stage.new(@level.maps[@level_index], @level.platform_set[@level_index], @level.ground_set[@level_index])
    @total_coins = @stage.coins.length
    @player = Player.new(WIDTH / 2, HEIGHT / 5, @stage)
    @enemies = Array.new()
    @fireballs = Array.new()
    @explosions = Array.new()

    @camera_x = @camera_y = 0
    @paused = false
    @volume = 1
    @highest_unlocked = 0
    @alive = true
    @won = false
    @game_complete = false
  end

  # Initializes new level
  def initialize_level(level_index)
    @level = Level.new()
    @level_index = level_index
    @stage = Stage.new(@level.maps[@level_index], @level.platform_set[@level_index], @level.ground_set[@level_index])
    @total_coins = @stage.coins.length
    @player = Player.new(WIDTH / 2, HEIGHT / 5, @stage, @player.lives, @player.hp)
    @enemies = Array.new()
    @fireballs = Array.new()
    @explosions = Array.new()
    @won = false
    @life_lost = false
    @alive = true
    @game_complete = false
  end

  def update
    if !@intro
      update_win_status

      if !@paused and @alive and !@game_complete
        update_game
      end
    end
  end

  # Pause game and display appropriate message if player has completed a level
  def update_win_status
    if @player.score >= @total_coins and !@paused
      @won = true
      @time = Gosu.milliseconds
    end

    # Proceed to next level if not on final level
    if @level_index < @level.max_level_index and @won == true
      if Gosu.milliseconds < @time + 2000
        @paused = true
      else
        @paused = false
        @level_index += 1
        if @level_index > @highest_unlocked
          @highest_unlocked = @level_index
        end
        initialize_level(@level_index)
      end

    # Game completed if final level is won
    elsif @level_index == @level.max_level_index and @won == true
      @game_complete = true
    
    # Re-place player on stage with updated lives and hp if life is lost
    elsif @life_lost and Gosu.milliseconds < @time + 1000
      @paused = true
    elsif @life_lost and Gosu.milliseconds > @time + 1000 and @alive
      @paused = false
      @life_lost = false
      @player = Player.new(WIDTH / 2, HEIGHT / 5, @stage, @player.lives, 100, @player.score)
    end
  end

  def update_game
    @player.current_image = @player.images[Sprite::Standing]
    @player.move(LEFT) if Gosu.button_down? Gosu::KB_LEFT
    @player.move(RIGHT) if Gosu.button_down? Gosu::KB_RIGHT
    @player.update
    @player.collect_coins(@stage.coins, @volume)
    @player.collect_mushrooms(@stage.mushrooms, @volume)

    # Enemies
    @enemies.each { |enemy| enemy.update}
    self.remove_enemies

    if rand(100) < 2 and @enemies.size < @level.num_enemies[@level_index]
      @enemies.push(Enemy.new(@stage))
    end

    @enemies.each { |enemy| change_firing(enemy)}

    # Fireballs
    @fireballs.each { |fireball| fireball.update}
    self.remove_fireballs

    # Explosions
    self.remove_explosions

    # Scrolling
    @camera_x = [[@player.x - WIDTH / 2, 0].max, @stage.width * @stage.tile_set[Tiles::Ground].width - WIDTH].min
    @camera_y = [[@player.y - HEIGHT / 2, 0].max, @stage.height * @stage.tile_set[Tiles::Ground].height - HEIGHT].min
  end

  def change_firing(enemy)
    if !enemy.firing
      if Gosu.milliseconds / 100 % rand(1..1000) == 1
        enemy.firing = true
        enemy.count = @level.fireball_freq[@level_index]
        @fireballs.push(Fireball.new(enemy, @volume))
      end
    else
      if enemy.count > 0
        enemy.count = enemy.count - 1
      else
        enemy.firing = false
      end
    end
  end

  def draw
    if @intro
      draw_intro
    else
      draw_game
    end
  end

  # Draws start menu
  def draw_intro
    Gosu.draw_rect(0, 0, WIDTH, HEIGHT, Gosu::Color.rgb(188,224,255), ZOrder::BACKGROUND, mode=:default)
    title = "DRAGON RAIDER"
    @title.draw_text(title, (WIDTH - @title.text_width(title)) / 2, HEIGHT / 4, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)

    # Draw start button
    if mouse_x > (WIDTH - 80) / 2 and mouse_x < (WIDTH + 80) / 2 and mouse_y > (HEIGHT - @font.height) / 2 and mouse_y < ((HEIGHT - @font.height) / 2) + 40
      color = Gosu::Color.rgb(179,194,255)
      border_color = text_color = Gosu::Color::WHITE
    else
      color = Gosu::Color::WHITE
      border_color = text_color = Gosu::Color.rgb(179,194,255)
    end
    Gosu.draw_rect(((WIDTH - 80) / 2) - 1, ((HEIGHT - @font.height) / 2) - 1, 82, 42, border_color, ZOrder::UI, mode=:default)
    Gosu.draw_rect((WIDTH - 80) / 2, (HEIGHT - @font.height) / 2, 80, 40, color, ZOrder::UI, mode=:default)
    text = "START"
    @font.draw_text(text, (WIDTH - @font.text_width(text) + 2) / 2, (HEIGHT - @font.height) / 2 + 10, ZOrder::UI, 1.0, 1.0, text_color)
  end

  # Draws gameplay
  def draw_game
    @level.backgrounds[@level_index].draw(0, 0, ZOrder::BACKGROUND, 0.5, 0.5)
    Gosu.translate(-@camera_x, -@camera_y) do
      @stage.draw
      @player.draw
      @enemies.each { |enemy| enemy.draw}
      @fireballs.each { |fireball| fireball.draw}
      @explosions.each { |explosion| explosion.draw}
    end

    draw_coin_score
    draw_mushroom_effect
    draw_lives
    draw_hp
    draw_level_navigation
    draw_pause_play_button
    draw_mute_button
    draw_restart_icon
    draw_info_icon
    draw_game_messages
  end

  # Displays coin icon and the number of coins collected out of the total number of coins in the stage
  def draw_coin_score
    @coin_icon.draw(10, 10, ZOrder::UI)
    @font.draw("#{@player.score}/#{@total_coins}", @coin_icon.width + 12, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  # Display symbol for the effect of collected mushroom and display countdown to effect ending
  def draw_mushroom_effect
    if @player.timer != 0
      if @player.effect > 0
        image = @effect_images[0]
      elsif @player.effect < 0
        image = @effect_images[1]
      end
      image.draw(90, 10, ZOrder::UI)
      @font.draw(@player.timer / 100 + 1, image.width + 92, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end
  end

  # Draw full or empty life symbol to indicate number of lives left
  def draw_lives
    3.times do |i|
      if @player.lives > i
        @full_life.draw(2 * WIDTH / 3 + (@full_life.width + 2) * i - 20, 10, ZOrder::UI)
      else
        @empty_life.draw(2 * WIDTH / 3 + (@empty_life.width + 2) * i - 20, 10, ZOrder::UI)
      end
    end
  end

  # Displays HP and HP bar with appropriate color and flashing for amount of HP
  def draw_hp
    bar_width = 140
    bar_height = @font.height
    hp_diplay = "#{@player.hp} HP"
    @font.draw_text(hp_diplay, WIDTH - bar_width - @font.text_width(hp_diplay) - 12, 10, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    Gosu.draw_rect(WIDTH - bar_width - 10, 10, bar_width, bar_height, Gosu::Color::WHITE, ZOrder::UI, mode=:default)

    case @player.hp
    when 60..100
      bar_color = Gosu::Color::GREEN
      @pulse = false
    when 30..60
      bar_color = Gosu::Color::YELLOW
      @pulse = false
    when 0..30
      bar_color = Gosu::Color::RED
      @pulse = true
    end
      
    if @pulse and (!@pulse_time or Gosu.milliseconds - @pulse_time > 1200)
      @pulse_time = Gosu.milliseconds
    end
    if !@pulse or !@pulse_time or Gosu.milliseconds < @pulse_time + 1000
      Gosu.draw_rect(WIDTH - bar_width - 10, 10, bar_width * @player.hp / 100, bar_height, bar_color, ZOrder::UI, mode=:default)
    end
  end

  # Draw Locked or Unlocked symbol to represent status of each level, highlight current level and unlocked level if hovered over
  def draw_level_navigation
    3.times do |i|
      if i <= @highest_unlocked and ((mouse_x > WIDTH / 3 + (@unlocked.width + 2) * i and mouse_x < WIDTH / 3 + (@unlocked.width + 2) * i + @unlocked.width and mouse_y > 10 and mouse_y < @unlocked.height + 10) or i == @level_index)
        image = @unlocked_white
      elsif i <= @highest_unlocked
        image = @unlocked
      else
        image = @locked
      end
      image.draw(WIDTH / 3 + (image.width + 2) * i, 10, ZOrder::UI)
      @label.draw("Lv #{i + 1}", WIDTH / 3 + (image.width + 2) * i + 2, 9 + image.height, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end
  end

  # Draws Pause button if game is playing and Play button if game is paused
  def draw_pause_play_button
    if !@paused
      @pause_button.draw(WIDTH - @pause_button.width, HEIGHT - @pause_button.height, ZOrder::UI)
    else
      @play_button.draw(WIDTH - @play_button.width, HEIGHT - @play_button.height, ZOrder::UI)
    end
  end

  # Draws Mute button if audio is on and AUDIO ON button if audio is muted
  def draw_mute_button
    if @volume == 1
      @music_on_symbol.draw(WIDTH - @music_on_symbol.width - 25, HEIGHT - @music_on_symbol.height, ZOrder::UI)
    else
      @music_off_symbol.draw(WIDTH - @music_off_symbol.width - 25, HEIGHT - @music_off_symbol.height, ZOrder::UI)
    end
  end

  def draw_restart_icon
    @restart_icon.draw(WIDTH - @restart_icon.width - 50, HEIGHT - @restart_icon.height, ZOrder::UI)
  end

  def draw_info_icon
    @info_icon.draw(0, HEIGHT - @info_icon.height, ZOrder::UI)
    if mouse_x > 0 and mouse_x < @info_icon.width and mouse_y > HEIGHT - @info_icon.height and mouse_y < HEIGHT
        @paused = true
        @info = true
        Gosu.draw_rect(WIDTH / 4 - 2, HEIGHT / 4 - 2, WIDTH / 2 + 4, HEIGHT / 2 + 4, Gosu::Color::BLACK, ZOrder::UI, mode=:default)
        Gosu.draw_rect(WIDTH / 4, HEIGHT / 4, WIDTH / 2, HEIGHT / 2, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
        @font.draw_text("LEFT\nRIGHT\nUP\nESC", WIDTH / 4 + 40, HEIGHT / 4 + 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
        @font.draw_text(" =  move left\n =  move right\n =  jump\n =  exit", WIDTH / 4 + 40 + @font.text_width("RIGHT"), HEIGHT / 4 + 40, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
        @font.draw_text("GAME OBJECTIVE", WIDTH / 2 - @font.text_width("GAME OBJECTIVE") / 2, 3 * (HEIGHT / 4) - 40 - 3.2 * @font.height, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
        @font.draw_text("- Collect all the coins\n- Don't get hit by the fireballs", WIDTH / 4 + 40, 3 * (HEIGHT / 4) - 40 - 2 * @font.height, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    elsif @info == true and (mouse_x < 0 or mouse_x > @info_icon.width or mouse_y < HEIGHT - @info_icon.height or mouse_y > HEIGHT)
      @paused = false
      @info = false
    end
  end

  # Display messages for changing of gameplay status and displays restart button is gameover or game complete
  def draw_game_messages
    if !@alive
      draw_message("GAME OVER")
      draw_restart_button
    elsif @level_index < @level.max_level_index and @won == true
      draw_message("NEXT LEVEL!")
    elsif @game_complete
      draw_message("VICTORY!")
      draw_restart_button
    elsif @life_lost
      draw_message("One Life Lost")
    end
  end

  def draw_message(message)
    @message.draw_text(message, (WIDTH - @message.text_width(message)) / 2, (HEIGHT - @message.height) / 2, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
  end

  # Displays restart button and highlight when hovered over
  def draw_restart_button
    if mouse_x > (WIDTH - @restart_button.width) / 2 and mouse_x < (WIDTH + @restart_button.width) / 2 and mouse_y > HEIGHT / 2 + @message.height / 2 and mouse_y < HEIGHT / 2 + 3 * (@message.height / 2)
      Gosu.draw_rect((WIDTH - @restart_button.width) / 2, HEIGHT / 2 + @message.height / 2, @restart_button.width, @restart_button.height, Gosu::Color::WHITE, ZOrder::UI, mode=:default)
    end
    @restart_button.draw((WIDTH - @restart_button.width) / 2, HEIGHT / 2 + @message.height / 2, ZOrder::UI)
  end

  # Remove enemies when they move off the stage
  def remove_enemies
    @enemies.reject! do |enemy|
      if enemy.x > @stage.width * @stage.tile_set[Tiles::Ground].width || enemy.y > @stage.height * @stage.tile_set[Tiles::Ground].height || enemy.x < 0 || enemy.y < 0
        true
      else
        false
      end
    end
  end

  # Removes fireballs when they collide with a player of move off the stage
  def remove_fireballs
    @fireballs.reject! do |fireball|
      if fireball.x > @stage.width * @stage.tile_set[Tiles::Ground].width || fireball.y > @stage.height * @stage.tile_set[Tiles::Ground].height || fireball.x < 0 || fireball.y < 0
        true
      elsif (fireball.x - @player.x).abs <= @player.current_image.width / 2 + fireball.current_image.width / 2 and (fireball.y - @player.y).abs <= @player.current_image.height / 2 + fireball.current_image.height / 2
        @explosions.push(Explosion.new(fireball, @volume))
        @player.hp -= 10
        if @player.hp == 0
          @player.lives -= 1
          @life_lost = true
          @time = Gosu.milliseconds
        end
        if @player.lives == 0
          @alive = false
        end
        true
      else
        false
      end
    end
  end

  # Removes explosions when animation is finished
  def remove_explosions
    @explosions.reject! do |explosion|
      if explosion.finished
        true
      else
        false
      end
    end
  end

  # Switches game status from playing to paused and vice versa depending on current puased status
  def pause_game(paused)
    if !paused
      @paused = true
    else
      @paused = false
    end
  end

  # Changes game volume form full to muted and vice versa depending on current volume
  def mute_game(volume)
    if volume != 1
      @volume = 1
    else
      @volume = 0
    end
  end

  def button_down(id)
    if @intro
      button_down_intro(id)
    else
      button_down_game(id)
    end
  end

  def button_down_intro(id)
    case id
    when Gosu::MsLeft
      # Start button
      if mouse_x > (WIDTH - 80) / 2 and mouse_x < (WIDTH - 80) / 2 + 80 and mouse_y > (HEIGHT - @font.height) / 2 and mouse_y < (HEIGHT - @font.height) / 2 + 40
        @intro = false
        initialize_game
      end
    when Gosu::KB_RETURN
      @intro = false
      initialize_game
    when Gosu::KB_ESCAPE
      close
    end
  end

  def button_down_game(id)
    case id
    when Gosu::KB_UP
      @player.initiate_jump
    when Gosu::MsLeft
      # Pause/Play button
      if mouse_x > WIDTH - @pause_button.width and mouse_x < WIDTH and mouse_y > HEIGHT - @pause_button.height and mouse_y < HEIGHT
        pause_game(@paused)
      end
      # Mute/Unmute button
      if mouse_x > WIDTH - @music_on_symbol.width - 25 and mouse_x < WIDTH - 25 and mouse_y > HEIGHT - @music_on_symbol.height and mouse_y < HEIGHT
        mute_game(@volume)
      # Restart icon at the bottom of the screen
      elsif mouse_x > WIDTH - @restart_icon.width - 50 and mouse_x < WIDTH - 50 and mouse_y > HEIGHT - @restart_icon.height and mouse_y < HEIGHT
        @player.lives = 3
        @player.hp = 100
        @paused = false
        @highest_unlocked = 0
        initialize_level(0)
      # Restart button displayed when gameover or game complete
      elsif (!@alive or @game_complete) and mouse_x > (WIDTH - @restart_button.width) / 2 and mouse_x < (WIDTH + @restart_button.width) / 2 and mouse_y > HEIGHT / 2 + @message.height / 2 and mouse_y < HEIGHT / 2 + 3 * (@message.height / 2)
        @player.lives = 3
        @player.hp = 100
        @paused = false
        @highest_unlocked = 0
        initialize_level(0)
      # Level navigation between unlocked levels
      elsif @alive and @highest_unlocked >= 0 and mouse_x > WIDTH / 3 and mouse_x < WIDTH / 3 + @unlocked.width and mouse_y > 10 and mouse_y < @unlocked.height + 10
        initialize_level(0)
      elsif @alive and @highest_unlocked >= 1 and mouse_x > WIDTH / 3 + @unlocked.width + 2 and mouse_x < WIDTH / 3 + 2 * @unlocked.width + 2 and mouse_y > 10 and mouse_y < @unlocked.height + 10
        initialize_level(1)
      elsif @alive and @highest_unlocked >= 2 and mouse_x > WIDTH / 3 + (@unlocked.width + 2) * 2 and mouse_x < WIDTH / 3 + (@unlocked.width + 2) * 2 + @unlocked.width and mouse_y > 10 and mouse_y < @unlocked.height + 10
        initialize_level(2)
      end
    when Gosu::KB_ESCAPE
      close
    end
  end

  def needs_cursor?; true; end

end

window = DragonRaider.new
window.show
