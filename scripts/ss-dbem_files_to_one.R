############################################################
#  SS-DBEM files to one file
#
#  Author: Asier Anabitarte
#  Institution: AZTI
#  Date: 2026
#
#  Description:
# This script processes SS-DBEM model outputs and compiles them 
# into a unified dataset for the North Atlantic. It filters species, 
# extracts metadata from filenames, calculates moving averages and 
# baseline references, removes land cells, computes relative changes, 
# and generates an ensemble mean across climate models
#
#  Workflow:
#  1. Input data and parameters
#  2. Spatial filtering
#  3. Species selection
#  4. File discovery and filtering
#  5. Data loading and compilation
#  6. Temporal processing
#  7. Land masking
#  8. Relative change calculation
#  9. Model ensemble computation
#  10. Data transformation and smoothing
#  11. Output generation
#
# Output:
# A processed CSV file containing ensemble biomass projections for marine species, 
# including relative change (%), log-transformed values, and spatially smoothed outputs 
# for the North Atlantic (2030–2100).
############################################################


#### 0. LIBRARIES ####
library(tidyverse)
library(data.table)
library(terra)
library(sf)

#### 1. INPUT DATA AND PARAMETERS ####
coords_path <- "data/Lat_Lon.csv"

species_csv_path <- "data/species.csv"

root_results <- "data/raw_data/"


#### 2. SPATIAL FILTERING ####

coords_all <- read_csv(coords_path, show_col_types = FALSE) %>%
  rename(cell = Cell)

cells_keep <- coords_all %>%
  filter(!is.na(Lat), !is.na(Lon),
         Lat >= 0, Lat <= 80,
         Lon >= -80, Lon <= 15) %>%
  pull(cell)

coords_join <- coords_all %>%
  filter(cell %in% cells_keep) %>%
  select(cell, Lon, Lat)

#### 3. SPECIES SELECTION ####
species_df <- read_csv2(species_csv_path, show_col_types = FALSE)


candidate_cols <- c("specie", "SpeciesCode", "species_code", "code",
                    "species", "sp", "especie", "Codigo", "codigo")

species_keep <- species_df %>%
  pull(all_of(Codigo)) %>%
  as.character() %>%
  trimws() %>%
  unique()

#### 4. FILE DISCOVERY AND FILTERING ####

todas_las_carpetas <- list.dirs(root_results, full.names = TRUE, recursive = FALSE)

carpetas_filtradas <- todas_las_carpetas[grepl("RCP8.5", todas_las_carpetas) & grepl("1.0FMSY", todas_las_carpetas)]
  

files_all <- list.files(
  carpetas_filtradas,
  pattern = ".*CompetitionBio.*\\.txt$",
  recursive = TRUE, full.names = TRUE
)




extract_spec_from_file <- function(path) {
  sub(".*FMSY[/\\\\]([^/\\\\]+?)Compe.*", "\\1", path)
}

files_dt <- data.table(
  file   = files_all,
  specie = vapply(files_all, extract_spec_from_file, FUN.VALUE = character(1))
)

files_sp <- files_dt[specie %chin% species_keep, file]


#### 5. DATA LOADING AND COMPILATION ####

mat <- rbindlist(lapply(files_sp, function(file) {
  tmp <- fread(file)
  tmp <- tmp[cells_keep]
  
  data.table(
    coords_join,
    "specie" = gsub(".*FMSY[/\\\\]([^/\\\\]+?)Compe.*", "\\1", file),
    "rcp"    = gsub(".*RCP(.+?)_.*", "\\1", file),
    "model"  = gsub(".*(GFDL|IPSL|MPII).*", "\\1", file),
    "fmsy"   = gsub(".*_(.+?)FMSY.*", "\\1", file),
    "year"   = as.numeric(gsub(".*Bio(.+?)\\.txt$", "\\1", file)),
    "Biomass" = tmp$V1
  )
}))


setorder(mat, specie, cell, rcp, model, fmsy, year)


#### 6. TEMPORAL PROCESSING (Moving average & Ref. period) ####

