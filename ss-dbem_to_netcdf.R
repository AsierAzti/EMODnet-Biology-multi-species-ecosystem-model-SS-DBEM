############################################################
#  SS-DBEM NetCDF Generation Script
#
#  Author: Asier Anabitarte
#  Institution: AZTI
#  Date: 2026
#
#  Description:
#  This script generates a NetCDF file from SS-DBEM model 
#  outputs for multiple marine species under climate scenarios.
#
#  Workflow:
#  1. Read species list and retrieve AphiaID (WoRMS).
#  2. Build mapping table (model code → AphiaID).
#  3. Define spatial (lon/lat) and temporal (time) dimensions.
#  4. Create NetCDF structure and metadata.
#  5. Map CSV data into multidimensional indices.
#  6. Fill and validate the biomass array.
#  7. Export data and attributes to NetCDF.
#
#  Output:
#  A CF-compliant NetCDF file containing biomass projections.
############################################################

#### 1. LIBRARIES ####

library(RNetCDF)
library(readr)
library(dplyr)
library(glue)
library(ncdf4)
library(dplyr)
library(raster)
library(tidyverse)
library(worrms)
library(glue)
library(readxl)

#### 2. SPECIES AND APHIAID MAPPING ####

#Generate the equivalence of the AphiaID codes and the data part
names <- read.csv("data/species.csv", sep=";")

filenames_sp <- names$TaxonName


n <- data.frame(names$Codigo)

names(n)

n <- n %>% 
  dplyr::rename (id = "names.Codigo")

n <- str_remove(n$id, "SP")

n <- as.numeric (n)

species_aphiaid <- matrix(NA, ncol = 4, nrow = 18) #nrow. According to your number of species

for(i in 1:length(n)){
aphiaid_id <- wm_name2id_(name = paste0(filenames_sp[i], collapse = '", "') )
n_aphiaid <- aphiaid_id[[paste0(filenames_sp[i], collapse = '", "')]]

species_aphiaid [i,]<-c(paste0("SP",i),
                        filenames_sp[i],
                        n_aphiaid,
                        paste0("urn:lsid:marinespecies.org:taxname:", n_aphiaid))
}

#Thunnus alalunga
species_aphiaid [8,]<-c(paste0("SP",8),
                                                  filenames_sp[8],
                                                  127026,
                                                  paste0("urn:lsid:marinespecies.org:taxname:127026"))

species_aphiaid.df <- as.data.frame(species_aphiaid)

species_aphiaid.df <- species_aphiaid.df %>% 
  drop_na()

names (species_aphiaid.df) <- c("SP", "SN", "aphiaid", "taxon_lsid")


species_aphiaid.df <- species_aphiaid.df %>%
  left_join(
    names %>% dplyr::select(TaxonName, Codigo), 
    by = c("SN" = "TaxonName")            
  )


#### 3. LON-LAT PREPARATION ####


##Read lon-lat
lonlat<- read.csv("data/Lat_Lon.csv", sep = ",")

#Mask lon-lat
lonlat<-lonlat %>%
  filter(!is.na(Lat), !is.na(Lon),
         Lat >= 0, Lat <= 80,
         Lon >= -80, Lon <= 15)

lon<- sort(unique(lonlat$Lon))
lat<- sort(unique(lonlat$Lat))


#### 4. NETCDF CREATION ####

nc <- create.nc("NC_Output/nc_output.nc")


# ---- Longitude ----

dim.def.nc(nc, dimname = "lon", dimlength = length(lon)) 
var.def.nc(nc, varname = "lon", vartype = "NC_DOUBLE", dimensions = "lon")
att.put.nc(nc, variable = "lon", name = "units", type = "NC_CHAR", value = "degrees_east")
att.put.nc(nc, variable = "lon", name = "standard_name", type = "NC_CHAR", value = "longitude")
att.put.nc(nc, variable = "lon", name = "long_name", type = "NC_CHAR", value = "Longitude")
var.put.nc(nc, variable = "lon", data = lon) 
var.get.nc(nc, variable = "lon")

# ---- 2. Latitude ----

dim.def.nc(nc, dimname = "lat", dimlength = length(lat)) 
var.def.nc(nc, varname = "lat", vartype = "NC_DOUBLE", dimensions = "lat")
att.put.nc(nc, variable = "lat", name = "units", type = "NC_CHAR", value = "degrees_north")
att.put.nc(nc, variable = "lat", name = "standard_name", type = "NC_CHAR", value = "latitude")
att.put.nc(nc, variable = "lat", name = "long_name", type = "NC_CHAR", value = "Latitude")
var.put.nc(nc, variable = "lat", data = lat) 
var.get.nc(nc, variable = "lat")

