def scale_step(amplitude)

  case amplitude
  when 0..5
    1
  when 6..12
    2
  when 13..22
    5
  when 23..45
    10
  when 46..90
    20
  when 91..110
    25
  when 111..180
    40
  when 181..270
    50
  when 271..320
    75
  when 321...650
    100  
  else

    handsome_round(amplitude)

  end
end

def handsome_round(amplitude)
  number = amplitude / 5    

  array = number.digits.reverse

  if (3..7).any?(array[1])
    array[1] = 5
  elsif (0..2).any?(array[1])
    array[1] = 0
  else
    array[1] = 0
    array[0] += 1
  end

  (2...array.size).each{ |i| array[i] = 0 }

  array.join.to_i
end