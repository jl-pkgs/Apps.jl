pacman::p_load(
  Ipaper, dplyr, data.table,
  data.tree, DiagrammeR, sf, sf2
)

tree_depth <- function(self) {
  if (isLeaf(self)) {
    1
  } else {
    ans <- sapply(self$children, tree_depth) %>% max()
    ans + 1
  }
}

# 寻找孤儿节点
TreeDepth <- function(tree) {
  ids <- tree$Get("name")
  depths <- tree$Get("depth") # not used
  n <- length(ids)
  data.table(grid = as.integer(ids[2:n]), depth = depths[2:n]) %>%
    arrange(grid)
}

# 奠定数据基础
find_children <- function(df, root = 0) {
  children <- df[iddown == root, id] %>% unique()
  n <- length(children)
  # print(root)
  if (n > 0) {
    l <- list()
    for (i in 1:n) {
      l[[i]] <- find_children(df, root = children[i])
    }
    l <- set_names(l, children)
    return(l)
  } else {
    return(list())
  }
}

# df <- fread(file_basinId)
# lst <- find_children(root = -1, df)

#' plot_tree
#'
#' @param info A data.table with the column of `["id", "iddown", "name"]`
#' @param title The title of the tree
#'
#' @export
plot_StreamNet <- function(info, title = "", fout = "tree.pdf", show = FALSE, root = 0) {
  # df <- fread(file_basinId)
  lst <- find_children(info, root = root)

  tree <- FromListSimple(lst)
  tree$Do(function(node) node$depth <- tree_depth(node))

  ids <- tree$Get("name")
  # depths <- tree$Get("depth") # not used

  names <- info$name[match(ids, info$id)] # 设置站点名
  names[ids == "Root"] <- title

  tree$Set(site = names)
  tree$Set(label = sprintf("%s\r\n%s", ids, names)) # 设置显示格式

  SetNodeStyle(tree, label = \(node) node$label, style = "filled,rounded")
  Do(tree$leaves, \(node) SetNodeStyle(node,
    inherit = FALSE, shape = "box", fillcolor = "GreenYellow"
  ))

  DiagrammeR::export_graph(tree %>% ToDiagrammeRGraph(dir = "descend"), file_name = fout)
  if (show) file.show(fout)
  tree
}


# 修复嵌套的流域边界
#' basins_merge_StreamNet
#'
#' @param ID the ID of basins
#' @param shp basin shapefile, sf polygon object
#' @param tree returned by [plot_StreamNet()]
#' @param outdir outdir of shapefile
#' @param prefix prefix of shapefile
#'
#' @export
basins_merge_StreamNet <- function(ID, basins, tree) {
  x <- FindNode(tree, ID)
  name <- x$Get("site")[1]
  ids <- x$Get("name") # ids = ID, 所有的下属节点
  shp_sub <- subset(basins, grid %in% ids) %>% mutate(grid = ID)
  sf2::st_dissolve(shp_sub) #%>% write_shp(outfile)
}

## 合并含有嵌套关系的流域
basins_merge <- function(basins, tree) {
  d_depth <- TreeDepth(tree)
  grids_multi <- d_depth[depth != 1, grid]

  basins1 <- basins %>% subset(grid %in% d_depth[depth == 1, grid])

  # 只修复含有嵌套关系的流域
  basins2_fix <- llply(grids_multi, \(ID) basins_merge_StreamNet(ID, basins, tree)) %>%
    do.call(rbind, .)
  
  basins2 <- basins[match(grids_multi, basins$grid), ]
  basins2$geometry <- basins2_fix$geometry

  rbind(basins1, basins2) %>%
    arrange(grid) %>%
    st_make_valid() %>%
    rename(id = grid)
}

basins_addInfo <- function(basins, st) {
  left_join(basins, st, by = "id") %>%
    relocate(geometry, .after = last_col()) %>%
    mutate(
      area_cal = st_area2(basins) / 1e6,
      perc_err = round((area_cal - area_obs) / area_obs * 100, 2),
      .after = area_obs
    )
}

#' @param pour has columns of `id`, `name` and `area_obs`
tidy_basins <- function(f_basin, f_pour) {
  fout <- gsub(".shp$", "_final.shp", f_basin)
  fig <- gsub(".shp$", ".pdf", f_basin)

  d_pour <- read_sf(f_pour) %>% as.data.table()
  st <- select(d_pour, id, name, area_obs) # 预期流域面积

  d_net <- fread("./OUTPUT/basinId.txt")
  info <- merge(st, d_net, by = "id")
  tree <- plot_StreamNet(info, "Root", fout = fig, root = 0)

  basins <- read_sf(f_basin)
  basins_final <- basins_merge(basins, tree) %>% basins_addInfo(st)

  err <- basins_final$perc_err %>% abs()
  inds_bad <- which(err >= 10) # 误差大于10%的流域
  print(basins_final[inds_bad, ])

  write_shp(basins_final, fout)
}
