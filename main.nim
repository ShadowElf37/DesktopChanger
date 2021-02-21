import sdl2 except quit
import sdl2/image except quit
import os
import vapoursynth
import strformat, strutils
import sugar
from net import newSocket, bindAddr, Port
import options

include win32

# Binding to this port will ensure that the program can't run twice.
try:
    let s = newSocket()
    s.bindAddr(Port(40288))
except:
    echo "Error: Only one instance of this program can run at a time. Please check that no other instances are running, or try again later (yes that might actually fix it if this error is mysterious)."
    quit()

# Convenience function to maintain a framerate
var lastFrame: uint32 = 0
proc tickFPS*(fps: int) =
    let desired = uint32(1000 / fps)
    let diff = getTicks() - lastFrame
    if desired > diff:
        sleep(int32(desired - diff)) # Delay to maintain steady frame rate
    lastFrame = getTicks()


# ==============
# Interpret argv
# ==============
let
    FNAME = splitFile(getAppFilename())[1]
    argc = paramCount()
    argv = collect(newSeq):
        for i in ..argc: paramStr(i)

var
    FPS, MAX_FRAME: int

if argc == 0:
    echo &"""
Error:   no file provided.
Syntax:  {FNAME} <path> [-f <FPS>]
"""
    quit()

let path = argv[1]

if not (fileExists(path) or dirExists(path)):
    #echo fileExists(path)
    #echo dirExists(path)
    #echo path
    echo &"""
    Error:   "{path}" does not exist.
    Syntax:  {FNAME} <path> [-f <FPS>]
    """
    quit()

block readFlags:
    var flag: char = char(0)
    if argc > 2:
        for arg in argv[2..^0]:
            if flag != char(0):
                case flag
                of 'f':
                    FPS = parseInt(arg)
                    flag = char(0)
                else:
                    echo &"""
                    Error:   invalid flag "-{flag}".
                    Syntax:  {FNAME} <path> [-f <FPS>]
                    """
                    quit()

            flag = char(arg[1])


# =========
# SDL init
# =========

discard image.init(IMG_INIT_PNG or IMG_INIT_JPG or IMG_INIT_TIF)
discard sdl2.init(INIT_EVERYTHING)

echo "Creating window..."
var window = sdl2.createWindowFrom(cast[ptr int](getDesktopWindow()))
echo "Creating renderer..."
var renderer = window.createRenderer(-1, 0);

renderer.setDrawColor(255, 0, 0)

echo "Opening file..."
var
    evt = sdl2.defaultEvent
    running = true

# ================
# FILETYPE PARSING
# ================
var
    FILETYPE: char
    texture: TexturePtr
    src: ptr VSMap
    video: ptr VSNodeRef
    images: seq[string]

# IF IT'S A DIRECTORY
if os.dirExists(path):
    echo "File is a directory."
    FILETYPE = 'D'

    images = getFilesInDir(path, restrict_to=[".tiff", ".tif", ".jpg", ".jpeg", ".png", ".bmp", ".gif"])
    MAX_FRAME = images.len

    echo "Found these images: ", images

    if FPS == 0:
        FPS = 30

# IF IT'S A FILE
else:
    let ext = splitFile(path)[2]

    # VIDEO
    if ext in [".mov", ".mp4", ".mpg"]:
        echo "File is a video. Initializing..."
        FILETYPE = 'V'

        src = Source(path, cache=some(0))
        video = src.propGetNode("clip", 0)

        if FPS == 0:
            FPS = video.getVideoInfo().fpsNum
        MAX_FRAME = video.getVideoInfo().numFrames

        echo "\n===========\nVideo info: ", video.getVideoInfo(), "\n===========\n"

        texture = renderer.createTexture(SDL_PIXELFORMAT_YV12, SDL_TEXTUREACCESS_STREAMING, 1920, 1080)

    # IMAGE
    else:
        echo "File is an image."
        echo setDesktop(path)
        quit()


var
    frame_index: int
    frame: ptr VSFrameRef
    Y, U, V: pointer

echo "Press CTRL+C or close this window at any time to stop the program. Feel free to minimize it in the meantime.\n"
echo "Rendering..."
while running:
    if FILETYPE == 'V':
        frame = video.getFrame(frame_index)

        Y = frame.getReadPtr(0)
        U = frame.getReadPtr(1)
        V = frame.getReadPtr(2)

        #echo &"Frame {frame_index}: ",
        updateYUVTexture(texture, nil, Y, 1920, U, 960, V, 960)

        freeFrame(frame)
        #echo getError()
    elif FILETYPE == 'D':
        texture = renderer.loadTexture(images[frame_index])

    inc(frame_index)
    if frame_index == MAX_FRAME:
        frame_index = 0

    renderer.clear()
    # DRAW
    renderer.copy(texture, nil, nil)
    renderer.present()

    tickFPS(FPS)

    while pollEvent(evt):
        if evt.kind == QuitEvent:
            running = false
            break

renderer.destroyRenderer()
window.destroy()