# 04. Features — Device Contacts & WhatsApp Sharing

Inka simplifies client onboarding and bill distribution by interfacing directly with device contacts and WhatsApp.

---

## 📇 Device Contacts Integration

Managed via `DeviceContactService` (`lib/services/device_contact_service.dart`) and `DeviceContactPickerSheet`:

1. **Permission Handling**:
   Requests `Permission.contacts` via `flutter_contacts`.
2. **Search & Fetch**:
   Fetches contacts with phone numbers and email addresses, filtering out empty entries.
3. **One-Tap Import**:
   Users can tap any contact from their mobile address book to instantly pre-fill a `Client` entity (Name, Phone, Email) without manual typing.

---

## 💬 WhatsApp Direct Delivery

Managed via `WhatsAppService` (`lib/services/whatsapp_service.dart`):

1. **Sanitization**:
   Normalizes client phone numbers into E.164 international format (strips spaces, dashes, parentheses, prepends country code).
2. **Dynamic Message Assembly**:
   Constructs a personalized billing message:
   ```
   Hi {Client Name},
   
   Here is the invoice {INV-001} from {Business Name} for the amount of {Currency}{Total}.
   Due Date: {Due Date}
   
   You can pay directly using UPI: {upi://pay...}
   
   Thank you for your business!
   ```
3. **Direct Dispatch**:
   Launches the native WhatsApp application via `url_launcher` using the `whatsapp://send?phone={number}&text={encodedText}` URI scheme.
