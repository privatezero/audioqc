#!/usr/local/bin/ruby

require 'json'

def CheckPeak(input)
  ffprobeout = JSON.parse(`ffprobe -print_format json -show_entries frame_tags=lavfi.astats.Overall.Peak_level -f lavfi -i "amovie='#{input}',astats=metadata=1"`)
  ffprobeout['frames'].each_with_index do |metadata, index|
    peaklevel = ffprobeout['frames'][index]['tags']['lavfi.astats.Overall.Peak_level'].to_f
    if peaklevel > -1.5
      puts peaklevel
    end
  end
end

ARGV.each do |fileinput|
  CheckPeak(fileinput)
end