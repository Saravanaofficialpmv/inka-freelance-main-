# 05. Backend & Cloud — Security Rules

Inka enforces multi-tenant database isolation using Cloud Firestore Security Rules (`firestore.rules`).

---

## 🛡️ Production Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Strict User-Level Sandboxing
    // A user can ONLY read, create, update, or delete documents inside their own {userId} hierarchy.
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Block all unauthorized top-level access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 🔒 Security Guarantees

1. **Complete Tenant Isolation**:
   No user can read, query, or enumerate invoices, clients, products, or financial statistics belonging to another user.
2. **Authentication Requirement**:
   Unauthenticated visitors (`request.auth == null`) are rejected at the Firestore network edge.
3. **No Cross-User Leaks**:
   Even if an attacker guessed an invoice UUID, the request is immediately denied unless `request.auth.uid == userId`.
