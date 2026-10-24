# Contrib – fake data generator

PowerShell tooling for populating a One Identity Manager database with a realistic, reproducible fake organization. Everything here talks to the database through the Identity Manager object layer (`VI.DB`), never through raw SQL, so templates, triggers and DBQueue tasks fire exactly as they would for real data.

## Layout

| Path | What it is |
|---|---|
| `..\PSIdentityManagerUtils\` | The **PSIdentityManagerUtils** module. Loads the product DLLs, opens a session and generates typed `New-/Get-/Set-/Remove-<Table>` cmdlets from the database schema at runtime. Exported cmdlets in `Public\*.ps1` (`New-IdentityManagerSession`, `New-Entity`, `Set-Entity`, `Get-Entity`, `Test-Entity`, `Invoke-EntityMethod`, `New-UnitOfWork`, `Add-UnitOfWorkEntity`, `Save-UnitOfWork`, `Get-ConfigParm`, `Get-TableCount`, …); session resolution, `*-TypedWrapperProvider` generators, entity member extensions and exception handling in `Private\*.ps1`. |
| `FillDbWithFakeData.ps1` | **The fake-data script.** Builds the whole organization in one run. |
| `BmwFakeData/BmwFakeData.psm1` | Product pool for the IT Shop: 288 BMW models + 10 WWII German small arms, each pre-formatted as an `AccProduct`. |
| `GermanNames/GermanNames.psm1` | Name pool for identities: 100 male + 100 female first names typical for German birth cohorts 1900-1950, 200 most common German surnames. |

## Dependencies

- **PowerShell 5.1 or 7.** The script picks `net40\` or `net6.0\` sub-folders for third-party DLLs by `$PSVersionTable.PSVersion.Major`. Use 5.1 for .NET Framework product files (v92), 7 for .NET ones. Script and data modules are UTF-8 **with BOM**; without it 5.1 mangles the umlauts.
- **Bogus.dll** (NuGet `Bogus`) in `.\net40\` or `.\net6.0\` – all random data.
- **Identity Manager product files** (`-ProductFilePath`, default `D:\ClientTools`): `VI.DB.dll`, `NLog.dll`, `Microsoft.Data.SqlClient.dll` (not in v92), and `VI.TSUtils.dll` for the custom target systems.
- **Database modules:** QER and DPR required; RMB optional (business roles); TSB + ConfigParm `TargetSystem\UNS\CreateNewRoot = 1` for custom target systems; ATT optional (`UID_OrgAttestator`).
- **A DialogUser login** (default `viadmin`) that may insert into all tables below and holds permission group `QER-752258FCCD544048848D8302EE7546C7` (needed for `Person.UniversalSubstitute`; `viadmin` normally has it).
- **Job Server + DBQueue Processor running** if you want the derived data (dynamic role memberships, risk indices on identities, delegation activation, `PersonInBaseTree`, …) to appear.

## Running it

```powershell
.\FillDbWithFakeData.ps1 `
  -Connectionstring 'Data Source=…;Initial Catalog=…;User ID=sa;Password=…;Pooling=False' `
  -ProductFilePath 'D:\ClientTools' `
  -AuthenticationString 'Module=DialogUser;User=viadmin;Password=…' `
  -Seed 973523
