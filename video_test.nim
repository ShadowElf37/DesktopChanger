import vapoursynth as vs
from sdl2 import TexturePtr

const path = "C:\\Users\\yovel\\Desktop\\final.mp4"

let clip = propGetNode(Source(path), "clip", 0)

let fps = clip.getVideoInfo().fpsNum

let frame: ptr VSFrameRef = clip.getFrame(0)

echo clip.getVideoInfo()
echo fps

var
    Y =  frame.getReadPtr(0)
    U =  frame.getReadPtr(1)
    V =  frame.getReadPtr(2)

echo frame.getFrameFormat()[]
