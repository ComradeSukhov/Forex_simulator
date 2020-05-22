class GraphWindow < Magick::ImageList

  def initialize(settings)
    super()

    self.new_image(settings['image_width'], 
      settings['image_height'],
      Magick::HatchFill.new(settings['grid_main_color'],
        settings['grid_line_color'],
        settings['grid_step']))

    GraphImage.take_and_process(settings)
    
    Candles.new.draw(self)
    # LeftScale.new(settings)  .left_scale.drow(self)
    # RightScale.new(settings) .right_scale.drow(self)
    # BottomScale.new(settings).bottom_scale.drow(self)
  end
end



class GraphImage < Magick::Draw

  class << self

    attr_reader :settings

    def take_and_process(settings)
      @settings = add_params(settings) 
    end


    private


    def add_params(hash)

      hash['history']      = to_points(rate_history)
      hash['top_extremum'] = top_extremum(hash['history'])
      hash['low_extremum'] = low_extremum(hash['history'])
      hash['amplitude']    = amplitude(hash)
      hash['scale_ratio']  = scale_ratio(hash)
      hash

    end

    def rate_history
      JSON.parse(File.read('data/candles/' + 
        'minute_candles_db.json')).transform_keys { |k| k.to_i}
    end

    def top_extremum(history)
      history.map { |x| x[1]['max'] }.max
    end

    def low_extremum(history)
      history.map { |x| x[1]['min'] }.min
    end

    def amplitude(hash)
      hash['top_extremum'] - hash['low_extremum']  
    end

    def scale_ratio(hash)
      (hash['image_height'].to_f -
        hash['vertical_padding'] * 2) / hash['amplitude']
    end

    def to_points(rate_history)
      rate_history.each_value do |val|
        val.each_value{ |value| (value * 10_000).round }
      end
    end

  end

  def initialize
    super
  end


  private


  def to_graph(value, settings)
    (settings['top_extremum'] - value) *
    settings['scale_ratio'] + settings['vertical_padding']
  end


end



class Candles < GraphImage

  def initialize
    super

    settings = GraphImage.settings

    self.stroke('green')
    self.fill('green')
    self.stroke_width(1)

    settings['start_date'].step(settings['finish_date'], 60).with_index do 
      |i, nth_candle|

      paint_candle(i, settings)
      draw_candle_body(i, nth_candle, settings)
      draw_body_shadows(i, nth_candle, settings)
      
    end
  end


  private


  def paint_candle(i, settings)
    if settings['history'][i]['start'] < settings['history'][i]['finish']
      self.fill_opacity(1)
    else
      self.fill_opacity(0)
    end
  end


  def draw_candle_body(i, nth_candle, settings)

    start  = settings['history'][i]['start']
    finish = settings['history'][i]['finish']

    self.rectangle(
      nth_candle * settings['density'],
      to_graph(start, settings),

      nth_candle * settings['density'] + settings['thickness'],
      to_graph(finish, settings) + 1,
      )
  end


  def draw_body_shadows(i, nth_candle, settings)

    start  = settings['history'][i]['start']
    finish = settings['history'][i]['finish']
    max    = settings['history'][i]['max']
    min    = settings['history'][i]['min']

    high_end      = [start, finish].max
    low_end       = [start, finish].min
    middle_center = nth_candle * settings['density'] + settings['thickness'] / 2

    if max != high_end
      self.line(
        middle_center,
        to_graph(high_end, settings),

        middle_center,
        to_graph(max, settings)
        )
    end

    if min != low_end

      self.line(
        middle_center,
        to_graph(low_end, settings) + 1,

        middle_center,
        to_graph(min, settings)
        )
    end
  end
end


class LeftScale < GraphImage

end

class RightScale < GraphImage

end

class BottomScale < GraphImage

end