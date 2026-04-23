# CARES — Current-State Analysis

Civil Aviation Registration Electronic Services — cloud replacement umbrella mandated by Section 546 of the FAA Reauthorization Act of 2018. Intended to consolidate Aircraft Registry, Airmen Registry, IACRA, and public inquiry services into a single modern web platform. As of 2026-04-23, CARES is in a **hybrid state**: it is live for Phase 1 aircraft registration intake, but the legacy adjudication core (RMS mainframe, AVS Registry/CAIS, IACRA) still runs behind it. Phase 1 FOC has slipped four years from the original Fall 2023 target to Fall 2027.

---

## 1. System Identity

| Attribute | Value |
|---|---|
| Name | Civil Aviation Registration Electronic Services (CARES) |
| URL | https://cares.faa.gov |
| Owning org | Registry Services & Information Management Branch |
| Program lead | Craig Whitbeck |
| Hosting site | Mike Monroney Aeronautical Center (MMAC), Oklahoma City |
| Authority to Operate | September 16, 2022 |
| Mandate | Section 546, FAA Reauthorization Act of 2018 |
| Scope exclusion | MedXPress/MSS is NOT in CARES scope |

CARES is the statutorily-mandated modernization vehicle for civil aviation registration. The mandate is legislative, not internal FAA prioritization — the program exists because Congress required it. This makes schedule slippage politically visible in a way that most IT modernization programs are not.

---

## 2. Technology Stack

| Layer | Technology / Provider | Notes |
|---|---|---|
| Hosting | Cloud-based | Specific CSP not disclosed in public PIA |
| Authentication | MyAccess | Single IdP handles both FAA PIV (internal staff) and public identity-proofed accounts |
| Public identity proofing | MyAccess native | SSN last-4, government ID upload, selfie photo match, reCAPTCHA gate |
| Digital signature | DocuSign | Replaces wet-ink signature on registration forms |
| Payment | Pay.gov | Treasury-operated collection service |
| Bot protection | reCAPTCHA | On public-facing intake pages |
| Records retention | NARA schedule N1-237-04-03 | Permanent records |

Notable: CARES does not run its own identity system. It federates to MyAccess for both employee and citizen authentication — a single IdP straddling two very different assurance populations. This is both a simplification (one system to integrate) and a coupling risk (MyAccess outage takes down both sides).

No public API. All integration is through MyAccess federation, Pay.gov/DocuSign callbacks, and internal coexistence with AVS Registry/CAIS.

---

## 3. Phase Plan & Schedule

Task order effective **August 28, 2020**. Three RFIs preceded the award, indicating the FAA struggled to scope the work before committing.

| Phase | Scope | Original plan | Current plan | Slip |
|---|---|---|---|---|
| Phase 1 | Aircraft Registration (individuals) | IOC Dec 2022, FOC Fall 2023 | IOC Dec 2022 (met), FOC Fall 2027 | +4 years on FOC |
| Phase 2 | Airman Examination + Certification | IOC Fall 2024, FOC Fall 2025 | IOC Fall 2025, FOC Fall 2027 | +2 years on FOC |
| Phase 3 | UAS services | Fall 2025 standalone | Absorbed into Phases 1/2 | scope collapsed |

**Program-level slip:** originally a 3-year program (2020 task order → 2023 FOC). Now effectively a 7-year program ending Fall 2027. Phase 3 disappearing into the other phases is either a scope simplification or a quiet descope — the public record doesn't distinguish.

---

## 4. Data Architecture

CARES is intentionally lean on data it owns — for Phase 1, it collects only what is needed to register an aircraft.

**Phase 1 (live) data elements:**
- Registrant name, address, phone, email
- N-number (tail number) request or assignment
- Aircraft make, model, serial number
- Uploaded legal documents (bill of sale, evidence of ownership, LLC/trust paperwork)

**Phase 2 (planned) data elements:**
- Will pull the full airmen dataset currently in IACRA / CAIS
- Examination results, certificate issuance, ratings, endorsements
- Not yet live — data model may still change before FOC

