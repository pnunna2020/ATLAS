# Cross-Cutting: Integration Map & Anti-Patterns

## Integration Anti-Patterns to Flag
1. **TIFF-over-FTP (IACRA → CAIS)** — most indefensible integration; CARES Phase 2 must eliminate
2. **SQL Server link (Atlas Aviation → IACRA)** — direct SQL across vendor boundary
3. **Email-based MFA (IACRA)** — violates NIST 800-63B AAL2; not phishing-resistant
4. **Integrated Windows Authentication (DMS)** — ties to on-prem AD, blocks zero-trust
5. **No enterprise-wide airman identifier** — FTN (IACRA/CAIS) vs Applicant ID (MSS) vs Certificate Number (CAIS) vs Designee Number (DMS); everything joined through SSN which FAA is trying to minimize

## Identity Sprawl
- IACRA: local accounts + PIV/MyAccess for FAA
- CARES: MyAccess identity proofing
- MedXPress: own account model
- AMCS/DMS: Login.gov for non-FAA (2025), PIV for FAA

## AI/GenAI Opportunity Heat Map
| # | Opportunity | Where |
|---|---|---|
| 1 | TIFF image intelligence (OCR + extraction + dedup) | RMS/CAIS 174M images |
| 2 | Natural language → application status query | CARES public tier |
| 3 | Form 8500-8 draft validation | MedXPress/AMCS seam |
| 4 | Anomaly detection on designee activity | DMS ↔ IACRA |
| 5 | Airman "golden record" RAG service | Cross-cutting |
| 6 | Fraud detection on aircraft registration | CARES Phase 1 |
| 7 | Agentic migration assistant | CARES transition |

## Rationalization Sequence
1. RMS/AVS Registry — portfolio anchor, clearest legacy burden
2. IACRA → CARES — forcing function for shared identity/document/state services
3. MSS + DMS — shared services (identity, document, workflow), not wholesale replacement
4. Formalize API/event strategy — replace file transfers and portal-to-portal passing
