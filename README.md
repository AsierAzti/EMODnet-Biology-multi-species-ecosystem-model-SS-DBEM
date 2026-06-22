R workflow to convert SS-DBEM model output into a CF-1.9 compliant NetCDF file.

---

This repository provides a fully reproducible R workflow to process outputs from the **Size-Structured Dynamic Bioclimate Envelope Model (SS-DBEM)** into a standardized **NetCDF-4** file following the [CF Metadata Conventions (v1.9)](https://cfconventions.org/).

SS-DBEM is a multi-species ecosystem model that combines a species-based model (DBEM) with a size-spectrum approach (SS) to project spatially (0.5°×0.5°) and temporally (yearly) resolved changes in marine species biomass. It incorporates key ecological processes alongside a competition algorithm that allocates energy resources among co-occurring species. Environmental conditions from biogeochemical models (GFDL, IPSL, MPII) are explicitly considered, allowing spatially explicit species responses to climate change.
- Biogeochemical models: [ISIMIP3a](https://protocol.isimip.org/#/ISIMIP3a/marine-fishery_global)
- Species parameters: [FishBase](https://www.fishbase.se/search.php)
- Model code and documentation: [SS-DBEM on Zenodo](https://zenodo.org/records/7548113)
- Reference paper: [Cheung et al. (2013), *Global Change Biology*](https://onlinelibrary.wiley.com/doi/10.1111/gcb.12231)


The output file contains **relative biomass change projections (2030–2100)** for 18 commercially important fish and invertebrate species in the **North Atlantic**, under the **RCP 8.5** climate scenario and a fishing mortality of **F/Fmsy = 1.0**, using the ensemble mean across climate models. Biomass change values are log-transformed and spatially smoothed using a 25-year focal window.

This work is based on the methodology described by Fernández-Bejarano, Salvador (2022), Create an EMODnet-Biology data product as NetCDF, available at https://github.com/EMODnet/EMODnet-Biology-products-erddap-demo.