The **adjudicated record of truth still lives in the legacy Registry (CAIS/RMS)** during the dual-run window. CARES is the intake surface; the authoritative system is still behind it.

---

## 5. Forms/Documents in Scope

Per PIA Appendix A, 14 forms are in scope across the phases:

| Form | Purpose |
|---|---|
| AC 8050-1 | Aircraft Registration Application |
| AC 8050-1B | Aircraft Re-registration / Renewal |
| AC 8050-88 / 88A | Dealer's Aircraft Registration Application |
| AC 8050-98 | Aircraft Registration Renewal |
| AC 8050-2 | Aircraft Bill of Sale |
| AC 8050-4 | International Registry / Cape Town filing |
| AC 8050-5 | Triennial Aircraft Registration Report |
| REGAR series | Registration amendment forms |
| LLC statement | Limited Liability Company ownership attestation |
| DIO | Declaration of International Operations |
| Heir-at-Law | Ownership-by-inheritance affidavit |
| POA | Power of Attorney |
| Evidence of Ownership | Catch-all for ownership chain documentation |

Form-set is Aircraft-Registry-dominant. No airman forms yet — those come with Phase 2.

---

## 6. Identity & Onboarding

CARES' identity model is a split population routed through one IdP:

**FAA PIV population:** Employees and contractors authenticate with their PIV card through MyAccess. Assurance is handled by the PIV issuance process itself.

