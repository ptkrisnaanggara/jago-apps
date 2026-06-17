# Bank Jago — Feature Parity

How this project maps to the real **Bank Jago** app, with status and plan.
Legend: ✅ implemented · 🟡 partial · ⏳ planned · 🔌 needs a real 3rd‑party
integration (implemented as a mock/simulation here).

| Real Jago feature | Status | Notes |
| --- | --- | --- |
| Onboarding + phone/OTP auth, KYC | 🟡 | Phone+OTP done (mock `123456`); KYC ⏳ |
| **Kantong (Pockets)** — up to 60 accounts | 🟡→✅ | List + **types, create, move money between pockets** (this change). Lock / autosave / shared ⏳ |
| Pocket types: Main / Spending / Saving | ✅ | `main` / `spending` / `saving` |
| Saving target + progress | ✅ | `target` + progress bar |
| Saving lock & autosave | ✅ | lock blocks moving out; autosave top-up from main |
| Shared / joint pockets (Kantong Bersama) | ⏳ | needs multi‑user invites |
| Interest (bunga) on savings | ⏳ | |
| Transfer & Pay (to contact / bank) | ✅ | contact picker → amount → receipt; event‑driven notification |
| Move money between pockets | ✅ | this change |
| **QRIS** scan‑to‑pay (linked to Spending Pocket) | ✅ | EMV TLV parse + pay from a pocket |
| Bills & payment plans (PLN, etc.) | ✅ | list / schedule / pay |
| Top‑up prepaid (pulsa / data) | ✅ | catalog + pay from a pocket |
| Money Pool / Patungan | ✅ | create → contribute → close (cash out to main pocket) |
| Cards (Visa debit, virtual, freeze) | ✅ | freeze/unfreeze + reveal details |
| Transactions history (+ filters) | ✅ | list + pagination + type filter |
| Notifications centre | ✅ | read/unread, mark‑all, live badge |
| Profile & settings (language, theme) | ✅ | id/en + light/dark |
| Security: PIN / biometric | 🟡 | app-lock PIN done (hashed); biometric ⏳ |
| e‑Wallet link (GoPay/GoTo) | 🔌 | external integration |
| Investments (Bibit / Stockbit) | 🔌 | external integration |
| Insurance ("Last Wish") | 🔌 | external integration |

## Implementation order (remaining)
1. **Kantong**: create + move money + types — _this change_.
2. **QRIS** pay (scan a payload → pay from a Spending Pocket).
3. **Top‑up** prepaid (pulsa/data) — extends the Bills/biller model.
4. Saving **lock/autosave**, transaction **filters**, security **PIN**.
5. Money Pool / Shared pockets (multi‑user).
6. 🔌 External: e‑wallet link, investments, insurance (mock surfaces only).
