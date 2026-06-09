R workflow to convert SS-DBEM model output into a CF-1.9 compliant NetCDF file.

---

## Description

This repository provides a fully reproducible R workflow to process outputs from the **Size-Structured Dynamic Bioclimate Envelope Model (SS-DBEM)** into a standardized **NetCDF-4** file following the [CF Metadata Conventions (v1.9)](https://cfconventions.org/).

SS-DBEM is a multi-species ecosystem model that combines a species-based model (DBEM) with a size-spectrum approach (SS) to project spatially (0.5°×0.5°) and temporally (yearly) resolved changes in marine species size, abundance, and biomass. It incorporates key ecological processes — including population growth, larval dispersal, and the ecophysiological effects of temperature, oxygen, and pH — alongside a competition algorithm that allocates energy resources among co-occurring species. Environmental conditions from biogeochemical models are explicitly considered, allowing spatially explicit species responses to climate change.

- 📦 Model code and documentation: [SS-DBEM on Zenodo](https://zenodo.org/records/7548113)
- 📄 Reference paper: [Cheung et al. (2013), *Global Change Biology*](https://onlinelibrary.wiley.com/doi/10.1111/gcb.12231)


The output file contains **relative biomass change projections (2030–2100)** for 18 commercially important fish and invertebrate species in the **North Atlantic**, under the **RCP 8.5** climate scenario and a fishing mortality of **F/Fmsy = 1.0**, using the ensemble mean across climate models. Biomass change values are log-transformed and spatially smoothed using a 25-year focal window.

The resulting NetCDF is designed for distribution, long-term archiving, and interoperability with standard tools in oceanography and marine ecology (e.g., Panoply, Python `xarray`, CDO).

---

## Study area and scenario

| Parameter | Value |
|---|---|
| Region | North Atlantic (Lon: -80° to 15°, Lat: 0° to 80°) |
| Scenario | RCP 8.5 |
| Fishing mortality | F/Fmsy = 1.0 |
| Model | Ensemble mean |
| Period | 2030–2100 |
| Variable | Relative biomass change (log-transformed, 25-year focal smoothing) |

---

## Species

18 commercially important species identified by their [WoRMS](https://www.marinespecies.org/) AphiaID:

| AphiaID | Scientific name |
|---|---|
| 126417 | *Clupea harengus* |
| 126421 | *Sardina pilchardus* |
| 126425 | *Sprattus sprattus* |
| 126426 | *Engraulis encrasicolus* |
| 126436 | *Gadus morhua* |
| 126437 | *Melanogrammus aeglefinus* |
| 126439 | *Micromesistius poutassou* |
| 126484 | *Merluccius merluccius* |
| 126735 | *Mallotus villosus* |
| 126822 | *Trachurus trachurus* |
| 127018 | *Katsuwonus pelamis* |
| 127023 | *Scomber scombrus* |
| 127026 | *Thunnus alalunga* |
| 127027 | *Thunnus albacares* |
| 127028 | *Thunnus obesus* |
| 127029 | *Thunnus thynnus* |
| 127089 | *Trichiurus lepturus* |
| 342064 | *Illex argentinus* |

---

## NetCDF structure

### Dimensions

| Dimension | Size | Description |
|---|---|---|
| `lon` | 190 | Longitude (degrees East) |
| `lat` | 160 | Latitude (degrees North) |
| `aphiaid` | 18 | Species identifier (WoRMS AphiaID) |
| `time` | 71 | Years 2030–2100 (days since 1960-01-01) |

### Variables

| Variable | Dimensions | Description |
|---|---|---|
| `lon` | lon | Longitude coordinates |
| `lat` | lat | Latitude coordinates |
| `time` | time | Time coordinate |
| `aphiaid` | aphiaid | WoRMS AphiaID species codes |
| `taxon_name` | string80, aphiaid | Scientific name of each species |
| `taxon_lsid` | string80, aphiaid | Life Science Identifier (LSID) from WoRMS |
| `crs` | — | Coordinate Reference System (WGS84) |
| `Biomass_relative` | lon, lat, aphiaid, time | Relative biomass change |

> Dimension order follows CF convention: T, Z, Y, X.

### Coordinate Reference System

- **CRS:** WGS84 (EPSG:4326)
- **Resolution:** ~0.083° (~9 km)

---

## CF Convention compliance

The output file has been checked against the [IOOS Compliance Checker](https://compliance.ioos.us/index.html). Key conventions applied:

- Dimension order: T, Z, Y, X (CF 1.6+)
- `standard_name` attributes following the [CF Standard Name Table](https://cfconventions.org/Data/cf-standard-names/current/build/cf-standard-name-table.html)
- `biological_taxon_name` and `biological_taxon_lsid` for species identification
- `_FillValue` = -99999 for missing data
- Time units: `days since 1960-01-01 00:00:00`, calendar: `standard`
- CRS explicitly defined via `grid_mapping` variable

---

## Requirements

### R packages

install.packages(c("RNetCDF", "dplyr", "stringr", "glue", "worrms", "ggplot2"))

| Package | Purpose |
|---|---|
| `RNetCDF` | NetCDF file creation and writing |
| `dplyr` | Data manipulation |
| `stringr` | String processing (species codes) |
| `worrms` | AphiaID retrieval from WoRMS API |
| `ggplot2` | Output verification plots |

---

## Input data

| File | Description |
|---|---|
| `Lat_Lon.csv` | Full model grid (lon/lat coordinates) |
| `lista_especies_18max_catches.csv` | Species list with internal model codes and scientific names |
| `18species_rcp8.5_1.0fmsy_..._log_25focal_onlysea.csv` | Model output: relative biomass change per species, cell and year |

---

## Usage

source("ss_dbem_to_netcdf.R")

The script will:

1. Read and mask the model grid to the study area.
2. Query WoRMS for AphiaIDs and LSIDs.
3. Sort species by AphiaID and build the taxon lookup table.
4. Build the 4D biomass array (lon x lat x aphiaid x time).
5. Write the CF-compliant NetCDF file.

---

## Output

ss-dbem_18species_rcp8.5_1.0fmsy_modelensemble_log_25focal_onlysea.nc

---

## Sources

### Model

- **SS-DBEM** — Size-Structured Dynamic Bioclimate Envelope Model  
  Cheung, W.W.L., Lam, V.W.Y., Sarmiento, J.L., Kearney, K., Watson, R., Zeller, D., Pauly, D. (2010). Large-scale redistribution of maximum fisheries catch potential in the global ocean under climate change. *Global Change Biology*, 16(1), 24–35. https://doi.org/10.1111/j.1365-2486.2009.01995.x

### Climate forcing

- **CMIP5 / RCP 8.5** — Coupled Model Intercomparison Project Phase 5  
  Taylor, K.E., Stouffer, R.J., Meehl, G.A. (2012). An overview of CMIP5 and the experiment design. *Bulletin of the American Meteorological Society*, 93(4), 485–498. https://doi.org/10.1175/BAMS-D-11-00094.1

### Species taxonomy

- **WoRMS** — World Register of Marine Species  
  WoRMS Editorial Board (2024). *World Register of Marine Species*. Available at https://www.marinespecies.org. https://doi.org/10.14284/170

### Conventions

- **CF Metadata Conventions v1.8**  
  Eaton, B., Gregory, J., Drach, B., Taylor, K., Hankin, S., et al. (2022). *NetCDF Climate and Forecast (CF) Metadata Conventions, Version 1.8*. Available at https://cfconventions.org

---

## Author

**Asier Anabitarte**  
[AZTI](https://www.azti.es) — Marine Research  
aanabitarte@azti.es
