import os
from PIL import Image

path = r"Resources\art\placeholder\32rogues\rogues.png"
if os.path.exists(path):
    img = Image.open(path)
    print(f"Dimensions: {img.size}")
    img.close()
else:
    print("File not found")
