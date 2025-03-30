import sdl3

var audioStream*: SDL_AudioStream
var currentSineSample: int = 0
const sampleRate = 8000
var isBeeping: bool = false

proc initAudioSystem*() =
    var desiredSpec: SDL_AudioSpec
    desiredSpec.freq = sampleRate
    desiredSpec.format = SDL_AUDIO_F32
    desiredSpec.channels = 1

    audioStream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, addr desiredSpec, nil, nil)
    if audioStream == nil:
        quit("SDL_OpenAudio Error: " & $SDL_GetError())


    discard SDL_ResumeAudioStreamDevice(audioStream)

proc beep*() =
    const minimumAudio: int = (sampleRate * sizeof(float32)) div 2
    currentSineSample = 0
    isBeeping = true

    if SDL_GetAudioStreamQueued(audioStream) < minimumAudio:
        var samples: array[sampleRate, float32]
        
        for i in 0..<samples.len:
            let freq = 440.0
            let time = currentSineSample / sampleRate
            samples[i] = SDL_sinf(freq * time * 2.0 * SDL_PI_F)
            inc currentSineSample
        
        currentSineSample = currentSineSample mod sampleRate
        
        discard SDL_PutAudioStreamData(audioStream, samples.unsafeAddr, len(samples).cint)

proc unbeep*() =
    discard SDL_ClearAudioStream(audioStream)