## 站点保存为shapefile
import Ipaper: sf
import Ipaper.sf: write_sf
using Shapefile


function sf.write_sf(x::DataFrame, f::AbstractString)
  Shapefile.write(f, x; force=true) # default is 
  prj = """
  GEOGCS["GCS_WGS_1984", DATUM["D_WGS_1984", SPHEROID["WGS_1984", 6378137.0, 298.257223563]], PRIMEM["Greenwich", 0.0], UNIT["Degree", 0.0174532925199433]]
  """
  f_prj = gsub(f, ".shp", ".prj")
  open(f_prj, "w") do fid
    write(fid, prj)
    # write(fid, "\n")
  end
  nothing
end

# function df2sf(st::DataFrame, coords=["lon", "lat"])
#   mat = Matrix(st[:, coords])
#   points = [Shapefile.Point(x[1], x[2]) for x in eachrow(mat)]
#   d_coord = DataFrame(geometry=points)
#   cbind(st[!, Not(coords)], d_coord)
# end


## R语言版本
using RCall
function df2sf(st, fout::AbstractString; coords=["lon", "lat"])
  R"""
  sp = sf2::df2sf($st, $coords)
  sf2::write_shp(sp, $fout)
  """
  nothing
end

# points = df2sf(info, ["Lon", "Lat"])
# write_sf(points, fout_shp)
