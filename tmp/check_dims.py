from PIL import Image
import os

files = [
    r"C:\Users\grant\Documents\github\hex\Resources\art\placeholder\32rogues\rogues.png",
    r"C:\Users\grant\Documents\github\hex\Resources\art\placeholder\32rogues\monsters.png"
]
for path in files:
    if os.path.exists(path):
        with Image.open(path) as img:
            print(f"{os.path.basename(path)}: {img.size}")
    else:
        print(f"{os.path.basename(path)}: File not found")
