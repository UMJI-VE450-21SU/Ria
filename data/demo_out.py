import numpy as np
import sys
from matplotlib.image import imread
from PIL import Image

outarr = np.fromfile(sys.argv[1], dtype=np.uint8, count=-1)
outarr = np.reshape(outarr, (64, -1))
im = Image.fromarray(outarr)
im.save("sobel_out.jpg")

