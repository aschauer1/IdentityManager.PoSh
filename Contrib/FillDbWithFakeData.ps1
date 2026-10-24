Param (
    [parameter(Mandatory = $false, HelpMessage = 'Connectionstring to an Identity Manager database.')]
    [ValidateNotNullOrEmpty()]
    [string] $Connectionstring = 'Data Source=127.0.0.1;Initial Catalog=DB;User ID=sa;Password=***;Pooling=False',

    [parameter(Mandatory = $false, HelpMessage = 'The base path to load the Identity Manager product files from.')]
    [ValidateNotNullOrEmpty()]
    [string] $ProductFilePath = 'D:\ClientTools',

    [parameter(Mandatory = $false, HelpMessage = 'The authentication to use.')]
    [ValidateNotNullOrEmpty()]
    [string] $AuthenticationString = 'Module=DialogUser;User=viadmin;Password=***',

    [parameter(Mandatory = $false, HelpMessage = 'Seed value to allow generation of reproducible data.')]
    [int] $Seed = 973523
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
$DebugPreference = 'SilentlyContinue' # Valid values are 'SilentlyContinue' -> Don't show any debug messages; Continue -> Show debug messages.
$ProgressPreference = 'SilentlyContinue'

Import-Module $(Join-Path "$PSScriptRoot" -ChildPath ".." | Join-Path -ChildPath 'PSIdentityManagerUtils' | Join-Path -ChildPath 'PSIdentityManagerUtils.psm1')
# Product pool (BMW models and WWII weapons) used for the IT Shop products
Import-Module $(Join-Path "$PSScriptRoot" -ChildPath 'BmwFakeData' | Join-Path -ChildPath 'BmwFakeData.psm1')
# German first/last name pool used for the identities
Import-Module $(Join-Path "$PSScriptRoot" -ChildPath 'GermanNames' | Join-Path -ChildPath 'GermanNames.psm1')

$ModulesToAdd = 'DPR', 'QER', 'RMB'

$numberOfIdentities = 100
$minSubordinates = 5
$maxSubordinates = 15
$rootMaxDirectReports = [Math]::Min([Math]::Ceiling($numberOfIdentities * 0.1), 7) # Size of ELT team
$numberOfDepartments = 20
$numberOfCostCenters = 40
$numberOfLocations = 20
$numberOfFirmPartner = 20
$numberOfFunctionalAreas = 20
$NumberOfItShopProducts = 100
$OrgStructureDepth = 3
$NumberOfCustomTargetSystems = 5
$NumberOfGroupsPerTargetSystem = 20
$DepartmentStructureDepth = 3
$numberOfRootDepartments = 4
$numberOfAdminIdentities = 8
$numberOfServiceIdentities = 5
$ShareOfLeavers = 0.08       # IsInActive + ExitDate in the past
$ShareOfJoiners = 0.05       # EntryDate in the future
$ShareOfOnLeave = 0.03       # IsTemporaryDeactivated
$ShareOfExternals = 0.10     # IsExternal + UID_FirmPartner
$ShareOfManagedAccounts = 0.5 # UNS accounts that get the account definition (managed) instead of looking synchronized
$ShareOfRequestableGroups = 0.5 # UNS groups that become IT Shop products

# Department naming: root departments use a business area, level 2 adds a sub-unit, level 3 adds a region
$DepartmentSubUnits = 'Platform', 'Applications', 'Infrastructure', 'Analytics', 'Strategy', 'Services', 'Support', 'Compliance', 'Development', 'Architecture', 'Partnerships', 'Controlling', 'Payroll', 'Talent', 'Field', 'Key Accounts', 'Brand', 'Digital', 'Treasury', 'Security'
$DepartmentRegions = 'EMEA', 'Americas', 'APAC', 'DACH', 'Nordics', 'UK & Ireland', 'Benelux', 'Iberia', 'Italy', 'France', 'CEE', 'Japan'
$ServiceIdentityNames = 'backup', 'monitoring', 'deploy', 'reporting', 'sync', 'scanner', 'etl', 'mailer'

# Job title pools - picked by level in the manager tree
$CLevelTitles = 'Chief Financial Officer', 'Chief Technology Officer', 'Chief Operating Officer', 'Chief Human Resources Officer', 'Chief Information Officer', 'Chief Marketing Officer', 'Chief Legal Officer'
$BusinessAreas = 'Engineering', 'Sales', 'Marketing', 'Finance', 'Human Resources', 'Operations', 'IT', 'Legal', 'Procurement', 'Customer Support', 'Quality Assurance', 'Research & Development', 'Logistics', 'Product Management', 'Facilities'
$IcRoles = 'Engineer', 'Analyst', 'Specialist', 'Consultant', 'Accountant', 'Administrator', 'Coordinator', 'Developer', 'Designer', 'Technician'
$IcLevels = 'Junior ', '', '', 'Senior ', 'Lead ', 'Principal '

trap {
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    Write-Host ''
    Write-Host "[$ts] ERROR: $_"
    Write-Host ''

    # Stack trace
    if ($_.ScriptStackTrace) {
        Write-Host "[$ts] --- Stack Trace ---"
        ($_.ScriptStackTrace -split '\r?\n') | Where-Object { $_.Trim() } | ForEach-Object {
            Write-Host "[$ts] $_"
        }
        Write-Host ''
    }

    # Main exception
    Write-Host "[$ts] Exception Type: $($_.Exception.GetType().FullName)"
    Write-Host "[$ts] Exception Message: $($_.Exception.Message)"

    # Walk inner exceptions
    $inner = $_.Exception.InnerException
    $level = 1
    while ($inner) {
        Write-Host ''
        Write-Host "[$ts] Inner Exception [$level]:"
        Write-Host "[$ts]   Type: $($inner.GetType().FullName)"
        Write-Host "[$ts]   Message: $($inner.Message)"

        $inner = $inner.InnerException
        $level++
    }

    Write-Host ''

    Exit 1
}

$Session = New-IdentityManagerSession `
-ConnectionString $Connectionstring `
-AuthenticationString $AuthenticationString `
-ProductFilePath $ProductFilePath `
-ModulesToAdd $ModulesToAdd

$StartTimeTotal = $(get-date)

Write-Information "Session for $($Session.Display)"

# Fail fast on multiple runs - not supported
$PersonCount = Get-TableCount -Name 'Person' -Filter "CustomProperty01 = 'Fakedata'"
if ($PersonCount -gt 0) {
  Write-Warning 'This script is not idempotent. Stopping.'
  Write-Information 'Closing connection.'
  Remove-IdentityManagerSession -Session $Session
  Exit
}

# For easy Fakedata we use Bogus - get it from https://github.com/bchavez/Bogus
$FileToLoad = Join-Path "$PSScriptRoot" $(if (7 -eq $PSVersionTable.PSVersion.Major) { $(Join-Path 'net6.0' -ChildPath 'Bogus.dll') } else { $(Join-Path 'net40' -ChildPath 'Bogus.dll') })
[System.Reflection.Assembly]::LoadFrom($FileToLoad) | Out-Null
$clientVersion = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($FileToLoad).ProductVersion
Write-Debug "[+] File ${FileToLoad} loaded with version ${clientVersion}"

$FakeData = [PSCustomObject]@{
  Identities = @()
  Departments = @()
  CostCenters = @()
  Locations = @()
  BusinessRoles = @()
  FirmPartners = @()
  FunctionalAreas = @()
  IdentityInDepartment = @()
  IdentityInCostCenter = @()
  IdentityInLocality = @()
  PersonInOrgs = @()
  AccProducts = @()
  ProductOwners = @()
  PersonInAERoles = @()
  QERReuses = @()
  ITShopOrgHasQERReuse = @()
  AccProductGroup = ''
  CarParamCategory = ''
  CarParamSet = ''
  CarParams = @()
  Delegations = @()
  TargetSystems = @()
  UNSAccounts = @()
  UNSAccountMemberships = @()
  ExtraIdentities = @()
  AccProductGroups = @()
  AccProductGroupByKey = @{}
  GroupProducts = @()
  GroupProductOwners = @()
  GroupProductOwnerMembers = @()
  GroupShelfAssignments = @()
  RequestableGroups = @()
  AccountDefAssignments = @()
}

function New-Identities {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
        [ValidateNotNull()]
        [VI.DB.Entities.ISession] $Session,
        [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
        [ValidateNotNull()]
        [Bogus.Faker] $Faker,
        [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
        [int] $Quantity
    )

    Write-Information "Creating $Quantity Identity records in memory"

    $StartTime = $(get-date)
    for ($i = 1; $i -le $Quantity; $i++) {
        $fakeDate = [Bogus.DataSets.Date]::new()

        # German name pool (1900-1950 cohorts); first name matches the gender
        $Name = Get-RandomGermanName -Faker $Faker

        $p = New-Person `
            -FirstName $Name.FirstName `
            -LastName $Name.LastName `
            -PersonalTitle $Faker.Name.JobTitle() `
            -Gender $Name.Gender `
            -Description $Faker.Name.JobType() `
            -BirthDate $([VI.Base.DbVal]::ToUniversalTime($fakeDate.Past(50, $(Get-Date).AddYears(-20)), $Session.TimeZone)) `
            -PersonnelNumber $Faker.Commerce.Ean13() `
            -Phone $Faker.Phone.PhoneNumber() `
            -PhoneMobile $Faker.Phone.PhoneNumber() `
            -Street $Faker.Address.StreetAddress() `
            -ZIPCode $Faker.Address.ZipCode() `
            -City $Faker.Address.City() `
            -Remarks $Faker.Lorem.Sentences() `
            -Room $Faker.Random.Number(1, 10000) `
            -Floor $Faker.Random.Number(1, 90) `
            -Building $Faker.Address.BuildingNumber() `
            -CustomProperty01 'Fakedata' `
            -DialogUserPassword 'AsdQwe123$' `
            -Unsaved

        $p
    }

    $ElapsedTime = New-TimeSpan $StartTime $(get-date)
    Write-Debug "Done in $elapsedTime"
}

function New-Departments {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity Department records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++) {
    $Department = New-Department `
      -DepartmentName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -CustomProperty01 'Fakedata' `
      -ObjectID $Faker.Commerce.Ean13() `
      -ShortName $Faker.Commerce.Ean13() `
      -Description $Faker.Lorem.Sentences() `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -Remarks $Faker.Lorem.Sentences() `
      -ZIPCode $Faker.Address.ZipCode() `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_RulerContainer 'QER-AEROLE-STRUCTADMIN-RULER' `
      -UID_RulerContainerIT 'QER-AEROLE-STRUCTADMIN-RULERIT' `
      -Unsaved

      $Risk = [Math]::Round($Faker.Random.Double(0.0, 0.6), 2)
      if (Test-RiskIndex 'Department') { $Department.RiskIndex = $Risk }

      if ($null -ne $Department.PSObject.Members['UID_OrgAttestator']) {
        $Department.UID_OrgAttestator = 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR'
      }

    $Department
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-CostCenters {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity Cost Center records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++) {
    $ProfitCenter = New-ProfitCenter `
      -AccountNumber $Faker.Commerce.Ean13() `
      -CustomProperty01 'Fakedata' `
      -ShortName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -Description $Faker.Lorem.Sentences() `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -Remarks $Faker.Lorem.Sentences() `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_RulerContainer 'QER-AEROLE-STRUCTADMIN-RULER' `
      -UID_RulerContainerIT 'QER-AEROLE-STRUCTADMIN-RULERIT' `
      -Unsaved

      $Risk = [Math]::Round($Faker.Random.Double(0.0, 0.6), 2)
      if (Test-RiskIndex 'ProfitCenter') { $ProfitCenter.RiskIndex = $Risk }

      if ($null -ne $ProfitCenter.PSObject.Members['UID_OrgAttestator']) {
        $ProfitCenter.UID_OrgAttestator = 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR'
      }

    $ProfitCenter
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-Locations {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity Location records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++) {
    $LocationName = $Faker.Address.OrdinalDirection() + ' ' + $Faker.Lorem.Word() + ' ' + $Faker.Commerce.Ean8()
    $Locality = New-Locality `
      -Ident_Locality $LocationName `
      -CustomProperty01 'Fakedata' `
      -ShortName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -LongName $($Faker.Address.City() + ' ' + $Faker.Commerce.Categories(1)) `
      -PostalAddress $Faker.Address.StreetAddress() `
      -Street $Faker.Address.StreetAddress() `
      -ZIPCode $Faker.Address.ZipCode() `
      -City $Faker.Address.City() `
      -Building $Faker.Address.BuildingNumber() `
      -Room $Faker.Random.Number(1, 10000) `
      -RoomRemarks $Faker.Lorem.Word() `
      -Telephone $Faker.Phone.PhoneNumber() `
      -Fax $Faker.Phone.PhoneNumber() `
      -TelephoneShort $Faker.Random.Number(0, 9999999) `
      -Description $Faker.Lorem.Sentences() `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -Remarks $Faker.Lorem.Sentences() `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_RulerContainer 'QER-AEROLE-STRUCTADMIN-RULER' `
      -UID_RulerContainerIT 'QER-AEROLE-STRUCTADMIN-RULERIT' `
      -Unsaved

      $Risk = [Math]::Round($Faker.Random.Double(0.0, 0.6), 2)
      if (Test-RiskIndex 'Locality') { $Locality.RiskIndex = $Risk }

      if ($null -ne $Locality.PSObject.Members['UID_OrgAttestator']) {
        $Locality.UID_OrgAttestator = 'ATT-AEROLE-STRUCTADMIN-ATTESTATOR'
      }

    $Locality
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-FirmPartners {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity FirmPartner records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++) {
    $FirmPartnerName = $Faker.Company.CompanyName()
    $FirmPartner = New-FirmPartner `
      -Ident_FirmPartner $FirmPartnerName `
      -Name1 $Faker.Lorem.Word() `
      -Name2 $Faker.Lorem.Word() `
      -ShortName $Faker.Lorem.Word() `
      -Remarks $Faker.Lorem.Sentences() `
      -Contact $Faker.Phone.PhoneNumber() `
      -Street $Faker.Address.StreetAddress() `
      -Building $Faker.Address.BuildingNumber() `
      -ZIPCode $Faker.Address.ZipCode() `
      -City $Faker.Address.City() `
      -Phone $Faker.Phone.PhoneNumber() `
      -Fax $Faker.Phone.PhoneNumber() `
      -EMail $Faker.Internet.Email() `
      -FirmPartnerURL 'https://oneidentity.com' `
      -Unsaved

    $FirmPartner
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-FunctionalAreas {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity FunctionalArea records in memory"

  $StartTime = $(get-date)
  for ($i = 1; $i -le $Quantity; $i++) {
    $FunctionalAreaName = $Faker.Company.Bs()
    $FunctionalArea = New-FunctionalArea `
      -Ident_FunctionalArea $FunctionalAreaName `
      -Description $Faker.Lorem.Sentences() `
      -Unsaved

    $FunctionalArea
  }

  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-AccProducts {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity AccProduct records in memory"

  $StartTime = $(get-date)
  # Unique picks so Ident_AccProduct (and the derived AERole / QERReuse idents) don't collide
  $Products = @(Get-RandomFakeProduct -Faker $Faker -Count $Quantity -Unique)

  for ($i = 0; $i -lt $Quantity; $i++) {
    $Product = $Products[$i]

    $AccProduct = New-AccProduct -Ident_AccProduct $Product.ProductName `
      -Description $Product.Description `
      -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
      -ArticleCode $Product.ArticleCode `
      -IsCopyOnShopChange 1 `
      -UID_FunctionalArea $Faker.Random.ArrayElement($($FakeData.FunctionalAreas).UID_FunctionalArea) `
      -CustomProperty01 'Fakedata' `
      -Unsaved

    # Cars get the "Car configuration" request properties
    if ($Product.Category -eq 'BMW' -and $FakeData.CarParamCategory -isnot [string]) {
      $AccProduct.UID_AccProductParamCategory = $FakeData.CarParamCategory.UID_AccProductParamCategory
    }

    # Risk index used for the resource and the owner role: weapons are high risk, cars scale with horsepower
    $Risk = if ($Product.Category -eq 'Weapon') {
      [Math]::Round($Faker.Random.Double(0.8, 1.0), 2)
    } else {
      [Math]::Round([Math]::Min(1.0, $Product.HP / 800.0), 2)
    }
    $AccProduct | Add-Member -NotePropertyName 'FakeRiskIndex' -NotePropertyValue $Risk
    $AccProduct | Add-Member -NotePropertyName 'FakeCategoryKey' -NotePropertyValue ($Product.Category + '|' + $Product.Group)

    $AccProduct
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-AccProductGroups {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating AccProductGroup (service category) tree in memory"

  $StartTime = $(get-date)

  $metaData = [VI.DB.Entities.SessionExtensions]::MetaData($Session)
  $tableMetaData = $metaData.GetTableAsync('AccProductGroup', [System.Threading.CancellationToken]::None).GetAwaiter().GetResult()
  $hasServiceNow = $tableMetaData.Columns.IsAvailable('IsServiceNowEnabled')

  # Accumulators live in script scope so the nested helper can reach them
  $script:CategoryAll = @()
  $script:CategoryByKey = @{}

  function New-Category {
    param ([string] $Name, [string] $Description, $Parent, [string] $Key)

    $p = @{
      Ident_AccProductGroup = $Name
      Description           = $Description
      CustomProperty01      = 'Fakedata'
      Unsaved               = $true
    }
    if ($null -ne $Parent) { $p['UID_AccProductGroupParent'] = $Parent.UID_AccProductGroup }
    if ($hasServiceNow) { $p['IsServiceNowEnabled'] = $false }

    $g = New-AccProductGroup @p
    $script:CategoryAll += $g
    if ($Key) { $script:CategoryByKey[$Key] = $g }
    $g
  }

  # Root -> category per product pool -> one leaf per series / weapon type; plus one category per custom target system
  $Root = New-Category -Name 'FakeShop products' -Description $Faker.Lorem.Sentence(3, 5) -Parent $null -Key 'Root'
  $Bmw = New-Category -Name 'BMW' -Description 'Company cars by series' -Parent $Root -Key 'BMW'
  $Weapons = New-Category -Name 'Weapons' -Description 'Historical small arms by type' -Parent $Root -Key 'Weapon'
  $TargetSystems = New-Category -Name 'Target system groups' -Description 'Group memberships in the custom target systems' -Parent $Root -Key 'TargetSystem'

  foreach ($Group in @(Get-FakeProductPool -Category BMW | Select-Object -ExpandProperty Group -Unique | Sort-Object)) {
    New-Category -Name $Group -Description "BMW $Group" -Parent $Bmw -Key "BMW|$Group" | Out-Null
  }
  foreach ($Group in @(Get-FakeProductPool -Category Weapon | Select-Object -ExpandProperty Group -Unique | Sort-Object)) {
    New-Category -Name $Group -Description "Weapons: $Group" -Parent $Weapons -Key "Weapon|$Group" | Out-Null
  }
  foreach ($TargetSystem in $FakeData.TargetSystems) {
    New-Category -Name $TargetSystem.Ident -Description "Groups of custom target system $($TargetSystem.Ident)" -Parent $TargetSystems -Key "TargetSystem|$($TargetSystem.Ident)" | Out-Null
  }

  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime ($($script:CategoryAll.Count) categories)"

  [PSCustomObject]@{ Root = $Root; All = $script:CategoryAll; ByKey = $script:CategoryByKey }
}

function New-TargetSystemGroupProducts {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData,
      [parameter(Mandatory = $true, HelpMessage = 'The UID_ITShopOrg shelf the groups go on')]
      [string] $UID_ITShopOrg
  )

  Write-Information 'Creating IT Shop products for target system groups in memory'
  $StartTime = $(get-date)

  $Owners = @(); $OwnerMembers = @(); $Products = @(); $Groups = @(); $ShelfAssignments = @()
  $Managers = @($FakeData.Identities | Where-Object { $_.Subordinates.Count -gt 0 -and $_.Lifecycle -eq 'Active' })

  foreach ($TargetSystem in $FakeData.TargetSystems) {
    # One product owner role per target system with two managers in it
    $Owner = New-AERole -Ident_AERole "Owners of $($TargetSystem.Ident) groups" `
      -UID_OrgRoot 'QER-V-AERole' `
      -UID_ParentAERole 'QER-AEROLE-ITSHOPADMIN-OWNER' `
      -Description "Product owners for the groups of custom target system $($TargetSystem.Ident)" `
      -CustomProperty01 'Fakedata'
    # Saved immediately: the AccProduct check looks UID_OrgRuler up in the database
    $Owners += $Owner
    foreach ($Manager in @($Managers | Get-Random -SetSeed ($Seed + $Owners.Count) -Count 2)) {
      $OwnerMembers += New-PersonInAERole -UID_AERole $Owner.UID_AERole -UID_Person $Manager.UID_Person -Unsaved
    }

    $Category = $FakeData.AccProductGroupByKey["TargetSystem|$($TargetSystem.Ident)"]
    $Count = [Math]::Ceiling($TargetSystem.Groups.Count * $ShareOfRequestableGroups)

    foreach ($Group in @($TargetSystem.Groups | Select-Object -First $Count)) {
      $Product = New-AccProduct -Ident_AccProduct $Group.DisplayName `
        -Description "Membership in group '$($Group.DisplayName)' of custom target system $($TargetSystem.Ident)" `
        -UID_AccProductGroup $Category.UID_AccProductGroup `
        -UID_OrgRuler $Owner.UID_AERole `
        -ArticleCode $TargetSystem.Ident `
        -IsCopyOnShopChange 1 `
        -CustomProperty01 'Fakedata' `
        -Unsaved
      $Products += $Product

      # The group itself becomes the requestable object; it was saved with the target system, so this is an update
      $Group.UID_AccProduct = $Product.UID_AccProduct
      $Group.IsForITShop = $true
      $Group.IsITShopOnly = $false
      $Groups += $Group

      $ShelfAssignments += New-Entity -Type 'ITShopOrgHasUNSGroupB' -Unsaved -Properties @{
        UID_ITShopOrg = $UID_ITShopOrg
        UID_UNSGroupB = $Group.UID_UNSGroupB
      }
    }
  }

  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime ($($Products.Count) group products)"

  [PSCustomObject]@{ Owners = $Owners; OwnerMembers = $OwnerMembers; Products = $Products; Groups = $Groups; ShelfAssignments = $ShelfAssignments }
}

function New-ProductOwners {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity ProductOwner records in memory"
  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++) {
    $ProductOwner = New-AERole -Ident_AERole $FakeData.AccProducts[$i].Ident_AccProduct `
      -UID_OrgRoot 'QER-V-AERole' `
      -Description $Faker.Lorem.Sentence(3, 5) `
      -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
      -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
      -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
      -UID_ParentAERole 'QER-AEROLE-ITSHOPADMIN-OWNER' `
      -Commentary $Faker.Lorem.Sentence(3, 5) `
      -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
      -CustomProperty01 'Fakedata' `
      -Unsaved
    if (Test-RiskIndex 'AERole') { $ProductOwner.RiskIndex = $FakeData.AccProducts[$i].FakeRiskIndex }

    $ProductOwner
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-QERReuses {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity QERReuse records in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++) {
   
    $QERReuse = New-QERReuse -Ident_QERReuse $FakeData.AccProducts[$i].Ident_AccProduct `
      -Description $Faker.Lorem.Sentence(3, 5) `
      -IsForITShop 1 `
      -IsITShopOnly 1 `
      -UID_AccProduct $FakeData.AccProducts[$i].UID_AccProduct `
      -CustomProperty01 'Fakedata' `
      -Unsaved
    if (Test-RiskIndex 'QERReuse') { $QERReuse.RiskIndex = $FakeData.AccProducts[$i].FakeRiskIndex }

    $QERReuse
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-ITShopOrgHasQERReuses {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData,
      [parameter(Mandatory = $true, Position = 3, HelpMessage = 'The UID_ITShopOrg Shelf for the assignment')]
      [string] $UID_ITShopOrg
  )

  Write-Information "Creating $Quantity ITShop <-> QERReuse assignment records in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $Quantity; $i++) {
   
    $ITShopOrgHasQERReuse = New-ITShopOrgHasQERReuse -UID_QERReuse $FakeData.QERReuses[$i].UID_QERReuse `
      -UID_ITShopOrg $UID_ITShopOrg `
      -Unsaved

    $ITShopOrgHasQERReuse
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-PersonInAERoles  {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information "Creating $Quantity PersonInAERole records for every AERole in memory"

  $StartTime = $(get-date)
  for ($i = 0; $i -lt $FakeData.ProductOwners.Count; $i++) {
    $RandomPersons = $FakeData.Identities | Get-Random -SetSeed $($Seed * $i) -Count $Quantity

    $RandomPersons | ForEach-Object {
      $PersonInAERole = New-PersonInAERole -UID_AERole $FakeData.ProductOwners[$i].UID_AERole `
        -UID_Person $_.UID_Person `
        -Unsaved
      $PersonInAERole
    }
  }
  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-PersonInOrgs {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $false, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData
  )

  Write-Information 'Creating PersonInOrg records'

  $StartTime = $(get-date)

  for ($i = 0; $i -lt $FakeData.Identities.Count; $i++) {
    $numberOfAdditionalAssignments = $Faker.Random.Int(1, $Quantity)
    $RandomOrgs = $FakeData.BusinessRoles | Get-Random -SetSeed $($Seed * $i) -Count $numberOfAdditionalAssignments

    $RandomOrgs | ForEach-Object {
      if ($FakeData.Identities[$i].UID_Org -eq $_.UID_Org) {
        # Don't assign same Org again (indirectly)
        continue
      }

      $PersonInOrg = New-PersonInOrg -UID_Org $_.UID_Org `
        -UID_Person $FakeData.Identities[$i].UID_Person `
        -Unsaved
      $PersonInOrg
    }
  }

  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime"
}

function New-OrgHierarchy {
  param (
      [int]$currentLevel = 1,
      [string]$UID_ParentOrg = $null
  )

  if ($currentLevel -le $OrgStructureDepth) {
      # Generate a random number of entries for this level
      $numEntries = Get-Random -Minimum 5 -Maximum 11

      for ($i = 1; $i -le $numEntries; $i++) {

        $BusinessRoleName = 'Org {0:D2}-{1:D2}' -f $currentLevel, $i

        $BusinessRole = New-Org -Ident_Org "$BusinessRoleName" `
          -InternalName $Faker.Lorem.Word() `
          -ShortName $Faker.Lorem.Word() `
          -UID_OrgRoot $OrgRoot.UID_OrgRoot `
          -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
          -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
          -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
          -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
          -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
          -UID_OrgAttestator 'RMB-AEROLE-ROLEADMIN-ATTESTATOR' `
          -UID_RulerContainer 'RMB-AEROLE-ROLEADMIN-RULER' `
          -UID_RulerContainerIT 'RMB-AEROLE-ROLEADMIN-RULERIT' `
          -Description $Faker.Lorem.Sentence(3, 5) `
          -PostalAddress $Faker.Address.StreetAddress() `
          -Street $Faker.Address.StreetAddress() `
          -Building $Faker.Address.BuildingNumber() `
          -ZIPCode $Faker.Address.ZipCode() `
          -City $Faker.Address.City() `
          -Telephone $Faker.Phone.PhoneNumber() `
          -TelephoneShort $Faker.Random.Number(0, 9999999) `
          -Room $Faker.Random.Number(1, 10000) `
          -RoomRemarks $Faker.Lorem.Word() `
          -UID_FunctionalArea $Faker.Random.ArrayElement($($FakeData.FunctionalAreas).UID_FunctionalArea) `
          -Commentary $Faker.Lorem.Sentence(3, 5) `
          -Remarks $Faker.Lorem.Sentences() `
          -CustomProperty01 'Fakedata' `
          -Unsaved

        $Risk = [Math]::Round($Faker.Random.Double(0.0, 0.8), 2)
        if (Test-RiskIndex 'Org') { $BusinessRole.RiskIndex = $Risk }

        if (-Not [string]::IsNullOrEmpty($UID_ParentOrg)) {
            $BusinessRole.UID_ParentOrg = $UID_ParentOrg
        }

        $BusinessRole | Add-UnitOfWorkEntity -UnitOfWork $uow
        $FakeData.BusinessRoles += $BusinessRole

        # Recursive call to create the next level
        New-OrgHierarchy -currentLevel ($currentLevel + 1) -UID_ParentOrg $BusinessRole.UID_Org
      }
  }
}

function HasCircularReference {
  param (
      $subordinate,
      $supervisor
  )

  while ($supervisor) {
    if ($supervisor.UID_Person -eq $subordinate.UID_Person) {
      return $true
    }
    $t = $FakeData.Identities | Where-Object {$_.UID_Person -eq $supervisor.UID_PersonHead}
    $supervisor = $t
  }
  return $false
}

function GetGaussianRandom {
  param (
      [double] $mean,
      [double] $stdDev,
      [int] $min,
      [int] $max
  )

  do {
    $u1 = [System.Random]::new($Seed).NextDouble()
    $u2 = [System.Random]::new($Seed * $u1).NextDouble()
    $randStdNormal = [Math]::Sqrt(-2 * [Math]::Log($u1)) * [Math]::Sin(2 * [Math]::PI * $u2)
    $randNormal = [Math]::Round($mean + $stdDev * $randStdNormal)

  } while ($randNormal -lt $min -or $randNormal -gt $max)

  return [int]$randNormal
}

function New-CustomTargetSystem {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $true, Position = 2, HelpMessage = 'The number of fake objects')]
      [int] $Quantity
  )

  # Load VI.TSUtils.dll as we need if to create a custom target system
  [System.Reflection.Assembly]::LoadFrom([io.path]::combine($ProductFilePath, 'VI.TSUtils.dll')) | Out-Null

  for ($i = 1; $i -le $Quantity; $i++) {
    # Create custom target system type and save it immediately
    $Ident_TargetSystemType = $($Faker.Commerce.ProductName()).Replace(' ', '-')
    $DNS = New-DPRNameSpace -Ident_DPRNameSpace $Ident_TargetSystemType `
      -Description $Faker.Lorem.Sentences() `
      -DisplayName $Ident_TargetSystemType

    $URB = New-Entity -Type 'UNSRootB' `
      -Properties @{
        UID_DPRNameSpace = $DNS.UID_DPRNameSpace
        Ident_UNSRoot = $Ident_TargetSystemType + "-$i"
        DisplayName = $Ident_TargetSystemType + "-$i"
        Description = $Faker.Lorem.Sentences()
        IsNoWrite = $true
        IsMemberOfEnabled = $true # Group membership as MVP
        UsesContainer = $true # for the OU=Groups/Entitlements/Users containers
        GroupUsageMask = 3 # Groups = 1; System Entitlement 1 = 2; System Entitlement 2 = 4; System Entitlement 3 = 8
        UID_AERoleOwner = 'TSB-AEROLE-NAMESPACEADMIN-UNSB'
      }

    # Create TSB AccountDefinition
    $TAD = New-Entity -Type 'TSBAccountDef' `
      -Properties @{
        Ident_TSBAccountDef = "Accounts@$Ident_TargetSystemType"
        PTDInheritAccountDef = 1
        PFDInheritAccountDef = 1
        PMDInheritAccountDef = 1
        PSIInheritAccountDef = 1
        UID_DialogTableAccountType = 'TSB-T-UNSAccountB'
        ObjectKeyTargetSystem = $URB.XObjectKey
        UID_TSBBehaviorDefault = 'TSB-FullManaged'
        Description = $Faker.Lorem.Sentences()
        CustomProperty01 = 'Fakedata'
      }

    # Create IT Data Mapping
    $dialogColumns = @{
      IsGroupAccount_UNSGroupB = 'TSB-B871B45D47FC7D8C30747CACC4DC00FF';
      IsGroupAccount_UNSGroupB1 = 'TSB-4FCB4A495D7E2B35E674FE66E28CA44B';
      IsGroupAccount_UNSGroupB2 = 'TSB-66C74F26EEF8B1A1FABFBF084E318022';
      IsGroupAccount_UNSGroupB3 = 'TSB-A817E34959FD1842D1DF080E4ED80C1D'
    }

    ForEach ($k in $dialogColumns.Keys) {
      New-Entity -Type 'TSBITDataMapping' `
      -Properties @{
        UID_TSBAccountDef = $TAD.UID_TSBAccountDef
        UID_DialogColumn = $dialogColumns[$k]
        UseAlwaysDefaultValue = 1
        FixValue = 1
      } | Out-Null
    }

    $DomainDN = 'DC=' + $Ident_TargetSystemType.ToLower() + ',DC=fakedata,DC=local'

    # ou containers are required, the tsb dn check rejects an ou in the dn without UID_UNSContainerB
    $Containers = @{}
    foreach ($OU in 'Groups', 'Entitlements', 'Users') {
      $Containers[$OU] = New-Entity -Type 'UNSContainerB' `
        -Properties @{
          cn = $OU
          DistinguishedName = "OU=$OU,$DomainDN"
          UID_UNSRootB = $URB.UID_UNSRootB
        }
    }

    # Create Groups
    $Groups = for ($j = 1; $j -le $NumberOfGroupsPerTargetSystem; $j++) {
      $GroupName = '{0} Group {1:D3}' -f $Ident_TargetSystemType, $j
      $Props = @{
        CN = $GroupName
        DisplayName= $GroupName
        DistinguishedName = "CN=$GroupName,OU=Groups,$DomainDN"
        UID_UNSContainerB = $Containers['Groups'].UID_UNSContainerB
        ObjectGuid = $Faker.Random.Guid().Guid
        Description = $Faker.Lorem.Sentences()
        UID_UNSRootB = $URB.UID_UNSRootB
      }
      $Risk = [Math]::Round($Faker.Random.Double(0.0, 1.0), 2)
      if (Test-RiskIndex 'UNSGroupB') { $Props['RiskIndex'] = $Risk }
      New-Entity -Type 'UNSGroupB' -Properties $Props
    }

    # System Entitlement 1
    $Groups1 = for ($j = 1; $j -le $NumberOfGroupsPerTargetSystem; $j++) {
      $GroupName = '{0} Entitlement {1:D3}' -f $Ident_TargetSystemType, $j
      $Props = @{
        CN = $GroupName
        DisplayName= $GroupName
        DistinguishedName = "CN=$GroupName,OU=Entitlements,$DomainDN"
        UID_UNSContainerB = $Containers['Entitlements'].UID_UNSContainerB
        ObjectGuid = $Faker.Random.Guid().Guid
        Description = $Faker.Lorem.Sentences()
        UID_UNSRootB = $URB.UID_UNSRootB
      }
      $Risk = [Math]::Round($Faker.Random.Double(0.0, 1.0), 2)
      if (Test-RiskIndex 'UNSGroupB1') { $Props['RiskIndex'] = $Risk }
      New-Entity -Type 'UNSGroupB1' -Properties $Props
    }

    # Add TSBAccountDef to the target system
    Set-Entity -Type 'UNSRootB' -Identity ($URB).XObjectKey -Properties @{'UID_TSBAccountDef' = $TAD.UID_TSBAccountDef} | Out-Null

    [PSCustomObject]@{
      Ident      = $Ident_TargetSystemType
      DomainDN   = $DomainDN
      Containers = $Containers
      Root       = $URB
      AccountDef = $TAD
      Groups     = @($Groups)
      Groups1    = @($Groups1)
    }
  }
}

function New-UNSAccounts {
  [CmdletBinding()]
  param (
      [parameter(Mandatory = $true, Position = 0, HelpMessage = 'The session to use')]
      [ValidateNotNull()]
      [VI.DB.Entities.ISession] $Session,
      [parameter(Mandatory = $true, Position = 1, HelpMessage = 'The Bogus faker instance')]
      [ValidateNotNull()]
      [Bogus.Faker] $Faker,
      [parameter(Mandatory = $false)]
      [PSCustomObject[]]$FakeData,
      [parameter(Mandatory = $false, HelpMessage = 'Share of identities that get an account in each target system')]
      [double] $Coverage = 0.8,
      [parameter(Mandatory = $false, HelpMessage = 'Accounts without an identity per target system')]
      [int] $OrphansPerSystem = 3,
      [parameter(Mandatory = $false, HelpMessage = 'Maximum group memberships per account')]
      [int] $MaxGroups = 5,
      [parameter(Mandatory = $false, HelpMessage = 'Maximum system entitlement 1 memberships per account')]
      [int] $MaxEntitlements = 2
  )

  Write-Information "Creating UNS accounts and group memberships for $($FakeData.TargetSystems.Count) target systems in memory"
  $StartTime = $(get-date)

  $script:UnsAccounts = @()
  $script:UnsMemberships = @()

  # Creates one account plus memberships. $Groups / $Entitlements are the explicit picks; when empty, random picks are made.
  function Add-UnsAccount {
    param ($TargetSystem, $Person, [string] $AccountName, [string] $FirstName, [string] $LastName, [string] $Description,
           [bool] $Disabled, [bool] $Privileged, [bool] $Managed, $Groups = @(), $Entitlements = @(), [bool] $RandomGroups = $true)

    $Props = @{
      UID_UNSRootB        = $TargetSystem.Root.UID_UNSRootB
      AccountName         = $AccountName
      cn                  = $AccountName
      DisplayName         = "$LastName, $FirstName"
      FirstName           = $FirstName
      LastName            = $LastName
      DistinguishedName   = "CN=$AccountName,OU=Users,$($TargetSystem.DomainDN)"
      UID_UNSContainerB   = $TargetSystem.Containers['Users'].UID_UNSContainerB
      ObjectGUID          = $Faker.Random.Guid().Guid
      Description         = $Description
      AccountDisabled     = $Disabled
      IsPrivilegedAccount = $Privileged
      LastLogon           = [VI.Base.DbVal]::ToUniversalTime($Faker.Date.Past(1), $Session.TimeZone)
      PWDLastSet          = [VI.Base.DbVal]::ToUniversalTime($Faker.Date.Past(1), $Session.TimeZone)
      # set explicitly, otherwise the generated initial password can fail the default password policy
      Password            = 'AsdQwe123$'
    }
    if ($null -ne $Person) { $Props['UID_Person'] = $Person.UID_Person }
    if ($Managed) {
      # Managed through the account definition; the rest look like plain synchronized accounts
      $Props['UID_TSBAccountDef'] = $TargetSystem.AccountDef.UID_TSBAccountDef
      $Props['UID_TSBBehavior'] = 'TSB-FullManaged'
    }

    $Account = New-Entity -Type 'UNSAccountB' -Properties $Props -Unsaved
    $script:UnsAccounts += $Account
    $n = $script:UnsAccounts.Count

    if ($RandomGroups) {
      $Groups = @($TargetSystem.Groups | Get-Random -SetSeed ($Seed + $n) -Count $Faker.Random.Int(1, $MaxGroups))
      $EntitlementCount = $Faker.Random.Int(0, $MaxEntitlements)
      $Entitlements = if ($EntitlementCount -gt 0) { @($TargetSystem.Groups1 | Get-Random -SetSeed ($Seed - $n) -Count $EntitlementCount) } else { @() }
    }

    # Direct assignments, XOrigin = 1
    foreach ($Group in $Groups) {
      $script:UnsMemberships += New-Entity -Type 'UNSAccountBInUNSGroupB' -Unsaved -Properties @{
        UID_UNSAccountB = $Account.UID_UNSAccountB
        UID_UNSGroupB   = $Group.UID_UNSGroupB
      }
    }
    foreach ($Entitlement in $Entitlements) {
      $script:UnsMemberships += New-Entity -Type 'UNSAccountBInUNSGroupB1' -Unsaved -Properties @{
        UID_UNSAccountB = $Account.UID_UNSAccountB
        UID_UNSGroupB1  = $Entitlement.UID_UNSGroupB1
      }
    }
  }

  function Get-AccountNameFor {
    param ($Person)
    if (-not [string]::IsNullOrEmpty($Person.CentralAccount)) { $Person.CentralAccount } else { ($Person.FirstName + '.' + $Person.LastName).ToLower() }
  }

  foreach ($TargetSystem in $FakeData.TargetSystems) {
    # Regular identities: a share of them has an account here; joiners have none yet, leavers' accounts are disabled
    $Owners = @($FakeData.Identities | Where-Object { $_.Lifecycle -ne 'Joiner' -and $Faker.Random.Double() -lt $Coverage })
    foreach ($Person in $Owners) {
      Add-UnsAccount -TargetSystem $TargetSystem -Person $Person `
        -AccountName (Get-AccountNameFor $Person) -FirstName $Person.FirstName -LastName $Person.LastName `
        -Description $Faker.Lorem.Sentence(3, 5) `
        -Disabled (($Person.Lifecycle -eq 'Leaver') -or ($Faker.Random.Double() -lt 0.05)) `
        -Privileged ($Faker.Random.Double() -lt 0.05) `
        -Managed ($Faker.Random.Double() -lt $ShareOfManagedAccounts)
    }

    # Orphans without an identity
    for ($o = 0; $o -lt $OrphansPerSystem; $o++) {
      $Name = Get-RandomGermanName -Faker $Faker
      Add-UnsAccount -TargetSystem $TargetSystem -Person $null `
        -AccountName (($Name.FirstName + '.' + $Name.LastName + $Faker.Random.Number(10, 99)).ToLower()) -FirstName $Name.FirstName -LastName $Name.LastName `
        -Description 'Orphaned account - no identity' -Disabled $false -Privileged $false -Managed $false
    }

    # Admin identities: a privileged account in every system, in the highest-risk groups
    $HighRiskGroups = @($TargetSystem.Groups | Sort-Object RiskIndex -Descending | Select-Object -First 3)
    foreach ($Admin in @($FakeData.ExtraIdentities | Where-Object { $_.IdentityType -eq 'Admin' })) {
      Add-UnsAccount -TargetSystem $TargetSystem -Person $Admin `
        -AccountName ('adm-' + (Get-AccountNameFor $Admin.Master)) -FirstName $Admin.FirstName -LastName $Admin.LastName `
        -Description "Privileged account of $($Admin.FirstName) $($Admin.LastName)" -Disabled $false -Privileged $true -Managed $false `
        -Groups $HighRiskGroups -Entitlements @() -RandomGroups $false
    }
  }

  # Service identities: an account in two systems each, one group, never disabled
  $s = 0
  foreach ($Service in @($FakeData.ExtraIdentities | Where-Object { $_.IdentityType -eq 'Service' })) {
    foreach ($TargetSystem in @($FakeData.TargetSystems | Get-Random -SetSeed ($Seed + 200 + ($s++)) -Count ([Math]::Min(2, $FakeData.TargetSystems.Count)))) {
      Add-UnsAccount -TargetSystem $TargetSystem -Person $Service `
        -AccountName $Service.LastName -FirstName $Service.FirstName -LastName $Service.LastName `
        -Description "Service account for the $($Service.LastName) job" -Disabled $false -Privileged $false -Managed $false `
        -Groups @($TargetSystem.Groups[$Faker.Random.Int(0, $TargetSystem.Groups.Count - 1)]) -Entitlements @() -RandomGroups $false
    }
  }

  $ElapsedTime = New-TimeSpan $StartTime $(get-date)
  Write-Debug "Done in $elapsedTime ($($script:UnsAccounts.Count) accounts, $($script:UnsMemberships.Count) memberships)"

  [PSCustomObject]@{ Accounts = $script:UnsAccounts; Memberships = $script:UnsMemberships }
}

[Bogus.Randomizer]::Seed = [System.Random]::new($Seed)
$Faker = [Bogus.Faker]::new('en')
$uow = New-UnitOfWork -Session $Session

$InstalledModules = Get-InstalledIdentityManagerModule

# RiskIndex is only writable with QER\CalculateRiskIndex enabled, and not every version has it on every table (v92: none on Department, ProfitCenter, Locality, Org)
$RiskIndexEnabled = [bool](Get-ConfigParm -Key 'QER\CalculateRiskIndex' | Where-Object { $_.Value -eq 1 })
function Test-RiskIndex([string] $Table) {
  $RiskIndexEnabled -and [VI.DB.Entities.SessionExtensions]::MetaData($Session).GetTableAsync($Table, [System.Threading.CancellationToken]::None).GetAwaiter().GetResult().Columns.IsAvailable('RiskIndex')
}

if ($InstalledModules.Contains('RMB')) {
  #
  # Create Org / Business role structure
  #
  Write-Information '[*] Creating OrgRoot'

  $OrgRoot = New-OrgRoot -Ident_OrgRoot 'FakeOrgRoot' `
    -Description $Faker.Lorem.Sentence(3, 5) `
    -UID_OrgAttestator 'RMB-AEROLE-ROLEADMIN-ATTESTATOR'

  $OA = Get-OrgRootAssign -UID_OrgRoot $OrgRoot.UID_OrgRoot

  $OA | ForEach-Object {
      try {
          $_.IsDirectAssignmentAllowed = $true
      } catch {
          # Silent fail
      }

      try {
          $_.IsAssignmentAllowed = $true
      } catch {
          # Silent fail
      }

      $_ | Set-OrgRootAssign | Out-Null
  }
} else {
  Write-Warning '[*] Skipping creating OrgRoot because of missing RMB module.'
}

# Create Identities
$FakeData.Identities = New-Identities -Session $Session -Faker $Faker -Quantity $numberOfIdentities

# Create Departments
$FakeData.Departments = New-Departments -Session $Session -Faker $Faker -Quantity $numberOfDepartments -FakeData $FakeData

# Create cost centers
$FakeData.CostCenters = New-CostCenters -Session $Session -Faker $Faker -Quantity $numberOfCostCenters -FakeData $FakeData

# Create locations
$FakeData.Locations = New-Locations -Session $Session -Faker $Faker -Quantity $numberOfLocations -FakeData $FakeData

# Create FirmPartners
$FakeData.FirmPartners = New-FirmPartners -Session $Session -Faker $Faker -Quantity $numberOfFirmPartner -FakeData $FakeData

# Create FunctionalAreas
$FakeData.FunctionalAreas = New-FunctionalAreas -Session $Session -Faker $Faker -Quantity $numberOfFunctionalAreas -FakeData $FakeData

#
# Department hierarchy: a few root departments, the rest hang below them up to $DepartmentStructureDepth levels
#
Write-Information '[*] Building department hierarchy'
$DepartmentsByLevel = @{}
$UsedDepartmentNames = @{}
$RootAreas = @($BusinessAreas | Get-Random -SetSeed $Seed -Count $numberOfRootDepartments)

function Get-UniqueDepartmentName {
  param ([string] $Prefix, [string[]] $Pool)

  # Try pool entries in a seeded order until one yields an unused name; fall back to a counter
  $Order = @($Pool | Get-Random -SetSeed ($Seed + $UsedDepartmentNames.Count) -Count $Pool.Count)
  foreach ($Candidate in $Order) {
    $Name = if ($Prefix) { "$Prefix - $Candidate" } else { $Candidate }
    if (-not $UsedDepartmentNames.ContainsKey($Name)) { return $Name }
  }
  "$Prefix - Unit $($UsedDepartmentNames.Count + 1)"
}

for ($i = 0; $i -lt $FakeData.Departments.Count; $i++) {
  $Department = $FakeData.Departments[$i]

  if ($i -lt $numberOfRootDepartments) {
    $Level = 1
    $Name = Get-UniqueDepartmentName -Prefix '' -Pool @($RootAreas[$i])
  } else {
    # Spread the remaining departments evenly over levels 2..depth
    $Level = 2 + (($i - $numberOfRootDepartments) % ($DepartmentStructureDepth - 1))
    $Parents = $DepartmentsByLevel[$Level - 1]
    $Parent = $Parents[$Faker.Random.Int(0, $Parents.Count - 1)]
    $Department.UID_ParentDepartment = $Parent.UID_Department
    $Pool = if ($Level -eq 2) { $DepartmentSubUnits } else { $DepartmentRegions }
    $Name = Get-UniqueDepartmentName -Prefix $Parent.DepartmentName -Pool $Pool
  }

  $Department.DepartmentName = $Name
  $Department.ShortName = $Name
  $UsedDepartmentNames[$Name] = $true

  $Department | Add-Member -NotePropertyName 'OrgLevel' -NotePropertyValue $Level
  if (-not $DepartmentsByLevel.ContainsKey($Level)) { $DepartmentsByLevel[$Level] = @() }
  $DepartmentsByLevel[$Level] += $Department
}

# Wire Departments <--> Cost Centers
for ($i = 0; $i -lt $FakeData.Departments.Count; $i++)
{
  # Assign a cost center to every department
  $UID_ProfitCenter = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
  $FakeData.Departments[$i].UID_ProfitCenter = $UID_ProfitCenter

  # Assign a location to every department
  $UID_Locality = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
  $FakeData.Departments[$i].UID_Locality = $UID_Locality

  # Assign a FunctionalArea to every department
  $UID_FunctionalArea = $Faker.Random.ArrayElement($($FakeData.FunctionalAreas).UID_FunctionalArea)
  $FakeData.Departments[$i].UID_FunctionalArea = $UID_FunctionalArea

  # Reverse the assignment - so the department links back to the same cost center
  $($FakeData.CostCenters | Where-Object UID_ProfitCenter -eq $UID_ProfitCenter).UID_Department = $FakeData.Departments[$i].UID_Department

  # Reverse the assignment - so the department links back to the same location
  $($FakeData.Locations | Where-Object UID_Locality -eq $UID_Locality).UID_Department = $FakeData.Departments[$i].UID_Department
}

# Because of the random based assignment, we might have some cost centers without any assigment for departments - let's fix that
$FakeData.CostCenters | Where-Object UID_Department -eq '' | ForEach-Object {
  $_.UID_Department = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
}

# Because of the random based assignment, we might have some locations without any assigment for departments - let's fix that
$FakeData.Locations | Where-Object UID_Department -eq '' | ForEach-Object {
  $_.UID_Department = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
}

# Wire Cost Centers <--> Locations
for ($i = 0; $i -lt $FakeData.CostCenters.Count; $i++)
{
  # Assign a location to every cost center
  $UID_Locality = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
  $FakeData.CostCenters[$i].UID_Locality = $UID_Locality

  # Assign a FunctionalArea to every cost center
  $UID_FunctionalArea = $Faker.Random.ArrayElement($($FakeData.FunctionalAreas).UID_FunctionalArea)
  $FakeData.CostCenters[$i].UID_FunctionalArea = $UID_FunctionalArea

  # Reverse the assignment - so the cost links back to the same location
  $($FakeData.Locations | Where-Object UID_Locality -eq $UID_Locality).UID_ProfitCenter = $FakeData.CostCenters[$i].UID_ProfitCenter
}

# Because of the random based assignment, we might have some locations without any assigment for profitcenter - let's fix that
$FakeData.Locations | Where-Object UID_ProfitCenter -eq '' | ForEach-Object {
  $_.UID_ProfitCenter = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
}

# Assign FunctionalArea to more objects
$FakeData.Locations | Where-Object UID_FunctionalArea -eq '' | ForEach-Object {
  $_.UID_FunctionalArea = $Faker.Random.ArrayElement($($FakeData.FunctionalAreas).UID_FunctionalArea)
}

#
# Persist data into database - this MUST be DONE HERE otherwise we cannot find the foreign keys
#
Write-Information '[*] Persisting data stage 1'

$st = $(get-date)
Write-Debug 'Adding FunctionalAreas to unit of work'
$FakeData.FunctionalAreas | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding Identities to unit of work'
$FakeData.Identities | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding Departments to unit of work'
$FakeData.Departments | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding Cost Centers to unit of work'
$FakeData.CostCenters | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding Locations to unit of work'
$FakeData.Locations | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding FirmPartners to unit of work'
$FakeData.FirmPartners | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

if ($InstalledModules.Contains('RMB')) {
  #
  # Create Org / Business role structure
  #
  Write-Information '[*] Creating Org structure'

  $st = $(get-date)
  New-OrgHierarchy
  $et = New-TimeSpan $st $(get-date)

  Write-Debug "Done in $et"
} else {
  Write-Warning '[*] Skipping creating of Org structure because of missing RMB module.'
}

# Create custom target systems
$CustomTargetSystemsAllowed = Get-ConfigParm -Key 'TargetSystem\UNS\CreateNewRoot'
if ($CustomTargetSystemsAllowed.Value -eq 1) {
  $st = $(get-date)
  Write-Information '[*] Creating custom target systems'
  $FakeData.TargetSystems = @(New-CustomTargetSystem -Session $Session -Faker $Faker -Quantity $NumberOfCustomTargetSystems)
  $et = New-TimeSpan $st $(get-date)
  Write-Debug "Done in $et"
} else {
  Write-Warning '[*] Skipping creating custom target system because of deactivated ConfigParm TargetSystem\UNS\CreateNewRoot.'
}

$st = $(get-date)
Write-Information '[*] Wire Identities with Cost Centers, Departments, Locations, Business Roles, Managers (direct and indirect)'
# Wire Identities with Cost Centers, Departments
# and add Identities additionally to Cost Centers, Departments
for ($i = 0; $i -lt $FakeData.Identities.Count; $i++)
{
  # Reload entities to allow further updates
  $FakeData.Identities[$i] = $FakeData.Identities[$i].Reload()

  $FakeData.Identities[$i] | Add-Member -NotePropertyName 'Subordinates' -NotePropertyValue @()

  # Assign a Cost Center to every identity
  $UID_ProfitCenter = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
  $FakeData.Identities[$i].UID_ProfitCenter = $UID_ProfitCenter

  # Assign a Department to every identity
  $UID_Department = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
  $FakeData.Identities[$i].UID_Department = $UID_Department

  # Assign a Location to every identity
  $UID_Locality = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
  $FakeData.Identities[$i].UID_Locality = $UID_Locality

  if ($InstalledModules.Contains('RMB')) {
    # Assign a Business Role to every identity
    $UID_Org = $Faker.Random.ArrayElement($($FakeData.BusinessRoles).UID_Org)
    $FakeData.Identities[$i].UID_Org = $UID_Org
  }

  # Give Identities a fixed default email address
  $FakeData.Identities[$i].DefaultEMailAddress = $FakeData.Identities[$i].CentralAccount + '@fakedata.local'

  # Do additional assignments only for every 10% of identity
  if (0 -ne $($i % ($FakeData.Identities.Count * 0.1))) {
    continue
  }

  # Additional Department assignments (Exclude the same as already direct assigned)
  $numberOfAdditionalAssignments = $Faker.Random.Number(0, $FakeData.Departments.Count)
  for ($j = 0; $j -lt $numberOfAdditionalAssignments; $j++) {
    $RandomAssignement = $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department)
    if ($RandomAssignement -ne $UID_Department) {
      $Assignment = New-PersonInDepartment -UID_Person $FakeData.Identities[$i].UID_Person `
        -UID_Department $RandomAssignement -Unsaved

      if (0 -eq $FakeData.IdentityInDepartment.Count) {
        $FakeData.IdentityInDepartment += $Assignment
      } elseif (-not ($FakeData.IdentityInDepartment | Where-Object { ($_.UID_Person -eq $FakeData.Identities[$i].UID_Person) -and ($_.UID_Department -eq $RandomAssignement) } )) {
        $FakeData.IdentityInDepartment += $Assignment
      }
    }
  }

  # Additional Cost Center assignments (Exclude the same as already direct assigned)
  $numberOfAdditionalAssignments = $Faker.Random.Number(0, $FakeData.CostCenters.Count)
  for ($j = 0; $j -lt $numberOfAdditionalAssignments; $j++) {
    $RandomAssignement = $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter)
    if ($RandomAssignement -ne $UID_ProfitCenter) {
      $Assignment = New-PersonInProfitCenter -UID_Person $FakeData.Identities[$i].UID_Person `
        -UID_ProfitCenter $RandomAssignement -Unsaved

      if (0 -eq $FakeData.IdentityInCostCenter.Count) {
        $FakeData.IdentityInCostCenter += $Assignment
      } elseif (-not ($FakeData.IdentityInCostCenter | Where-Object { ($_.UID_Person -eq $FakeData.Identities[$i].UID_Person) -and ($_.UID_ProfitCenter -eq $RandomAssignement) } )) {
        $FakeData.IdentityInCostCenter += $Assignment
      }
    }
  }

  # Additional Locality assignments (Exclude the same as already direct assigned)
  $numberOfAdditionalAssignments = $Faker.Random.Number(0, $FakeData.Locations.Count)
  for ($j = 0; $j -lt $numberOfAdditionalAssignments; $j++) {
    $RandomAssignement = $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality)
    if ($RandomAssignement -ne $UID_Locality) {
      $Assignment = New-PersonInLocality -UID_Person $FakeData.Identities[$i].UID_Person `
        -UID_Locality $RandomAssignement -Unsaved

      if (0 -eq $FakeData.IdentityInLocality.Count) {
        $FakeData.IdentityInLocality += $Assignment
      } elseif (-not ($FakeData.IdentityInLocality | Where-Object { ($_.UID_Person -eq $FakeData.Identities[$i].UID_Person) -and ($_.UID_Locality -eq $RandomAssignement) } )) {
        $FakeData.IdentityInLocality += $Assignment
      }
    }
  }

}

# Add managers to identities start
$remainingPeople = $FakeData.Identities[1..($FakeData.Identities.Count - 1)]
$availableSupervisors = @($FakeData.Identities[0])

while ($FakeData.Identities[0].Subordinates.Count -lt $rootMaxDirectReports -and $remainingPeople.Count -gt 0) {
    $person = $remainingPeople[0]
    $remainingPeople = $remainingPeople[1..($remainingPeople.Count - 1)]

    $FakeData.Identities[0].Subordinates += $person
    $person.UID_PersonHead = $FakeData.Identities[0].UID_Person
    $availableSupervisors += $person
}

$j = $remainingPeople.Count

foreach ($person in $remainingPeople) {
    $assigned = $false
    while (-not $assigned) {
        $meanSubordinates = [Math]::Ceiling($numberOfIdentities * 0.1)
        $stdDevSubordinates = [Math]::Ceiling($numberOfIdentities * 0.03)
        $desiredSubordinates = GetGaussianRandom -mean $meanSubordinates -stdDev $stdDevSubordinates -min $minSubordinates -max $maxSubordinates

        $potentialSupervisors = $availableSupervisors | Where-Object {
            $_.UID_Person -ne $FakeData.Identities[0].UID_Person -and $_.Subordinates.Count -lt $maxSubordinates
        } | Where-Object { !(HasCircularReference -subordinate $person -supervisor $_) }

        if (-Not ('Count' -In $potentialSupervisors.PSobject.Properties.Name)) {
            $newSupervisor = $availableSupervisors |Get-Random -SetSeed $($Seed * $j + $j)
            $newSupervisor.Subordinates += $person
            $person.UID_PersonHead = $newSupervisor.UID_Person
            $availableSupervisors += $person
            $assigned = $true
        } else {
            $supervisor = $potentialSupervisors |Get-Random -SetSeed $($Seed * $j)
            $supervisor.Subordinates += $person
            $person.UID_PersonHead = $supervisor.UID_Person
            $assigned = $true

            if ($supervisor.Subordinates.Count -ge $desiredSubordinates) {
                $availableSupervisors = $availableSupervisors -ne $supervisor
            }
        }
    }

    $j--
}

# Add managers to identities end

#
# Job titles by level in the manager tree
#
Write-Information '[*] Assigning job titles by hierarchy level'
$IdentityByUid = @{}
$FakeData.Identities | ForEach-Object { $IdentityByUid[$_.UID_Person] = $_ }

function Get-ManagerDepth {
  param ($Person)

  $depth = 0
  $current = $Person
  while (-not [string]::IsNullOrEmpty($current.UID_PersonHead) -and $IdentityByUid.ContainsKey($current.UID_PersonHead) -and $depth -lt 50) {
    $depth++
    $current = $IdentityByUid[$current.UID_PersonHead]
  }
  $depth
}

$cLevelIndex = 0
foreach ($Person in $FakeData.Identities) {
  $Depth = Get-ManagerDepth -Person $Person
  $Person | Add-Member -NotePropertyName 'OrgLevel' -NotePropertyValue $Depth
  $Area = $BusinessAreas[$Faker.Random.Int(0, $BusinessAreas.Count - 1)]
  $IsManager = $Person.Subordinates.Count -gt 0

  $Person.PersonalTitle = switch ($Depth) {
    0 { 'Chief Executive Officer' }
    1 { $CLevelTitles[($cLevelIndex++) % $CLevelTitles.Count] }
    2 { if ($IsManager) { "Vice President $Area" } else { "Executive Assistant" } }
    3 { if ($IsManager) { "Director $Area" } else { "Senior Manager $Area" } }
    default {
      if ($IsManager) {
        "Team Lead $Area"
      } else {
        $IcLevels[$Faker.Random.Int(0, $IcLevels.Count - 1)] + $IcRoles[$Faker.Random.Int(0, $IcRoles.Count - 1)]
      }
    }
  }
}

#
# Heads and deputies that follow the manager tree:
#  - head of a level-N department is a manager at depth N in the manager tree
#  - the deputy (UID_PersonHeadSecond) is the head's most senior direct report
#  - cost centers, locations and business roles get a manager as head and that manager's most senior report as deputy
#
Write-Information '[*] Re-wiring heads and deputies to the manager tree'
$Managers = @($FakeData.Identities | Where-Object { $_.Subordinates.Count -gt 0 })

function Get-DeputyFor {
  param ($Head)

  if ($Head.Subordinates.Count -gt 0) {
    # most senior direct report = the one with the most own subordinates
    ($Head.Subordinates | Sort-Object { $_.Subordinates.Count } -Descending)[0]
  } else {
    $IdentityByUid[$Head.UID_PersonHead]
  }
}

function Set-HeadAndDeputy {
  param ($Entity, $Head, [string] $Table)

  $Deputy = Get-DeputyFor -Head $Head
  $Entity.UID_PersonHead = $Head.UID_Person
  $Entity.UID_PersonHeadSecond = $Deputy.UID_Person

  # Remember the pair for the delegation set-up after the save
  if (-not ($FakeData.Delegations | Where-Object { $_.Sender -eq $Head.UID_Person -and $_.Receiver -eq $Deputy.UID_Person })) {
    $FakeData.Delegations += [PSCustomObject]@{ Sender = $Head.UID_Person; Receiver = $Deputy.UID_Person; Table = $Table }
  }
}

function Get-RandomManager {
  param ([int] $Depth = -1)

  $Candidates = @(if ($Depth -ge 0) { $Managers | Where-Object { $_.OrgLevel -eq $Depth } })
  if ($Candidates.Count -eq 0) { $Candidates = $Managers }
  $Candidates[$Faker.Random.Int(0, $Candidates.Count - 1)]
}

for ($i = 0; $i -lt $FakeData.Departments.Count; $i++) {
  # Reload returns a fresh entity, so keep the note property across it
  $Level = $FakeData.Departments[$i].OrgLevel
  $FakeData.Departments[$i] = $FakeData.Departments[$i].Reload()
  $FakeData.Departments[$i] | Add-Member -NotePropertyName 'OrgLevel' -NotePropertyValue $Level
  Set-HeadAndDeputy -Entity $FakeData.Departments[$i] -Head (Get-RandomManager -Depth $Level) -Table 'Department'
}
for ($i = 0; $i -lt $FakeData.CostCenters.Count; $i++) {
  $FakeData.CostCenters[$i] = $FakeData.CostCenters[$i].Reload()
  Set-HeadAndDeputy -Entity $FakeData.CostCenters[$i] -Head (Get-RandomManager) -Table 'ProfitCenter'
}
for ($i = 0; $i -lt $FakeData.Locations.Count; $i++) {
  $FakeData.Locations[$i] = $FakeData.Locations[$i].Reload()
  Set-HeadAndDeputy -Entity $FakeData.Locations[$i] -Head (Get-RandomManager) -Table 'Locality'
}
for ($i = 0; $i -lt $FakeData.BusinessRoles.Count; $i++) {
  $FakeData.BusinessRoles[$i] = $FakeData.BusinessRoles[$i].Reload()
  Set-HeadAndDeputy -Entity $FakeData.BusinessRoles[$i] -Head (Get-RandomManager) -Table 'Org'
}

$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

#
# Lifecycle states and externals - only individual contributors, so the manager tree stays intact
#
Write-Information '[*] Assigning lifecycle states (leavers, joiners, on leave) and externals'
$Today = (Get-Date).Date
$FakeData.Identities | ForEach-Object { $_ | Add-Member -NotePropertyName 'Lifecycle' -NotePropertyValue 'Active' }
$ICs = @($FakeData.Identities | Where-Object { $_.Subordinates.Count -eq 0 } | Get-Random -SetSeed ($Seed + 7) -Count ([int]::MaxValue))

$nLeavers = [int][Math]::Ceiling($FakeData.Identities.Count * $ShareOfLeavers)
$nJoiners = [int][Math]::Ceiling($FakeData.Identities.Count * $ShareOfJoiners)
$nOnLeave = [int][Math]::Ceiling($FakeData.Identities.Count * $ShareOfOnLeave)
$nExternals = [int][Math]::Ceiling($FakeData.Identities.Count * $ShareOfExternals)
if ($nLeavers + $nJoiners + $nOnLeave + $nExternals -gt $ICs.Count) {
  throw "Lifecycle shares need $($nLeavers + $nJoiners + $nOnLeave + $nExternals) individual contributors but only $($ICs.Count) exist. Lower the Share* values."
}
$cursor = 0

foreach ($Person in $ICs[$cursor..($cursor + $nLeavers - 1)]) {
  $Person.Lifecycle = 'Leaver'
  $Person.IsInActive = $true
  $Person.ExitDate = $Today.AddDays(-$Faker.Random.Int(1, 365))
}
$cursor += $nLeavers
foreach ($Person in $ICs[$cursor..($cursor + $nJoiners - 1)]) {
  $Person.Lifecycle = 'Joiner'
  $Person.EntryDate = $Today.AddDays($Faker.Random.Int(1, 60))
}
$cursor += $nJoiners
foreach ($Person in $ICs[$cursor..($cursor + $nOnLeave - 1)]) {
  $Person.Lifecycle = 'OnLeave'
  $Person.IsTemporaryDeactivated = $true
}
$cursor += $nOnLeave
foreach ($Person in $ICs[$cursor..($cursor + $nExternals - 1)]) {
  $Person.IsExternal = $true
  $Person.UID_FirmPartner = $FakeData.FirmPartners[$Faker.Random.Int(0, $FakeData.FirmPartners.Count - 1)].UID_FirmPartner
}

# Everyone who is not a joiner has been with the company for a while
foreach ($Person in $FakeData.Identities | Where-Object { $_.Lifecycle -ne 'Joiner' }) {
  $Person.EntryDate = $Today.AddDays(-$Faker.Random.Int(30, 20 * 365))
}

#
# Extra identities: administrative identities tied to a master identity, and service identities
#
Write-Information "[*] Creating $numberOfAdminIdentities admin and $numberOfServiceIdentities service identities"
$MasterCandidates = @($FakeData.Identities | Where-Object { $_.Lifecycle -eq 'Active' -and -not $_.IsExternal })
$Masters = @($MasterCandidates | Get-Random -SetSeed ($Seed + 11) -Count $numberOfAdminIdentities)

foreach ($Master in $Masters) {
  $Admin = New-Person -FirstName $Master.FirstName `
    -LastName $Master.LastName `
    -IdentityType 'Admin' `
    -UID_PersonMasterIdentity $Master.UID_Person `
    -UID_PersonHead $Master.UID_PersonHead `
    -UID_Department $Master.UID_Department `
    -UID_ProfitCenter $Master.UID_ProfitCenter `
    -UID_Locality $Master.UID_Locality `
    -PersonalTitle "Administrator ($($Master.PersonalTitle))" `
    -Description "Administrative identity of $($Master.FirstName) $($Master.LastName)" `
    -CustomProperty01 'Fakedata' `
    -Unsaved
  $Admin | Add-Member -NotePropertyName 'Lifecycle' -NotePropertyValue 'Active'
  $Admin | Add-Member -NotePropertyName 'Master' -NotePropertyValue $Master
  $FakeData.ExtraIdentities += $Admin
}

$RootDepartments = @($FakeData.Departments | Where-Object { $_.OrgLevel -eq 1 })
foreach ($Name in @($ServiceIdentityNames | Select-Object -First $numberOfServiceIdentities)) {
  $Service = New-Person -FirstName 'Service' `
    -LastName "svc-$Name" `
    -IdentityType 'Service' `
    -UID_PersonHead (Get-RandomManager).UID_Person `
    -UID_Department $RootDepartments[$Faker.Random.Int(0, $RootDepartments.Count - 1)].UID_Department `
    -PersonalTitle 'Service identity' `
    -Description "Service identity for the $Name job" `
    -CustomProperty01 'Fakedata' `
    -Unsaved
  $Service | Add-Member -NotePropertyName 'Lifecycle' -NotePropertyValue 'Active'
  $Service | Add-Member -NotePropertyName 'Master' -NotePropertyValue $null
  $FakeData.ExtraIdentities += $Service
}

#
# UNS accounts + group memberships in the custom target systems; account definitions inherited via root departments
#
if ($FakeData.TargetSystems.Count -gt 0) {
  Write-Information '[*] Creating UNS accounts and group memberships'
  $UNS = New-UNSAccounts -Session $Session -Faker $Faker -FakeData $FakeData
  $FakeData.UNSAccounts = $UNS.Accounts
  $FakeData.UNSAccountMemberships = $UNS.Memberships

  Write-Information '[*] Assigning account definitions to root departments'
  $n = 0
  foreach ($TargetSystem in $FakeData.TargetSystems) {
    foreach ($Department in @($RootDepartments | Get-Random -SetSeed ($Seed + 100 + ($n++)) -Count 2)) {
      $FakeData.AccountDefAssignments += New-Entity -Type 'DepartmentHasTSBAccountDef' -Unsaved -Properties @{
        UID_Department    = $Department.UID_Department
        UID_TSBAccountDef = $TargetSystem.AccountDef.UID_TSBAccountDef
      }
    }
  }
} else {
  Write-Warning '[*] Skipping UNS accounts because no custom target systems were created.'
}

#
# Create IT Shop structure
#

# Shop
$ItShop = New-ITShopOrg -Ident_Org 'FakeShop' `
  -ITShopInfo 'SH' `
  -InternalName 'Dummy Shop for testing' `
  -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
  -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
  -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -CustomProperty01 'Fakedata' `
  -Unsaved

# Customer Folder
$ItShopCustomer = New-ITShopOrg -Ident_Org 'Customers of FakeShop' `
  -ITShopInfo 'CU' `
  -InternalName 'Customer folder for FakeShop' `
  -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
  -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
  -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -CustomProperty01 'Fakedata' `
  -Unsaved

$ItShopCustomer.UID_ParentITShopOrg = $ItShop.UID_ITShopOrg

# Dynamic group for Customer Folder
# UID_DialogSchedule -> "Dynamic roles check" with fixed UID 'QER-B78E7C59F09D487085506ED339F0257D'
$DynGroupForCustomers = New-DynamicGroup -DisplayName 'Dynamic Group for FakeShop customers' `
  -IsCalculateImmediately 1 `
  -ObjectKeyBaseTree $('<Key><T>ITShopOrg</T><P>' + $ItShopCustomer.UID_ITShopOrg + '</P></Key>') `
  -UID_DialogTableObjectClass 'QER-T-Person' `
  -UID_DialogSchedule 'QER-B78E7C59F09D487085506ED339F0257D' `
  -WhereClause "isnull(IsInActive, 0) = 0 and CustomProperty01 = 'Fakedata'" `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -Unsaved

# Shelf
$ItShopShelf = New-ITShopOrg -Ident_Org 'Shelf for FakeShop' `
  -ITShopInfo 'BO' `
  -InternalName 'Shelf for FakeShop' `
  -UID_PersonHead $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_PersonHeadSecond $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) `
  -UID_ProfitCenter $Faker.Random.ArrayElement($($FakeData.CostCenters).UID_ProfitCenter) `
  -UID_Department $Faker.Random.ArrayElement($($FakeData.Departments).UID_Department) `
  -UID_Locality $Faker.Random.ArrayElement($($FakeData.Locations).UID_Locality) `
  -Description $Faker.Lorem.Sentence(3, 5) `
  -CustomProperty01 'Fakedata' `
  -Unsaved

$ItShopShelf.UID_ParentITShopOrg = $ItShop.UID_ITShopOrg

# Assigning the "Recipient's manager" Approval Policy
$ITShopOrgHasPWODecisionMethod = New-ITShopOrgHasPWODecisionMethod -UID_ITShopOrg $ItShop.UID_ITShopOrg `
  -UID_PWODecisionMethod 'QER-9F9FF8FD4D2FCB4E916B45990E8765B7' `
  -Unsaved

#
# Request properties for the cars (new-style: AccProductParamCategory + DialogParameterSet + DialogParameter)
#
Write-Information '[*] Creating car request properties'
$FakeData.CarParamCategory = New-Entity -Type 'AccProductParamCategory' -Unsaved -Properties @{
  Ident_AccProductParamCategory = 'Car configuration'
  Description                   = 'Options the requester fills in when ordering a car'
  IsOldStyle                    = $false
}

$FakeData.CarParamSet = New-Entity -Type 'DialogParameterSet' -Unsaved -Properties @{
  DisplayName     = 'Car configuration'
  Description     = 'Request properties for BMW products in the FakeShop'
  Category        = 'Request properties (AccProductParamCategory)'
  # built from the UID, XObjectKey of an unsaved entity is empty in v92
  ObjectKeyUsedBy = "<Key><T>AccProductParamCategory</T><P>$($FakeData.CarParamCategory.UID_AccProductParamCategory)</P></Key>"
}

# DataType uses VI.Base.ValType: 0 = Bool, 1 = Int, 5 = Date, 6 = String. LimitedValues entries are separated by char 7.
$CarParamDefinitions = @(
  @{ ParameterName = 'ExteriorColor'; DisplayName = 'Exterior colour';     DataType = 6; IsMandatory = 1; DataSourceType = 'LimitedValue'; LimitedValues = ('Alpine White', 'Black Sapphire', 'Mineral Grey', 'Portimao Blue', 'Melbourne Red', 'Sunset Orange', 'Isle of Man Green', 'Frozen Deep Grey') -join [char]7 }
  @{ ParameterName = 'Transmission';  DisplayName = 'Transmission';        DataType = 6; IsMandatory = 1; DataSourceType = 'LimitedValue'; LimitedValues = ('Manual', 'Automatic') -join [char]7; DefaultValue = 'Automatic' }
  @{ ParameterName = 'LeaseMonths';   DisplayName = 'Lease duration (months)'; DataType = 1; IsMandatory = 1; DefaultValue = '36' }
  @{ ParameterName = 'DeliveryDate';  DisplayName = 'Requested delivery date'; DataType = 5; IsMandatory = 0 }
  @{ ParameterName = 'WinterTyres';   DisplayName = 'Include winter tyres';    DataType = 0; IsMandatory = 0; DefaultValue = '0' }
  @{ ParameterName = 'LicensePlate';  DisplayName = 'Preferred licence plate'; DataType = 6; IsMandatory = 0 }
)

$sortOrder = 0
$FakeData.CarParams = $CarParamDefinitions | ForEach-Object {
  $props = @{
    UID_DialogParameterSet = $FakeData.CarParamSet.UID_DialogParameterSet
    ParameterType          = 'Fix'
    SortOrder              = [string]($sortOrder++)
  } + $_
  New-Entity -Type 'DialogParameter' -Unsaved -Properties $props
}

$Categories = New-AccProductGroups -Session $Session -Faker $Faker -FakeData $FakeData
$FakeData.AccProductGroup = $Categories.Root
$FakeData.AccProductGroups = $Categories.All
$FakeData.AccProductGroupByKey = $Categories.ByKey
$FakeData.AccProducts = New-AccProducts -Session $Session -Faker $Faker -Quantity $NumberOfItShopProducts -FakeData $FakeData
$FakeData.ProductOwners = New-ProductOwners -Session $Session -Faker $Faker -Quantity $NumberOfItShopProducts -FakeData $FakeData
$FakeData.QERReuses = New-QERReuses -Session $Session -Faker $Faker -Quantity $NumberOfItShopProducts -FakeData $FakeData
$FakeData.ITShopOrgHasQERReuse = New-ITShopOrgHasQERReuses -Session $Session -Faker $Faker -Quantity $NumberOfItShopProducts -FakeData $FakeData -UID_ITShopOrg $ItShopShelf.UID_ITShopOrg

# Target system groups as IT Shop products on the same shelf
if ($FakeData.TargetSystems.Count -gt 0) {
  $GroupProducts = New-TargetSystemGroupProducts -Session $Session -Faker $Faker -FakeData $FakeData -UID_ITShopOrg $ItShopShelf.UID_ITShopOrg
  $FakeData.GroupProductOwners = $GroupProducts.Owners
  $FakeData.GroupProductOwnerMembers = $GroupProducts.OwnerMembers
  $FakeData.GroupProducts = $GroupProducts.Products
  $FakeData.RequestableGroups = $GroupProducts.Groups
  $FakeData.GroupShelfAssignments = $GroupProducts.ShelfAssignments
}

#
# Persist data into database
#
Write-Information '[*] Persisting data stage 2'
$st = $(get-date)
Write-Debug 'Adding Identities to unit of work'
$FakeData.Identities | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.ExtraIdentities | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding assignment of Identities to Departments to unit of work'
$FakeData.IdentityInDepartment | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding assignment of Identities to Cost Centers to unit of work'
$FakeData.IdentityInCostCenter | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding assignment of Identities to Locations to unit of work'
$FakeData.IdentityInLocality | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding ITShop Orgs to unit of work'
$ItShop | Add-UnitOfWorkEntity -UnitOfWork $uow
$ItShopCustomer | Add-UnitOfWorkEntity -UnitOfWork $uow
$ItShopShelf | Add-UnitOfWorkEntity -UnitOfWork $uow
$ITShopOrgHasPWODecisionMethod | Add-UnitOfWorkEntity -UnitOfWork $uow
$DynGroupForCustomers | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding re-wired Departments, Cost Centers, Locations and Business Roles to unit of work'
$FakeData.Departments | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.CostCenters | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.Locations | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.BusinessRoles | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

Write-Debug 'Adding car request properties to unit of work'
$FakeData.CarParamCategory | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.CarParamSet | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.CarParams | Add-UnitOfWorkEntity -UnitOfWork $uow

Write-Debug 'Adding service categories to unit of work'
$FakeData.AccProductGroups | Add-UnitOfWorkEntity -UnitOfWork $uow

$st = $(get-date)
Write-Debug 'Adding AccProducts to unit of work I'
$FakeData.AccProducts | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding ProductOwners to unit of work'
$FakeData.ProductOwners | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

# Assign ProductOwner to AccProduct
for ($i = 0; $i -lt $FakeData.AccProducts.Count; $i++) {
  # Leaf category (series / weapon type); fall back to the root if the key is unknown. Read before Reload() drops the note property.
  $Key = $FakeData.AccProducts[$i].FakeCategoryKey
  # Reload entities to allow further updates
  $FakeData.AccProducts[$i] = $FakeData.AccProducts[$i].Reload()
  $FakeData.AccProducts[$i].UID_OrgRuler = $FakeData.ProductOwners[$i].UID_AERole
  $Category = if ($FakeData.AccProductGroupByKey.ContainsKey($Key)) { $FakeData.AccProductGroupByKey[$Key] } else { $FakeData.AccProductGroup }
  $FakeData.AccProducts[$i].UID_AccProductGroup = $Category.UID_AccProductGroup
}

$st = $(get-date)
Write-Debug 'Adding AccProducts to unit of work II'
$FakeData.AccProducts | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding target system group products, owners and shelf assignments to unit of work'
$FakeData.GroupProductOwners | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.GroupProductOwnerMembers | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.GroupProducts | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.RequestableGroups | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.GroupShelfAssignments | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.AccountDefAssignments | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$FakeData.PersonInAERoles = New-PersonInAERoles -Session $Session -Faker $Faker -Quantity 3 -FakeData $FakeData

# Add some random Identities to some common AERoles

$CommonAeRoles = @(
'AOB-AEROLE-ADMIN', # Application Governance\Administrators
'AOB-AEROLE-APPROVERS', # Application Governance\Application approvers
'AOB-AEROLE-OWNERS', # Application Governance\Application owners
'QER-AEROLE-AEADMIN', # Base roles\Administrators
'QER-AEROLE-SCIM-FILTER', # Base roles\ApiServer SCIM Filter
'QER-F8B968E2DFECD64EAFFE6A823816549F', # Base roles\Lock single properties
'QER-812e7024e3484428bb363ec24da53bfa', # Base roles\Operations support
'QER-493191220A59224BAD0D89D67C769D68', # Base roles\Operations support\Password helpdesk
'QER-5171ec005dde4649b3e10b3736033e0d', # Base roles\Operations support\Synchronization post-processing
'QER-ec9fe80870cb443da743d68d270c17be', # Base roles\Operations support\System administrators
'QER-AEROLE-CRITICAL-WHERECLAUSE', # Base roles\Security-critical queries
'QER-AEROLE-CUSTOMADMIN-ADMIN', # Custom\Administrators
'QER-AEROLE-CUSTOMADMIN-CUSTOM', # Custom\Managers
'CAP-AEROLE-AUDITING-AUDITOR', # Identity & Access Governance\§§Auditors
'ATT-AEROLE-ATTESTATIONADMIN-ADMIN', # Identity & Access Governance\Attestation\Administrators
'ATT-AEROLE-ATTESTATION-OWNER-DIRECT', # Identity & Access Governance\Attestation\Attestation policy owners\Direct owners
'ATT-AEROLE-ATTESTATION-OWNER-ROLE', # Identity & Access Governance\Attestation\Attestation policy owners\Owner roles
'ATT-AEROLE-ATTESTATION-INTERVENTION', # Identity & Access Governance\Attestation\Chief approval team
'ATT-6567356C50B5460693BBF3CF69F5883B', # Identity & Access Governance\Attestation\External user approvers
'POL-AEROLE-QERPOLICY-ADMIN', # Identity & Access Governance\Company policies\Administrators
'POL-AEROLE-QERPOLICY-ATTESTATOR', # Identity & Access Governance\Company policies\Attestors
'POL-AEROLE-QERPOLICY-EXCEPTION', # Identity & Access Governance\Company policies\Exception approvers
'POL-AEROLE-QERPOLICY-RESPONSIBLE', # Identity & Access Governance\Company policies\Policy supervisors
'CAP-AEROLE-IAG-CISO', # Identity & Access Governance\Compliance & Security Officer
'CPL-AEROLE-RULEADMIN-ADMIN', # Identity & Access Governance\Identity Audit\Administrators
'CPL-AEROLE-RULEADMIN-ATTESTATOR', # Identity & Access Governance\Identity Audit\Attestors
'CPL-AEROLE-RULEADMIN-EXCEPTION', # Identity & Access Governance\Identity Audit\Exception approvers
'SAC-AEROLE-RULEADMIN-SAPRIGHTS', # Identity & Access Governance\Identity Audit\Maintain SAP functions
'CPL-AEROLE-RULEADMIN-RESPONSIBLE', # Identity & Access Governance\Identity Audit\Rule supervisors
'RPS-AEROLE-IAG-REPORT-ADMIN', # Identity & Access Governance\Report Subscriptions\Administrators
'QER-AEROLE-AEROLEADMIN-ADDMANAGER', # Identity Management\Application roles\Additional managers
'RMB-AEROLE-ROLEADMIN-ADDMANAGER', # Identity Management\Business roles\Additional managers
'RMB-AEROLE-ROLEADMIN-ADMIN', # Identity Management\Business roles\Administrators
'RMB-AEROLE-ROLEADMIN-ATTESTATOR', # Identity Management\Business roles\Attestors
'RMB-AEROLE-ROLEADMIN-RULER', # Identity Management\Business roles\Role Approvers
'RMB-AEROLE-ROLEADMIN-RULERIT', # Identity Management\Business roles\Role Approvers (IT)
'QER-AEROLE-PERSONADMIN-ADMIN', # Identity Management\Identities\Administrators
'QER-AEROLE-STRUCTADMIN-ADDMANAGER', # Identity Management\Organizations\Additional managers
'QER-AEROLE-STRUCTADMIN-ADMIN', # Identity Management\Organizations\Administrators
'ATT-AEROLE-STRUCTADMIN-ATTESTATOR', # Identity Management\Organizations\Attestors
'QER-AEROLE-STRUCTADMIN-RULER', # Identity Management\Organizations\Role Approvers
'QER-AEROLE-STRUCTADMIN-RULERIT', # Identity Management\Organizations\Role Approvers (IT)
'PAG-AEROLE-ASSET-OWNER', # Privileged Account Governance\Asset and account owners
'QER-AEROLE-ITSHOPADMIN-ADDMANAGER', # Request & Fulfillment\IT Shop\Additional managers
'QER-AEROLE-ITSHOPADMIN-ADMIN', # Request & Fulfillment\IT Shop\Administrators
'ATT-AEROLE-ITSHOPADMIN-ATTESTATOR', # Request & Fulfillment\IT Shop\Attestors
'QER-AEROLE-ITSHOP-INTERVENTION', # Request & Fulfillment\IT Shop\Chief approval team
'QER-AEROLE-ITSHOPADMIN-OWNER', # Request & Fulfillment\IT Shop\Product owners
'ADS-AEROLE-ADSGROUP-OWNER-EMPTY', # Request & Fulfillment\IT Shop\Product owners\<Without owner in AD>
'SP0-AEROLE-SPSGROUP-OWNER-EMPTY', # Request & Fulfillment\IT Shop\Product owners\<Without owner in SharePoint>
'PAG-AEROLE-ITSHOP-OWNER-USRGROUP', # Request & Fulfillment\IT Shop\Product owners\PAM user groups
'APC-AEROLE-ITSHOP-OWNER-APP', # Request & Fulfillment\IT Shop\Product owners\Software
'RPS-AEROLE-ITSHOP-OWNER-RPSREPORT', # Request & Fulfillment\IT Shop\Product owners\Subscribable reports
'RMS-AEROLE-ITSHOP-OWNER-ESET', # Request & Fulfillment\IT Shop\Product owners\System roles
'ADS-AEROLE-NAMESPACEADMIN-ADS', # Target systems\Active Directory
'TSB-AEROLE-NAMESPACEADMIN-ADMIN', # Target systems\Administrators
'AAD-AEROLE-NAMESPACEADMIN-AAD', # Target systems\Azure Active Directory
'AAD-3ba6aa44fefb4b2694b7ca12d504b903', # Target systems\Azure Active Directory\Administrative unit owners
'AAD-c6b5865628cd46249367730f922a490b', # Target systems\Azure Active Directory\App registration owners
'AAD-AA4FBEC4EBCD3641BA75B7479D090EEF', # Target systems\Azure Active Directory\Role owners
'AAD-1d27dbae3fe94c9c83e633e72e4ab235', # Target systems\Azure Active Directory\Service principal owners
'CSM-AEROLE-NAMESPACEADMIN-CSM', # Target systems\Cloud target systems
'TSB-AEROLE-NAMESPACEADMIN-UNSB', # Target systems\Custom target systems
'NDO-AEROLE-NAMESPACEADMIN-NDO', # Target systems\Domino
'EX0-AEROLE-NAMESPACEADMIN-EX0', # Target systems\Exchange
'O3E-AEROLE-NAMESPACEADMIN-O3E', # Target systems\Exchange Online
'GAP-AEROLE-NAMESPACEADMIN-GAP', # Target systems\G Suite
'LDP-AEROLE-NAMESPACEADMIN-LDAP', # Target systems\LDAP
'OLG-AEROLE-NAMESPACEADMIN-OLG', # Target systems\OneLogin
'EBS-AEROLE-NAMESPACEADMIN-EBS', # Target systems\Oracle E-Business Suite
'PAG-AEROLE-NAMESPACEADMIN-PAG', # Target systems\Privileged Account Management
'SAP-AEROLE-NAMESPACEADMIN-SAPR3', # Target systems\SAP R/3
'SP0-AEROLE-NAMESPACEADMIN-SPS', # Target systems\SharePoint
'O3S-AEROLE-NAMESPACEADMIN-O3S', # Target systems\SharePoint Online
'TSB-AEROLE-NAMESPACEADMIN-UNS', # Target systems\Unified Namespace
'UNX-AEROLE-NAMESPACEADMIN-UNIX', # Target systems\Unix
'UCI-AEROLE-CLOUD-ADMINISTRATOR', # Universal Cloud Interface\Administrators
'UCI-AEROLE-CLOUD-AUDITOR', # Universal Cloud Interface\Auditors
'UCI-AEROLE-CLOUD-OPERATOR' # Universal Cloud Interface\Operators
)

$CommonAeRoles | ForEach-Object {
    if (Test-Entity -Type 'AERole' -Identity $_) {
      # Base roles\Administrators
      $FakeData.PersonInAERoles += New-PersonInAERole -UID_AERole $_ `
        -UID_Person $Faker.Random.ArrayElement($($FakeData.Identities).UID_Person) -Unsaved
    } else {
      Write-Debug "Skip assignment of '$_'"
    }
}

if ($InstalledModules.Contains('RMB')) {
  $FakeData.PersonInOrgs = New-PersonInOrgs -Session $Session -Faker $Faker -Quantity 7 -FakeData $FakeData
}

$st = $(get-date)
Write-Debug 'Adding UNS accounts and group memberships to unit of work'
$FakeData.UNSAccounts | Add-UnitOfWorkEntity -UnitOfWork $uow
$FakeData.UNSAccountMemberships | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding PersonInAERoles to unit of work'
$FakeData.PersonInAERoles | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding QERReuses to unit of work'
$FakeData.QERReuses | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding ITShopOrgHasQERReuse to unit of work'
$FakeData.ITShopOrgHasQERReuse | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$st = $(get-date)
Write-Debug 'Adding PersonInOrg to unit of work'
$FakeData.PersonInOrgs | Add-UnitOfWorkEntity -UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

#
# Real save into database
#
Write-Information 'Saving data into database'
$st = $(get-date)
Save-UnitOfWork $uow
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

#
# Delegations: every department head delegates manager and department-head responsibilities to the deputy.
# Person.UniversalSubstitute creates the PersonWantsOrg + QERUniversalSubstitute pair itself, so this has to run after the save.
#
Write-Information '[*] Creating delegations for department head deputies'
$st = $(get-date)
$DepartmentDelegations = @($FakeData.Delegations | Where-Object { $_.Table -eq 'Department' })
$emptyDate = [DateTime]::MinValue
foreach ($Delegation in $DepartmentDelegations) {
  try {
    # Parameters: uidPersonReceiver, validFrom, validUntil, useForITShop, useForITShopCompliance, useForAttestation,
    #             keepMeInformed, useForHeadPerson, useForHeadOrg, uidOrgMVP, uidOrgPRExternal, orderReason
    Invoke-EntityMethod -Type 'Person' -Identity $Delegation.Sender -MethodName 'UniversalSubstitute' -Unsaved -Parameters @(
      $Delegation.Receiver,
      $emptyDate,
      $emptyDate,
      $true,                # IT Shop approvals
      $false,               # IT Shop compliance
      $true,                # attestation
      $true,                # keep me informed
      $true,                # manager responsibilities (UseForHeadPerson)
      $true,                # role head responsibilities (UseForHeadOrg) ...
      'QER-V-Department',   # ... for departments
      '',
      'Fakedata: deputy of the department head'
    ) | Out-Null
  } catch {
    Write-Warning "Delegation $($Delegation.Sender) -> $($Delegation.Receiver) failed: $($_.Exception.Message)"
  }
}
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et ($($DepartmentDelegations.Count) delegations)"

Write-Information 'Closing connection'
$st = $(get-date)
Remove-IdentityManagerSession -Session $Session
$et = New-TimeSpan $st $(get-date)
Write-Debug "Done in $et"

$ElapsedTimeTotal = New-TimeSpan $StartTimeTotal $(get-date)
Write-Information "[*] Total runtime: $ElapsedTimeTotal"

### Cleanup

# update ITShopOrgHasQERReuse set XOrigin = 0 where uid_QERReuse in (select uid_QERReuse from QERReuse where CustomProperty01 = 'Fakedata')
# delete from ITShopOrgHasQERReuse where uid_QERReuse in (select uid_QERReuse from QERReuse where CustomProperty01 = 'Fakedata')
# update PersonInAERole set XOrigin = 0 where UID_Person in (select UID_Person from Person where CustomProperty01 = 'Fakedata')
# update PersonInOrg set XOrigin = 0 where UID_Person in (select UID_Person from Person where CustomProperty01 = 'Fakedata')
# delete from PersonInAERole where UID_Person in (select UID_Person from Person where CustomProperty01 = 'Fakedata')
# delete from AERole where CustomProperty01 = 'Fakedata'
# delete from PersonInOrg where UID_Org in (select UID_Org from Org where CustomProperty01 = 'Fakedata')

# delete from ITShopOrg where UID_AccProduct in (select UID_AccProduct from AccProduct where CustomProperty01 = 'Fakedata')
# delete from QERReuse where CustomProperty01 = 'Fakedata'
# delete from AccProduct where CustomProperty01 = 'Fakedata'
# delete from AccProductGroup where CustomProperty01 = 'Fakedata'

# delete from DynamicGroup where DisplayName = 'Dynamic Group for FakeShop customers'
# delete from ITShopOrg where CustomProperty01 = 'Fakedata'

# delete FunctionalArea
# delete FirmPartner

# delete from Org where CustomProperty01 = 'Fakedata'
# delete from OrgRoot where Ident_OrgRoot = 'FakeOrgRoot'

# update PersonHasTSBAccountDef set xorigin = 0
# delete from PersonHasTSBAccountDef
# update DepartmentHasTSBAccountDef set XOrigin = 0 where UID_TSBAccountDef in (select UID_TSBAccountDef from TSBAccountDef where CustomProperty01 = 'Fakedata')
# delete from DepartmentHasTSBAccountDef where UID_TSBAccountDef in (select UID_TSBAccountDef from TSBAccountDef where CustomProperty01 = 'Fakedata')
# update ITShopOrgHasUNSGroupB set XOrigin = 0
# delete from ITShopOrgHasUNSGroupB
# update UNSGroupB set UID_AccProduct = null, IsForITShop = 0
# update UNSAccountBInUNSGroupB set XOrigin = 0
# update UNSAccountBInUNSGroupB1 set XOrigin = 0
# delete UNSAccountBInUNSGroupB
# delete UNSAccountBInUNSGroupB1
# delete UNSAccountB
# delete UNSGroupB1
# delete UNSGroupB
# delete UNSContainerB
# delete from TSBITDataMapping where uid_TSBAccountDef in (
# 	select uid_TSBAccountDef from TSBAccountDef where CustomProperty01 = 'Fakedata'
# )
# delete from TSBAccountDefHasBehavior where uid_TSBAccountDef in (
# 	select uid_TSBAccountDef from TSBAccountDef where CustomProperty01 = 'Fakedata'
# )
# update unsrootb set uid_tsbaccountdef = null
# delete TSBAccountDef

# delete unsrootb
# delete DPRNameSpace where UID_DPRNameSpace not in ('ADS-DPRNameSpace-ADS','LDP-DPRNameSpace-LDAP')

# delete from Person where CustomProperty01 = 'Fakedata'
# delete from Department where CustomProperty01 = 'Fakedata'
# delete from ProfitCenter where CustomProperty01 = 'Fakedata'
# delete from Locality where CustomProperty01 = 'Fakedata'