# ---- 3. Time ----

time <- as.numeric(as.Date(paste0(2030:2100, "-01-01")) - as.Date("1960-01-01"))
dim.def.nc(nc, dimname = "time", dimlength = length(time)) 
var.def.nc(nc, varname = "time", vartype = "NC_DOUBLE", dimensions = "time")
att.put.nc(nc, variable = "time", name = "standard_name", type = "NC_CHAR", value = "time")
att.put.nc(nc, variable = "time", name = "long_name", type = "NC_CHAR", value = "Time")
att.put.nc(nc, variable = "time", name = "units", type = "NC_CHAR", value = "days since 1960-01-01 00:00:00")
att.put.nc(nc, variable = "time", name = "calendar", type = "NC_CHAR", value = "standard")
var.put.nc(nc, variable = "time", data = time)
var.get.nc(nc, variable = "time")


# ---- 4. Species ----

# Ensure correct type and order
species_aphiaid.df$aphiaid <- as.numeric(species_aphiaid.df$aphiaid)
species_aphiaid.df         <- species_aphiaid.df[order(species_aphiaid.df$aphiaid), ]

aphiaid_sorted    <- species_aphiaid.df$aphiaid
taxon_name_sorted <- species_aphiaid.df$SN
taxon_lsid_sorted <- species_aphiaid.df$taxon_lsid


# Aphiaid
dim.def.nc(nc, dimname = "aphiaid", dimlength = 18) #number of species
dim.def.nc(nc, dimname = "string80", dimlength = 80)
var.def.nc(nc, varname = "aphiaid", vartype = "NC_INT", dimensions = "aphiaid")
att.put.nc(nc, variable = "aphiaid", name = "long_name", type = "NC_CHAR", value = "Life Science Identifier - World Register of Marine Species")
att.put.nc(nc, variable = "aphiaid", name = "units", type = "NC_CHAR", value = "1")
var.put.nc(nc, variable = "aphiaid", data = aphiaid_sorted)
var.get.nc(nc, variable = "aphiaid")

# Taxon name
var.def.nc(nc, varname = "taxon_name",  vartype = "NC_CHAR", dimension = c("string80", "aphiaid"))
att.put.nc(nc, variable = "taxon_name", name = "standard_name", type = "NC_CHAR", value = "biological_taxon_name")
att.put.nc(nc, variable = "taxon_name", name = "long_name", type = "NC_CHAR", value = "Scientific name of the taxa")
var.put.nc(nc, variable = "taxon_name", data = taxon_name_sorted)
var.get.nc(nc, variable = "taxon_name")

# Taxon lsid
var.def.nc(nc, varname = "taxon_lsid", vartype = "NC_CHAR", dimension = c("string80", "aphiaid"))
att.put.nc(nc, variable = "taxon_lsid", name = "standard_name", type = "NC_CHAR", value = "biological_taxon_lsid")
att.put.nc(nc, variable = "taxon_lsid", name = "long_name", type = "NC_CHAR", value = "Life Science Identifier - World Register of Marine Species")
var.put.nc(nc, variable = "taxon_lsid", data = taxon_lsid_sorted)
var.get.nc(nc, variable = "taxon_lsid")

# ---- 5. Coordinate Reference System ----

var.def.nc(nc, varname = "crs", vartype = "NC_CHAR", dimensions = NA)
att.put.nc(nc, variable = "crs", name = "long_name", type = "NC_CHAR", value = "Coordinate Reference System")
att.put.nc(nc, variable = "crs", name = "geographic_crs_name", type = "NC_CHAR", value = "WGS 84")
att.put.nc(nc, variable = "crs", name = "grid_mapping_name", type = "NC_CHAR", value = "latitude_longitude")
att.put.nc(nc, variable = "crs", name = "reference_ellipsoid_name", type = "NC_CHAR", value = "WGS 84")
att.put.nc(nc, variable = "crs", name = "horizontal_datum_name", type = "NC_CHAR", value = "WGS 84")
att.put.nc(nc, variable = "crs", name = "prime_meridian_name", type = "NC_CHAR", value = "Greenwich")
att.put.nc(nc, variable = "crs", name = "longitude_of_prime_meridian", type = "NC_DOUBLE", value = 0.)
att.put.nc(nc, variable = "crs", name = "semi_major_axis", type = "NC_DOUBLE", value = 6378137.)
att.put.nc(nc, variable = "crs", name = "semi_minor_axis", type = "NC_DOUBLE", value = 6356752.314245179)
att.put.nc(nc, variable = "crs", name = "inverse_flattening", type = "NC_DOUBLE", value = 298.257223563)
att.put.nc(nc, variable = "crs", name = "spatial_ref", type = "NC_CHAR", value = 'GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563]],PRIMEM[\"Greenwich\",0],UNIT[\"degree\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AXIS[\"Latitude\",NORTH],AXIS[\"Longitude\",EAST],AUTHORITY[\"EPSG\",\"4326\"]]')
att.put.nc(nc, variable = "crs", name = "GeoTransform", type = "NC_CHAR", value = '-180 0.08333333333333333 0 90 0 -0.08333333333333333 ')


