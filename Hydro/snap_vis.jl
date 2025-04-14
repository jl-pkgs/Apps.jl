### Visualization ==============================================================
# 进行绘图
using Printf
import MakieLayers: imagesc!
using GLMakie, MakieLayers

function imagesc!(fig, ra::SpatRaster; kw...)
  lon, lat = st_dims(ra)
  ax, plt = imagesc!(fig, lon, lat, ra.A; kw...)
  rm_ticks!(ax)
  ax, plt
end

function plot_snap_site(fig, r; title="")
  ax, plt = imagesc!(fig, r.rast; title,
    colorrange=(0, 2))
  # force_show_legend=true

  scatter!(ax, r.pour; markersize=12, color=:red)
  scatter!(ax, r.pour_adj; markersize=12, color=:green)
  return ax, plt
end
# info2 = deepcopy(info)
# sort!(info2, [order(:bias_abs, rev=true), :dist])

function plot_snap(lst, info; inspector=false)
  # titles = info.Name
  titles = map(i -> begin
      r = info[i, :]
      @sprintf("%s (%.1f%%)", r.name, r.bias_abs)
    end, 1:nrow(info)) # Bias%% = 

  nx = ceil(Int, sqrt(nrow(info)))
  ny = ceil(Int, nrow(info) / nx)
  
  fig = Figure(; size=(1400, 800))
  plt = nothing
  axs = []

  for i in 1:nx, j in 1:ny
    k = (i - 1) * ny + j
    r = lst[k]
    ax, _plt = plot_snap_site(fig[i, j], r)
    push!(axs, ax)
    k == 1 && (plt = _plt)
  end

  text_rel!(axs, titles, 0.02, 1; align=(0, 1))
  gap = (2, 2, 15)
  rowgap!(fig.layout, gap[1])
  colgap!(fig.layout, gap[2])

  cbar = Colorbar(fig[1:nx, ny+1], plt; width=30)
  # set_colgap(fig, ncol, cgap)
  
  inspector && DataInspector(fig)
  fig
end
