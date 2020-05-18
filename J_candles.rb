# frozen_string_literal: true

require 'rmagick'
require 'json'
require_relative 'methods.rb'

rate = JSON.parse(File.read('candles_db.json')).transform_keys{ |key| key.to_i}

density          = 14 # плотность отображения японских свечей
thickness        = 10 # толщина одной свечи
vertical_padding = 10 # отступ он верха и низа

top_extremum = to_points(rate.map { |x| x[1]['max']}.max)
low_extremum = to_points(rate.map { |x| x[1]['min']}.min)
amplitude    = top_extremum - low_extremum

scale_ratio = (720.0 - vertical_padding * 2) / (top_extremum - low_extremum)


canvas = Magick::ImageList.new
canvas.new_image(1280, 720, Magick::HatchFill.new('white', 'gray93'))

candles = Magick::Draw.new
candles.stroke('green')
candles.fill('green')
candles.stroke_width(1)

50.times do |i|
  if rate[i]['start'] < rate[i]['finish']
    candles.fill_opacity(1)
  else
    candles.fill_opacity(0)
  end

  candles.rectangle(
    i * density,
    (top_extremum - to_points(rate[i]["start"])) * scale_ratio + 10,

    i * density + thickness,
    (top_extremum - to_points(rate[i]["finish"])) * scale_ratio + 10 + 1
  )



  high_end      = [rate[i]['start'], rate[i]['finish']].max
  low_end       = [rate[i]['start'], rate[i]['finish']].min
  candles_center = i * density + thickness / 2

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
end




page_bottom = (low_extremum - 10 / scale_ratio).ceil
page_top    = (top_extremum + 10 / scale_ratio).floor
step        = scale_step(amplitude)


first_mark = (page_bottom..).find{ |x| x % step == 0 }



left_scale = Magick::Draw.new

left_scale.stroke('black')
left_scale.stroke_width(1)
left_scale.pointsize(12)
left_scale.line(10,0, 10,720)

first_mark.step(page_top, step) do |mark|

left_scale.stroke_width(1)
  left_scale.line(10,(top_extremum - mark) * scale_ratio + 10,
                  20,(top_extremum - mark) * scale_ratio + 10)

left_scale.text_undercolor('white')
left_scale.stroke_width(0)

left_scale.text(25,(top_extremum - mark) * scale_ratio + 10 + 4,
                  mark.to_s.insert(1, "."))

end

candles.draw(canvas)
left_scale.draw(canvas)
canvas.write('test.jpg')