```

- **Not idempotent.** It stops immediately if any `Person` with `CustomProperty01 = 'Fakedata'` exists. Use the SQL in the comment block at the end of the script to clean up.
- **Reproducible.** The same `-Seed` and the same Bogus version yield the same data. Removing or reordering any `$Faker.*` call changes everything after it.
- **Mostly one transaction.** All objects are queued in a single UnitOfWork and written by one `Save-UnitOfWork` at the end. Exceptions that save immediately: the `OrgRoot`, the custom target systems (roots, account definitions, OU containers, groups), the target-system group owner roles (the `AccProduct` check looks `UID_OrgRuler` up in the database) and the delegations (created after the save by a customizer method). If the run dies in between, those rows stay behind and the idempotence check will **not** notice them.
- **RiskIndex is conditional.** Written only if `QER\CalculateRiskIndex` is enabled and the table has the column (`Test-RiskIndex`); v92 has none on `Department`, `ProfitCenter`, `Locality`, `Org`. The `$Faker` draw happens either way, so the data stream doesn't depend on it.
- Set `$DebugPreference = 'Continue'` at the top for per-step timings.

Tunables are plain variables at the top of the script (`$numberOfIdentities`, `$numberOfDepartments`, `$NumberOfItShopProducts`, `$NumberOfCustomTargetSystems`, `$NumberOfGroupsPerTargetSystem`, `$OrgStructureDepth`, `$DepartmentStructureDepth`, `$numberOfRootDepartments`, `$numberOfAdminIdentities`, `$numberOfServiceIdentities`, the `$ShareOf*` lifecycle/account ratios, title and department-name pools, …).

## Execution order

1. Open session, generate typed cmdlets for the `DPR`, `QER`, `RMB` modules only (TSB/QBM tables are reached through the generic `New-Entity`).
2. Idempotence check on `Person`.
3. `OrgRoot` **FakeOrgRoot** (RMB only), saved immediately; `OrgRootAssign` rows opened for direct/indirect assignment.
4. In memory: identities, departments, cost centers, locations, firm partners, functional areas. Department hierarchy with structured names. Department ⇄ cost center ⇄ location ⇄ functional area cross-wiring.
5. **Stage 1** – queue the above into the UnitOfWork.
6. Business-role tree under FakeOrgRoot (RMB only).
7. Custom target systems (TSB, saved immediately): namespace, root, account definition, IT-data mappings, OU containers, groups, system entitlements.
8. Identity wiring: primary department/cost center/location/business role, e-mail, secondary memberships for every 10th identity, manager tree.
9. Job titles by hierarchy level; heads and deputies re-wired to the manager tree; lifecycle states and externals; admin + service identities; UNS accounts + memberships; account definitions assigned to root departments.
10. IT Shop: shop, customer folder (dynamic role), shelf, approval policy, car request properties, service category tree, products, owner roles, resources, shelf assignments, target-system groups as products, role memberships.
11. **Stage 2** – queue everything from steps 8-10, then **`Save-UnitOfWork`**.
12. Delegations via `Person.UniversalSubstitute` (one per department head → deputy).

## Feature list

### Identities (`Person`, 100)
- German names from `GermanNames.psm1`; `Gender` matches the first name (1 = male, 2 = female).
- Birth date 20-70 years ago, personnel number, phones, address, room/floor/building, remarks, `CustomProperty01 = 'Fakedata'`, DialogUser password.
- `DefaultEMailAddress = <CentralAccount>@fakedata.local`.
- Primary `UID_Department`, `UID_ProfitCenter`, `UID_Locality`, `UID_Org` (RMB).
- Every 10th identity additionally gets random secondary memberships: `PersonInDepartment`, `PersonInProfitCenter`, `PersonInLocality`; with RMB every identity gets 1-7 `PersonInOrg`.
- **Manager tree** (`UID_PersonHead`): identity #1 is the root with up to 7 direct reports (the "ELT"), every other manager has 5-15 reports (Gaussian around 10 % of headcount), circular references are prevented.
- **Job titles** (`PersonalTitle`) follow tree depth: CEO → C-level (CFO/CTO/COO/CHRO/CIO/CMO/CLO, rotated) → *Vice President &lt;area&gt;* → *Director &lt;area&gt;* → *Team Lead &lt;area&gt;*; leaves get `{Junior|Senior|Lead|Principal} {Engineer|Analyst|…}`. Depth is kept on each identity as the `OrgLevel` note property.
- Members of the 100 product-owner roles (3 each) and of ~75 built-in application roles (1 random identity each, roles that don't exist are skipped).
- **Lifecycle states** (individual contributors only, so the manager tree stays intact; shares are `$ShareOf*`): 8 % **leavers** (`IsInActive = 1`, `ExitDate` in the past year), 5 % **joiners** (`EntryDate` 1-60 days in the future), 3 % **on leave** (`IsTemporaryDeactivated = 1`). Everyone else has an `EntryDate` 1 month to 20 years ago. Each identity carries a `Lifecycle` note property (`Active` / `Leaver` / `Joiner` / `OnLeave`).
- **Externals**: 10 % of the remaining ICs get `IsExternal = 1` and a random `UID_FirmPartner` (this is what the 20 firm partners are for).
- **Admin identities** (8, `IdentityType = 'Admin'`): same name as a random active internal master identity, `UID_PersonMasterIdentity` → that master, same department/cost center/location/manager, title "Administrator (<master's title>)".
- **Service identities** (5, `IdentityType = 'Service'`): `Service svc-backup`, `svc-monitoring`, … with a random manager and a root department.
- Admin and service identities live in `$FakeData.ExtraIdentities`, not in `$FakeData.Identities`, so they are excluded from the manager tree, titles, lifecycle and role-membership logic.

### Organization
- **Departments** (20): 4 roots, 8 on level 2, 8 on level 3 via `UID_ParentDepartment`. Names are structured: roots are business areas (`Finance`, `Engineering`, …), level 2 adds a sub-unit (`Finance - Controlling`), level 3 adds a region (`Finance - Controlling - DACH`); uniqueness is enforced, with a `Unit n` fallback. Head = a manager whose tree depth equals the department level (root → C-level, level 2 → VP, level 3 → Director). Also linked to one cost center, one location, one functional area; `RiskIndex` 0-0.6.
- **Cost centers** (`ProfitCenter`, 40) and **locations** (`Locality`, 20): random manager as head; linked to a department, each other and a functional area so every object has a full set of back-references; `RiskIndex` 0-0.6.
- **Deputies everywhere:** `UID_PersonHeadSecond` = the head's most senior direct report (the report with the most own reports). Applies to departments, cost centers, locations and business roles.
- **Delegations:** for every department head → deputy pair a real delegation is created through `Person.UniversalSubstitute` (IT Shop approvals, attestation, keep-me-informed, manager responsibilities, department-head responsibilities on `QER-V-Department`). They are IT Shop requests on the built-in delegation product and only become *active* (`QERUniversalSubstitute.IsCurrentlyActive`) once the process chain assigns them.
- **Business roles** (RMB, `Org`): tree of depth 3 with 5-10 nodes per level (≈155-1110 roles) named `Org LL-NN`, under FakeOrgRoot, with heads/deputies, department/cost center/location/functional area links, approver roles `RMB-AEROLE-ROLEADMIN-*`, `RiskIndex` 0-0.8.
- **Firm partners** (20) and **functional areas** (20). Firm partners are referenced by nothing; functional areas classify departments, cost centers, locations, business roles and products.
- Approver/attestor roles on departments, cost centers, locations: `QER-AEROLE-STRUCTADMIN-RULER`, `-RULERIT`, `ATT-AEROLE-STRUCTADMIN-ATTESTATOR`.

### IT Shop
- `ITShopOrg` **FakeShop** (`SH`) → **Customers of FakeShop** (`CU`) + **Shelf for FakeShop** (`BO`).
- Customers come from a **dynamic role** on the customer folder: `isnull(IsInActive,0) = 0 and CustomProperty01 = 'Fakedata'` on `Person`, schedule "Dynamic roles check", calculated immediately → every active fake identity can shop.
- Approval policy "Recipient's manager" (`QER-9F9FF8FD…`) attached to the shop.
- **Products** (100, drawn uniquely from `BmwFakeData.psm1`): `AccProduct` with `Ident_AccProduct = "BMW <model> <year>"` or `"<weapon> <year>"`, `Description = "HP: …, Consumption: …, Max Speed: …, 0-100: …"` (cars) or caliber/action/rate-of-fire/… (weapons), `ArticleCode` = chassis codename / designation, `CustomProperty01 = 'Fakedata'`, `IsCopyOnShopChange`, random cost center + functional area.
- **Service category tree** (`AccProductGroup` with `UID_AccProductGroupParent`): `FakeShop products` → `BMW` → one leaf per series (`1 / 2 Series`, `3 Series`, …, `X Models`, `Z Roadsters`, `i Models`, `Classics` for pre-1990), `Weapons` → `Rifles` / `Submachine guns` / `Machine guns` / `Pistols` / `Anti-tank weapons`, and `Target system groups` → one leaf per custom target system. Every product sits in its leaf (the product pool's `Group` field, kept on the entity as `FakeCategoryKey`). `$FakeData.AccProductGroupByKey` maps `"<Category>|<Group>"` to the entity.
- **Target-system groups as products**: half of each system's `UNSGroupB` (`$ShareOfRequestableGroups`) get an `AccProduct` named after the group in the system's category, `UNSGroupB.UID_AccProduct` + `IsForITShop = 1`, a shelf assignment via `ITShopOrgHasUNSGroupB`, and an owner role `Owners of <system> groups` under `QER-AEROLE-ITSHOPADMIN-OWNER` with two managers in it (saved immediately).
- **Request properties for cars:** new-style `AccProductParamCategory` "Car configuration" → `DialogParameterSet` → six `DialogParameter`s (exterior colour, transmission, lease months, delivery date, winter tyres, licence plate). Linked only to BMW products (`AccProduct.UID_AccProductParamCategory`). `DialogParameterSet.ObjectKeyUsedBy` is built from the category UID because `XObjectKey` of an unsaved entity is empty in v92.
- Each product has **its own owner role** `AERole` under `QER-AEROLE-ITSHOPADMIN-OWNER` (`AccProduct.UID_OrgRuler`) with 3 members, and **one `QERReuse`** (multi-request resource, `IsForITShop`, `IsITShopOnly`) placed on the shelf via `ITShopOrgHasQERReuse`.
- **Risk:** weapons 0.80-1.00, cars `min(1, HP/800)`; written to `QERReuse.RiskIndex` and the owner `AERole.RiskIndex`. `Person.RiskIndexCalculated` is derived by the DBQueue.

### Custom target systems (TSB, 5)
- Per system: `DPRNameSpace` + `UNSRootB` (`IsNoWrite = 1`, `UsesContainer = 1`, `GroupUsageMask = 3` → groups + system entitlement 1, owner `TSB-AEROLE-NAMESPACEADMIN-UNSB`), `TSBAccountDef` "Accounts@<type>" (`TSB-FullManaged`, inherited via department/cost center/location/business role), four `TSBITDataMapping` rows for `IsGroupAccount_UNSGroupB*`.
- Three `UNSContainerB` per system: `OU=Groups`, `OU=Entitlements`, `OU=Users`. Required: the TSB DN check rejects an `OU=` in the DN without a matching `UID_UNSContainerB`.
- 20 `UNSGroupB` ("… Group 001") and 20 `UNSGroupB1` ("… Entitlement 001") with DN, container, GUID, `RiskIndex` 0-1.
- **Accounts:** ~80 % of non-joiner identities get a `UNSAccountB` in every system (`AccountName`/`cn` = `CentralAccount`, DN + container `OU=Users`, GUID, last logon / password set within a year, `Password` set explicitly because the generated initial one can fail the default password policy) plus 3 **orphans** per system without `UID_Person`. Leavers' accounts are disabled, plus ~5 % random disabled and ~5 % privileged. Half of the identity-linked accounts (`$ShareOfManagedAccounts`) are **managed** (`UID_TSBAccountDef` + `UID_TSBBehavior = 'TSB-FullManaged'`); the rest have no account definition and look synchronized.
- **Admin accounts:** every admin identity gets `adm-<master's central account>` in every system, `IsPrivilegedAccount = 1`, member of the three highest-risk groups of that system.
- **Service accounts:** every service identity gets an account named like the identity (`svc-backup`) in two systems, one group each, never disabled.
- **Memberships:** regular accounts get 1-5 `UNSAccountBInUNSGroupB` and 0-2 `UNSAccountBInUNSGroupB1`, direct (`XOrigin = 1`).
- **Account definition inheritance:** each system's `TSBAccountDef` is assigned to two random root departments (`DepartmentHasTSBAccountDef`, `XOrigin = 1`). The DBQueue will derive `PersonHasTSBAccountDef` for everyone below those departments and may create additional managed accounts for identities that have none in that system.
- There is no connector; the custom target system is DB-only by design.

