Set-StrictMode -Version Latest

<#
  Pools of common German names for the birth cohorts 1900-1950.

  First names follow the popular decade rankings for Germany (Hans, Karl, Walter ... Anna, Maria, Martha ...).
  Last names are the 100 most common German family names, which hardly changed over that period.
#>
$script:MaleFirstNames = @(
  'Hans', 'Karl', 'Wilhelm', 'Walter', 'Heinrich', 'Hermann', 'Friedrich', 'Paul', 'Otto', 'Ernst',
  'Kurt', 'Werner', 'Günter', 'Helmut', 'Gerhard', 'Horst', 'Heinz', 'Herbert', 'Erich', 'Rudolf',
  'Fritz', 'Max', 'Willi', 'Georg', 'Alfred', 'Franz', 'Josef', 'Johann', 'Richard', 'Erwin',
  'Willy', 'Peter', 'Klaus', 'Wolfgang', 'Dieter', 'Manfred', 'Jürgen', 'Rolf', 'Rainer', 'Bernd',
  'Uwe', 'Hans-Jürgen', 'Gerd', 'Harald', 'Siegfried', 'Joachim', 'Bruno', 'Ludwig', 'Albert', 'Alois',
  'Anton', 'Arthur', 'August', 'Bernhard', 'Christian', 'Konrad', 'Eberhard', 'Edmund', 'Egon', 'Emil',
  'Erhard', 'Ewald', 'Ferdinand', 'Gustav', 'Günther', 'Hartmut', 'Hubert', 'Jakob', 'Johannes', 'Karl-Heinz',
  'Leo', 'Lothar', 'Martin', 'Michael', 'Norbert', 'Oskar', 'Reinhard', 'Reinhold', 'Robert', 'Roland',
  'Rudi', 'Theodor', 'Ulrich', 'Wilfried', 'Winfried', 'Alfons', 'Armin', 'Arnold', 'Detlef', 'Eugen',
  'Friedhelm', 'Gottfried', 'Hans-Joachim', 'Hans-Peter', 'Hugo', 'Jochen', 'Klaus-Dieter', 'Udo', 'Volker', 'Waldemar'
)

$script:FemaleFirstNames = @(
  'Anna', 'Maria', 'Martha', 'Frieda', 'Erna', 'Gertrud', 'Elisabeth', 'Margarete', 'Emma', 'Hedwig',
  'Else', 'Hildegard', 'Ilse', 'Irmgard', 'Ursula', 'Helga', 'Gisela', 'Ingrid', 'Renate', 'Karin',
  'Monika', 'Brigitte', 'Christa', 'Erika', 'Ruth', 'Edith', 'Lieselotte', 'Elfriede', 'Charlotte', 'Johanna',
  'Käthe', 'Luise', 'Marie', 'Bertha', 'Clara', 'Dora', 'Elly', 'Gerda', 'Grete', 'Hanna',
  'Herta', 'Hilde', 'Ida', 'Irma', 'Lina', 'Lotte', 'Margot', 'Marianne', 'Rosa', 'Wilhelmine',
  'Anneliese', 'Annemarie', 'Elli', 'Eva', 'Hannelore', 'Heidi', 'Helene', 'Hilda', 'Ingeborg', 'Inge',
  'Irene', 'Jutta', 'Klara', 'Liesel', 'Lore', 'Mathilde', 'Minna', 'Olga', 'Paula', 'Rita',
  'Rosemarie', 'Sigrid', 'Sophie', 'Therese', 'Ute', 'Waltraud', 'Wanda', 'Agnes', 'Alma', 'Auguste',
  'Barbara', 'Berta', 'Christel', 'Doris', 'Edeltraud', 'Elke', 'Elsa', 'Franziska', 'Gabriele', 'Gudrun',
  'Hertha', 'Ilona', 'Katharina', 'Lisa', 'Magdalena', 'Rosina', 'Traudel', 'Ursel', 'Veronika', 'Gertraud'
)

