require 'cairo'
include Cairo
benchmark = {}
#LOGFILE = "Ruby1_8-off.log"
#LOGFILE = "Ruby1_8-offir.log"
#LOGFILE = "Ruby1_9-off.log"
LOGFILE = "Ruby1_9-offir.log"

File.open(LOGFILE).each_line do |line|
  benchmark.store *(line.split " ")
end

width = 5000
height = 1000
step = 30
interspace = 150
start = 0

surface = ImageSurface.new width, height
context = Context.new surface

context.fill do
  context.set_source_rgb 1,1,1
  context.rectangle 0,0,width,height
end

benchmark.each do |name, data|
  next if name =~ /\w+\/kernel19\/\w+/
  context.set_source_rgb 0,0,1
  context.rectangle start, height, step, -data.to_f/3
  context.fill

  context.set_source_rgb 1,0,0
  context.select_font_face "Inconsolata"
  context.font_size = 30
  context.move_to start-10, height-data.to_f/3
  context.show_text data.to_s
  context.font_size = 15
  context.move_to start-10, height-data.to_f/3 - 30
  context.show_text name

  start = start + interspace
end

surface.write_to_png LOGFILE.gsub("log", "png")
