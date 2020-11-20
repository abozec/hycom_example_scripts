#!python3
# plot results from HYCOM-BB86
import sys
import os
from os.path import join
### might not need next line in older or newer version of proplot
os.environ['PROJ_LIB'] = '/Users/abozec/opt/anaconda3/share/proj'
import proplot as plot
import numpy as np

iodir='/Users/abozec/Documents/GitHub/BB86_PACKAGE/PYTHON/'
sys.path.append(iodir)
from hycom.info import read_field_names,read_field_grid_names
from hycom.io import read_hycom_fields, read_hycom_grid, sub_var2

## PATH
io = iodir+'../'
## size of the domain
idm = 101 ; jdm = 101  ## size of the domain

## Read depth
filet='depth_BB86_02_python.a'
ivar=1 ## record index 
bathy=sub_var2(io+'topo/'+filet,idm,jdm,ivar)

levels2=np.linspace(4000,5000,12)
fig, axs = plot.subplots(nrows=1,width='10cm')
axs[0].format(title='Bathymetry BB86')
m = axs[0].contourf(bathy, cmap='Mako', extend='max',levels=levels2)
fig.colorbar(m, loc='b')
plot.show()


