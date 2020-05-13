require 'rmagick'

graph = {}

start = 360 + rand(-100..100)


50.times { |i| 
  graph[i] = {
    "start"  => start,
    "finish" => start + rand(-50..50),
    "max"    => start - rand(0..75),
    "min"    => start + rand(0..75)
  }

  start = graph[i]["finish"]
}

p graph




canvas = Magick::ImageList.new

canvas.new_image(1280, 720, Magick::HatchFill.new('white', 'gray93'))

density   = 14
thickness = 10

# density   это плотность отображения японских свечей 
# thickness это толщина одной свечи

p canvas


candle = Magick::Draw.new
candle.stroke('green')
candle.fill('green')
candle.stroke_width(1)

50.times { |i|
  if graph[i]["start"] < graph[i]["finish"]
    candle.fill_opacity(0)
  else
    candle.fill_opacity(1)
  end

  candle.rectangle(
    i * density, graph[i]["start"],
    i * density + thickness, graph[i]["finish"]
  )
  

  high_end      = [graph[i]["start"], graph[i]["finish"]].min
  low_end       = [graph[i]["start"], graph[i]["finish"]].max
  candle_centre = i * density + thickness/2


  if graph[i]["max"] < high_end
    candle.line(
      candle_centre, high_end,
      candle_centre, graph[i]["max"]
    )
  end

  if graph[i]["min"] > low_end
    candle.line(
      candle_centre, low_end,
      candle_centre, graph[i]["min"])
  end
}

candle.draw(canvas)
canvas.write('test.jpg')