#!/usr/local/bin/ruby

require 'json'

def CheckAudioQuality(input)
  $highdb = Array.new
  ffprobeout = JSON.parse(`ffprobe -print_format json -show_entries frame_tags=lavfi.astats.Overall.Peak_level,lavfi.aphasemeter.phase -f lavfi -i "amovie='#{input}',astats=metadata=1,aphasemeter=video=0"`)
  ffprobeout['frames'].each_with_index do |metadata, index|
    peaklevel = ffprobeout['frames'][index]['tags']['lavfi.astats.Overall.Peak_level'].to_f
    audiophase = ffprobeout['frames'][index]['tags']['lavfi.aphasemeter.phase'].to_f
    if peaklevel > -5.5
      $highdb << peaklevel
    end
    puts audiophase
  end
  puts $highdb.count
end

ARGV.each do |fileinput|
  CheckAudioQuality(fileinput)
end