**Public identity-proofed population:** External filers (aircraft owners, trustees, attorneys, designees) go through MyAccess identity proofing:
1. SSN last-4 collection
2. Government-issued photo ID upload (driver's license, passport)
3. Selfie photo with liveness / match to ID
4. reCAPTCHA on the front end

MyAccess is the single integration point for both — CARES itself holds no passwords or credentials. This is a genuine improvement over the legacy systems (IACRA had its own auth; RMS had terminal/mainframe access controls).

---

## 7. Integration Architecture

```
                    ┌─────────────────┐
                    │    MyAccess     │──── inbound auth (PIV + public)
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
   Pay.gov ◄────────┤                 ├────────► DocuSign
   (outbound +      │     CARES       │         (outbound +
    callback)       │  cares.faa.gov  │          signed-doc callback)
                    │                 │
                    └────────┬────────┘
                             │
                    ┌────────▼────────────┐
                    │  AVS Registry /     │
                    │  CAIS (coexistence  │
                    │  + handover)        │
                    └─────────────────────┘
```

- **MyAccess** — inbound federated authentication for both user populations
- **Pay.gov** — outbound payment initiation, inbound receipt callback
- **DocuSign** — outbound envelope creation, inbound signed-document callback
- **AVS Registry / CAIS** — bidirectional coexistence during dual-run; handover of finalized records to the legacy registry of truth

---

## 8. Relationship to Legacy Systems

CARES is in a **hybrid state**: new intake surface, old adjudication core.

| Legacy system | Relationship | Status |
|---|---|---|
| RMS (mainframe) | CARES submits; RMS still adjudicates Aircraft Registry records | Decommission planned, no firm date |
| AVS Registry / CAIS | Canonical store during transition | Must stay live through FOC |
| IACRA | Phase 2 absorption target | Planned, not executed |
| DRS | Separate absorption track (airman medical) | Out of scope — see MedXPress/MSS profile |

The hybrid state was not the original plan — it is the consequence of the Phase 1 FOC slip. A four-year delay on Phase 1 FOC means the dual-run window is now the steady-state, not a short transition. IACRA absorption can't begin in earnest until Phase 1 is closed out.

---

## 9. Compliance & Governance

| Item | Detail |
|---|---|
| Authority to Operate | September 16, 2022 |
| Security review cadence | Annual |
| Statutory basis | Section 546, FAA Reauthorization Act of 2018 |
| Privacy Impact Assessment | CARES PIA 2022 (on file) |
| Records retention | NARA N1-237-04-03 (permanent) |
| Governing regulations | 14 CFR Parts 47 (aircraft registration) and 49 (recording of aircraft conveyances), updated January 2025 |

The January 2025 Parts 47/49 update is a recent regulatory change that CARES must track. Any behavioral or data-element change driven by the Parts update has to flow through both the CARES intake surface and the legacy adjudication core — a cost multiplier of the hybrid state.

---

## 10. Schedule Risk Analysis

**Headline risk:** Phase 1 FOC slip from Fall 2023 → Fall 2027 is the single biggest signal in the entire registration modernization portfolio. A 4-year slip on a 3-year program is effectively a restart.

**Contributing factors (inferred from public record):**
- Three RFIs before award — scope was not well-understood at task-order time
- Phase 3 absorbed into Phases 1/2 — suggests scope rebalancing under duress, not clean simplification
- Phase 2 IOC also moved (Fall 2024 → Fall 2025)
- Hybrid state extends the IACRA dual-run window indefinitely until Phase 1 closes

**Downstream impacts:**
- IACRA absorption cannot start until Phase 1 FOC — so Fall 2027 is the earliest reasonable Phase 2 execution window
- RMS mainframe decommission is blocked behind CARES FOC
- Every Parts 47/49 regulatory change during the dual-run has to be implemented twice
- Program credibility with Congress (Section 546 mandate) erodes with each slip

---

## 11. Technical Debt & Risk Assessment

| Risk | Severity | Notes |
|---|---|---|
| Hybrid state is now steady-state | High | Dual maintenance of CARES + RMS + CAIS + IACRA for 4+ additional years |
| RMS mainframe concurrent operation | High | Mainframe expertise attrition during extended dual-run |
| Identity model split | Medium | One IdP, two populations — MyAccess outage is a full CARES outage |
| No public API | Medium | All integration is brittle file-drop or human-mediated; no modern integration surface for designees/DMS |
| Phase 2 data model not yet fixed | Medium | Airmen absorption still being designed; schedule risk compounds |
| DocuSign / Pay.gov vendor coupling | Low | Treasury-endorsed and widely used, but still single points of integration |
| Section 546 political exposure | Medium | Statutory mandate with a visible deadline means slippage attracts oversight |

The core technical debt is not in CARES itself — it is in **everything CARES has not yet replaced**. The longer the hybrid state runs, the more the legacy systems accumulate incremental changes that CARES will later have to match.

---

## 12. Rationalization Recommendations

1. **Make CARES the only intake system.** Even before Phase 2 FOC, route all new intake through CARES — including airman applications — with a thin adapter to IACRA for adjudication. Stop adding features to legacy intake surfaces. Every form still accepted outside CARES extends the hybrid state.

2. **Build one canonical registry document service.** Aircraft Registry, Airmen Registry, and designee-submitted documents (DMS) all need the same primitives: upload, virus scan, preservation, retrieval, NARA retention. Build it once under CARES; retire the per-system document stores.

3. **Build one payment abstraction.** Pay.gov is already the backend — make CARES the one integration point and have IACRA / AVS Registry call through CARES rather than integrating Pay.gov separately. Reduces Treasury-integration surface from N to 1.

4. **Accept adapter services during dual-run.** Don't try to eliminate the hybrid state by accelerating Phase 1/2. Instead, invest in the adapters (CARES→RMS, CARES→CAIS, CARES→IACRA) as first-class services with SLAs. The dual-run is now long enough (4+ years) that adapters deserve real engineering, not script-grade glue.

5. **Don't swing for the fence on Phase 2.** The Phase 1 slip pattern suggests the program cannot absorb large new scope well. For Phase 2, target a narrow airman-certification MVP that replaces IACRA's intake first, and leave examination workflows and full absorption for a separate phase. Small increments with public milestones will rebuild credibility faster than another multi-year monolithic push.

6. **Lock the Phase 2 data model early.** Pull the full airmen dataset from IACRA/CAIS as a read-only federation first, and only migrate ownership once the CARES representation has been stable for two or more quarters. This avoids carrying schema churn into production.

7. **Publish a public API.** The lack of a modern integration surface forces every downstream consumer (DMS, designees, airmen's workflow tools) to rely on screen-scraping or manual handoff. A REST/OAuth surface costs modest effort and unblocks the rest of the portfolio.
