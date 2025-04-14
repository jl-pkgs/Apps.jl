using Ipaper, Ipaper.sf, ArchGDAL, Shapefile
using RTableTools, DataFrames
# using GLMakie, MakieLayers
include("main_sf.jl")

function snap_pour(point, ra_accu; win_half::Int=25,
  area_obs, 
  perc_min=0.7, perc_max=1.3,
  accu_min=1000, 
  order_by = [:dist], 
  name="", ignore...)

  cellsize = st_cellsize(ra_accu)
  _area = cellArea(point..., cellsize) # 单个网格面积
  accu_target = floor(Int, area_obs / _area) # 计算累积流个数

  lon, lat = st_dims(ra_accu)
  nlon, nlat = length(lon), length(lat)

  i, j = xy2ij(point, ra_accu)
  ii = max(i - win_half, 1):min(i + win_half, nlon)
  jj = max(j - win_half, 1):min(j + win_half, nlat)

  x, y = lon[ii], lat[jj]
  A = ra_accu.A[ii, jj]

  # This is a DataFrame
  d = array2df(A, (; lon_adj=x, lat_adj=y)) # value is accu
  d.perc = d.value / accu_target
  d.dist = earth_dist(point, Matrix(d[:, 1:2]))

  ## 如果找不到则，降低标准
  con = @. (d.value > accu_min && d.perc >= perc_min && d.perc <= perc_max)
  d2 = d[con, :]

  if (nrow(d2) == 0) 
    println("[w]: $name")
    perc_min = 0.3
    perc_max = 2 - perc_min
    con = @. (d.value > accu_min && d.perc >= perc_min && d.perc <= perc_max)
    d2 = d[con, :]
  end
  d2.target .= accu_target
  d2.area_obs .= area_obs
  d2.bias_abs .= round.(abs.(d2.perc .- 1) .* 100, digits=2)

  # info = d2[sortperm(d2.dist), :]
  info = sort(d2, order_by)  
  info = info[:, Cols(:lon_adj, :lat_adj, :area_obs, :value, :target, :perc, :bias_abs, 1:end)]

  lon_adj, lat_adj = info[1, 1:2]
  (; rast=rast(A ./ accu_target, st_bbox(x, y)),
    pour=point,
    pour_adj=(lon_adj, lat_adj),
    info=info[1:1, :])
end

"""
    所有站点批量处理

## Arguments
- `st`: with the columns of `Lon`, `Lat` and `area`
- `kw`: others to snap_pour, like `bias_max`
- `options`: 部分站点的特殊设置

```julia
options = Dict(
  "红岩溪" => (; perc_min = 0.6, perc_max = 1.3)
)
```

## Return
- `rast`     : 
- `pour`     : (x, y)
- `pour_adj` : (x_adj, y_adj)
- `info`     : detailed info about adjusted pour points
"""
function main_snap(ra_accu, st; options = Dict(), kw...)
  sites_option = keys(options) |> collect

  lst = map(k -> begin
      origin = st.lon[k], st.lat[k]
      name = st.name[k]
      area_obs = st.area[k]
      _kw = kw
      name in sites_option && (_kw = options[name])
      
      r = snap_pour(origin, ra_accu; area_obs, name,  _kw...)
    end, 1:nrow(st))

  info = vcat(map(r -> r.info, lst)...)
  info = cbind(; st, info)
  lst, info
end
