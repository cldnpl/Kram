import pandas as pd
import json
import os
from PIL import Image, ImageDraw, ImageFont

# Carica il CSV
df = pd.read_csv('dataset/external_df.csv')
os.makedirs('dataset/images', exist_ok=True)

print("Kram sta generando le immagini con un metodo più leggero...")

with open('dataset/metadata.jsonl', 'w') as f:
    for i, row in df.head(100).iterrows():
        img_name = f"img_{i}.png"
        img_path = f"dataset/images/{img_name}"
        
        # Crea un'immagine bianca
        img = Image.new('RGB', (800, 300), color=(255, 255, 255))
        d = ImageDraw.Draw(img)
        
        # Scrive il testo del problema
        text = row['problem'][:200] # Accorciamo se troppo lungo per il test
        d.text((20, 100), text, fill=(0, 0, 0))
        
        img.save(img_path)
        
        # Metadati
        entry = {
            "file_name": f"images/{img_name}",
            "ground_truth": json.dumps({"gt_parse": {"problem": row['problem'], "solution": row['solution']}})
        }
        f.write(json.dumps(entry) + "\n")
        if i % 10 == 0: print(f"Generate {i} immagini...")

print("✅ Operazione completata con successo!")