## Resulting structure

```
Person #1  "Chief Executive Officer"                              ← root of the manager tree
 ├─ C-level (≤7)  CFO / CTO / COO / CHRO / CIO / CMO / CLO        ← heads of the 4 root departments
 │   ├─ Vice President <area>  (5-15 reports each)               ← heads of level-2 departments
 │   │   ├─ Director <area>                                       ← heads of level-3 departments
 │   │   │   ├─ Team Lead <area>
 │   │   │   │   └─ Junior/Senior/Lead/Principal Engineer…
 │   │   │   └─ Senior Manager <area> (no reports)
 │   │   └─ Executive Assistant (no reports)
 ...
UID_PersonHeadSecond on every Department/ProfitCenter/Locality/Org = head's most senior report
Delegation (QERUniversalSubstitute): department head → that deputy

Department "Finance" ── "Finance - Controlling" ── "Finance - Controlling - DACH"   (4 roots → 8 → 8)
      │  ⇄ ProfitCenter (40), Locality (20), FunctionalArea (20), back-links in both directions
      ├─ Person.UID_Department (primary) + PersonInDepartment (secondary, every 10th identity)
      └─ DepartmentHasTSBAccountDef (root departments only, 2 per target system)

Person lifecycle:  ~84 active · 8 leavers (IsInActive, ExitDate) · 5 joiners (future EntryDate) · 3 on leave
                   10 externals (IsExternal, UID_FirmPartner)
Extra identities:  8 Admin (UID_PersonMasterIdentity → an active internal) · 5 Service (svc-*)

OrgRoot FakeOrgRoot ── Org "Org 01-01" ── Org "Org 02-01" ── Org "Org 03-01"   (5-10 per node, depth 3)
                                               └─ Person.UID_Org + PersonInOrg (1-7 per identity)

ITShopOrg FakeShop (SH)
 ├─ Customers of FakeShop (CU)  ← DynamicGroup: all active Fakedata identities
 └─ Shelf for FakeShop (BO)
      ├─ ITShopOrgHasQERReuse ×100 ──► QERReuse ──► AccProduct ("BMW 530i 2017", "MG 42 1942", …)
      │                                                ├─ UID_AccProductGroup ──► leaf category (see below)
      │                                                ├─ UID_OrgRuler ──► AERole (owner, 3 members)
      │                                                └─ UID_AccProductParamCategory ──► "Car configuration" (cars only)
      └─ ITShopOrgHasUNSGroupB ×50 ──► UNSGroupB (IsForITShop) ──► AccProduct ("<type> Group 007")
                                                                     └─ UID_OrgRuler ──► AERole "Owners of <type> groups" (2 managers)

AccProductGroup "FakeShop products"
 ├─ BMW ── 1 / 2 Series · 3 Series · 4 Series · 5 Series · 6 Series · 7 Series · 8 Series · X Models · Z Roadsters · i Models · Classics
 ├─ Weapons ── Rifles · Submachine guns · Machine guns · Pistols · Anti-tank weapons
 └─ Target system groups ── one per custom target system

DPRNameSpace ×5 ── UNSRootB ── TSBAccountDef "Accounts@<type>" ──► DepartmentHasTSBAccountDef (2 root departments)
                      ├─ UNSContainerB OU=Groups / OU=Entitlements / OU=Users
                      ├─ UNSGroupB ×20 (10 requestable), UNSGroupB1 ×20
                      └─ UNSAccountB ×~95 per system
                            ├─ ~75 regular (80 % of non-joiners; leavers disabled; half managed via TSBAccountDef)
                            ├─ 3 orphans (no UID_Person)
                            ├─ 8 adm-* (admin identities, privileged, in the 3 highest-risk groups)
                            ├─ ~2 svc-* (service identities, 2 systems each)
                            ├─ UNSAccountBInUNSGroupB  ×1-5
                            └─ UNSAccountBInUNSGroupB1 ×0-2
```

