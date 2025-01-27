library(terra)

ndvi_files <- list.files('~/Documents/1_dtw/scenes/NDVI Limari/',
                         full.names = T)

scl_files <- list.files('~/Documents/1_dtw/scenes/SCL Limari/',
                        full.names = T)

# for ndvi
file_doy <- gsub(pattern = '.*ndvi_',
                 replacement = '',
                 x = ndvi_files)

file_date <- gsub(pattern = '.tif',
                  replacement = '',
                  x = file_doy)

file_date <- as.Date(file_date,
                     format = '%Y-%j')

# for scl
scl_doy <- gsub(pattern = '.*scl_',
                replacement = '',
                x = scl_files)

scl_date <- gsub(pattern = '.tif',
                 replacement = '',
                 x = scl_doy)

scl_date <- as.Date(scl_date,
                    format = '%Y-%j')

polys <- vect('~/Documents/1_dtw/vectors/zones.shp')

r_log <- list()

for(i in seq_along(ndvi_files)){
  r <- rast(ndvi_files[i])
  scl <- rast(scl_files[i])
  
  r_log[[i]] <- list()
  
  for(j in seq_along(polys)){
    poly <- polys[j,]
    
    id_name <- sprintf("%03d",
                       poly$id)
    
    r_crop <- crop(r, poly)
    scl_crop <- crop(scl, poly)
    
    total_cells <- ncell(scl_crop)
    cloud_high <- round(sum(values(scl_crop == 9))/total_cells,3)
    cloud_med <- round(sum(values(scl_crop == 8))/total_cells,3)
    cirrus <- round(sum(values(scl_crop == 10))/total_cells,3)
    
    
    
    if(cloud_high > 0.01 | cloud_med > 0.05 | cirrus >= 0.1){
      decision <- 'out'
    }else{
      
      decision <- 'in'
      
      fname <- paste0('~/Documents/1_dtw/scenes/NDVI cropped/',
                      id_name,
                      '_ndvi_',
                      file_date[i],
                      '.tif')
      
      writeRaster(r_crop,
                  fname,
                  gdal=c("COMPRESS=LZW"),
                  overwrite = TRUE)
    }
    
    r_log[[i]][[j]] <- data.frame(filename = paste0('ndvi_',
                                                    file_doy[i]),
                                  date = file_date[i],
                                  zone_id = id_name,
                                  cloud_high = cloud_high,
                                  cloud_med = cloud_med,
                                  cirrus = cirrus,
                                  decision = decision)
  }
  
  r_log[[i]] <- do.call(rbind.data.frame,r_log[[i]])
  
  print(paste0('Scene: ',file_doy[i], ' done'))
}

r_summary <- do.call(rbind.data.frame, r_log)

r_summary <- r_summary[order(r_summary$date),]

write.csv(r_summary, '~/Documents/1_dtw/results/ndvi_clouds.csv')