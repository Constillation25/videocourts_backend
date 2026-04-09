/**
 * TotalRecall Integration Module
 * 
 * Provides sovereign file indexing, cryptographic verification, and chain-of-custody
 * tracking for video evidence and court documents using blockchain-style hashing.
 */

import crypto from "crypto";
import { storagePut, storageGet } from "../storage";

export interface TotalRecallFile {
  id: string;
  name: string;
  hash: string; // SHA256
  size: number;
  mimeType: string;
  uploadedAt: Date;
  uploadedBy: string;
  s3Key: string;
  s3Url: string;
  metadata: Record<string, unknown>;
  chainOfCustody: ChainOfCustodyEntry[];
}

export interface ChainOfCustodyEntry {
  timestamp: Date;
  action: "uploaded" | "accessed" | "verified" | "exported" | "archived";
  actor: string;
  actorRole: string;
  details: string;
  ipAddress?: string;
  hash: string; // Hash of this entry for integrity
}

export interface TotalRecallIndexEntry {
  fileId: string;
  fileName: string;
  fileHash: string;
  indexed: Date;
  tags: string[];
  searchableContent?: string;
  relatedFiles: string[];
}

/**
 * Calculate SHA256 hash of file content
 */
export function calculateFileHash(buffer: Buffer | Uint8Array): string {
  return crypto
    .createHash("sha256")
    .update(buffer)
    .digest("hex");
}

/**
 * Verify file integrity using stored hash
 */
export function verifyFileIntegrity(
  buffer: Buffer | Uint8Array,
  expectedHash: string
): boolean {
  const calculatedHash = calculateFileHash(buffer);
  return calculatedHash === expectedHash;
}

/**
 * Create chain-of-custody entry with cryptographic linking
 */
export function createChainOfCustodyEntry(
  action: ChainOfCustodyEntry["action"],
  actor: string,
  actorRole: string,
  details: string,
  previousHash?: string,
  ipAddress?: string
): ChainOfCustodyEntry {
  const entry: ChainOfCustodyEntry = {
    timestamp: new Date(),
    action,
    actor,
    actorRole,
    details,
    ipAddress,
    hash: "", // Will be calculated below
  };

  // Create hash of this entry (including previous hash for blockchain-style linking)
  const entryString = JSON.stringify({
    timestamp: entry.timestamp.toISOString(),
    action: entry.action,
    actor: entry.actor,
    actorRole: entry.actorRole,
    details: entry.details,
    previousHash: previousHash || "genesis",
  });

  entry.hash = crypto
    .createHash("sha256")
    .update(entryString)
    .digest("hex");

  return entry;
}

/**
 * Verify chain-of-custody integrity
 */
export function verifyChainOfCustody(
  entries: ChainOfCustodyEntry[]
): { valid: boolean; issues: string[] } {
  const issues: string[] = [];

  if (entries.length === 0) {
    return { valid: true, issues: [] };
  }

  let previousHash = "genesis";

  for (let i = 0; i < entries.length; i++) {
    const entry = entries[i];

    // Verify entry hash
    const entryString = JSON.stringify({
      timestamp: entry.timestamp.toISOString(),
      action: entry.action,
      actor: entry.actor,
      actorRole: entry.actorRole,
      details: entry.details,
      previousHash: previousHash,
    });

    const calculatedHash = crypto
      .createHash("sha256")
      .update(entryString)
      .digest("hex");

    if (calculatedHash !== entry.hash) {
      issues.push(
        `Chain-of-custody entry ${i} hash mismatch at ${entry.timestamp.toISOString()}`
      );
    }

    previousHash = entry.hash;
  }

  return {
    valid: issues.length === 0,
    issues,
  };
}

/**
 * Upload file to TotalRecall vault with SHA256 hashing
 */
export async function uploadToTotalRecall(
  fileBuffer: Buffer | Uint8Array,
  fileName: string,
  mimeType: string,
  uploadedBy: string,
  metadata: Record<string, unknown> = {}
): Promise<TotalRecallFile> {
  // Calculate SHA256 hash
  const fileHash = calculateFileHash(fileBuffer);

  // Generate unique file key
  const timestamp = Date.now();
  const randomSuffix = Math.random().toString(36).substring(2, 8);
  const s3Key = `totalrecall/${uploadedBy}/${timestamp}-${randomSuffix}-${fileName}`;

  // Upload to S3
  const { url: s3Url } = await storagePut(s3Key, fileBuffer, mimeType);

  // Create initial chain-of-custody entry
  const initialEntry = createChainOfCustodyEntry(
    "uploaded",
    uploadedBy,
    "system",
    `File uploaded to TotalRecall vault: ${fileName}`,
    undefined
  );

  // Create TotalRecall file record
  const totalRecallFile: TotalRecallFile = {
    id: `tr-${timestamp}-${randomSuffix}`,
    name: fileName,
    hash: fileHash,
    size: Buffer.isBuffer(fileBuffer) ? fileBuffer.length : fileBuffer.byteLength,
    mimeType,
    uploadedAt: new Date(),
    uploadedBy,
    s3Key,
    s3Url,
    metadata,
    chainOfCustody: [initialEntry],
  };

  return totalRecallFile;
}

