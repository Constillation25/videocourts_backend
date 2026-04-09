import { int, mysqlEnum, mysqlTable, text, timestamp, varchar, decimal, boolean, json } from "drizzle-orm/mysql-core";

/**
 * Core user table backing auth flow.
 * Extend this file with additional tables as your product grows.
 * Columns use camelCase to match both database fields and generated types.
 */
export const users = mysqlTable("users", {
  /**
   * Surrogate primary key. Auto-incremented numeric value managed by the database.
   * Use this for relations between tables.
   */
  id: int("id").autoincrement().primaryKey(),
  /** Manus OAuth identifier (openId) returned from the OAuth callback. Unique per user. */
  openId: varchar("openId", { length: 64 }).notNull().unique(),
  name: text("name"),
  email: varchar("email", { length: 320 }),
  loginMethod: varchar("loginMethod", { length: 64 }),
  role: mysqlEnum("role", ["user", "admin", "judge", "clerk", "attorney", "defendant", "observer"]).default("user").notNull(),
  phoneNumber: varchar("phoneNumber", { length: 20 }),
  biometricEnrolled: boolean("biometricEnrolled").default(false).notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
  lastSignedIn: timestamp("lastSignedIn").defaultNow().notNull(),
});

export type User = typeof users.$inferSelect;
export type InsertUser = typeof users.$inferInsert;