## Tables written

`Person`, `Department`, `ProfitCenter`, `Locality`, `FirmPartner`, `FunctionalArea`, `OrgRoot`, `OrgRootAssign` (update), `Org`, `PersonInDepartment`, `PersonInProfitCenter`, `PersonInLocality`, `PersonInOrg`, `ITShopOrg`, `DynamicGroup`, `ITShopOrgHasPWODecisionMethod`, `AccProductGroup`, `AccProduct`, `AccProductParamCategory`, `DialogParameterSet`, `DialogParameter`, `AERole`, `PersonInAERole`, `QERReuse`, `ITShopOrgHasQERReuse`, `ITShopOrgHasUNSGroupB`, `DPRNameSpace`, `UNSRootB`, `UNSContainerB`, `TSBAccountDef`, `TSBITDataMapping`, `DepartmentHasTSBAccountDef`, `UNSGroupB` (insert + update for the requestable ones), `UNSGroupB1`, `UNSAccountB`, `UNSAccountBInUNSGroupB`, `UNSAccountBInUNSGroupB1`, and – through `Person.UniversalSubstitute` – `PersonWantsOrg` + `QERUniversalSubstitute`.

Everything created by the script carries `CustomProperty01 = 'Fakedata'` where the table has that column; the exceptions are the QBM parameter tables, the UNS tables (no such column) and the delegations (`OrderReason` starts with `Fakedata:`).

