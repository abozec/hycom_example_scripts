#!/bin/csh
#
set echo
#
# --- output is netCDF.
# --- this is an example, customize it for your datafile needs.
#

touch regional.depth.a regional.depth.b
if (-z regional.depth.a) then
  /bin/rm regional.depth.a
  /bin/ln -s ../topo/depth_ATLb2.00_01.a regional.depth.a
endif
if (-z regional.depth.b) then
  /bin/rm regional.depth.b
  /bin/ln -s ../topo/depth_ATLb2.00_01.b regional.depth.b
endif
#
touch regional.grid.a regional.grid.b
if (-z regional.grid.a) then
  /bin/rm regional.grid.a
  /bin/ln -s ../topo/regional.grid.a regional.grid.a
endif
if (-z regional.grid.b) then
  /bin/rm regional.grid.b
  /bin/ln -s ../topo/regional.grid.b regional.grid.b
endif
#
# --- optional title and institution.
#
setenv CDF_TITLE        "HYCOM ATLb2.00"
#setenv CDF_INST        "RSMAS"
setenv CDF_INST         "Naval Research Laboratory"
#
# --- D,y,d select the archive files.
#
setenv D ../expt_01.7/data/tarv_001
setenv O ../expt_01.7/data/netcdf
setenv E 017
setenv y 0001
setenv d 16
while ($d < 17)
    setenv d1 `echo $d | awk '{printf("%03d", $1)}'`
    foreach h ( 00 )
   setenv CDF030  ${O}/${E}_archv.${y}_${d1}_ssh.nc
   setenv CDF031  ${O}/${E}_archv.${y}_${d1}_3du.nc
   setenv CDF032  ${O}/${E}_archv.${y}_${d1}_3dv.nc
   setenv CDF033  ${O}/${E}_archv.${y}_${d1}_3dthk.nc
   setenv CDF034  ${O}/${E}_archv.${y}_${d1}_3dt.nc
   setenv CDF035  ${O}/${E}_archv.${y}_${d1}_3ds.nc
   setenv CDF036  ${O}/${E}_archv.${y}_${d1}_3dr.nc
    /bin/rm $CDF030  $CDF031  $CDF032 $CDF033 $CDF034 $CDF035 $CDF036
    ~/hycom/ALL2/archive/src/archv2ncdf2d  <<E-o-D
${D}/${E}_archv.${y}_${d1}_${h}.a
netCDF
000     'iexpt ' = experiment number x10 (000=from archive file)
  1     'yrflag' = days in year flag (0=360J16,1=366J16,2=366J01,3-actual)
 57     'idm   ' = longitudinal array size
 52     'jdm   ' = latitudinal  array size
 22     'kdm   ' = number of layers
 25.0   'thbase' = reference density (sigma units)
  0     'smooth' = smooth fields before plotting (0=F,1=T)
  0     'mthin ' = mask thin layers from plots   (0=F,1=T)
  1     'iorign' = i-origin of plotted subregion
  1     'jorign' = j-origin of plotted subregion
  0     'idmp  ' = i-extent of plotted subregion (<=idm; 0 implies idm)
  0     'jdmp  ' = j-extent of plotted subregion (<=jdm; 0 implies jdm)
  0     'botio ' = bathymetry       I/O unit (0 no I/O)
  0     'flxio ' = surf. heat flux  I/O unit (0 no I/O)
  0     'empio ' = surf. evap-pcip  I/O unit (0 no I/O)
  0     'ttrio ' = surf. temp trend I/O unit (0 no I/O)
  0     'strio ' = surf. saln trend I/O unit (0 no I/O)
  0     'icvio ' = ice coverage     I/O unit (0 no I/O)
  0     'ithio ' = ice thickness    I/O unit (0 no I/O)
  0     'ictio ' = ice temperature  I/O unit (0 no I/O)
  30    'sshio ' = sea surf. height I/O unit (0 no I/O)
  0     'bsfio ' = baro. strmfn.    I/O unit (0 no I/O)
  0     'uvmio ' = mix. lay. u-vel. I/O unit (0 no I/O)
  0     'vvmio ' = mix. lay. v-vel. I/O unit (0 no I/O)
  0     'spmio ' = mix. lay. speed  I/O unit (0 no I/O)
  0     'bltio ' = bnd. lay. thick. I/O unit (0 no I/O)
  0     'mltio ' = mix. lay. thick. I/O unit (0 no I/O)
  0     'sstio ' = mix. lay. temp.  I/O unit (0 no I/O)
  0     'sssio ' = mix. lay. saln.  I/O unit (0 no I/O)
  0     'ssdio ' = mix. lay. dens.  I/O unit (0 no I/O)
-1      'kf    ' = first output layer (=0 end output; <0 label with layer #)
  30    'kl    ' = last  output layer
  31    'uvlio ' = layer k   u-vel. I/O unit (0 no I/O)
  32    'vvlio ' = layer k   v-vel. I/O unit (0 no I/O)
  0     'splio ' = layer k   speed. I/O unit (0 no I/O)
  0     'wvlio ' = layer k   w-vel. I/O unit (0 no I/O)
  33    'infio ' = layer k   i.dep. I/O unit (0 no I/O)
  0     'thkio ' = layer k   thick. I/O unit (0 no I/O)
  34    'temio ' = layer k   temp   I/O unit (0 no I/O)
  35    'salio ' = layer k   saln.  I/O unit (0 no I/O)
  36    'tthio ' = layer k   dens,  I/O unit (0 no I/O)
  0     'sfnio ' = layer k  strmfn. I/O unit (0 no I/O)
  0     'kf    ' = first output layer (=0 end output; <0 label with layer #)
E-o-D
end
    set d=`expr $d + 1`
  end
