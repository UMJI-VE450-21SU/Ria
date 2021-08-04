import numpy as np
import sys
from matplotlib.image import imread
from PIL import Image
import re

img_np = imread(sys.argv[1])

height, width, _ = img_np.shape

img_gray_np = np.zeros((height, width), dtype=np.uint8)

for y in range(height):
  for x in range(width):
    r = float(img_np[y][x][0] / 255)
    g = float(img_np[y][x][1] / 255)
    b = float(img_np[y][x][2] / 255)

    gs = 0.2989 * r + 0.5870 * g + 0.1140 * b
    gs = int(gs * 255)
    img_gray_np[y][x] = gs

with open(re.sub(r".jpg", ".img.bin", sys.argv[1]), "w") as f:
    img_gray_np.tofile(f)