## Built-in objects referenced by fixed UID

Application roles `QER-AEROLE-STRUCTADMIN-RULER/-RULERIT`, `ATT-AEROLE-STRUCTADMIN-ATTESTATOR`, `RMB-AEROLE-ROLEADMIN-ATTESTATOR/-RULER/-RULERIT`, `QER-AEROLE-ITSHOPADMIN-OWNER`, `TSB-AEROLE-NAMESPACEADMIN-UNSB`; OrgRoots `QER-V-AERole`, `QER-V-Department`; schedule `QER-B78E7C59F09D487085506ED339F0257D` (Dynamic roles check); approval policy `QER-9F9FF8FD4D2FCB4E916B45990E8765B7` (Recipient's manager); `TSB-FullManaged`, `TSB-T-UNSAccountB`, four `TSB-…` DialogColumn UIDs for the IT-data mappings; delegation product node `QER-ITSHOPORG-SUBSTITUTE-PR` (used implicitly by `UniversalSubstitute`).

## The data modules

### `BmwFakeData.psm1`
- `Get-FakeProductPool [-Category All|BMW|Weapon]` – 298 entries. Every entry exposes the common fields `Category`, `Group` (BMW series derived from the model name, or weapon type), `ProductName`, `Description`, `Code` (engine code / manufacturer), `ArticleCode` (chassis codename / designation) plus category-specific data (`HP`, `Consumption`, `MaxSpeed`, `Acceleration`, `EngineCode` … or `Caliber`, `Action`, `RateOfFire`, `MuzzleVelocity`, `Weight`, `Range`, `Magazine`).
- `Get-RandomFakeProduct [-Faker] [-Seed] [-Count] [-Unique] [-Category]` – seeded picks; `-Unique` shuffles and throws when `Count` exceeds the pool.
- `Get-BmwModelPool`, `Get-RandomBmwModel` – backwards-compatible BMW-only wrappers.
- Electric Gen5/Gen6 motors use the placeholder codes `GEN5-ESM`/`GEN6-ESM`; the i3 codes `IB1P25`/`IB1P35` are real. Spec figures are typical values, not audited.

### `GermanNames.psm1`
- `Get-GermanNamePool -Pool Male|Female|Last`.
- `Get-RandomGermanName [-Faker] [-Seed] [-Gender 0|1|2] [-Count]` → `{ FirstName, LastName, Gender }`, with the first name always matching the gender.

Both modules accept a Bogus `Faker` so their picks are part of the script's seeded stream; without one they fall back to `System.Random($Seed)`. The `Faker` parameter is deliberately untyped so the modules load without Bogus.dll.

## Conventions when editing the script

- Create objects with `-Unsaved` and queue them with `Add-UnitOfWorkEntity`; don't save individually unless a later step needs the row in the database (target systems, delegations).
- Entities that must be modified again after being queued are `.Reload()`ed first and re-queued (see identities, departments, products). `Reload()` returns a *new* object – note properties (`Subordinates`, `OrgLevel`, `Lifecycle`, `Master`, `FakeRiskIndex`, `FakeCategoryKey`) must be re-added.
- Nested helper functions (`New-Category`, `Add-UnsAccount`) accumulate into `$script:`-scoped variables because a nested function cannot write to its parent function's locals.
- Keep `CustomProperty01 = 'Fakedata'` on every new object type that has the column, and add the matching delete statement to the cleanup block at the end of the script.
- Generated `New-<Table>` cmdlets exist only for DPR/QER/RMB tables; use `New-Entity -Type` for anything else.
- Draw randomness from `$Faker` (or the data modules with `-Faker $Faker`) so runs stay reproducible; remember that inserting a new `$Faker` call shifts all later values.
- Read note properties **before** `Reload()`.
- Don't set `XOrigin`; it isn't writable, and the object layer sets the direct bit on insert.
- Columns that differ per version or are behind a preprocessor condition: check them with `Columns.IsAvailable()` (see `Test-RiskIndex`) and keep the `$Faker` draw unconditional.
- 5.1 + `Set-StrictMode -Version Latest`: wrap statement assignments in `@(...)` before using `.Count` (`$x = @(if (…) { … })`).
