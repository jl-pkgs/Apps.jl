includet("Z:/GitHub/jl-pkgs/apps.jl/Hydro/snap_pour_points.jl")
includet("Z:/GitHub/jl-pkgs/apps.jl/Hydro/TauDEM.jl")
includet("Z:/GitHub/jl-pkgs/apps.jl/Hydro/snap_vis.jl")

## Step1: snap pour points =====================================================
@time ra_accu = rast("data-raw/merit_Hunan_flowaccu.tif")
st = fread("data-raw/湖南-基本站64.csv")

kw = (; perc_min=0.7, perc_max=1.3)
options = Dict(
  "红岩溪" => (; perc_min=0.6, perc_max=2.0)
)
lst, info = main_snap(ra_accu, st; options)

## 绘图展示
plot_snap(lst, info; inspector=true)
save("FigureS1_湖南_Pour64.png", fig)

## 保存结果
fout = "data/shp/Pour_Hunan_sp64_adjusted.csv"
fout_shp = gsub(fout, ".csv", ".shp")

fwrite(info, fout)
df2sf(info, fout_shp; coords=["lon_adj", "lat_adj"])

## Step2: 流域边界提取 ==========================================================
# flowdir = "./raster/ChangJiang_flowdir_taudem.tif"
flowdir = "Z:/GitHub/jl-pkgs/apps.jl/data-raw/merit_Hunan_flowdir_taudem.tif"
pour = "data/shp/Pour_Hunan_sp64_adjusted.shp"
basin = "data/shp/湖南基本站_basins64_v20250414.shp"
fout = "./OUTPUT/watershed_V2.tif"

watershed(flowdir, pour; fout)
watershed_rast2poly(fout, basin)
tidy_basins(basin, pour) # 提取得到最终流域