#### 5. BIOMASS VARIABLE ####

var.def.nc(nc, varname = "Biomass_relative", vartype = "NC_DOUBLE", dimensions = c("time", "aphiaid", "lat", "lon"))
att.put.nc(nc, variable = "Biomass_relative", name = "_FillValue", type = "NC_DOUBLE", value = -99999)
att.put.nc(nc, variable = "Biomass_relative", name = "long_name", type = "NC_CHAR", value = "Biomass relative change")

#### 6. DATA MAPPING ####

df<-read.csv("data/ss-dbem_data.csv")

#Mapping table: model code -> Aphiaid
codigo_a_aphiaid <- species_aphiaid.df[, c("Codigo", "aphiaid")]

# Join aphiaid
df <- df %>%
  left_join(codigo_a_aphiaid, by = c("specie" = "Codigo"))

# Validation: no missing aphiaid
n_sin_mapeo <- sum(is.na(df$aphiaid))
if (n_sin_mapeo > 0) {
  stop(glue("ERROR: {n_sin_mapeo} rows do not have an assigned AphiaID. Check the mapping Code → AphiaID."))
} else {
  cat("OK: All rows have an assigned aphiaid.\n")
}

#### 7. INDEXING AND ARRAY CREATION ####

df <- df %>%
  mutate(
    lon_i = match(Lon,     lon),            
    lat_i = match(Lat,     lat),            
    t_i   = match(year,    2030:2100),      
    s_i   = match(aphiaid, aphiaid_sorted)  
  )

# Check: No index should be NA
stopifnot("lon_i has NAs - Some Lon value is not in the lon dimension" = !any(is.na(df$lon_i)))
stopifnot("lat_i has NAs - Some Lat value is not in the lat dimension" = !any(is.na(df$lat_i)))
stopifnot("t_i has NAs - Some year is outside the 2030-2100 range"              = !any(is.na(df$t_i)))
stopifnot("s_i has NAs - Some aphiaid is not found in the mapping table" = !any(is.na(df$s_i)))

cat("OK: All indices calculated correctly.\n")

# Create 4D array
biomass_array <- array(
  NA_real_,
  dim = c(length(2030:2100), length(aphiaid_sorted), length(lat), length(lon))
)

# Fill array
idx <- cbind(df$t_i, df$s_i, df$lat_i, df$lon_i)
biomass_array[idx] <- df$change_smooth

# Validation: consistency check
cat("Rows in csv:            ", nrow(df), "\n")
cat("Values written:", sum(!is.na(biomass_array)), "\n")

if (nrow(df) != sum(!is.na(biomass_array))) {
  warning("Warning: number of values does not match. Duplicates may exist.")
}


#### 8. WRITE DATA TO NETCDF
var.put.nc(
  nc,
  variable = "Biomass_relative",
  data     = biomass_array,
  start    = rep(1, 4),
  count    = dim(biomass_array)
)


#### 9. GLOBAL ATTRIBUTES ####

