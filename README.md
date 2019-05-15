# audioqc

Depends on: FFprobe and Mediaconch

Usage:  `audioqc.rb [options] TARGET`

Options: `-h` Help, ` -t` set target extension (for example `-t flac`). Default is wav. `-p` Override the built in mediaconch policy file with a custom file. `-p PATH-TO-POLICY-FILE`.

This script can target both directories and single audio files, and will generate basic audio QC reports of to the desktop. Reports contain a warning for high levels, a warning for audio phase, and a Media Conch compliance check. Script has been tested on macOS and Linux.

