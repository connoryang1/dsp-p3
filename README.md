# Guitar Synthesizer and Transcriber

ENGR 100-400 (Digital Signal Processing) - Project 3

Developed by: Adam Baydoun, Yagho Grossi, and Connor Yang


## Run instructions

This program requires multiple threads, unsupported by default Julia configurations. In order to run Julia with multiple threads, run:
```
$ julia --threads 2
```
This should open the Julia interactive terminal. Install necessary packages:
```
julia> using Pkg
julia> Pkg.add("WAV")
julia> Pkg.add("MAT")
julia> Pkg.add("Sound")
julia> Pkg.add("FFTW")
julia> Pkg.add("Dates")
julia> Pkg.add("PortAudio")
```
Once necessary packages are installed, run the program using:
```
julia> include("synthgui.jl")
```

## File overview

### Main functionality
- `synthgui.jl` the main GUI file. Contains code for the main window, synthesizer window, and transcriber window
- `synthwrite.jl` the synthesizer
- `transcriber.jl` the transcriber

### Input/output artifacts + assets
- `logo.png` the image displayed on our home page
- `guitar_tab.txt` one of the two output files generated from transcriber.jl. This is the "human-readable" version displayed in the transcriber window
- `guitar_tab_Concise.txt` the other output file generated from `transcriber.jl`. This is the tablature format used in most of the program, including importing to the synthesizer
- `asdf.txt` a temporary file used when clicking "Play" on the synthesizer window. This contains automatically exported tablature from the synthesizer editor and is subsequently played using `synthwrite.jl`
- `recordedFromComputer.wav` outputted .wav file from the recording functionality in the transcriber window
- `guitarFromComputer.wav` sample synthesized audio used to test the transcriber and synthesizer with each other
- `output.txt` sample tablature, can be imported into the Synthesizer