mat[, MovAvg := frollmean(Biomass, n = 10, align = "right"),
    by = c("specie", "cell", "rcp", "model", "fmsy")]


ref_year <- 2025:2030
ref <- mat[year %in% ref_year,
           .(ref = mean(Biomass, na.rm = TRUE)),
           by = c("specie", "cell", "rcp", "model", "fmsy")]

mat <- mat[ref, on = c("specie", "cell", "rcp", "model", "fmsy")]


#### 7. LAND MASKING ####

land <- vect("data/ne_10m_land.shp")

ext_pts <- ext(
  min(mat$Lon), max(mat$Lon),
  min(mat$Lat), max(mat$Lat))

land_crop <- crop(land, ext_pts)


resol <- 0.5   # Adjust to your current grid

r <- rast(ext(land_crop), resolution = resol)

land_r <- rasterize(land_crop, r, field = 1)



n <- nrow(mat)
chunk_size <- 1e6   # adjustable

idx <- split(1:n, ceiling((1:n)/chunk_size))

cat("Total chunks:", length(idx), "\n")

res_list <- vector("list", length(idx))



for(i in seq_along(idx)) {
  
  cat("Chunk", i, "de", length(idx), "\n")
  
  sub <- mat[idx[[i]], ]
  
  pts <- vect(sub[, c("Lon", "Lat")], 
              geom = c("Lon", "Lat"), 
              crs = "EPSG:4326")
  
  vals <- extract(land_r, pts)
  
  if(i == 1) {
    cat("Check values:\n")
    print(table(is.na(vals[,2])))
    
    # plot diagnóstico
    plot(land_r, main = "Check clasification")
    points(pts, 
           col = ifelse(is.na(vals[,2]), "blue", "red"),
           pch = 16, cex = 0.3)
    
    legend("bottomleft",
           legend = c("Sea", "Land"),
           col = c("blue", "red"),
           pch = 16)
  }
  
  res_list[[i]] <- sub[is.na(vals[,2]), ]
}

mat_notland <- do.call(rbind, res_list)

cat("Process completed\n")
cat("Original total:", nrow(mat), "\n")
cat("Total sea:", nrow(mat_notland), "\n")
cat("Total land:", nrow(mat) - nrow(mat_notland), "\n")

mat_sea<-mat_notland


#### 8. RELATIVE CHANGE CALCULATION ####
mat_sea[, change := 100 * ((MovAvg - ref) / (ref))]


mat_sea[, change := {
  x <- change
  x[!is.finite(x)] <- 0
  x
}]

#### 9. MODEL ENSEMBLE COMPUTATION ####
ens <- mat_sea[, .(
  MovAvg_ensemble = mean(MovAvg, na.rm = TRUE),  # opcional, referencia
  ref_ensemble    = mean(ref,    na.rm = TRUE),  # opcional, referencia
  change_ensemble = mean(change, na.rm = TRUE),  # media % cambio
  n_models        = sum(!is.na(change))          # nº modelos en la media
), by = .(specie, cell, Lon, Lat, rcp, fmsy, year)]

ens = ens[as.numeric(year) %in% 2030:2100] 

#### 10. DATA TRANSFORMATION AND SMOOTHING

q <- quantile(ens$change_ensemble, probs = c(0.01, 0.99), na.rm = TRUE)

ens[, change_w := pmin(pmax(change_ensemble, q[1]), q[2])]
ens[, log_change := sign(change_w) * log1p(abs(change_w))]

ens[, change_smooth := {
    r        <- rast(data.frame(x = Lon, y = Lat, z = log_change),
                     type = "xyz", crs = "EPSG:4326")
    r_smooth <- terra::focal(r, w = 25, fun = "mean", na.policy = "omit", na.rm = TRUE)
    extract(r_smooth, data.frame(x = Lon, y = Lat))[[2]]
  } , by = .(specie, year, rcp, fmsy)]

#### 11. OUTPUT GENERATION ####
fwrite(ens, file = "data/derived_data/ss-dbem_rcp8.5_modelensemble_fmsy.csv")
