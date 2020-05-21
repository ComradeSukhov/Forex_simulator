class GraphWindow
  attr_accessor :vertical_padding, :image_height
  attr_reader :canvas, :settings

  def initialize(settings)
    @settings         = settings
    @image_width      = 1280
    @image_height     = 720
    @vertical_padding = 10
    @canvas           = Magick::ImageList.new
    @grid             = Magick::HatchFill.new('white', 'grey95', 10)
    @candles          = Candles.new(1589749200, 1589752200, self).candles
    @left_scale       = LeftScale.new
    @right_scale      = RightScale.new
    @bottom_scale     = BottomScale.new

    @canvas.new_image(@image_width, @image_height, @grid)
    @candles.     draw(@canvas)
    # @left_scale.  draw(@canvas)
    # @right_scale. draw(@canvas)
    # @bottom_scale.draw(@canvas)
  end
end

class Candles
  attr_reader :candles

  def initialize(start_date, finish_date, canvas)
    
    rate = JSON.parse(File.read('data/candles/' + 
     'minute_candles_db.json')).transform_keys { |k| k.to_i}

    @density   = 14 # плотность отображения японских свечей
    @thickness = 10 # толщина одной свечи

    top_extremum = to_points(rate.map { |x| x[1]['max']}.max) # верх графика
    low_extremum = to_points(rate.map { |x| x[1]['min']}.min) # низ графика
    amplitude    = top_extremum - low_extremum                 # размер графика
    scale_ratio  = (canvas.image_height.to_f -
                   canvas.vertical_padding * 2) /amplitude
    # коэффициент масштабирования при размещении графика на экране

    candles = Magick::Draw.new
    candles.stroke('green')
    candles.fill('green')
    candles.stroke_width(1)

    counter = 0
    start_date.step(finish_date, 60) do |i|

      if rate[i]['start'] < rate[i]['finish']
        candles.fill_opacity(1)
      else
        candles.fill_opacity(0)
      end

      candles.rectangle(
        counter * @density,
        (top_extremum - to_points(rate[i]["start"])) * scale_ratio + 10,

        counter * @density + @thickness,
        (top_extremum - to_points(rate[i]["finish"])) * scale_ratio + 10 + 1,
        )

      high_end       = [rate[i]['start'], rate[i]['finish']].max
      low_end        = [rate[i]['start'], rate[i]['finish']].min
      candles_center = counter * @density + @thickness / 2

      if rate[i]['max'] != high_end
        candles.line(
          candles_center,
          (top_extremum - to_points(high_end)) * scale_ratio + 10,

          candles_center,
          (top_extremum - to_points(rate[i]["max"])) * scale_ratio + 10
          )
      end

      if rate[i]['min'] != low_end

        candles.line(
          candles_center,
          (top_extremum - to_points(low_end)) * scale_ratio + 10 + 1,

          candles_center,
          (top_extremum - to_points(rate[i]["min"])) * scale_ratio + 10
          )
      end
      counter += 1
    end
    @candles = candles
  end
end

class LeftScale

end

class RightScale

end

class BottomScale
end