// Court Cases Table
export const cases = mysqlTable("cases", {
  id: int("id").autoincrement().primaryKey(),
  caseNumber: varchar("caseNumber", { length: 64 }).notNull().unique(),
  caseId: varchar("caseId", { length: 128 }).notNull().unique(),
  title: text("title"),
  description: text("description"),
  judgeId: int("judgeId"),
  status: mysqlEnum("status", ["open", "scheduled", "in-progress", "completed", "closed"]).default("open").notNull(),
  courtName: varchar("courtName", { length: 255 }),
  county: varchar("county", { length: 128 }),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type Case = typeof cases.$inferSelect;
export type InsertCase = typeof cases.$inferInsert;

// Virtual Court Sessions Table
export const sessions = mysqlTable("sessions", {
  id: int("id").autoincrement().primaryKey(),
  sessionId: varchar("sessionId", { length: 128 }).notNull().unique(),
  caseId: int("caseId").notNull(),
  judgeId: int("judgeId").notNull(),
  status: mysqlEnum("status", ["scheduled", "in-progress", "completed", "cancelled"]).default("scheduled").notNull(),
  videoRoomUrl: text("videoRoomUrl"),
  startTime: timestamp("startTime"),
  endTime: timestamp("endTime"),
  expectedDurationMinutes: int("expectedDurationMinutes").default(30),
  calendarId: varchar("calendarId", { length: 128 }),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type Session = typeof sessions.$inferSelect;
export type InsertSession = typeof sessions.$inferInsert;

// Session Participants Table
export const sessionParticipants = mysqlTable("sessionParticipants", {
  id: int("id").autoincrement().primaryKey(),
  sessionId: int("sessionId").notNull(),
  userId: int("userId").notNull(),
  role: mysqlEnum("role", ["judge", "clerk", "attorney", "defendant", "observer"]).notNull(),
  identityVerified: boolean("identityVerified").default(false),
  riskScore: decimal("riskScore", { precision: 5, scale: 2 }),
  accessToken: text("accessToken"),
  joinedAt: timestamp("joinedAt"),
  leftAt: timestamp("leftAt"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type SessionParticipant = typeof sessionParticipants.$inferSelect;
export type InsertSessionParticipant = typeof sessionParticipants.$inferInsert;

// Evidence Table
export const evidence = mysqlTable("evidence", {
  id: int("id").autoincrement().primaryKey(),
  evidenceId: varchar("evidenceId", { length: 128 }).notNull().unique(),
  caseId: int("caseId").notNull(),
  fileName: varchar("fileName", { length: 255 }).notNull(),
  fileSize: int("fileSize"),
  mimeType: varchar("mimeType", { length: 128 }),
  sha256Hash: varchar("sha256Hash", { length: 64 }).notNull(),
  description: text("description"),
  uploadedBy: int("uploadedBy").notNull(),
  s3Key: text("s3Key"),
  s3Url: text("s3Url"),
  chainLink: varchar("chainLink", { length: 64 }),
  previousChainLink: varchar("previousChainLink", { length: 64 }),
  status: mysqlEnum("status", ["pending", "verified", "archived"]).default("pending").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type Evidence = typeof evidence.$inferSelect;
export type InsertEvidence = typeof evidence.$inferInsert;

// Forensic Reports Table
export const forensicReports = mysqlTable("forensicReports", {
  id: int("id").autoincrement().primaryKey(),
  reportId: varchar("reportId", { length: 128 }).notNull().unique(),
  caseId: int("caseId").notNull(),
  generatedBy: int("generatedBy").notNull(),
  content: text("content"),
  s3Key: text("s3Key"),
  s3Url: text("s3Url"),
  status: mysqlEnum("status", ["draft", "completed", "exported"]).default("draft").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type ForensicReport = typeof forensicReports.$inferSelect;
export type InsertForensicReport = typeof forensicReports.$inferInsert;

// Audit Logs Table
export const auditLogs = mysqlTable("auditLogs", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId"),
  action: varchar("action", { length: 128 }).notNull(),
  resource: varchar("resource", { length: 128 }).notNull(),
  resourceId: varchar("resourceId", { length: 128 }),
  details: json("details"),
  ipAddress: varchar("ipAddress", { length: 45 }),
  userAgent: text("userAgent"),
  status: mysqlEnum("status", ["success", "failure"]).default("success").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type AuditLog = typeof auditLogs.$inferSelect;
export type InsertAuditLog = typeof auditLogs.$inferInsert;

// Identity Verification Attempts Table
export const identityVerifications = mysqlTable("identityVerifications", {
  id: int("id").autoincrement().primaryKey(),
  userId: int("userId").notNull(),
  caseId: int("caseId"),
  biometricToken: text("biometricToken"),
  riskScore: decimal("riskScore", { precision: 5, scale: 2 }),
  verified: boolean("verified").default(false),
  reason: text("reason"),
  accessToken: text("accessToken"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type IdentityVerification = typeof identityVerifications.$inferSelect;
export type InsertIdentityVerification = typeof identityVerifications.$inferInsert;

// CM/ECF Exports Table
export const cmecfExports = mysqlTable("cmecfExports", {
  id: int("id").autoincrement().primaryKey(),
  exportId: varchar("exportId", { length: 128 }).notNull().unique(),
  caseId: int("caseId").notNull(),
  exportedBy: int("exportedBy").notNull(),
  s3Key: text("s3Key"),
  s3Url: text("s3Url"),
  status: mysqlEnum("status", ["pending", "completed", "failed"]).default("pending").notNull(),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
  updatedAt: timestamp("updatedAt").defaultNow().onUpdateNow().notNull(),
});

export type CMECFExport = typeof cmecfExports.$inferSelect;
export type InsertCMECFExport = typeof cmecfExports.$inferInsert;

// Tyler Integration Log Table
export const tylerIntegrationLogs = mysqlTable("tylerIntegrationLogs", {
  id: int("id").autoincrement().primaryKey(),
  caseId: int("caseId").notNull(),
  action: varchar("action", { length: 128 }).notNull(),
  payload: json("payload"),
  response: json("response"),
  status: mysqlEnum("status", ["pending", "success", "failed"]).default("pending").notNull(),
  errorMessage: text("errorMessage"),
  createdAt: timestamp("createdAt").defaultNow().notNull(),
});

export type TylerIntegrationLog = typeof tylerIntegrationLogs.$inferSelect;
export type InsertTylerIntegrationLog = typeof tylerIntegrationLogs.$inferInsert;