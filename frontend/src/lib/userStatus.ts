import type { KycStatus, UserStatus } from "./types";

// Display labels + chip styling for user KYC and access status.

export const KYC_LABELS: Record<KycStatus, string> = {
  none: "Belum KYC",
  pending: "KYC Menunggu",
  verified: "Terverifikasi",
  rejected: "KYC Ditolak",
};

export const KYC_OPTIONS: KycStatus[] = [
  "none",
  "pending",
  "verified",
  "rejected",
];

export const STATUS_LABELS: Record<UserStatus, string> = {
  active: "Aktif",
  blocked: "Diblokir",
};

export const STATUS_OPTIONS: UserStatus[] = ["active", "blocked"];

export function kycChipClass(s: KycStatus): string {
  if (s === "verified") return "chip chip-ok";
  if (s === "rejected") return "chip chip-danger";
  if (s === "pending") return "chip chip-warn";
  return "chip";
}

export function statusChipClass(s: UserStatus): string {
  return s === "blocked" ? "chip chip-danger" : "chip chip-ok";
}
