# import Ipaper.sf: read_sf, write_sf
using Ipaper, Ipaper.sf, ArchGDAL, Shapefile
import Ipaper.sf: watershed, watershed_rast2poly

"""
    watershed(flowdir, pour; fout="./OUTPUT/watershed.tif", basin_id="./OUTPUT/basinId.txt")

```bash
gagewatershed -p fflowdir -o f_pour -gw watershed.tif -id basinId_十堰.txt
```

```julia
using Ipaper, Ipaper.sf, Shapefile, ArchGDAL
watershed(flowdir, pour; fout="./OUTPUT/watershed.tif", basin_id="./OUTPUT/basinId.txt")
watershed_rast2poly("")
```
"""
function watershed(flowdir, pour; fout="./OUTPUT/watershed.tif", basin_id="./OUTPUT/basinId.txt")
  check_dir(dirname(fout))
  check_dir(dirname(basin_id))
  
  run(`gagewatershed -p $flowdir -o $pour -gw $fout -id $basin_id`)
  nothing
end


function watershed_rast2poly(tif::String, f_basin::String)
  gdal_polygonize(tif, f_basin)
  basins_dissolve_grid(f_basin)
  # shp = read_sf(f_basin)
  # shp2 = shp[shp.data.grid.>=0, :]
  # if size(shp) != size(shp2)
  #   write_sf(f_basin, shp2; force=true)
  # end
end


## 合并相同grid的流域
using RCall

function basins_dissolve_grid(f_basin::String)
  R"""
  library(sf)
  library(sf2)
  library(dplyr)

  shp = read_sf($f_basin)
  shp2 = subset(shp, grid >= 0) |> sf2::st_dissolve() |> arrange(grid)
  if (nrow(shp) != nrow(shp2)) {
    write_sf(shp2, $f_basin, overwrite=TRUE) 
  }
  """
  nothing
end


## 检查流域提取结果
function tidy_basins(basin, pour)
  R"""
  source("Z:/GitHub/jl-pkgs/apps.jl/Hydro/Basins_StreamNet.R")
  tidy_basins($basin, $pour)
  """
  nothing
end

export watershed, watershed_rast2poly
# gdal_polygonize.py watershed_${region}.tif shed_${region}.shp shape
