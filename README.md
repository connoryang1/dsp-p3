# Guitar Synthesizer and Transcriber

ENGR 100-400 (Digital Signal Processing) - Project 3

Oboe Group: Adam Baydoun, Yagho Grossi, and Connor Yang

## Run instructions

**Note:** each of the code blocks are duplicated to provide an easily copy-pastable version. Running them twice is not necessary.

This program requires multiple threads, unsupported by default Julia configurations. In order to run Julia with multiple threads, run:
```
$ julia --threads 2
```
```
julia --threads 2
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
```
using Pkg
Pkg.add("WAV")
Pkg.add("MAT")
Pkg.add("Sound")
Pkg.add("FFTW")
Pkg.add("Dates")
Pkg.add("PortAudio")
```
Once necessary packages are installed, run the program using:
```
julia> include("synthgui.jl")
```
```
include("synthgui.jl")
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

### Testing
- `guitarFromComputer.wav` sample synthesized audio used to test the transcriber and synthesizer with each other. Can be selected as input in the transcriber window.
- `output.txt` sample tablature, can be imported into the Synthesizer


## Disclaimer

Mileage may vary depending on device. From our tests, recording (in the Transcriber window) on a M2 Macbook does not seem to work. The functionality of our recording is largely derived from Prof. Fessler's implementation, so this is likely a hardware-specific issue (we consulted Zach about the issue and he agreed).

All other GUI features were developed on and should work correctly on an ARM-chip Mac. The program should be fully compatible with other devices as well, but some minor issues have been found in our testing. In particular, the "Synthesizer" button on the Transcriber window and the bottom insertion window in the Synthesizer window have experienced some issues when tested on a Windows device.

I have not been able to replicate either of these issues on my Mac, so it is likely hardware-specific or device-specific. Ideally, though, all features should be fully functional on at least one device.
