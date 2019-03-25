#!/usr/bin/ruby

require 'json'
require 'tempfile'
require 'csv'

# set up arrays
$file_results = Array.new
$write_to_csv = Array.new

# Function to scan file for mediaconch compliance
def MediaConchScan(input)
  #Policy taken fromn MediaConch Public Policies. Maintainer Peter B. License: CC-BY-4.0+
  mcpolicy = <<EOS
<?xml version="1.0"?>
<policy type="and" name="Audio: &quot;normal&quot; WAV?" license="CC-BY-4.0+">
  <description>This is the common norm for WAVE audiofiles.&#xD;
Any WAVs not matching this policy should be inspected and possibly normalized to conform to this.</description>
  <policy type="or" name="Signed Integer or Float?">
    <rule name="Is signed Integer?" value="Format_Settings_Sign" tracktype="Audio" occurrence="*" operator="=">Signed</rule>
    <rule name="Is floating point?" value="Format_Profile" tracktype="Audio" occurrence="*" operator="=">Float</rule>
  </policy>
  <policy type="and" name="Audio: Proper resolution?">
    <description>This policy defines audio-resolution values that are proper for WAV.</description>
    <policy type="or" name="Valid samplerate?">
      <description>This was not implemented as rule in order to avoid irregular sampling rates.</description>
      <rule name="Audio is 44.1 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">44100</rule>
      <rule name="Audio is 48 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">48000</rule>
      <rule name="Audio is 88.2 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">88200</rule>
      <rule name="Audio is 96 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">96000</rule>
      <rule name="Audio is 192 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">192000</rule>
      <rule name="Audio is 11 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">11025</rule>
      <rule name="Audio is 22.05 kHz?" value="SamplingRate" tracktype="Audio" occurrence="*" operator="=">22050</rule>
    </policy>
    <policy type="or" name="Valid bit depth?">
      <rule name="Audio is 16 bit?" value="BitDepth" tracktype="Audio" occurrence="*" operator="=">16</rule>
      <rule name="Audio is 24 bit?" value="BitDepth" tracktype="Audio" occurrence="*" operator="=">24</rule>
      <rule name="Audio is 32 bit?" value="BitDepth" tracktype="Audio" occurrence="*" operator="=">32</rule>
      <rule name="Audio is 8 bit?" value="BitDepth" tracktype="Audio" occurrence="*" operator="=">8</rule>
    </policy>
  </policy>
  <rule name="Container is RIFF (WAV)?" value="Format" tracktype="General" occurrence="*" operator="=">Wave</rule>
  <rule name="Encoding is linear PCM?" value="Format" tracktype="Audio" occurrence="*" operator="=">PCM</rule>
  <rule name="Audio is 'Little Endian'?" value="Format_Settings_Endianness" tracktype="Audio" occurrence="*" operator="=">Little</rule>
</policy>
EOS
  if ! defined? $policyfile
    $policyfile = Tempfile.new('mediaconch')
    $policyfile.write(mcpolicy)
    $policyfile.rewind
  end
  command = 'mediaconch --Policy=' + $policyfile.path + ' ' + '"' + input + '"'
  mcoutcome = `#{command}`.tr('--','').tr(' ','')
  mcoutcome.split('/n').each do |qcline|
    $file_results << qcline
  end
end

# Function to scan audio stream characteristics
def CheckAudioQuality(input)
  $highdb = Array.new
  $phasewarnings = Array.new
  ffprobe_command = 'ffprobe -print_format json -show_entries frame_tags=lavfi.astats.Overall.Peak_level,lavfi.aphasemeter.phase -f lavfi -i "amovie=' + "'" + input + "'" + ',astats=reset=1:metadata=1,aphasemeter=video=0"'
  ffprobeout = JSON.parse(`#{ffprobe_command}`)
  ffprobeout['frames'].each do |frames|
    peaklevel = frames['tags']['lavfi.astats.Overall.Peak_level'].to_f
    audiophase = frames['tags']['lavfi.aphasemeter.phase'].to_f
    if peaklevel > -2.0
      $highdb << peaklevel
    end
    if audiophase < -0.25
      $phasewarnings << audiophase
    end
  end
  if $highdb.count > 0
    $file_results << "WARNING! Levels up to #{$highdb.max}"
    $file_results << "#{$highdb.count} out of #{ffprobeout['frames'].count}"
  else
    $file_results << 'Levels OK'
    $file_results << 'Levels OK'
  end
  if $phasewarnings.count > 50
    $file_results << $phasewarnings.count
  else
    $file_results << 'Phase OK'
  end
end
fileinputs = Array.new

ARGV.each do |input|
  if File.directory?(input)
    targets = Dir["#{input}/*.wav"]
    targets.each do |file|
      fileinputs << file
    end
  else
    if File.extname(input) == '.wav'
      fileinputs << input
    end
  end
end

fileinputs.each do |fileinput|
  fileinput = File.expand_path(fileinput)
  $file_results << fileinput
  CheckAudioQuality(fileinput)
  MediaConchScan(fileinput)
  $write_to_csv << $file_results
  $file_results = Array.new
end

timestamp = Time.now.strftime('%Y-%m-%d_%H-%M-%S')
CSV.open(File.expand_path("~/Desktop/audioqc-out_#{timestamp}.csv"), 'wb') do |csv|
  headers = ['Filename','Levels Warnings','Phase Warnings','MediaConch Policy Compliance']
  csv << headers
  $write_to_csv.each do |line|
    csv << line
  end
end