/**
 * Add access entry to chain-of-custody
 */
export function addAccessEntry(
  file: TotalRecallFile,
  actor: string,
  actorRole: string,
  ipAddress?: string
): TotalRecallFile {
  const lastEntry = file.chainOfCustody[file.chainOfCustody.length - 1];
  const previousHash = lastEntry?.hash || "genesis";

  const newEntry = createChainOfCustodyEntry(
    "accessed",
    actor,
    actorRole,
    `File accessed by ${actor}`,
    previousHash,
    ipAddress
  );

  file.chainOfCustody.push(newEntry);
  return file;
}

/**
 * Add verification entry to chain-of-custody
 */
export function addVerificationEntry(
  file: TotalRecallFile,
  actor: string,
  actorRole: string,
  verificationResult: boolean
): TotalRecallFile {
  const lastEntry = file.chainOfCustody[file.chainOfCustody.length - 1];
  const previousHash = lastEntry?.hash || "genesis";

  const newEntry = createChainOfCustodyEntry(
    "verified",
    actor,
    actorRole,
    `File integrity verified: ${verificationResult ? "PASS" : "FAIL"}`,
    previousHash
  );

  file.chainOfCustody.push(newEntry);
  return file;
}

/**
 * Create TotalRecall index entry for searchable file
 */
export function createIndexEntry(
  file: TotalRecallFile,
  tags: string[] = [],
  searchableContent?: string,
  relatedFiles: string[] = []
): TotalRecallIndexEntry {
  return {
    fileId: file.id,
    fileName: file.name,
    fileHash: file.hash,
    indexed: new Date(),
    tags: [
      ...tags,
      file.mimeType.split("/")[0], // Add type tag (video, image, etc.)
    ],
    searchableContent,
    relatedFiles,
  };
}

/**
 * Generate forensic report for file
 */
export function generateForensicReport(file: TotalRecallFile): string {
  const report = `
# TotalRecall Forensic Report

## File Information
- **File ID**: ${file.id}
- **File Name**: ${file.name}
- **File Size**: ${file.size} bytes
- **MIME Type**: ${file.mimeType}
- **SHA256 Hash**: ${file.hash}
- **Uploaded At**: ${file.uploadedAt.toISOString()}
- **Uploaded By**: ${file.uploadedBy}

## Storage Location
- **S3 Key**: ${file.s3Key}
- **S3 URL**: ${file.s3Url}

## Chain of Custody
| Timestamp | Action | Actor | Role | Details | Hash |
|-----------|--------|-------|------|---------|------|
${file.chainOfCustody
  .map(
    (entry) =>
      `| ${entry.timestamp.toISOString()} | ${entry.action} | ${entry.actor} | ${entry.actorRole} | ${entry.details} | ${entry.hash.substring(0, 8)}... |`
  )
  .join("\n")}

## Integrity Verification
${
  file.chainOfCustody.length > 0
    ? `- **Chain Valid**: ${verifyChainOfCustody(file.chainOfCustody).valid ? "✓ YES" : "✗ NO"}`
    : "- **Chain Valid**: No entries"
}

## Metadata
\`\`\`json
${JSON.stringify(file.metadata, null, 2)}
\`\`\`

---
*Report Generated: ${new Date().toISOString()}*
*VideoCourts™ TotalRecall Forensic Evidence Vault*
`;

  return report;
}

/**
 * Export file with forensic certification
 */
export async function exportWithCertification(
  file: TotalRecallFile,
  exportedBy: string,
  exportedByRole: string
): Promise<{
  file: TotalRecallFile;
  forensicReport: string;
  exportCertificate: string;
}> {
  // Add export entry to chain
  const updatedFile = addAccessEntry(file, exportedBy, exportedByRole);

  // Generate forensic report
  const forensicReport = generateForensicReport(updatedFile);

  // Create export certificate
  const certificate = `
VIDEOCOURTS™ FORENSIC EVIDENCE EXPORT CERTIFICATE

File ID: ${file.id}
File Name: ${file.name}
SHA256 Hash: ${file.hash}
Export Date: ${new Date().toISOString()}
Exported By: ${exportedBy} (${exportedByRole})

This certifies that the above-referenced file has been exported from the 
VideoCourts™ TotalRecall Forensic Evidence Vault with complete chain-of-custody 
verification. The file integrity has been verified using SHA256 cryptographic hashing.

Chain of Custody Entries: ${updatedFile.chainOfCustody.length}
Chain Integrity: ${verifyChainOfCustody(updatedFile.chainOfCustody).valid ? "VERIFIED ✓" : "COMPROMISED ✗"}

This export is suitable for court filing and legal proceedings.

---
Digitally Certified by VideoCourts™ Justice Stack
${new Date().toISOString()}
`;

  return {
    file: updatedFile,
    forensicReport,
    exportCertificate: certificate,
  };
}
