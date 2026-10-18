# 04. Features — Voice Dictation AI

Inka incorporates speech recognition (`speech_to_text: ^7.3.0`) in `CreateInvoiceScreen` to allow hands-free invoice data entry.

---

## 🎙️ Speech Recognition Flow

```
User Taps Mic Button
        │
        ▼
Request Audio Permission (permission_handler)
        │
        ▼
Initialize SpeechToText Session
        │
        ▼
Capture Live Voice Input Stream
        │
        ├── Context: Line Item Entry ──► Natural Language Item Parser
        └── Context: Notes/Remarks ────► Direct Transcription to Notes Field
```

---

## 🧠 Natural Language Item Parsing

When dictating line items, users can speak naturally:

> **Example**: *"Add 3 UI UX Design for 450 dollars"* or *"Add Website Audit for 1200"*

The internal regex parser extracts:
1. **Quantity**: Scans for leading integers (`3`). Defaults to `1` if omitted.
2. **Item Name**: Captures text between the action word ("add") and price preposition ("for" / "at").
3. **Price**: Extracts numerical tokens following currency symbols or keywords ("for", "at", "dollars", "rupees").

The extracted attributes are automatically populated into a new `InvoiceItem` row, triggering immediate recalculation of subtotal, taxes, and totals.
