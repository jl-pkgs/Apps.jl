includet("Z:/GitHub/jl-pkgs/apps.jl/Hydro/snap_pour_points.jl")
includet("Z:/GitHub/jl-pkgs/apps.jl/Hydro/TauDEM.jl")
includet("Z:/GitHub/jl-pkgs/apps.jl/Hydro/snap_vis.jl")

## Step1: snap pour points =====================================================
@time ra_accu = rast("data-raw/merit_Hunan_flowaccu.tif")
st = fread("data-raw/st_湖南-其他131.csv")

## 这94个passed，余37个
begin
  options = Dict(
    "高塘岭" => (; order_by=[:bias_abs]),
    "韶山" => (; order_by=[:bias_abs]),
    "梅桥" => (; order_by=[:bias_abs]),
    "白溪" => (; perc_max=1.08),
    "南阳嘴" => (; win_half=50),
  )
  @time lst, info = main_snap(ra_accu, st; kw..., options)
  plot_snap(lst[inds], info[inds, :]; inspector=true)
end

inds_good = info[info.bias_abs.<=10, :id]
inds_bad = setdiff(1:nrow(info), inds_good)

inds = inds_good
fig = plot_snap(lst[inds], info[inds, :]; inspector=false)
save("FigureS1_湖南_Pour131_good.png", fig)

inds = inds_bad
fig = plot_snap(lst[inds], info[inds, :]; inspector=false)
save("FigureS1_湖南_Pour131_bad.png", fig)


## 保存结果
fout = "data/shp/Pour_Hunan_sp131_adjusted.csv"
fout_shp = gsub(fout, ".csv", ".shp")

fwrite(info, fout)
df2sf(info, fout_shp; coords=["lon_adj", "lat_adj"])


## Step2: 流域边界提取 ==========================================================
# flowdir = "./raster/ChangJiang_flowdir_taudem.tif"
flowdir = "Z:/GitHub/jl-pkgs/apps.jl/data-raw/merit_Hunan_flowdir_taudem.tif"
pour = "data/shp/Pour_Hunan_sp131_adjusted.shp"
basin = "data/shp/湖南基本站_basins131_v20250414.shp"
fout = "./OUTPUT/watershed_basins131.tif"

watershed(flowdir, pour; fout)
watershed_rast2poly(fout, basin)
tidy_basins(basin, pour) # 提取得到最终流域
