# SS-DBEM ensemble projections of 18 North Atlantic fish species under IPCC AR6 RCP 8.5 climate and MSY fishing scenario
## Introduction
Climate change is reshaping ocean environmental conditions—altering temperature, oxygen levels, acidity, and primary production—which in turn affects the growth, distribution, and abundance of marine species, including those targeted by fisheries.  Future predictions of fish distributions and catches models are available, but many do not provide ensembles to account for uncertainty in environmental projections. Furthermore, these environmental projections from biogeochemical models are regularly updated with revision of climate scenarios. SS-DBEM model is a multi-species model that combines a species-based model (DBEM) with a size-spectrum approach (SS) to project spatially (0.5°×0.5°) and temporally (yearly) resolved changes in marine fish species biomass. It incorporates key ecological processes alongside a competition algorithm that allocates energy resources among co-occurring species using ocean environmental conditions from biogeochemical models

## Directory structure

```
{{directory_name}}/
├── data/
│   ├── derived_data/
│   └── raw_data/
├── product/
└── scripts/
```
* **data** - Raw and derived data
* **product** - Output product files
* **scripts** - Reusable code

## Data series
This data product use the following datasets:
- Biogeochemical models: [ISIMIP3a](https://protocol.isimip.org/#/ISIMIP3a/marine-fishery_global)
- Species parameters: [FishBase](https://www.fishbase.se/search.php)
  
## Data product
The output file contains **relative biomass change projections (2030–2100)** for 18 commercially important fish and invertebrate species in the **North Atlantic**, under the **RCP 8.5** climate scenario and a fishing mortality of **F/Fmsy = 1.0**, using the ensemble mean across projections using three biogeochemical models (GFDL, IPSL, MPII). Biomass change values are log-transformed and spatially smoothed using a 25-year focal window

## More information:
### Methods References
[Fernandes et al. (2013), *Global Change Biology*](https://onlinelibrary.wiley.com/doi/10.1111/gcb.12231)

[SS-DBEM on Zenodo](https://zenodo.org/records/7548113)

### Citation and download link
This product should be cited as:

Anabitarte, A., Granado, I., Valle, M., Erauskin-Extramiana, M., & Fernandes-Salvador, J. A. (2026). SS-DBEM ensemble projections of 18 North Atlantic fish species under IPCC AR6 RCP 8.5 climate and MSY fishing scenario

Available to download in:

[EMODnet web page where netcdf is located link]

### Authors
Anabitarte, A., Granado, I., Valle, M., Erauskin-Extramiana, M., Fernandes-Salvador, J.A.  
