// Domain types mirroring the backend admin API response shapes.

export interface AdminInfo {
  id?: string;
  name: string;
  phone: string;
  status?: "active" | "disabled";
  role: string;
}

export interface Admin {
  id: string;
  name: string;
  phone: string;
  status: "active" | "disabled";
  role: string;
  createdAt: string;
}

export interface ChartDaily {
  date: string;
  income: number;
  expense: number;
}

export interface ChartCategory {
  category: string;
  total: number;
  count: number;
}

export interface ChartsData {
  days: number;
  daily: ChartDaily[];
  topCategories: ChartCategory[];
}

export interface AuditLog {
  id: string;
  actorAdminId: string;
  actorName: string;
  action: string;
  targetType: string;
  targetId: string;
  detail: string;
  ip: string;
  createdAt: string;
}

export interface Stats {
  users: number;
  accounts: number;
  pockets: number;
  cards: number;
  transactions: number;
  transfers: number;
  bills: number;
  pools: number;
  totalBalance: number;
  pocketBalance: number;
}

export interface AdminUser {
  id: string;
  name: string;
  phone: string;
  accountNumber: string;
  balance: number;
  createdAt: string;
}

export interface AdminTransaction {
  id: string;
  userId: string;
  userName: string;
  title: string;
  category: string;
  amount: number;
  type: "income" | "expense";
  createdAt: string;
}

export interface Pocket {
  id: string;
  name: string;
  type: "main" | "spending" | "saving";
  balance: number;
  target?: number;
  isMain: boolean;
  locked: boolean;
  shared: boolean;
}

export interface Card {
  id: string;
  label: string;
  number: string;
  holderName: string;
  expiry: string;
  type: "virtual" | "physical";
  isFrozen: boolean;
}

export interface Bill {
  id: string;
  biller: string;
  category: string;
  amount: number;
  dueDate: string;
  isPaid: boolean;
  recurrence: string;
}

export interface Pool {
  id: string;
  title: string;
  target: number;
  collected: number;
  status: "open" | "closed";
  createdAt: string;
}

export interface AdminPool extends Pool {
  ownerUserId: string;
  ownerName: string;
}

export interface UserDetail {
  user: { id: string; name: string; phone: string; createdAt: string };
  account: { accountNumber: string; balance: number } | null;
  pockets: Pocket[];
  cards: Card[];
  bills: Bill[];
  pools: Pool[];
  transactions: AdminTransaction[];
}

export type TxFilter = "" | "income" | "expense";

export interface Meta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
}

export interface Page<T> {
  data: T[];
  meta: Meta;
}