attributes <- list(
  title = "SS-DBEM fish projections under climate and fishing scenarios",
  summary = "SS-DBEM projections for eighteen species under RCP8.5, biogeochemical ensemble model and FMSY (Fishing Maximum Sustainable Yield). Ensemble change fields were winsorized to limit extreme outliers and transformed using a signed log (log1p) to accommodate negative and zero values. Spatial patterns were then smoothed using a 15x15 cell moving average (terra::focal) to reduce grid-scale noise while preserving large-scale trends",  
  Conventions = "CF-1.9",
  # id = "",
  naming_authority = "emodnet-biology.eu",
  history = "2026-05-27 07:10:00Z: Created initial biomass dataset in R.
2026-05-28 09:22:00Z: Calculated moving average of biomass using data.table::frollmean().
2026-05-28 09:30:00Z: Computed relative change of biomass based on the moving average.
2026-05-28 09:42:00Z: Added derived variables 'biomass_ma' (moving average) and 'biomass_rel_change' (relative change).
2026-05-28 10:05:00Z: Updated metadata to comply with CF-1.9 conventions.
2026-05-28 10:30:00Z: Saved final NetCDF using R (ncdf4).",
  source = "",
  # processing_level = "",
  # comment = "", 
  #acknowledgment = "",
  standard_name_vocabulary = "CF Standard Name Table v90",
  date_created = as.character(Sys.Date()),
  creator_name = "Asier Anabitarte",
  creator_email = "aanabitarte@azti.es",
  creator_url = "www.azti.es",
  institution = "AZTI, Marine research, Basque Research and Technology Alliance (BRTA)",
  project = "CINEA/EMFAF/2022/3.5.2/SI2.895681", 
  publisher_name = "EMODnet-Biology",                 
  publisher_email = "bio@emodnet.eu",                
  publisher_url = "https://emodnet.ec.europa.eu/en/biology",                  
  # geospatial_bounds = "",              
  # geospatial_bounds_crs = "",          
  # geospatial_bounds_vertical_crs = "", 
  geospatial_lat_min = min(lat),
  geospatial_lat_max = max(lat),
  geospatial_lon_min = min(lon),
  geospatial_lon_max = max(lon),
  # geospatial_vertical_min = "",        
  # geospatial_vertical_max = "",        
  # geospatial_vertical_positive = "",  
  # time_coverage_start = "1911",            
  # time_coverage_end = "2016",              
  # time_coverage_duration = "",         
  # time_coverage_resolution = "",       
  # uuid = "",                           
  # sea_name = "",                       
  # creator_type = "",                   
  creator_institution = "AZTI, Marine research, Basque Research and Technology Alliance (BRTA)",            
  # publisher_type = "",                 
  publisher_institution = "Flanders Marine Institute (VLIZ)",        
  # program = "",                        
  # contributor_name = "",               
  # contributor_role  = "",              
  geospatial_lat_units = "degrees_north",           
  geospatial_lon_units = "degrees_east",           
  # geospatial_vertical_units   = "",    
  # date_modified = "",               
  # date_issued = "",                    
  # date_metadata_modified   = "",       
  # product_version = "",            
  # keywords_vocabulary = "",          
  # platform  = "",              
  # platform_vocabulary = "",          
  # instrument = "",          
  # instrument_vocabulary  = "",        
  # featureType = "Point",                  
  # metadata_link = "",                  
  references = "Fernandes, J. A., Cheung, W. W., Jennings, S., Butenschön, M., de Mora, L., Frölicher, T. L., ... & Grant, A. (2013). Modelling the effects of climate change on the distribution and production of marine fishes: accounting for trophic interactions in a dynamic bioclimate envelope model. Global change biology, 19(8), 2596-2607",
  comment = "Uses attributes recommended by http://cfconventions.org",
  license = "CC-BY", 
  publisher_name = "EMODnet Biology Data Management Team",
  citation = "Anabitarte, A., Granado, I., Valle, M., Erauskin-Extramiana, M., & Fernandes-Salvador, J. A. (2026). SS-DBEM ensemble projections of 18 North Atlantic fish species under IPCC AR6 RCP 8.5 climate and MSY fishing scenario",
  acknowledgment = "European Marine Observation Data Network (EMODnet) Biology project CINEA/EMFAF/2022/3.5.2/SI2.895681, funded by the European Union under Regulation (EU) No 508/2014 of the European Parliament and of the Council of 15 May 2014 on the European Maritime and Fisheries Fund"
)

# Define function that detects if the data type should be character of 
# integer and add to global attributes
add_global_attributes <- function(nc, attributes){
  
  stopifnot(is.list(attributes))
  
  for(j in 1:length(attributes)){
    if(is.character(attributes[[j]])){
      type <- "NC_CHAR"
    }else if(is.numeric(attributes[[j]])){
      type <- "NC_DOUBLE"
    }
    att.put.nc(nc, variable = "NC_GLOBAL", name = names(attributes[j]), type = type, value = attributes[[j]])
  }
  sync.nc(nc)
}

# Add attributes
add_global_attributes(nc, attributes)


#### 10. FINALIZE FILE ####
sync.nc(nc)
print.nc(nc)

close.nc(nc)





