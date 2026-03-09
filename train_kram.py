import torch
from transformers import DonutProcessor, VisionEncoderDecoderModel, TrainingArguments, Trainer
from datasets import load_dataset
import os

# 1. Setup modello ultraleggero
# 1. Setup modello ultraleggero
device = "mps" if torch.backends.mps.is_available() else "cpu"
processor = DonutProcessor.from_pretrained("naver-clova-ix/donut-base")
model = VisionEncoderDecoderModel.from_pretrained("naver-clova-ix/donut-base")
model.config.pad_token_id = processor.tokenizer.pad_token_id
model.config.decoder_start_token_id = processor.tokenizer.cls_token_id
model.to(device)

# 2. Carichiamo solo 5 esempi (per testare se vive)
dataset = load_dataset("imagefolder", data_dir="dataset", split="train").select(range(5))

def preprocess(sample):
    pixel_values = processor(sample["image"], return_tensors="pt").pixel_values.squeeze(0)
    labels = processor.tokenizer(sample["ground_truth"], add_special_tokens=False, return_tensors="pt", max_length=128, truncation=True).input_ids.squeeze(0)
    return {"pixel_values": pixel_values, "labels": labels}

processed_dataset = dataset.map(preprocess, remove_columns=["image", "ground_truth"])
processed_dataset.set_format(type="torch", columns=["pixel_values", "labels"])

def data_collator(features):
    batch = {}
    batch["pixel_values"] = torch.stack([f["pixel_values"] for f in features])
    labels = [f["labels"] for f in features]
    max_label_length = max(len(l) for l in labels)
    padded_labels = []
    for l in labels:
        padding_length = max_label_length - len(l)
        padded_l = torch.cat([l, torch.full((padding_length,), -100, dtype=torch.long)])
        padded_labels.append(padded_l)
    batch["labels"] = torch.stack(padded_labels)
    return batch

training_args = TrainingArguments(
    output_dir="./output/test",
    num_train_epochs=1,
    per_device_train_batch_size=1,
    logging_steps=1,
    report_to="none"
)

trainer = Trainer(model=model, args=training_args, train_dataset=processed_dataset, data_collator=data_collator)

print("🚀 TEST DI EMERGENZA: Kram sta studiando solo 5 righe...")
trainer.train()
print("✅ CE L'ABBIAMO FATTA!")
