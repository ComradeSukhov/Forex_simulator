class GraphWindow < Magick::ImageList

  def initialize
    super

    settings = read_settings

    self.new_image(settings["image_width"], 
                   settings["image_height"], 
                   Magick::HatchFill.new(settings["grid_main_color"],
                                         settings["grid_line_color"],
                                         settings["grid_step"]))


    GraphImage.take_and_process(settings)
    Candles.new.draw(self)
    LeftScale.new.draw(self)
  
  end
  
  private

  def read_settings

    settings = {}
    current_path = File.dirname(__FILE__)

    
    doc = File.read(current_path +
          "/default_settings.xml").scan /<(\w+)>(\w+)<\/\1>/
    
    doc.each { |i| settings[i[0]] = i[1].match(/\A\d+\z/) ? i[1].to_i : i[1] }
    
    settings

  end
end

class GraphImage < Magick::Draw

  class << self
    attr_reader :settings

    def take_and_process(settings)
      @settings = add_params(settings)
    end

    private

    def add_params(settings)
      settings["history"]          = to_points(rate_history)
      settings["top_extremum"]     = top_extremum(settings["history"])
      settings["low_extremum"]     = low_extremum(settings["history"])
      settings["amplitude"]        = amplitude(settings)
      settings["scale_ratio"]      = scale_ratio(settings)
      settings["page_bottom"]      = page_bottom(settings)
      settings["page_top"]         = page_top(settings)
      scale_step_cashe             = scale_step(settings["amplitude"])
      settings["scale_main_step"]  = scale_step_cashe[0]
      settings["scale_small_step"] = scale_step_cashe[1]
      settings["first_mark"]       = find_first_mark(settings)
      settings
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

    def amplitude(settings)
      settings["top_extremum"] - settings["low_extremum"]
    end

    def scale_ratio(settings)
      (settings["image_height"].to_f -
        settings["vertical_padding"] * 2) / settings["amplitude"]
    end

    def page_bottom(settings)
      (settings["low_extremum"] - settings["vertical_padding"] / 
        settings["scale_ratio"]).ceil
    end

    def page_top(settings)
      (settings["top_extremum"] + settings["vertical_padding"] / 
        settings["scale_ratio"]).floor
    end

    def find_first_mark(settings)
      (settings["page_bottom"]..).find do |x|
        x % settings["scale_main_step"] == 0
      end
    end

    def scale_step(amplitude) 
      case amplitude
      when 0..5
        return 1, 1
      when 6..12
        return 2, 1
      when 13..22
        return 5, 1
      when 23..45
        return 10, 5
      when 46..90
        return 20, 5
      when 90..110
        return 25, 5
      when 111..180
        return 40, 10
      when 181..270
        return 50, 10
      when 271..320
        return 75, 25
      when 321...650
        return 100, 50
      else
        handsome_round(amplitude)
      end
    end

    def handsome_round(amplitude) 
      number = amplitude / 5
      arr    = number.digits.reverse

      if (3..7).any?(arr[1]) 
        arr[1] = 5
      elsif (0..2).any?(arr[1])
        arr[1] = 0
      else
        arr[0] += 1
        arr[1] = 0
      end

      (2...arr.size).each { |i| arr[i] = 0 }
      arr.join.to_i
    end

    def to_points(rate_history) 
      rate_history.each_key do |key|
        rate_history[key].each_pair do |k, v| 
          rate_history[key][k] = (v * 10_000).round 
        end
      end
    end
  end

  def initialize
    super
  end


  private
  
  def to_graph(value, settings)
    (settings["top_extremum"] - value) * 
      settings["scale_ratio"] + settings["vertical_padding"]
  end
end

class Candles < GraphImage

  def initialize
    super
    settings = GraphImage.settings

    self.stroke(settings["candle_stroke"])
    self.fill(settings["candle_fill"])
    self.stroke_width(settings["candle_stroke_width"])

    draw_candles(settings)
  end


  private

  def draw_candles(settings)
    settings["start_date"].step(settings["finish_date"], 60).with_index do 
      |i, nth_candle|
      
      candle_cashe = {}

      set_candle_opacity(i, settings)
      draw_candle_body(i, nth_candle, settings, candle_cashe)
      draw_candle_shadows(i, nth_candle, settings, candle_cashe)
    end
  end

  def set_candle_opacity(i, settings)
    if settings["history"][i]['start'] < settings["history"][i]['finish']
      self.fill_opacity(settings["up_candle_opacity"])
    else
      self.fill_opacity(settings["down_candle_opacity"])
    end
  end


  def draw_candle_body(i, nth_candle, settings, candle_cashe)
    candle_cashe["start"]  = to_graph(settings["history"][i]["start"],
                                      settings)
    candle_cashe["finish"] = to_graph(settings["history"][i]["finish"],
                                      settings)

    self.rectangle(nth_candle * settings["density"],
                   candle_cashe["start"],

                   nth_candle * settings["density"] + settings["thickness"],
                   candle_cashe["finish"] + 1)
  end


  def draw_candle_shadows(i, nth_candle, settings, candle_cashe)
    min = to_graph(settings["history"][i]["min"], settings)
    max = to_graph(settings["history"][i]["max"], settings)

    high_end = [candle_cashe["start"], candle_cashe["finish"]].min
    low_end  = [candle_cashe["start"], candle_cashe["finish"]].max
    middle   = nth_candle * settings["density"] + settings["thickness"] / 2

    if max != high_end
      self.line(middle, high_end, middle, max)
    end

    if min != low_end
      self.line(middle, low_end + 1, middle, min)
    end
  end
end

class LeftScale < GraphImage
  def initialize
    super
    settings = GraphImage.settings

    self.stroke(settings["scale_stroke"])
    self.stroke_opacity(settings["scale_stroke_opacity"])
    self.pointsize(settings["font_size"])
    self.text_undercolor('#FFFFFFA5')

    self.line(settings["scale_margin"],
              0,
              settings["scale_margin"],
              settings["image_height"])

    draw_main_marks(settings)
    draw_small_marks(settings)

  end


  private

  def draw_main_marks(settings)
    settings["first_mark"].step(settings["page_top"],
                                settings["scale_main_step"]) do |mark|

      y_coord_cashe = to_graph(mark, settings)

      self.line(settings["scale_margin"],
                y_coord_cashe,
                settings["scale_margin"] + settings["scale_mark_size"],
                y_coord_cashe)

      self.text(settings["scale_margin"] + settings["text_left_padding"],
                y_coord_cashe - settings["text_vert_padding"],
                mark.to_s.insert(1, '.'))
    end
  end

  def draw_small_marks(settings)
    # сокращение шапок итераторов
    first_mark = settings["first_mark"]
    top        = settings["page_top"]
    bottom     = settings["page_bottom"]
    step       = settings["scale_small_step"]

    # отрисовка засечек вверх от первой (first_mark)
    first_mark.step(top, step) do |mark|

      unless mark % settings["scale_main_step"] == 0
        y_coord_cashe = to_graph(mark, settings)

        self.line(settings["scale_margin"],
                  y_coord_cashe,
                  settings["scale_margin"] + settings["scale_mark_size"] / 2,
                  y_coord_cashe)
      end
    end

    # отрисовка засечек вниз от первой (first_mark)
    (first_mark - step).step(bottom, - step) do |mark|

        y_coord_cashe = to_graph(mark, settings)

        self.line(settings["scale_margin"],
                  y_coord_cashe,
                  settings["scale_margin"] + settings["scale_mark_size"] / 2,
                  y_coord_cashe)
    end
  end

end
