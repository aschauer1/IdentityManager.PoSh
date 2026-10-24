Set-StrictMode -Version Latest

<#
  Pools of items used as fake IT Shop products.

  Every pool entry is projected to a common shape so the caller can fill AccProduct without
  caring about the category:
    Category     - 'BMW' or 'Weapon'
    ProductName  - Ident_AccProduct
    Description  - Description
    Code         - CustomProperty01 (engine code for cars, manufacturer for weapons)
    ArticleCode  - ArticleCode (chassis codename for cars, designation for weapons)

  BMW pool: one entry per model/year/engine combination. The same model appears several times
  with different codenames and engine codes (petrol, diesel, hybrid, electric) across the years.
  Consumption is given in l/100km for combustion and hybrid engines, in kWh/100km for electric cars.
#>
$script:BmwModelPool = @(
  # --- 3 Series ---
  @{ Model = '318i';               Year = 1987; Codename = 'E30';  Engine = 'M10B18';     HP = 105; Consumption = '8.5 l/100km';    MaxSpeed = 185; Acceleration = 11.5 }
  @{ Model = '320i';               Year = 1986; Codename = 'E30';  Engine = 'M20B20';     HP = 129; Consumption = '9.0 l/100km';    MaxSpeed = 198; Acceleration = 10.1 }
  @{ Model = '325i';               Year = 1987; Codename = 'E30';  Engine = 'M20B25';     HP = 170; Consumption = '9.5 l/100km';    MaxSpeed = 218; Acceleration = 8.3 }
  @{ Model = '325iX';              Year = 1988; Codename = 'E30';  Engine = 'M20B25';     HP = 170; Consumption = '10.0 l/100km';   MaxSpeed = 212; Acceleration = 9.0 }
  @{ Model = '324td';              Year = 1988; Codename = 'E30';  Engine = 'M21D24';     HP = 115; Consumption = '7.0 l/100km';    MaxSpeed = 190; Acceleration = 11.5 }
  @{ Model = 'M3';                 Year = 1988; Codename = 'E30';  Engine = 'S14B23';     HP = 195; Consumption = '9.8 l/100km';    MaxSpeed = 235; Acceleration = 6.9 }
  @{ Model = '318is';              Year = 1993; Codename = 'E36';  Engine = 'M42B18';     HP = 140; Consumption = '8.0 l/100km';    MaxSpeed = 208; Acceleration = 9.9 }
  @{ Model = '320i';               Year = 1992; Codename = 'E36';  Engine = 'M50B20';     HP = 150; Consumption = '9.3 l/100km';    MaxSpeed = 214; Acceleration = 9.9 }
  @{ Model = '325i';               Year = 1992; Codename = 'E36';  Engine = 'M50B25';     HP = 192; Consumption = '9.5 l/100km';    MaxSpeed = 233; Acceleration = 8.0 }
  @{ Model = '328i';               Year = 1995; Codename = 'E36';  Engine = 'M52B28';     HP = 193; Consumption = '8.8 l/100km';    MaxSpeed = 236; Acceleration = 7.3 }
  @{ Model = '325tds';             Year = 1993; Codename = 'E36';  Engine = 'M51D25';     HP = 143; Consumption = '6.9 l/100km';    MaxSpeed = 214; Acceleration = 10.4 }
  @{ Model = 'M3';                 Year = 1996; Codename = 'E36';  Engine = 'S50B32';     HP = 321; Consumption = '10.0 l/100km';   MaxSpeed = 250; Acceleration = 5.5 }
  @{ Model = '318i';               Year = 2002; Codename = 'E46';  Engine = 'N42B20';     HP = 143; Consumption = '7.4 l/100km';    MaxSpeed = 213; Acceleration = 9.3 }
  @{ Model = '320d';               Year = 2001; Codename = 'E46';  Engine = 'M47D20TU';   HP = 150; Consumption = '5.7 l/100km';    MaxSpeed = 220; Acceleration = 8.9 }
  @{ Model = '325i';               Year = 2001; Codename = 'E46';  Engine = 'M54B25';     HP = 192; Consumption = '8.9 l/100km';    MaxSpeed = 237; Acceleration = 8.2 }
  @{ Model = '330i';               Year = 2000; Codename = 'E46';  Engine = 'M54B30';     HP = 231; Consumption = '9.0 l/100km';    MaxSpeed = 250; Acceleration = 6.5 }
  @{ Model = '330d';               Year = 2003; Codename = 'E46';  Engine = 'M57D30TU';   HP = 204; Consumption = '6.6 l/100km';    MaxSpeed = 243; Acceleration = 7.2 }
  @{ Model = 'M3';                 Year = 2001; Codename = 'E46';  Engine = 'S54B32';     HP = 343; Consumption = '12.0 l/100km';   MaxSpeed = 250; Acceleration = 5.2 }
  @{ Model = '320i';               Year = 2007; Codename = 'E90';  Engine = 'N43B20';     HP = 170; Consumption = '6.4 l/100km';    MaxSpeed = 228; Acceleration = 8.2 }
  @{ Model = '320d';               Year = 2008; Codename = 'E90';  Engine = 'N47D20';     HP = 177; Consumption = '4.8 l/100km';    MaxSpeed = 228; Acceleration = 7.9 }
  @{ Model = '325i';               Year = 2005; Codename = 'E90';  Engine = 'N52B25';     HP = 218; Consumption = '8.1 l/100km';    MaxSpeed = 247; Acceleration = 7.1 }
  @{ Model = '330i';               Year = 2006; Codename = 'E90';  Engine = 'N52B30';     HP = 258; Consumption = '8.4 l/100km';    MaxSpeed = 250; Acceleration = 6.1 }
  @{ Model = '335i';               Year = 2007; Codename = 'E92';  Engine = 'N54B30';     HP = 306; Consumption = '9.5 l/100km';    MaxSpeed = 250; Acceleration = 5.5 }
  @{ Model = '335d';               Year = 2007; Codename = 'E90';  Engine = 'M57D30TU2';  HP = 286; Consumption = '7.2 l/100km';    MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = 'M3';                 Year = 2008; Codename = 'E92';  Engine = 'S65B40';     HP = 420; Consumption = '12.4 l/100km';   MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = '316i';               Year = 2013; Codename = 'F30';  Engine = 'N13B16';     HP = 136; Consumption = '5.9 l/100km';    MaxSpeed = 210; Acceleration = 8.9 }
  @{ Model = '320i';               Year = 2012; Codename = 'F30';  Engine = 'N20B20';     HP = 184; Consumption = '6.0 l/100km';    MaxSpeed = 235; Acceleration = 7.3 }
  @{ Model = '328i';               Year = 2012; Codename = 'F30';  Engine = 'N20B20';     HP = 245; Consumption = '6.4 l/100km';    MaxSpeed = 250; Acceleration = 5.9 }
  @{ Model = '320d';               Year = 2012; Codename = 'F30';  Engine = 'N47D20';     HP = 184; Consumption = '4.5 l/100km';    MaxSpeed = 235; Acceleration = 7.5 }
  @{ Model = '330d';               Year = 2013; Codename = 'F30';  Engine = 'N57D30';     HP = 258; Consumption = '5.1 l/100km';    MaxSpeed = 250; Acceleration = 5.6 }
  @{ Model = '335i';               Year = 2012; Codename = 'F30';  Engine = 'N55B30';     HP = 306; Consumption = '7.9 l/100km';    MaxSpeed = 250; Acceleration = 5.5 }
  @{ Model = '340i';               Year = 2016; Codename = 'F30';  Engine = 'B58B30';     HP = 326; Consumption = '6.8 l/100km';    MaxSpeed = 250; Acceleration = 5.1 }
  @{ Model = '330e';               Year = 2016; Codename = 'F30';  Engine = 'B48B20';     HP = 252; Consumption = '1.9 l/100km';    MaxSpeed = 225; Acceleration = 6.1 }
  @{ Model = 'M3';                 Year = 2015; Codename = 'F80';  Engine = 'S55B30';     HP = 431; Consumption = '8.3 l/100km';    MaxSpeed = 250; Acceleration = 4.1 }
  @{ Model = '318i';               Year = 2020; Codename = 'G20';  Engine = 'B38A15';     HP = 156; Consumption = '5.9 l/100km';    MaxSpeed = 223; Acceleration = 8.4 }
  @{ Model = '320i';               Year = 2019; Codename = 'G20';  Engine = 'B48B20';     HP = 184; Consumption = '5.9 l/100km';    MaxSpeed = 235; Acceleration = 7.1 }
  @{ Model = '330i';               Year = 2019; Codename = 'G20';  Engine = 'B48B20';     HP = 258; Consumption = '6.0 l/100km';    MaxSpeed = 250; Acceleration = 5.8 }
  @{ Model = '320d';               Year = 2019; Codename = 'G20';  Engine = 'B47D20';     HP = 190; Consumption = '4.5 l/100km';    MaxSpeed = 240; Acceleration = 6.8 }
  @{ Model = '330d';               Year = 2020; Codename = 'G20';  Engine = 'B57D30';     HP = 286; Consumption = '5.3 l/100km';    MaxSpeed = 250; Acceleration = 5.1 }
  @{ Model = '330e';               Year = 2020; Codename = 'G20';  Engine = 'B48B20';     HP = 292; Consumption = '1.7 l/100km';    MaxSpeed = 230; Acceleration = 5.9 }
  @{ Model = 'M340i xDrive';       Year = 2020; Codename = 'G20';  Engine = 'B58B30';     HP = 374; Consumption = '7.7 l/100km';    MaxSpeed = 250; Acceleration = 4.4 }
  @{ Model = 'M3 Competition';     Year = 2021; Codename = 'G80';  Engine = 'S58B30';     HP = 510; Consumption = '10.2 l/100km';   MaxSpeed = 250; Acceleration = 3.9 }

  # --- 5 Series ---
  @{ Model = '520i';               Year = 1990; Codename = 'E34';  Engine = 'M50B20';     HP = 150; Consumption = '9.5 l/100km';    MaxSpeed = 213; Acceleration = 11.1 }
  @{ Model = '525i';               Year = 1989; Codename = 'E34';  Engine = 'M20B25';     HP = 170; Consumption = '9.4 l/100km';    MaxSpeed = 222; Acceleration = 9.5 }
  @{ Model = '535i';               Year = 1988; Codename = 'E34';  Engine = 'M30B35';     HP = 211; Consumption = '10.5 l/100km';   MaxSpeed = 230; Acceleration = 8.0 }
  @{ Model = 'M5';                 Year = 1990; Codename = 'E34';  Engine = 'S38B36';     HP = 315; Consumption = '12.0 l/100km';   MaxSpeed = 250; Acceleration = 6.3 }
  @{ Model = '523i';               Year = 1996; Codename = 'E39';  Engine = 'M52B25';     HP = 170; Consumption = '9.2 l/100km';    MaxSpeed = 228; Acceleration = 9.0 }
  @{ Model = '528i';               Year = 1996; Codename = 'E39';  Engine = 'M52B28';     HP = 193; Consumption = '9.0 l/100km';    MaxSpeed = 236; Acceleration = 8.0 }
  @{ Model = '530d';               Year = 1998; Codename = 'E39';  Engine = 'M57D30';     HP = 184; Consumption = '7.2 l/100km';    MaxSpeed = 227; Acceleration = 8.5 }
  @{ Model = '540i';               Year = 1997; Codename = 'E39';  Engine = 'M62B44';     HP = 286; Consumption = '11.3 l/100km';   MaxSpeed = 250; Acceleration = 6.2 }
  @{ Model = 'M5';                 Year = 1999; Codename = 'E39';  Engine = 'S62B50';     HP = 400; Consumption = '13.9 l/100km';   MaxSpeed = 250; Acceleration = 5.3 }
  @{ Model = '525i';               Year = 2004; Codename = 'E60';  Engine = 'M54B25';     HP = 192; Consumption = '9.0 l/100km';    MaxSpeed = 238; Acceleration = 8.3 }
  @{ Model = '530d';               Year = 2005; Codename = 'E60';  Engine = 'M57D30TU';   HP = 218; Consumption = '6.9 l/100km';    MaxSpeed = 245; Acceleration = 6.9 }
  @{ Model = '545i';               Year = 2004; Codename = 'E60';  Engine = 'N62B44';     HP = 333; Consumption = '10.9 l/100km';   MaxSpeed = 250; Acceleration = 5.9 }
  @{ Model = 'M5';                 Year = 2005; Codename = 'E60';  Engine = 'S85B50';     HP = 507; Consumption = '14.8 l/100km';   MaxSpeed = 250; Acceleration = 4.7 }
  @{ Model = '520d';               Year = 2011; Codename = 'F10';  Engine = 'N47D20';     HP = 184; Consumption = '4.7 l/100km';    MaxSpeed = 227; Acceleration = 8.1 }
  @{ Model = '528i';               Year = 2012; Codename = 'F10';  Engine = 'N20B20';     HP = 245; Consumption = '6.8 l/100km';    MaxSpeed = 250; Acceleration = 6.2 }
  @{ Model = '530d';               Year = 2011; Codename = 'F10';  Engine = 'N57D30';     HP = 258; Consumption = '5.8 l/100km';    MaxSpeed = 250; Acceleration = 5.9 }
  @{ Model = '535i';               Year = 2010; Codename = 'F10';  Engine = 'N55B30';     HP = 306; Consumption = '8.4 l/100km';    MaxSpeed = 250; Acceleration = 5.9 }
  @{ Model = '550i';               Year = 2010; Codename = 'F10';  Engine = 'N63B44';     HP = 407; Consumption = '10.4 l/100km';   MaxSpeed = 250; Acceleration = 5.0 }
  @{ Model = 'M550d xDrive';       Year = 2012; Codename = 'F10';  Engine = 'N57D30S1';   HP = 381; Consumption = '6.3 l/100km';    MaxSpeed = 250; Acceleration = 4.7 }
  @{ Model = 'M5';                 Year = 2012; Codename = 'F10';  Engine = 'S63B44T0';   HP = 560; Consumption = '9.9 l/100km';    MaxSpeed = 250; Acceleration = 4.4 }
  @{ Model = '520d';               Year = 2017; Codename = 'G30';  Engine = 'B47D20';     HP = 190; Consumption = '4.1 l/100km';    MaxSpeed = 235; Acceleration = 7.5 }
  @{ Model = '530i';               Year = 2017; Codename = 'G30';  Engine = 'B48B20';     HP = 252; Consumption = '5.4 l/100km';    MaxSpeed = 250; Acceleration = 6.2 }
  @{ Model = '530i xDrive';        Year = 2018; Codename = 'G30';  Engine = 'B48B20';     HP = 252; Consumption = '5.9 l/100km';    MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = '530d';               Year = 2017; Codename = 'G30';  Engine = 'B57D30';     HP = 265; Consumption = '4.5 l/100km';    MaxSpeed = 250; Acceleration = 5.7 }
  @{ Model = '530e';               Year = 2017; Codename = 'G30';  Engine = 'B48B20';     HP = 252; Consumption = '2.1 l/100km';    MaxSpeed = 235; Acceleration = 6.2 }
  @{ Model = '540i';               Year = 2017; Codename = 'G30';  Engine = 'B58B30';     HP = 340; Consumption = '6.5 l/100km';    MaxSpeed = 250; Acceleration = 5.1 }
  @{ Model = 'M550d xDrive';       Year = 2017; Codename = 'G30';  Engine = 'B57D30S0';   HP = 400; Consumption = '5.9 l/100km';    MaxSpeed = 250; Acceleration = 4.4 }
  @{ Model = 'M550i xDrive';       Year = 2020; Codename = 'G30';  Engine = 'N63B44T3';   HP = 530; Consumption = '10.6 l/100km';   MaxSpeed = 250; Acceleration = 3.8 }
  @{ Model = 'M5 Competition';     Year = 2019; Codename = 'F90';  Engine = 'S63B44T4';   HP = 625; Consumption = '10.6 l/100km';   MaxSpeed = 250; Acceleration = 3.3 }
  @{ Model = '520d';               Year = 2024; Codename = 'G60';  Engine = 'B47D20';     HP = 197; Consumption = '4.9 l/100km';    MaxSpeed = 233; Acceleration = 7.3 }
  @{ Model = '530e';               Year = 2024; Codename = 'G60';  Engine = 'B48B20';     HP = 299; Consumption = '0.9 l/100km';    MaxSpeed = 230; Acceleration = 6.3 }
  @{ Model = 'i5 eDrive40';        Year = 2024; Codename = 'G60';  Engine = 'GEN5-ESM';   HP = 340; Consumption = '15.9 kWh/100km'; MaxSpeed = 193; Acceleration = 6.0 }
  @{ Model = 'i5 M60 xDrive';      Year = 2024; Codename = 'G60';  Engine = 'GEN5-ESM';   HP = 601; Consumption = '18.2 kWh/100km'; MaxSpeed = 230; Acceleration = 3.8 }

  # --- 7 Series ---
  @{ Model = '735i';               Year = 1988; Codename = 'E32';  Engine = 'M30B35';     HP = 211; Consumption = '11.0 l/100km';   MaxSpeed = 227; Acceleration = 8.3 }
  @{ Model = '750iL';              Year = 1988; Codename = 'E32';  Engine = 'M70B50';     HP = 300; Consumption = '14.0 l/100km';   MaxSpeed = 250; Acceleration = 7.4 }
  @{ Model = '740i';               Year = 1996; Codename = 'E38';  Engine = 'M62B44';     HP = 286; Consumption = '11.5 l/100km';   MaxSpeed = 250; Acceleration = 6.6 }
  @{ Model = '730d';               Year = 2000; Codename = 'E38';  Engine = 'M57D30';     HP = 193; Consumption = '8.0 l/100km';    MaxSpeed = 222; Acceleration = 9.1 }
  @{ Model = '760Li';              Year = 2003; Codename = 'E66';  Engine = 'N73B60';     HP = 445; Consumption = '13.9 l/100km';   MaxSpeed = 250; Acceleration = 5.5 }
  @{ Model = '730d';               Year = 2009; Codename = 'F01';  Engine = 'N57D30';     HP = 245; Consumption = '6.8 l/100km';    MaxSpeed = 245; Acceleration = 7.2 }
  @{ Model = '750i';               Year = 2009; Codename = 'F01';  Engine = 'N63B44';     HP = 407; Consumption = '11.4 l/100km';   MaxSpeed = 250; Acceleration = 5.2 }
  @{ Model = '740d xDrive';        Year = 2016; Codename = 'G11';  Engine = 'B57D30';     HP = 320; Consumption = '5.9 l/100km';    MaxSpeed = 250; Acceleration = 5.2 }
  @{ Model = '745e';               Year = 2019; Codename = 'G11';  Engine = 'B58B30';     HP = 394; Consumption = '2.3 l/100km';    MaxSpeed = 250; Acceleration = 5.2 }
  @{ Model = 'i7 xDrive60';        Year = 2023; Codename = 'G70';  Engine = 'GEN5-ESM';   HP = 544; Consumption = '19.6 kWh/100km'; MaxSpeed = 240; Acceleration = 4.7 }

  # --- 8 Series ---
  @{ Model = '840d xDrive';        Year = 2019; Codename = 'G15';  Engine = 'B57D30';     HP = 320; Consumption = '6.2 l/100km';    MaxSpeed = 250; Acceleration = 4.9 }
  @{ Model = 'M850i xDrive';       Year = 2019; Codename = 'G15';  Engine = 'N63B44T3';   HP = 530; Consumption = '10.0 l/100km';   MaxSpeed = 250; Acceleration = 3.7 }
  @{ Model = 'M8 Competition';     Year = 2020; Codename = 'F92';  Engine = 'S63B44T4';   HP = 625; Consumption = '10.6 l/100km';   MaxSpeed = 250; Acceleration = 3.2 }

  # --- 1 / 2 Series ---
  @{ Model = '118d';               Year = 2008; Codename = 'E87';  Engine = 'N47D20';     HP = 143; Consumption = '4.8 l/100km';    MaxSpeed = 210; Acceleration = 8.9 }
  @{ Model = '120i';               Year = 2012; Codename = 'F20';  Engine = 'N13B16';     HP = 170; Consumption = '5.8 l/100km';    MaxSpeed = 225; Acceleration = 7.4 }
  @{ Model = 'M135i';              Year = 2013; Codename = 'F20';  Engine = 'N55B30';     HP = 320; Consumption = '8.0 l/100km';    MaxSpeed = 250; Acceleration = 4.9 }
  @{ Model = 'M135i xDrive';       Year = 2020; Codename = 'F40';  Engine = 'B48A20T1';   HP = 306; Consumption = '7.0 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'M2 Competition';     Year = 2019; Codename = 'F87';  Engine = 'S55B30';     HP = 410; Consumption = '10.0 l/100km';   MaxSpeed = 250; Acceleration = 4.2 }
  @{ Model = 'M2';                 Year = 2023; Codename = 'G87';  Engine = 'S58B30';     HP = 460; Consumption = '10.0 l/100km';   MaxSpeed = 250; Acceleration = 4.1 }
  @{ Model = 'M4 Competition';     Year = 2021; Codename = 'G82';  Engine = 'S58B30';     HP = 510; Consumption = '10.1 l/100km';   MaxSpeed = 250; Acceleration = 3.9 }

  # --- Z Roadsters ---
  @{ Model = 'Z3 2.8';             Year = 1997; Codename = 'E36/7'; Engine = 'M52B28';    HP = 193; Consumption = '9.8 l/100km';    MaxSpeed = 231; Acceleration = 7.0 }
  @{ Model = 'Z4 3.0si';           Year = 2006; Codename = 'E85';  Engine = 'N52B30';     HP = 265; Consumption = '9.1 l/100km';    MaxSpeed = 250; Acceleration = 5.7 }
  @{ Model = 'Z4 M40i';            Year = 2019; Codename = 'G29';  Engine = 'B58B30';     HP = 340; Consumption = '7.4 l/100km';    MaxSpeed = 250; Acceleration = 4.5 }

  # --- X Models ---
  @{ Model = 'X3 2.0d';            Year = 2005; Codename = 'E83';  Engine = 'M47D20TU';   HP = 150; Consumption = '7.1 l/100km';    MaxSpeed = 198; Acceleration = 10.2 }
  @{ Model = 'X3 xDrive30d';       Year = 2012; Codename = 'F25';  Engine = 'N57D30';     HP = 258; Consumption = '6.0 l/100km';    MaxSpeed = 230; Acceleration = 6.2 }
  @{ Model = 'X3 xDrive20d';       Year = 2018; Codename = 'G01';  Engine = 'B47D20';     HP = 190; Consumption = '5.0 l/100km';    MaxSpeed = 213; Acceleration = 8.0 }
  @{ Model = 'X3 M40i';            Year = 2018; Codename = 'G01';  Engine = 'B58B30';     HP = 360; Consumption = '8.2 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'X3 M Competition';   Year = 2020; Codename = 'F97';  Engine = 'S58B30';     HP = 510; Consumption = '10.5 l/100km';   MaxSpeed = 250; Acceleration = 4.1 }
  @{ Model = 'iX3';                Year = 2021; Codename = 'G08';  Engine = 'GEN5-ESM';   HP = 286; Consumption = '18.5 kWh/100km'; MaxSpeed = 180; Acceleration = 6.8 }
  @{ Model = 'X5 3.0d';            Year = 2001; Codename = 'E53';  Engine = 'M57D30';     HP = 184; Consumption = '9.2 l/100km';    MaxSpeed = 200; Acceleration = 10.2 }
  @{ Model = 'X5 4.4i';            Year = 2000; Codename = 'E53';  Engine = 'M62B44';     HP = 286; Consumption = '13.9 l/100km';   MaxSpeed = 222; Acceleration = 7.5 }
  @{ Model = 'X5 xDrive30d';       Year = 2007; Codename = 'E70';  Engine = 'M57D30TU2';  HP = 235; Consumption = '8.7 l/100km';    MaxSpeed = 216; Acceleration = 8.0 }
  @{ Model = 'X5 M50d';            Year = 2013; Codename = 'F15';  Engine = 'N57D30S1';   HP = 381; Consumption = '6.7 l/100km';    MaxSpeed = 250; Acceleration = 5.3 }
  @{ Model = 'X5 xDrive45e';       Year = 2020; Codename = 'G05';  Engine = 'B58B30';     HP = 394; Consumption = '1.7 l/100km';    MaxSpeed = 235; Acceleration = 5.6 }
  @{ Model = 'X5 M Competition';   Year = 2020; Codename = 'F95';  Engine = 'S63B44T4';   HP = 625; Consumption = '13.0 l/100km';   MaxSpeed = 250; Acceleration = 3.8 }
  @{ Model = 'X6 M';               Year = 2015; Codename = 'F86';  Engine = 'S63B44T2';   HP = 575; Consumption = '11.1 l/100km';   MaxSpeed = 250; Acceleration = 4.2 }
  @{ Model = 'X7 xDrive40i';       Year = 2019; Codename = 'G07';  Engine = 'B58B30';     HP = 340; Consumption = '9.2 l/100km';    MaxSpeed = 245; Acceleration = 6.1 }
  @{ Model = 'XM';                 Year = 2023; Codename = 'G09';  Engine = 'S68B44';     HP = 653; Consumption = '1.6 l/100km';    MaxSpeed = 250; Acceleration = 4.3 }
  @{ Model = 'XM Label Red';       Year = 2024; Codename = 'G09';  Engine = 'S68B44';     HP = 748; Consumption = '1.7 l/100km';    MaxSpeed = 290; Acceleration = 3.8 }

  # --- i Models ---
  @{ Model = 'i3';                 Year = 2014; Codename = 'I01';  Engine = 'IB1P25';     HP = 170; Consumption = '12.9 kWh/100km'; MaxSpeed = 150; Acceleration = 7.2 }
  @{ Model = 'i3s';                Year = 2018; Codename = 'I01';  Engine = 'IB1P35';     HP = 184; Consumption = '14.3 kWh/100km'; MaxSpeed = 160; Acceleration = 6.9 }
  @{ Model = 'i8';                 Year = 2015; Codename = 'I12';  Engine = 'B38K15';     HP = 362; Consumption = '2.1 l/100km';    MaxSpeed = 250; Acceleration = 4.4 }
  @{ Model = 'i4 eDrive40';        Year = 2022; Codename = 'G26';  Engine = 'GEN5-ESM';   HP = 340; Consumption = '16.1 kWh/100km'; MaxSpeed = 190; Acceleration = 5.7 }
  @{ Model = 'i4 M50';             Year = 2022; Codename = 'G26';  Engine = 'GEN5-ESM';   HP = 544; Consumption = '18.0 kWh/100km'; MaxSpeed = 225; Acceleration = 3.9 }
  @{ Model = 'iX xDrive40';        Year = 2022; Codename = 'I20';  Engine = 'GEN5-ESM';   HP = 326; Consumption = '20.0 kWh/100km'; MaxSpeed = 200; Acceleration = 6.1 }
  @{ Model = 'iX xDrive50';        Year = 2022; Codename = 'I20';  Engine = 'GEN5-ESM';   HP = 523; Consumption = '21.0 kWh/100km'; MaxSpeed = 200; Acceleration = 4.6 }
  @{ Model = 'iX M60';             Year = 2022; Codename = 'I20';  Engine = 'GEN5-ESM';   HP = 619; Consumption = '21.9 kWh/100km'; MaxSpeed = 250; Acceleration = 3.8 }

  # --- Classics (E21 / E28 / E24 / E23 / E31 / Z1 / Z8) ---
  @{ Model = '316';                Year = 1978; Codename = 'E21';  Engine = 'M10B16';     HP = 90;  Consumption = '9.0 l/100km';    MaxSpeed = 160; Acceleration = 13.0 }
  @{ Model = '320/6';              Year = 1980; Codename = 'E21';  Engine = 'M20B20';     HP = 122; Consumption = '9.6 l/100km';    MaxSpeed = 181; Acceleration = 10.5 }
  @{ Model = '323i';               Year = 1979; Codename = 'E21';  Engine = 'M20B23';     HP = 143; Consumption = '10.0 l/100km';   MaxSpeed = 190; Acceleration = 9.0 }
  @{ Model = '518i';               Year = 1984; Codename = 'E28';  Engine = 'M10B18';     HP = 105; Consumption = '8.6 l/100km';    MaxSpeed = 175; Acceleration = 12.0 }
  @{ Model = '520i';               Year = 1985; Codename = 'E28';  Engine = 'M20B20';     HP = 129; Consumption = '9.3 l/100km';    MaxSpeed = 190; Acceleration = 11.0 }
  @{ Model = '524td';              Year = 1985; Codename = 'E28';  Engine = 'M21D24';     HP = 115; Consumption = '7.2 l/100km';    MaxSpeed = 180; Acceleration = 12.0 }
  @{ Model = '528i';               Year = 1983; Codename = 'E28';  Engine = 'M30B28';     HP = 184; Consumption = '10.5 l/100km';   MaxSpeed = 215; Acceleration = 8.9 }
  @{ Model = '535i';               Year = 1986; Codename = 'E28';  Engine = 'M30B34';     HP = 218; Consumption = '11.0 l/100km';   MaxSpeed = 230; Acceleration = 7.6 }
  @{ Model = 'M5';                 Year = 1986; Codename = 'E28';  Engine = 'S38B35';     HP = 286; Consumption = '12.5 l/100km';   MaxSpeed = 245; Acceleration = 6.5 }
  @{ Model = '628CSi';             Year = 1981; Codename = 'E24';  Engine = 'M30B28';     HP = 184; Consumption = '11.5 l/100km';   MaxSpeed = 215; Acceleration = 8.8 }
  @{ Model = '635CSi';             Year = 1984; Codename = 'E24';  Engine = 'M30B34';     HP = 218; Consumption = '11.8 l/100km';   MaxSpeed = 228; Acceleration = 7.6 }
  @{ Model = 'M635CSi';            Year = 1985; Codename = 'E24';  Engine = 'M88/3';      HP = 286; Consumption = '12.6 l/100km';   MaxSpeed = 255; Acceleration = 6.4 }
  @{ Model = '735i';               Year = 1983; Codename = 'E23';  Engine = 'M30B34';     HP = 218; Consumption = '12.5 l/100km';   MaxSpeed = 222; Acceleration = 8.3 }
  @{ Model = '745i';               Year = 1984; Codename = 'E23';  Engine = 'M102';       HP = 252; Consumption = '13.5 l/100km';   MaxSpeed = 227; Acceleration = 7.9 }
  @{ Model = '840Ci';              Year = 1996; Codename = 'E31';  Engine = 'M62B44';     HP = 286; Consumption = '12.0 l/100km';   MaxSpeed = 250; Acceleration = 6.6 }
  @{ Model = '850i';               Year = 1991; Codename = 'E31';  Engine = 'M70B50';     HP = 300; Consumption = '14.5 l/100km';   MaxSpeed = 250; Acceleration = 6.8 }
  @{ Model = '850CSi';             Year = 1993; Codename = 'E31';  Engine = 'S70B56';     HP = 380; Consumption = '15.0 l/100km';   MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = 'Z1';                 Year = 1989; Codename = 'Z1';   Engine = 'M20B25';     HP = 170; Consumption = '9.8 l/100km';    MaxSpeed = 225; Acceleration = 7.9 }
  @{ Model = 'Z8';                 Year = 2000; Codename = 'E52';  Engine = 'S62B50';     HP = 400; Consumption = '14.0 l/100km';   MaxSpeed = 250; Acceleration = 4.7 }

  # --- 3 Series (more) ---
  @{ Model = '316i Compact';       Year = 1994; Codename = 'E36/5'; Engine = 'M43B16';    HP = 102; Consumption = '7.6 l/100km';    MaxSpeed = 192; Acceleration = 12.9 }
  @{ Model = '323ti Compact';      Year = 1998; Codename = 'E36/5'; Engine = 'M52B25';    HP = 170; Consumption = '8.8 l/100km';    MaxSpeed = 226; Acceleration = 8.2 }
  @{ Model = '320i';               Year = 1995; Codename = 'E36';  Engine = 'M52B20';     HP = 150; Consumption = '8.5 l/100km';    MaxSpeed = 214; Acceleration = 9.9 }
  @{ Model = 'M3';                 Year = 1993; Codename = 'E36';  Engine = 'S50B30';     HP = 286; Consumption = '10.5 l/100km';   MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = '316ti Compact';      Year = 2001; Codename = 'E46/5'; Engine = 'N42B18';    HP = 115; Consumption = '7.1 l/100km';    MaxSpeed = 200; Acceleration = 10.9 }
  @{ Model = '318d';               Year = 2002; Codename = 'E46';  Engine = 'M47D20TU';   HP = 115; Consumption = '5.5 l/100km';    MaxSpeed = 200; Acceleration = 10.6 }
  @{ Model = '320i';               Year = 2003; Codename = 'E46';  Engine = 'M54B22';     HP = 170; Consumption = '8.4 l/100km';    MaxSpeed = 226; Acceleration = 8.9 }
  @{ Model = '328i';               Year = 1999; Codename = 'E46';  Engine = 'M52TUB28';   HP = 193; Consumption = '8.8 l/100km';    MaxSpeed = 240; Acceleration = 7.0 }
  @{ Model = '330xd';              Year = 2003; Codename = 'E46';  Engine = 'M57D30TU';   HP = 204; Consumption = '7.4 l/100km';    MaxSpeed = 237; Acceleration = 7.5 }
  @{ Model = 'M3 CSL';             Year = 2003; Codename = 'E46';  Engine = 'S54B32HP';   HP = 360; Consumption = '11.9 l/100km';   MaxSpeed = 250; Acceleration = 4.9 }
  @{ Model = '318i';               Year = 2007; Codename = 'E90';  Engine = 'N46B20';     HP = 143; Consumption = '6.5 l/100km';    MaxSpeed = 210; Acceleration = 9.6 }
  @{ Model = '318d';               Year = 2008; Codename = 'E90';  Engine = 'N47D20';     HP = 143; Consumption = '4.7 l/100km';    MaxSpeed = 210; Acceleration = 9.3 }
  @{ Model = '325d';               Year = 2007; Codename = 'E90';  Engine = 'M57D30TU2';  HP = 197; Consumption = '6.1 l/100km';    MaxSpeed = 238; Acceleration = 7.5 }
  @{ Model = '330d';               Year = 2008; Codename = 'E90';  Engine = 'M57D30TU2';  HP = 245; Consumption = '5.7 l/100km';    MaxSpeed = 250; Acceleration = 6.1 }
  @{ Model = '335is';              Year = 2011; Codename = 'E92';  Engine = 'N54B30';     HP = 326; Consumption = '9.6 l/100km';    MaxSpeed = 250; Acceleration = 5.1 }
  @{ Model = 'M3 GTS';             Year = 2010; Codename = 'E92';  Engine = 'S65B44';     HP = 450; Consumption = '13.7 l/100km';   MaxSpeed = 305; Acceleration = 4.4 }
  @{ Model = '318d';               Year = 2013; Codename = 'F30';  Engine = 'N47D20';     HP = 143; Consumption = '4.5 l/100km';    MaxSpeed = 210; Acceleration = 9.1 }
  @{ Model = '320i';               Year = 2016; Codename = 'F30';  Engine = 'B48B20';     HP = 184; Consumption = '5.5 l/100km';    MaxSpeed = 235; Acceleration = 7.3 }
  @{ Model = '320d';               Year = 2016; Codename = 'F30';  Engine = 'B47D20';     HP = 190; Consumption = '4.1 l/100km';    MaxSpeed = 230; Acceleration = 7.2 }
  @{ Model = '325d';               Year = 2013; Codename = 'F30';  Engine = 'N47D20';     HP = 218; Consumption = '4.7 l/100km';    MaxSpeed = 245; Acceleration = 6.9 }
  @{ Model = '335d xDrive';        Year = 2013; Codename = 'F30';  Engine = 'N57D30';     HP = 313; Consumption = '5.3 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'M3 CS';              Year = 2018; Codename = 'F80';  Engine = 'S55B30';     HP = 460; Consumption = '8.8 l/100km';    MaxSpeed = 280; Acceleration = 3.9 }
  @{ Model = '320d xDrive';        Year = 2021; Codename = 'G20';  Engine = 'B47D20';     HP = 190; Consumption = '4.8 l/100km';    MaxSpeed = 232; Acceleration = 6.9 }
  @{ Model = '330i';               Year = 2023; Codename = 'G20';  Engine = 'B48B20';     HP = 245; Consumption = '6.5 l/100km';    MaxSpeed = 250; Acceleration = 5.9 }
  @{ Model = 'M340d xDrive';       Year = 2021; Codename = 'G20';  Engine = 'B57D30';     HP = 340; Consumption = '5.9 l/100km';    MaxSpeed = 250; Acceleration = 4.6 }
  @{ Model = 'M3 Touring Competition'; Year = 2023; Codename = 'G81'; Engine = 'S58B30';  HP = 510; Consumption = '10.2 l/100km';   MaxSpeed = 250; Acceleration = 3.6 }

  # --- 4 Series ---
  @{ Model = '428i';               Year = 2014; Codename = 'F32';  Engine = 'N20B20';     HP = 245; Consumption = '6.4 l/100km';    MaxSpeed = 250; Acceleration = 5.8 }
  @{ Model = '435i';               Year = 2014; Codename = 'F32';  Engine = 'N55B30';     HP = 306; Consumption = '7.6 l/100km';    MaxSpeed = 250; Acceleration = 5.1 }
  @{ Model = '430d';               Year = 2015; Codename = 'F32';  Engine = 'N57D30';     HP = 258; Consumption = '5.2 l/100km';    MaxSpeed = 250; Acceleration = 5.4 }
  @{ Model = '440i';               Year = 2017; Codename = 'F32';  Engine = 'B58B30';     HP = 326; Consumption = '6.9 l/100km';    MaxSpeed = 250; Acceleration = 5.0 }
  @{ Model = 'M4';                 Year = 2014; Codename = 'F82';  Engine = 'S55B30';     HP = 431; Consumption = '8.8 l/100km';    MaxSpeed = 250; Acceleration = 4.3 }
  @{ Model = 'M4 GTS';             Year = 2016; Codename = 'F82';  Engine = 'S55B30';     HP = 500; Consumption = '8.5 l/100km';    MaxSpeed = 305; Acceleration = 3.8 }
  @{ Model = '420i';               Year = 2021; Codename = 'G22';  Engine = 'B48B20';     HP = 184; Consumption = '6.3 l/100km';    MaxSpeed = 236; Acceleration = 7.5 }
  @{ Model = '430i';               Year = 2021; Codename = 'G22';  Engine = 'B48B20';     HP = 258; Consumption = '6.6 l/100km';    MaxSpeed = 250; Acceleration = 5.8 }
  @{ Model = 'M440i xDrive';       Year = 2021; Codename = 'G22';  Engine = 'B58B30';     HP = 374; Consumption = '7.8 l/100km';    MaxSpeed = 250; Acceleration = 4.5 }
  @{ Model = 'M4 CSL';             Year = 2023; Codename = 'G82';  Engine = 'S58B30';     HP = 550; Consumption = '10.1 l/100km';   MaxSpeed = 307; Acceleration = 3.7 }

  # --- 5 Series (more) ---
  @{ Model = '525tds';             Year = 1993; Codename = 'E34';  Engine = 'M51D25';     HP = 143; Consumption = '7.4 l/100km';    MaxSpeed = 205; Acceleration = 11.5 }
  @{ Model = '540i';               Year = 1993; Codename = 'E34';  Engine = 'M60B40';     HP = 286; Consumption = '11.9 l/100km';   MaxSpeed = 250; Acceleration = 6.4 }
  @{ Model = '525d';               Year = 2000; Codename = 'E39';  Engine = 'M57D25';     HP = 163; Consumption = '7.0 l/100km';    MaxSpeed = 222; Acceleration = 9.0 }
  @{ Model = '530i';               Year = 2001; Codename = 'E39';  Engine = 'M54B30';     HP = 231; Consumption = '9.3 l/100km';    MaxSpeed = 250; Acceleration = 6.9 }
  @{ Model = '520d';               Year = 2007; Codename = 'E60';  Engine = 'N47D20';     HP = 177; Consumption = '5.1 l/100km';    MaxSpeed = 231; Acceleration = 8.3 }
  @{ Model = '530i';               Year = 2005; Codename = 'E60';  Engine = 'N52B30';     HP = 258; Consumption = '8.8 l/100km';    MaxSpeed = 250; Acceleration = 6.5 }
  @{ Model = '535d';               Year = 2005; Codename = 'E60';  Engine = 'M57D30TOP';  HP = 272; Consumption = '7.3 l/100km';    MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = '550i';               Year = 2006; Codename = 'E60';  Engine = 'N62B48';     HP = 367; Consumption = '11.3 l/100km';   MaxSpeed = 250; Acceleration = 5.5 }
  @{ Model = '518d';               Year = 2014; Codename = 'F10';  Engine = 'N47D20';     HP = 143; Consumption = '4.5 l/100km';    MaxSpeed = 212; Acceleration = 9.7 }
  @{ Model = '525d';               Year = 2012; Codename = 'F10';  Engine = 'N47D20';     HP = 218; Consumption = '4.9 l/100km';    MaxSpeed = 243; Acceleration = 7.2 }
  @{ Model = '528i';               Year = 2010; Codename = 'F10';  Engine = 'N52B30';     HP = 258; Consumption = '7.9 l/100km';    MaxSpeed = 250; Acceleration = 6.6 }
  @{ Model = '535d';               Year = 2011; Codename = 'F10';  Engine = 'N57D30';     HP = 313; Consumption = '5.5 l/100km';    MaxSpeed = 250; Acceleration = 5.5 }
  @{ Model = '520i';               Year = 2018; Codename = 'G30';  Engine = 'B48B20';     HP = 184; Consumption = '5.8 l/100km';    MaxSpeed = 235; Acceleration = 7.8 }
  @{ Model = '530d xDrive';        Year = 2019; Codename = 'G30';  Engine = 'B57D30';     HP = 265; Consumption = '5.1 l/100km';    MaxSpeed = 250; Acceleration = 5.4 }
  @{ Model = '545e xDrive';        Year = 2021; Codename = 'G30';  Engine = 'B58B30';     HP = 394; Consumption = '2.2 l/100km';    MaxSpeed = 250; Acceleration = 4.7 }
  @{ Model = 'M5 CS';              Year = 2021; Codename = 'F90';  Engine = 'S63B44T4';   HP = 635; Consumption = '10.6 l/100km';   MaxSpeed = 305; Acceleration = 3.0 }
  @{ Model = '540d xDrive';        Year = 2024; Codename = 'G60';  Engine = 'B57D30';     HP = 299; Consumption = '5.5 l/100km';    MaxSpeed = 250; Acceleration = 5.1 }
  @{ Model = 'i5 eDrive40 Touring'; Year = 2024; Codename = 'G61'; Engine = 'GEN5-ESM';   HP = 340; Consumption = '17.5 kWh/100km'; MaxSpeed = 193; Acceleration = 6.1 }
  @{ Model = 'i5 M60 xDrive Touring'; Year = 2024; Codename = 'G61'; Engine = 'GEN5-ESM'; HP = 601; Consumption = '18.7 kWh/100km'; MaxSpeed = 230; Acceleration = 3.9 }

  # --- 6 Series ---
  @{ Model = '630i';               Year = 2005; Codename = 'E63';  Engine = 'N52B30';     HP = 258; Consumption = '9.2 l/100km';    MaxSpeed = 250; Acceleration = 6.9 }
  @{ Model = '645Ci';              Year = 2004; Codename = 'E63';  Engine = 'N62B44';     HP = 333; Consumption = '11.4 l/100km';   MaxSpeed = 250; Acceleration = 5.6 }
  @{ Model = 'M6';                 Year = 2006; Codename = 'E63';  Engine = 'S85B50';     HP = 507; Consumption = '14.8 l/100km';   MaxSpeed = 250; Acceleration = 4.6 }
  @{ Model = '640d';               Year = 2012; Codename = 'F13';  Engine = 'N57D30';     HP = 313; Consumption = '5.5 l/100km';    MaxSpeed = 250; Acceleration = 5.4 }
  @{ Model = '650i';               Year = 2012; Codename = 'F12';  Engine = 'N63B44';     HP = 407; Consumption = '10.8 l/100km';   MaxSpeed = 250; Acceleration = 5.0 }
  @{ Model = 'M6';                 Year = 2013; Codename = 'F13';  Engine = 'S63B44T0';   HP = 560; Consumption = '9.9 l/100km';    MaxSpeed = 250; Acceleration = 4.2 }
  @{ Model = '630d Gran Turismo';  Year = 2018; Codename = 'G32';  Engine = 'B57D30';     HP = 265; Consumption = '5.4 l/100km';    MaxSpeed = 250; Acceleration = 6.1 }

  # --- 7 Series (more) ---
  @{ Model = '740i';               Year = 1993; Codename = 'E32';  Engine = 'M60B40';     HP = 286; Consumption = '12.0 l/100km';   MaxSpeed = 240; Acceleration = 7.4 }
  @{ Model = '728i';               Year = 1996; Codename = 'E38';  Engine = 'M52B28';     HP = 193; Consumption = '10.5 l/100km';   MaxSpeed = 228; Acceleration = 8.8 }
  @{ Model = '740d';               Year = 2000; Codename = 'E38';  Engine = 'M67D40';     HP = 245; Consumption = '9.8 l/100km';    MaxSpeed = 242; Acceleration = 7.2 }
  @{ Model = '745i';               Year = 2002; Codename = 'E65';  Engine = 'N62B44';     HP = 333; Consumption = '11.4 l/100km';   MaxSpeed = 250; Acceleration = 6.3 }
  @{ Model = '730d';               Year = 2003; Codename = 'E65';  Engine = 'M57D30';     HP = 218; Consumption = '8.4 l/100km';    MaxSpeed = 238; Acceleration = 7.8 }
  @{ Model = '740Li';              Year = 2010; Codename = 'F02';  Engine = 'N54B30';     HP = 326; Consumption = '9.9 l/100km';    MaxSpeed = 250; Acceleration = 5.9 }
  @{ Model = '750Li xDrive';       Year = 2013; Codename = 'F02';  Engine = 'N63B44';     HP = 450; Consumption = '10.4 l/100km';   MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = '730d xDrive';        Year = 2016; Codename = 'G11';  Engine = 'B57D30';     HP = 265; Consumption = '5.1 l/100km';    MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = '760Li xDrive';       Year = 2017; Codename = 'G12';  Engine = 'N74B66';     HP = 610; Consumption = '12.8 l/100km';   MaxSpeed = 250; Acceleration = 3.7 }
  @{ Model = '740i';               Year = 2023; Codename = 'G70';  Engine = 'B58B30';     HP = 381; Consumption = '7.7 l/100km';    MaxSpeed = 250; Acceleration = 5.4 }
  @{ Model = '750e xDrive';        Year = 2023; Codename = 'G70';  Engine = 'B58B30';     HP = 489; Consumption = '1.2 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'i7 M70 xDrive';      Year = 2024; Codename = 'G70';  Engine = 'GEN5-ESM';   HP = 659; Consumption = '23.8 kWh/100km'; MaxSpeed = 250; Acceleration = 3.7 }

  # --- 8 Series (more) ---
  @{ Model = '840i';               Year = 2019; Codename = 'G15';  Engine = 'B58B30';     HP = 340; Consumption = '7.0 l/100km';    MaxSpeed = 250; Acceleration = 5.0 }
  @{ Model = 'M850i xDrive Gran Coupe'; Year = 2020; Codename = 'G16'; Engine = 'N63B44T3'; HP = 530; Consumption = '10.4 l/100km'; MaxSpeed = 250; Acceleration = 3.9 }

  # --- 1 / 2 Series (more) ---
  @{ Model = '116i';               Year = 2005; Codename = 'E87';  Engine = 'N45B16';     HP = 115; Consumption = '6.8 l/100km';    MaxSpeed = 200; Acceleration = 10.8 }
  @{ Model = '120d';               Year = 2007; Codename = 'E87';  Engine = 'N47D20';     HP = 177; Consumption = '5.0 l/100km';    MaxSpeed = 228; Acceleration = 7.6 }
  @{ Model = '130i';               Year = 2006; Codename = 'E87';  Engine = 'N52B30';     HP = 265; Consumption = '9.2 l/100km';    MaxSpeed = 250; Acceleration = 6.0 }
  @{ Model = '135i';               Year = 2008; Codename = 'E82';  Engine = 'N54B30';     HP = 306; Consumption = '9.1 l/100km';    MaxSpeed = 250; Acceleration = 5.3 }
  @{ Model = '1M Coupe';           Year = 2011; Codename = 'E82';  Engine = 'N54B30T0';   HP = 340; Consumption = '9.6 l/100km';    MaxSpeed = 250; Acceleration = 4.9 }
  @{ Model = '116d';               Year = 2015; Codename = 'F20';  Engine = 'B37D15';     HP = 116; Consumption = '3.8 l/100km';    MaxSpeed = 200; Acceleration = 10.3 }
  @{ Model = '118i';               Year = 2016; Codename = 'F20';  Engine = 'B38B15';     HP = 136; Consumption = '5.1 l/100km';    MaxSpeed = 210; Acceleration = 8.5 }
  @{ Model = '125i';               Year = 2017; Codename = 'F20';  Engine = 'B48B20';     HP = 224; Consumption = '5.9 l/100km';    MaxSpeed = 243; Acceleration = 6.1 }
  @{ Model = '118i';               Year = 2020; Codename = 'F40';  Engine = 'B38A15';     HP = 140; Consumption = '5.7 l/100km';    MaxSpeed = 213; Acceleration = 8.5 }
  @{ Model = '120d xDrive';        Year = 2020; Codename = 'F40';  Engine = 'B47D20';     HP = 190; Consumption = '4.5 l/100km';    MaxSpeed = 230; Acceleration = 7.0 }
  @{ Model = '128ti';              Year = 2021; Codename = 'F40';  Engine = 'B48A20';     HP = 265; Consumption = '6.2 l/100km';    MaxSpeed = 250; Acceleration = 6.1 }
  @{ Model = '120';                Year = 2024; Codename = 'F70';  Engine = 'B38A15';     HP = 170; Consumption = '5.8 l/100km';    MaxSpeed = 225; Acceleration = 7.8 }
  @{ Model = 'M135 xDrive';        Year = 2024; Codename = 'F70';  Engine = 'B48A20';     HP = 300; Consumption = '7.5 l/100km';    MaxSpeed = 250; Acceleration = 4.9 }
  @{ Model = '220i';               Year = 2015; Codename = 'F22';  Engine = 'N20B20';     HP = 184; Consumption = '5.9 l/100km';    MaxSpeed = 235; Acceleration = 7.0 }
  @{ Model = '228i';               Year = 2015; Codename = 'F22';  Engine = 'N20B20';     HP = 245; Consumption = '6.4 l/100km';    MaxSpeed = 250; Acceleration = 5.7 }
  @{ Model = 'M235i';              Year = 2014; Codename = 'F22';  Engine = 'N55B30';     HP = 326; Consumption = '7.6 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'M240i';              Year = 2017; Codename = 'F22';  Engine = 'B58B30';     HP = 340; Consumption = '7.1 l/100km';    MaxSpeed = 250; Acceleration = 4.6 }
  @{ Model = 'M2';                 Year = 2016; Codename = 'F87';  Engine = 'N55B30T0';   HP = 370; Consumption = '8.5 l/100km';    MaxSpeed = 250; Acceleration = 4.3 }
  @{ Model = 'M2 CS';              Year = 2020; Codename = 'F87';  Engine = 'S55B30';     HP = 450; Consumption = '10.0 l/100km';   MaxSpeed = 280; Acceleration = 4.0 }
  @{ Model = '218i Active Tourer'; Year = 2015; Codename = 'F45';  Engine = 'B38A15';     HP = 136; Consumption = '5.1 l/100km';    MaxSpeed = 205; Acceleration = 9.3 }
  @{ Model = '225xe Active Tourer'; Year = 2016; Codename = 'F45'; Engine = 'B38A15';     HP = 224; Consumption = '2.1 l/100km';    MaxSpeed = 202; Acceleration = 6.7 }
  @{ Model = '230i Coupe';         Year = 2022; Codename = 'G42';  Engine = 'B48B20';     HP = 245; Consumption = '6.5 l/100km';    MaxSpeed = 250; Acceleration = 5.8 }
  @{ Model = 'M240i xDrive';       Year = 2022; Codename = 'G42';  Engine = 'B58B30';     HP = 374; Consumption = '8.1 l/100km';    MaxSpeed = 250; Acceleration = 4.3 }
  @{ Model = 'M235i xDrive Gran Coupe'; Year = 2020; Codename = 'F44'; Engine = 'B48A20T1'; HP = 306; Consumption = '7.1 l/100km'; MaxSpeed = 250; Acceleration = 4.9 }

  # --- Z Roadsters (more) ---
  @{ Model = 'Z3 1.9';             Year = 1996; Codename = 'E36/7'; Engine = 'M44B19';    HP = 140; Consumption = '8.1 l/100km';    MaxSpeed = 205; Acceleration = 9.5 }
  @{ Model = 'Z3 M Roadster';      Year = 1998; Codename = 'E36/7'; Engine = 'S50B32';    HP = 321; Consumption = '11.0 l/100km';   MaxSpeed = 250; Acceleration = 5.4 }
  @{ Model = 'Z4 2.5i';            Year = 2003; Codename = 'E85';  Engine = 'M54B25';     HP = 192; Consumption = '9.1 l/100km';    MaxSpeed = 235; Acceleration = 7.0 }
  @{ Model = 'Z4 M Coupe';         Year = 2006; Codename = 'E86';  Engine = 'S54B32';     HP = 343; Consumption = '12.1 l/100km';   MaxSpeed = 250; Acceleration = 5.0 }
  @{ Model = 'Z4 sDrive23i';       Year = 2009; Codename = 'E89';  Engine = 'N52B25';     HP = 204; Consumption = '8.5 l/100km';    MaxSpeed = 242; Acceleration = 6.6 }
  @{ Model = 'Z4 sDrive35is';      Year = 2010; Codename = 'E89';  Engine = 'N54B30';     HP = 340; Consumption = '9.0 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'Z4 sDrive20i';       Year = 2019; Codename = 'G29';  Engine = 'B48B20';     HP = 197; Consumption = '6.1 l/100km';    MaxSpeed = 240; Acceleration = 6.6 }

  # --- X Models (more) ---
  @{ Model = 'X1 xDrive20d';       Year = 2010; Codename = 'E84';  Engine = 'N47D20';     HP = 177; Consumption = '5.5 l/100km';    MaxSpeed = 215; Acceleration = 8.1 }
  @{ Model = 'X1 sDrive18d';       Year = 2016; Codename = 'F48';  Engine = 'B47C20';     HP = 150; Consumption = '4.3 l/100km';    MaxSpeed = 204; Acceleration = 9.3 }
  @{ Model = 'X1 xDrive25e';       Year = 2020; Codename = 'F48';  Engine = 'B38A15';     HP = 220; Consumption = '1.9 l/100km';    MaxSpeed = 193; Acceleration = 6.9 }
  @{ Model = 'X1 xDrive23d';       Year = 2023; Codename = 'U11';  Engine = 'B47D20';     HP = 211; Consumption = '5.2 l/100km';    MaxSpeed = 228; Acceleration = 7.4 }
  @{ Model = 'iX1 xDrive30';       Year = 2023; Codename = 'U11';  Engine = 'GEN5-ESM';   HP = 313; Consumption = '17.3 kWh/100km'; MaxSpeed = 180; Acceleration = 5.6 }
  @{ Model = 'X2 M35i';            Year = 2019; Codename = 'F39';  Engine = 'B48A20T1';   HP = 306; Consumption = '7.1 l/100km';    MaxSpeed = 250; Acceleration = 4.9 }
  @{ Model = 'X2 sDrive20i';       Year = 2024; Codename = 'U10';  Engine = 'B48A20';     HP = 170; Consumption = '6.6 l/100km';    MaxSpeed = 221; Acceleration = 8.0 }
  @{ Model = 'iX2 xDrive30';       Year = 2024; Codename = 'U10';  Engine = 'GEN5-ESM';   HP = 313; Consumption = '17.7 kWh/100km'; MaxSpeed = 180; Acceleration = 5.6 }
  @{ Model = 'X3 3.0i';            Year = 2004; Codename = 'E83';  Engine = 'M54B30';     HP = 231; Consumption = '10.8 l/100km';   MaxSpeed = 210; Acceleration = 7.8 }
  @{ Model = 'X3 xDrive35d';       Year = 2009; Codename = 'E83';  Engine = 'M57D30TU2';  HP = 286; Consumption = '8.0 l/100km';    MaxSpeed = 240; Acceleration = 6.4 }
  @{ Model = 'X3 xDrive20d';       Year = 2011; Codename = 'F25';  Engine = 'N47D20';     HP = 184; Consumption = '5.6 l/100km';    MaxSpeed = 210; Acceleration = 8.5 }
  @{ Model = 'X3 xDrive35i';       Year = 2011; Codename = 'F25';  Engine = 'N55B30';     HP = 306; Consumption = '8.8 l/100km';    MaxSpeed = 245; Acceleration = 5.7 }
  @{ Model = 'X3 xDrive30e';       Year = 2020; Codename = 'G01';  Engine = 'B48B20';     HP = 292; Consumption = '2.1 l/100km';    MaxSpeed = 210; Acceleration = 6.1 }
  @{ Model = 'X3 xDrive30d';       Year = 2022; Codename = 'G01';  Engine = 'B57D30';     HP = 286; Consumption = '6.6 l/100km';    MaxSpeed = 240; Acceleration = 5.7 }
  @{ Model = 'X3 20 xDrive';       Year = 2024; Codename = 'G45';  Engine = 'B48A20';     HP = 208; Consumption = '7.1 l/100km';    MaxSpeed = 215; Acceleration = 7.8 }
  @{ Model = 'X3 M50 xDrive';      Year = 2024; Codename = 'G45';  Engine = 'B58B30';     HP = 398; Consumption = '8.2 l/100km';    MaxSpeed = 250; Acceleration = 4.6 }
  @{ Model = 'iX3';                Year = 2025; Codename = 'NA5';  Engine = 'GEN6-ESM';   HP = 469; Consumption = '15.1 kWh/100km'; MaxSpeed = 210; Acceleration = 4.9 }
  @{ Model = 'X4 xDrive20d';       Year = 2015; Codename = 'F26';  Engine = 'N47D20';     HP = 190; Consumption = '5.5 l/100km';    MaxSpeed = 212; Acceleration = 8.0 }
  @{ Model = 'X4 M40i';            Year = 2019; Codename = 'G02';  Engine = 'B58B30';     HP = 360; Consumption = '8.9 l/100km';    MaxSpeed = 250; Acceleration = 4.8 }
  @{ Model = 'X4 M Competition';   Year = 2021; Codename = 'F98';  Engine = 'S58B30';     HP = 510; Consumption = '10.6 l/100km';   MaxSpeed = 250; Acceleration = 3.8 }
  @{ Model = 'X5 4.8is';           Year = 2004; Codename = 'E53';  Engine = 'N62B48';     HP = 360; Consumption = '13.9 l/100km';   MaxSpeed = 250; Acceleration = 6.1 }
  @{ Model = 'X5 xDrive48i';       Year = 2007; Codename = 'E70';  Engine = 'N62B48';     HP = 355; Consumption = '12.5 l/100km';   MaxSpeed = 240; Acceleration = 6.5 }
  @{ Model = 'X5 M';               Year = 2010; Codename = 'E70';  Engine = 'S63B44';     HP = 555; Consumption = '13.9 l/100km';   MaxSpeed = 250; Acceleration = 4.7 }
  @{ Model = 'X5 xDrive25d';       Year = 2014; Codename = 'F15';  Engine = 'N47D20';     HP = 218; Consumption = '5.7 l/100km';    MaxSpeed = 220; Acceleration = 8.2 }
  @{ Model = 'X5 xDrive40e';       Year = 2016; Codename = 'F15';  Engine = 'N20B20';     HP = 313; Consumption = '3.3 l/100km';    MaxSpeed = 210; Acceleration = 6.8 }
  @{ Model = 'X5 xDrive40i';       Year = 2019; Codename = 'G05';  Engine = 'B58B30';     HP = 340; Consumption = '8.8 l/100km';    MaxSpeed = 243; Acceleration = 5.5 }
  @{ Model = 'X5 M50i';            Year = 2020; Codename = 'G05';  Engine = 'N63B44T3';   HP = 530; Consumption = '11.0 l/100km';   MaxSpeed = 250; Acceleration = 4.3 }
  @{ Model = 'X5 xDrive30d';       Year = 2024; Codename = 'G05';  Engine = 'B57D30';     HP = 298; Consumption = '7.6 l/100km';    MaxSpeed = 242; Acceleration = 6.1 }
  @{ Model = 'X6 xDrive35d';       Year = 2008; Codename = 'E71';  Engine = 'M57D30TU2';  HP = 286; Consumption = '8.3 l/100km';    MaxSpeed = 236; Acceleration = 6.9 }
  @{ Model = 'X6 M50d';            Year = 2013; Codename = 'E71';  Engine = 'N57D30S1';   HP = 381; Consumption = '7.7 l/100km';    MaxSpeed = 250; Acceleration = 5.3 }
  @{ Model = 'X6 M50i';            Year = 2020; Codename = 'G06';  Engine = 'N63B44T3';   HP = 530; Consumption = '10.7 l/100km';   MaxSpeed = 250; Acceleration = 4.3 }
  @{ Model = 'X7 M50d';            Year = 2019; Codename = 'G07';  Engine = 'B57D30S0';   HP = 400; Consumption = '7.0 l/100km';    MaxSpeed = 250; Acceleration = 5.4 }
  @{ Model = 'X7 xDrive40d';       Year = 2023; Codename = 'G07';  Engine = 'B57D30';     HP = 352; Consumption = '7.5 l/100km';    MaxSpeed = 245; Acceleration = 5.9 }
  @{ Model = 'X7 M60i xDrive';     Year = 2023; Codename = 'G07';  Engine = 'S68B44';     HP = 530; Consumption = '12.3 l/100km';   MaxSpeed = 250; Acceleration = 4.7 }

  # --- i Models (more) ---
  @{ Model = 'i3 94Ah';            Year = 2017; Codename = 'I01';  Engine = 'IB1P25';     HP = 170; Consumption = '13.1 kWh/100km'; MaxSpeed = 150; Acceleration = 7.3 }
  @{ Model = 'i3 120Ah';           Year = 2019; Codename = 'I01';  Engine = 'IB1P25';     HP = 170; Consumption = '13.1 kWh/100km'; MaxSpeed = 150; Acceleration = 7.3 }
  @{ Model = 'i8 Roadster';        Year = 2018; Codename = 'I15';  Engine = 'B38K15';     HP = 374; Consumption = '2.0 l/100km';    MaxSpeed = 250; Acceleration = 4.6 }
  @{ Model = 'i4 eDrive35';        Year = 2023; Codename = 'G26';  Engine = 'GEN5-ESM';   HP = 286; Consumption = '15.8 kWh/100km'; MaxSpeed = 190; Acceleration = 6.0 }
  @{ Model = 'i4 xDrive40';        Year = 2024; Codename = 'G26';  Engine = 'GEN5-ESM';   HP = 401; Consumption = '18.3 kWh/100km'; MaxSpeed = 190; Acceleration = 5.1 }
  @{ Model = 'iX xDrive45';        Year = 2025; Codename = 'I20';  Engine = 'GEN5-ESM';   HP = 408; Consumption = '20.3 kWh/100km'; MaxSpeed = 200; Acceleration = 5.1 }
) | ForEach-Object {
  # Series derived from the model name - used as the service category below the "BMW" category
  $m = $_.Model
  $series = switch -Regex ($m) {
    '^(X|XM)'            { 'X Models' }
    '^Z'                 { 'Z Roadsters' }
    '^i[0-9X]'           { 'i Models' }
    '^1M|^M1'            { '1 / 2 Series' }
    '^M([2-8])'          { @{ '2' = '1 / 2 Series'; '3' = '3 Series'; '4' = '4 Series'; '5' = '5 Series'; '6' = '6 Series'; '8' = '8 Series' }[$Matches[1]] }
    '^[12][0-9]{2}'      { '1 / 2 Series' }
    '^3[0-9]{2}|^320/6'  { '3 Series' }
    '^4[0-9]{2}'         { '4 Series' }
    '^5[0-9]{2}'         { '5 Series' }
    '^6[0-9]{2}'         { '6 Series' }
    '^7[0-9]{2}'         { '7 Series' }
    '^8[0-9]{2}'         { '8 Series' }
    default              { 'Other' }
  }
  if ($_.Year -lt 1990) { $series = 'Classics' }

  [PSCustomObject]@{
    Category     = 'BMW'
    Group        = $series
    Model        = $_.Model
    Year         = $_.Year
    Codename     = $_.Codename
    EngineCode   = $_.Engine
    HP           = $_.HP
    Consumption  = $_.Consumption
    MaxSpeed     = $_.MaxSpeed
    Acceleration = $_.Acceleration
    # Ready-to-use values for AccProduct
    ProductName  = 'BMW {0} {1}' -f $_.Model, $_.Year
    Description  = 'HP: {0}, Consumption: {1}, Max Speed: {2} km/h, 0-100: {3:0.0} s' -f $_.HP, $_.Consumption, $_.MaxSpeed, [double]$_.Acceleration
    Code         = $_.Engine
    ArticleCode  = $_.Codename
  }
}

<#
  Weapon pool: German WWII small arms. Year is the year of adoption / introduction.
  Rate of fire is cyclic for automatic weapons; for manual and semi-automatic weapons it is a practical figure.
#>
$script:WeaponPool = @(
  @{ Name = 'Karabiner 98k';   Designation = 'Kar98k'; Type = 'Rifles';            Year = 1935; Manufacturer = 'Mauser';            Caliber = '7.92x57mm Mauser';      Action = 'Bolt-action';        RateOfFire = '15 rpm';        MuzzleVelocity = 760;  Weight = 3.9;  Range = 500;  Magazine = '5-round internal' }
  @{ Name = 'MP 40';           Designation = 'MP40';   Type = 'Submachine guns';   Year = 1940; Manufacturer = 'Erma';              Caliber = '9x19mm Parabellum';     Action = 'Blowback, open bolt'; RateOfFire = '500 rpm';      MuzzleVelocity = 400;  Weight = 4.0;  Range = 150;  Magazine = '32-round box' }
  @{ Name = 'MG 34';           Designation = 'MG34';   Type = 'Machine guns';      Year = 1934; Manufacturer = 'Rheinmetall-Borsig'; Caliber = '7.92x57mm Mauser';     Action = 'Recoil-operated';    RateOfFire = '850 rpm';       MuzzleVelocity = 755;  Weight = 12.1; Range = 2000; Magazine = '50-round belt / 75-round drum' }
  @{ Name = 'MG 42';           Designation = 'MG42';   Type = 'Machine guns';      Year = 1942; Manufacturer = 'Mauser';            Caliber = '7.92x57mm Mauser';      Action = 'Recoil-operated, roller-locked'; RateOfFire = '1200 rpm'; MuzzleVelocity = 740; Weight = 11.6; Range = 2000; Magazine = '50-round belt' }
  @{ Name = 'StG 44';          Designation = 'StG44';  Type = 'Rifles';            Year = 1944; Manufacturer = 'Haenel';            Caliber = '7.92x33mm Kurz';        Action = 'Gas-operated, tilting bolt'; RateOfFire = '550 rpm'; MuzzleVelocity = 685; Weight = 4.6;  Range = 300;  Magazine = '30-round box' }
  @{ Name = 'Gewehr 43';       Designation = 'G43';    Type = 'Rifles';            Year = 1943; Manufacturer = 'Walther';           Caliber = '7.92x57mm Mauser';      Action = 'Gas-operated, semi-automatic'; RateOfFire = '30 rpm'; MuzzleVelocity = 775; Weight = 4.1; Range = 500;  Magazine = '10-round box' }
  @{ Name = 'FG 42';           Designation = 'FG42';   Type = 'Rifles';            Year = 1942; Manufacturer = 'Rheinmetall-Borsig'; Caliber = '7.92x57mm Mauser';     Action = 'Gas-operated, select-fire'; RateOfFire = '900 rpm'; MuzzleVelocity = 740; Weight = 4.2; Range = 600;  Magazine = '20-round box' }
  @{ Name = 'Luger P08';       Designation = 'P08';    Type = 'Pistols';           Year = 1908; Manufacturer = 'DWM';               Caliber = '9x19mm Parabellum';     Action = 'Toggle-locked, short recoil'; RateOfFire = '20 rpm'; MuzzleVelocity = 370; Weight = 0.87; Range = 50; Magazine = '8-round box' }
  @{ Name = 'Walther P38';     Designation = 'P38';    Type = 'Pistols';           Year = 1938; Manufacturer = 'Walther';           Caliber = '9x19mm Parabellum';     Action = 'Short recoil, DA/SA'; RateOfFire = '20 rpm';       MuzzleVelocity = 365;  Weight = 0.8;  Range = 50;   Magazine = '8-round box' }
  @{ Name = 'Panzerbüchse 39'; Designation = 'PzB39';  Type = 'Anti-tank weapons'; Year = 1939; Manufacturer = 'Gustloff';          Caliber = '7.92x94mm Patronen 318'; Action = 'Single-shot, falling block'; RateOfFire = '10 rpm'; MuzzleVelocity = 1210; Weight = 12.6; Range = 300; Magazine = 'Single-shot, 2x10-round holders' }
) | ForEach-Object {
  [PSCustomObject]@{
    Category       = 'Weapon'
    Group          = $_.Type
    Name           = $_.Name
    Designation    = $_.Designation
    Year           = $_.Year
    Manufacturer   = $_.Manufacturer
    Caliber        = $_.Caliber
    Action         = $_.Action
    RateOfFire     = $_.RateOfFire
    MuzzleVelocity = $_.MuzzleVelocity
    Weight         = $_.Weight
    Range          = $_.Range
    Magazine       = $_.Magazine
    # Ready-to-use values for AccProduct
    ProductName    = '{0} {1}' -f $_.Name, $_.Year
    Description    = 'Caliber: {0}, Action: {1}, Rate of Fire: {2}, Muzzle Velocity: {3} m/s, Weight: {4:0.0} kg, Range: {5} m, Feed: {6}' -f $_.Caliber, $_.Action, $_.RateOfFire, $_.MuzzleVelocity, [double]$_.Weight, $_.Range, $_.Magazine
    Code           = $_.Manufacturer
    ArticleCode    = $_.Designation
  }
}

# Combined pool the randomizer draws from
$script:ProductPool = @($script:BmwModelPool) + @($script:WeaponPool)

<#!
.SYNOPSIS
Returns the product pool, optionally filtered by category.

.PARAMETER Category
'BMW', 'Weapon' or 'All' (default).

.OUTPUTS
PSCustomObject[] - every entry has Category, ProductName, Description, Code, ArticleCode plus category-specific fields.
#>
function Get-FakeProductPool {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param (
    [parameter(Mandatory = $false)]
    [ValidateSet('All', 'BMW', 'Weapon')]
    [string] $Category = 'All'
  )

  switch ($Category) {
    'BMW'    { $script:BmwModelPool }
    'Weapon' { $script:WeaponPool }
    default  { $script:ProductPool }
  }
}

<#!
.SYNOPSIS
Returns the BMW model pool. Kept for backwards compatibility, same as Get-FakeProductPool -Category BMW.
#>
function Get-BmwModelPool {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param ()

  $script:BmwModelPool
}

<#!
.SYNOPSIS
Returns one or more random products (cars and/or weapons) from the pool.

.DESCRIPTION
Picks random entries from the product pool. When a Bogus Faker instance is passed the picks
are driven by its seeded randomizer, so the result is reproducible together with the rest of
the fake data. Without a Faker a System.Random seeded with -Seed is used.

.PARAMETER Faker
A Bogus.Faker instance. Optional.

.PARAMETER Seed
Seed for the fallback randomizer when no Faker is given.

.PARAMETER Count
Number of products to return. Default 1.

.PARAMETER Unique
Return every product at most once. Count must not exceed the pool size then.

.PARAMETER Category
Restrict picks to 'BMW' or 'Weapon'. Default 'All'.

.EXAMPLE
Get-RandomFakeProduct -Faker $Faker

.EXAMPLE
Get-RandomFakeProduct -Faker $Faker -Count 100 -Unique
#>
function Get-RandomFakeProduct {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param (
    [parameter(Mandatory = $false, HelpMessage = 'Bogus.Faker instance used for seeded randomness')]
    $Faker = $null,
    [parameter(Mandatory = $false, HelpMessage = 'Seed for the fallback randomizer when no Faker is given')]
    [int] $Seed = 973523,
    [parameter(Mandatory = $false, HelpMessage = 'Number of products to return')]
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Count = 1,
    [parameter(Mandatory = $false, HelpMessage = 'Return every product at most once')]
    [switch] $Unique,
    [parameter(Mandatory = $false, HelpMessage = 'Restrict picks to one category')]
    [ValidateSet('All', 'BMW', 'Weapon')]
    [string] $Category = 'All'
  )

  $pool = @(Get-FakeProductPool -Category $Category)

  if ($Unique -and $Count -gt $pool.Count) {
    throw "Requested $Count unique products but the '$Category' pool only contains $($pool.Count)."
  }

  if ($null -ne $Faker) {
    $nextInt = { param($max) $Faker.Random.Int(0, $max - 1) }
  } else {
    $rng = [System.Random]::new($Seed)
    $nextInt = { param($max) $rng.Next(0, $max) }
  }

  if ($Unique) {
    # Fisher-Yates shuffle driven by the chosen randomizer, then take the first $Count
    $indices = 0..($pool.Count - 1)
    for ($i = $indices.Count - 1; $i -gt 0; $i--) {
      $j = & $nextInt ($i + 1)
      $tmp = $indices[$i]; $indices[$i] = $indices[$j]; $indices[$j] = $tmp
    }
    foreach ($idx in $indices[0..($Count - 1)]) {
      $pool[$idx]
    }
  } else {
    for ($i = 0; $i -lt $Count; $i++) {
      $pool[(& $nextInt $pool.Count)]
    }
  }
}

<#!
.SYNOPSIS
Returns random BMW models only. Kept for backwards compatibility, same as Get-RandomFakeProduct -Category BMW.
#>
function Get-RandomBmwModel {
  [CmdletBinding()]
  [OutputType([PSCustomObject[]])]
  param (
    $Faker = $null,
    [int] $Seed = 973523,
    [ValidateRange(1, [int]::MaxValue)]
    [int] $Count = 1,
    [switch] $Unique
  )

  Get-RandomFakeProduct -Faker $Faker -Seed $Seed -Count $Count -Unique:$Unique -Category 'BMW'
}

Export-ModuleMember -Function Get-FakeProductPool, Get-BmwModelPool, Get-RandomFakeProduct, Get-RandomBmwModel
