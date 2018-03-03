#!/usr/local/bin/ruby

require 'json'
fileinput = ARGV[0]
puts fileinput
ffprobeout = JSON.parse(`ffprobe -print_format json -show_entries frame_tags=lavfi.astats.Overall.Peak_level -f lavfi -i "amovie='#{fileinput}',astats=metadata=1"`)
ffprobeout['frames'].each_with_index do |metadata, index|
	puts ffprobeout['frames'][index]['tags']['lavfi.astats.Overall.Peak_level']
end