$script:LastNames = @(
  'Müller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner', 'Becker', 'Schulz', 'Hoffmann',
  'Schäfer', 'Koch', 'Bauer', 'Richter', 'Klein', 'Wolf', 'Schröder', 'Neumann', 'Schwarz', 'Zimmermann',
  'Braun', 'Krüger', 'Hofmann', 'Hartmann', 'Lange', 'Schmitt', 'Werner', 'Schmitz', 'Krause', 'Meier',
  'Lehmann', 'Schmid', 'Schulze', 'Maier', 'Köhler', 'Herrmann', 'König', 'Walter', 'Mayer', 'Huber',
  'Kaiser', 'Fuchs', 'Peters', 'Lang', 'Scholz', 'Möller', 'Weiß', 'Jung', 'Hahn', 'Schubert',
  'Vogel', 'Friedrich', 'Keller', 'Günther', 'Frank', 'Berger', 'Winkler', 'Roth', 'Beck', 'Lorenz',
  'Baumann', 'Franke', 'Albrecht', 'Schuster', 'Simon', 'Ludwig', 'Böhm', 'Winter', 'Kraus', 'Martin',
  'Schumacher', 'Krämer', 'Vogt', 'Stein', 'Jäger', 'Otto', 'Sommer', 'Groß', 'Seidel', 'Heinrich',
  'Brandt', 'Haas', 'Schreiber', 'Graf', 'Schulte', 'Dietrich', 'Ziegler', 'Kuhn', 'Kühn', 'Pohl',
  'Engel', 'Horn', 'Busch', 'Bergmann', 'Thomas', 'Voigt', 'Sauer', 'Arnold', 'Wolff', 'Pfeiffer',
  # ranks ~101-200
  'Lindner', 'Ernst', 'Kramer', 'Maurer', 'Hoppe', 'Fiedler', 'Behrens', 'Nagel', 'Brinkmann', 'Hermann',
  'Beyer', 'Bayer', 'Nowak', 'Böhme', 'Bachmann', 'Hesse', 'Götz', 'Marx', 'Lenz', 'Krebs',
  'Mohr', 'Reuter', 'Jansen', 'Stephan', 'Reinhardt', 'Wegner', 'Dietz', 'Barth', 'Wilhelm', 'Bock',
  'Lutz', 'Ebert', 'Ritter', 'Schilling', 'Kaufmann', 'Wendt', 'Benz', 'Gruber', 'Herzog', 'Fritz',
  'Kirchner', 'Paul', 'Wenzel', 'Stahl', 'Lehner', 'Kiefer', 'Kunze', 'Hummel', 'Wirth', 'Reichert',
  'Ullrich', 'Ulrich', 'Hennig', 'Henke', 'Heller', 'Seifert', 'Kessler', 'Schade', 'Urban', 'Schramm',
  'Schlüter', 'Gebhardt', 'Baier', 'Kohl', 'Konrad', 'Mann', 'Adam', 'Heinze', 'Rudolph', 'Schenk',
  'Rupp', 'Stark', 'Brunner', 'Wild', 'Brenner', 'Fink', 'Falk', 'Eckert', 'Petersen', 'Jakob',
  'Preuß', 'Kunz', 'Lemke', 'Hofer', 'Hagen', 'Moser', 'Hauser', 'Böttcher', 'Schwab', 'Sturm',
  'Steiner', 'Harms', 'Thiel', 'Hinz', 'Kraft', 'Hildebrandt', 'Jahn', 'Bischoff', 'Hübner', 'Geiger'
)

<#!
.SYNOPSIS
Returns one of the name pools.

.PARAMETER Pool
'Male', 'Female' or 'Last'.
#>
function Get-GermanNamePool {
  [CmdletBinding()]
  [OutputType([string[]])]
  param (
    [parameter(Mandatory = $true)]
    [ValidateSet('Male', 'Female', 'Last')]
    [string] $Pool
  )

  switch ($Pool) {
    'Male'   { $script:MaleFirstNames }
    'Female' { $script:FemaleFirstNames }
    'Last'   { $script:LastNames }
  }
}

<#!
.SYNOPSIS
Returns one or more random German names matching the 1900-1950 cohorts.

.DESCRIPTION
Picks a first name matching the gender and a last name. When a Bogus Faker instance is passed
the picks are driven by its seeded randomizer, so the result is reproducible together with the
rest of the fake data. Without a Faker a System.Random seeded with -Seed is used.

.PARAMETER Faker
A Bogus.Faker instance. Optional.

.PARAMETER Seed
Seed for the fallback randomizer when no Faker is given.

.PARAMETER Gender
1 = male, 2 = female (Identity Manager Person.Gender values). 0 = pick randomly. Default 0.

.PARAMETER Count
Number of names to return. Default 1.

.OUTPUTS
PSCustomObject with FirstName, LastName, Gender

.EXAMPLE
Get-RandomGermanName -Faker $Faker

.EXAMPLE
Get-RandomGermanName -Faker $Faker -Gender 2 -Count 10
#>
function Get-RandomGermanName {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param (
    [parameter(Mandatory = $false, HelpMessage = 'Bogus.Faker instance used for seeded randomness')]
    $Faker = $null,
    [parameter(Mandatory = $false, HelpMessage = 'Seed for the fallback randomizer when no Faker is given')]
    [int] $Seed = 973523,
    [parameter(Mandatory = $false, HelpMessage = '1 = male, 2 = female, 0 = random')]
    [ValidateRange(0, 2)]
    [int] $Gender = 0,
    [parameter(Mandatory = $false, HelpMessage = 'Number of names to return')]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Count = 1
  )

  if ($null -ne $Faker) {
    $nextInt = { param($max) $Faker.Random.Int(0, $max - 1) }
  } else {
    $rng = [System.Random]::new($Seed)
    $nextInt = { param($max) $rng.Next(0, $max) }
  }

  for ($i = 0; $i -lt $Count; $i++) {
    $g = if ($Gender -eq 0) { 1 + (& $nextInt 2) } else { $Gender }
    $firstNames = if ($g -eq 1) { $script:MaleFirstNames } else { $script:FemaleFirstNames }

    [PSCustomObject]@{
      FirstName = $firstNames[(& $nextInt $firstNames.Count)]
      LastName  = $script:LastNames[(& $nextInt $script:LastNames.Count)]
      Gender    = $g
    }
  }
}

Export-ModuleMember -Function Get-GermanNamePool, Get-RandomGermanName
