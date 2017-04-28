#! /bin/csh
#

set echo
set time = 1
set timestamp
#
# --- Experiment ATLb2.00 - 14.X
# --- 22 layer HYCOM on 2.00 degree grid
#

#
# --- Set parallel configuration, see ../README/README.expt_parallel.
# --- NOMP = number of OpenMP threads, 0 for no OpenMP, 1 for inactive OpenMP
# --- NMPI = number of MPI    tasks,   0 for no MPI
#
  setenv NOMP 0
  setenv NMPI 0
  echo "NOMP is " $NOMP " and NMPI is " $NMPI
#
# --- R is region name.
# --- V is source code version number.
# --- T is topography number.
# --- K is number of layers.
# --- E is expt number.
# --- P is primary path.
# --- D is permanent directory.
# --- S is scratch   directory, must not be the permanent directory.
#
setenv R ATLc2.00
setenv V 2.2.18
setenv T 01
setenv K 22 
setenv E 017 
setenv P ${R}/expt_01.7/data
setenv D ~/HYCOM/hycom/$P
setenv S ~/HYCOM/hycom/$P/SCRATCH
setenv ST ~/HYCOM/hycom/${R}/tides
 

#
mkdir -p $S
cd       $S
#
# --- For whole year runs.
# ---   Y01 initial model year of this run.
# ---   YXX is the last model year of this run, and the first of the next run.
# ---   A and B are identical, typically blank.
# --- For part year runs.
# ---   A is this part of the year, B is next part of the year.
# ---   Y01 is the start model year of this run.
# ---   YXX is the end   model year of this run, usually Y01.
# --- For a few hour/day run
# ---   A   is the start day and hour, of form "dDDDhHH".
# ---   B   is the end   day and hour, of form "dXXXhYY".
# ---   Y01 is the start model year of this run.
# ---   YXX is the end   model year of this run, usually Y01.
# --- Note that these variables are set by the .awk generating script.
#
# 
setenv A ""
setenv B ""
setenv Y01 "001"
setenv YXX "002"
# 
echo "Y01 =" $Y01 "YXX = " $YXX  "A =" ${A} "B =" ${B}
#
# --- local input files.
#
if (-e ${D}/../${E}y${Y01}${A}.limits) then
  /bin/cp ${D}/../${E}y${Y01}${A}.limits limits
else
  echo "LIMITS" | awk -f ${D}/../${E}.awk y01=${Y01} ab=${A} >! limits
endif
cat limits
#
## blkdat.input
  /bin/cp ${D}/../blkdat.input blkdat.input
#
## partition file for MPI run
if ($NMPI != 0) then
  setenv NPATCH `echo $NMPI | awk '{printf("%03d", $1)}'`
  /bin/rm -f patch.input
  /bin/cp ${D}/../../topo/partit/depth_${R}_${T}.${NPATCH}  patch.input
endif

## open boundary files if needed
#  /bin/cp ${D}/../ports.input ports.input
#  /bin/cp ${D}/../lowfreq.input lowfreq.input

#  /bin/cp ${ST}/${E}/tidalports_p.input.notides_tpxtransp_gom8 tidalports_p.input
#  /bin/cp ${ST}/${E}/tidalports_v.input.notides_tpxtransp_gom8 tidalports_v.input


# --- pget, pput "copy" files between scratch and permanent storage.
# --- Can both be cp if the permanent filesystem is mounted locally.
#
    setenv pget /bin/cp
    setenv pput /bin/cp
#
# --- input files from file server.
#
## grid and bathymetry
touch regional.depth.a regional.depth.b
if (-z regional.depth.a) then
   ${pget} ${D}/../../topo/depth_${R}_${T}.a regional.depth.a &
endif
if (-z regional.depth.b) then
   ${pget} ${D}/../../topo/depth_${R}_${T}.b regional.depth.b &
endif
#
touch regional.grid.a regional.grid.b
if (-z regional.grid.a) then
   ${pget} ${D}/../../topo/regional.grid.a regional.grid.a &
endif
if (-z regional.grid.b) then
   ${pget} ${D}/../../topo/regional.grid.b regional.grid.b &
endif
#
#
# --- Climatological atmospheric forcing.
#
  setenv FN coads
  touch forcing.tauewd.a forcing.taunwd.a forcing.wndspd.a forcing.ustar.a
  touch forcing.radflx.a forcing.shwflx.a forcing.vapmix.a forcing.precip.a
  touch forcing.airtmp.a forcing.seatmp.a forcing.surtmp.a
  touch forcing.tauewd.b forcing.taunwd.b forcing.wndspd.b forcing.ustar.b
  touch forcing.radflx.b forcing.shwflx.b forcing.vapmix.b forcing.precip.b
  touch forcing.airtmp.b forcing.seatmp.b forcing.surtmp.b
    setenv Y 108h
  if (-z forcing.tauewd.a) then
     ${pget} ${D}/../../force/${FN}/tauewd.a      forcing.tauewd.a &
  endif
  if (-z forcing.tauewd.b) then
     ${pget} ${D}/../../force/${FN}/tauewd.b      forcing.tauewd.b &
  endif
  if (-z forcing.taunwd.a) then
     ${pget} ${D}/../../force/${FN}/taunwd.a      forcing.taunwd.a &
  endif
  if (-z forcing.taunwd.b) then
     ${pget} ${D}/../../force/${FN}/taunwd.b      forcing.taunwd.b &
  endif
  if (-z forcing.wndspd.a) then
     ${pget} ${D}/../../force/${FN}/wndspd.a      forcing.wndspd.a &
  endif
  if (-z forcing.wndspd.b) then
     ${pget} ${D}/../../force/${FN}/wndspd.b      forcing.wndspd.b &
  endif
  if (-z forcing.vapmix.a) then
     ${pget} ${D}/../../force/${FN}/vapmix.a      forcing.vapmix.a &
  endif
  if (-z forcing.vapmix.b) then
     ${pget} ${D}/../../force/${FN}/vapmix.b      forcing.vapmix.b &
  endif
  if (-z forcing.airtmp.a) then
     ${pget} ${D}/../../force/${FN}/airtmp.a      forcing.airtmp.a &
  endif
  if (-z forcing.airtmp.b) then
     ${pget} ${D}/../../force/${FN}/airtmp.b      forcing.airtmp.b &
  endif
  if (-z forcing.precip.a) then
     ${pget} ${D}/../../force/${FN}/precip.a      forcing.precip.a &
  endif
  if (-z forcing.precip.b) then
     ${pget} ${D}/../../force/${FN}/precip.b      forcing.precip.b &
  endif
  if (-z forcing.radflx.a) then
     ${pget} ${D}/../../force/${FN}/radflx.a      forcing.radflx.a &
  endif
  if (-z forcing.radflx.b) then
     ${pget} ${D}/../../force/${FN}/radflx.b      forcing.radflx.b &
  endif
  if (-z forcing.shwflx.a) then
     ${pget} ${D}/../../force/${FN}/shwflx.a      forcing.shwflx.a &
  endif
  if (-z forcing.shwflx.b) then
     ${pget} ${D}/../../force/${FN}/shwflx.b      forcing.shwflx.b &
  endif
  if (-z forcing.surtmp.a) then
     ${pget} ${D}/../../force/${FN}/surtmp.a      forcing.surtmp.a &
  endif
  if (-z forcing.surtmp.b) then
     ${pget} ${D}/../../force/${FN}/surtmp.b      forcing.surtmp.b &
  endif

## Initial conditions
 touch relax.saln.a relax.temp.a relax.intf.a relax.rmu.a
 touch  relax.saln.b relax.temp.b relax.intf.b relax.rmu.b
touch relax.weird

if (-z relax.rmu.a) then
   ${pget} ${S}/../../relax/${E}/relax_rmu.a relax.rmu.a &
endif
if (-z relax.rmu.b) then
   ${pget} ${S}/../../relax/${E}/relax_rmu.b relax.rmu.b &
endif
if (-z relax.saln.a) then
   ${pget} ${S}/../../relax/${E}/relax_sal.a relax.saln.a &
endif
if (-z relax.saln.b) then
   ${pget} ${S}/../../relax/${E}/relax_sal.b relax.saln.b &
endif
if (-z relax.temp.a) then
   ${pget} ${S}/../../relax/${E}/relax_tem.a relax.temp.a &
endif
if (-z relax.temp.b) then
   ${pget} ${S}/../../relax/${E}/relax_tem.b relax.temp.b &
endif
if (-z relax.intf.a) then
   ${pget} ${S}/../../relax/${E}/relax_int.a relax.intf.a &
endif
if (-z relax.intf.b) then
   ${pget} ${S}/../../relax/${E}/relax_int.b relax.intf.b &
endif


#
## tidal drag
#
#touch tidal.rh.a tidal.rh.b

#if (-z tidal.rh.a) then
#   ${pget} ${S}/../../relax/${E}/tidal.rh.11.lim17.goml08.a tidal.rh.a &
#endif
#if (-z tidal.rh.b) then
#   ${pget} ${S}/../../relax/${E}/tidal.rh.11.lim17.goml08.b tidal.rh.b &
#endif
#
## Restart
#
touch   restart_in.a restart_in.b restart_out.a restart_out.b restart_out1.a restart_out1.b

if (-z restart_in.b) then
  setenv RI "       0.00"
else
  setenv RI `head -2 restart_in.b | tail -1 | awk  '{printf("%11.2f\n", $5)}'`
endif
if (-z restart_out.b) then
  setenv RO "       0.00"
else
  setenv RO `head -2 restart_out.b | tail -1 | awk  '{printf("%11.2f\n", $5)}'`
endif
if (-z restart_out1.b) then
  setenv R1 "       0.00"
else
  setenv R1 `head -2 restart_out1.b | tail -1 | awk  '{printf("%11.2f\n", $5)}'`
endif
setenv LI `awk  '{printf("%11.2f\n", $1)}' limits`
C
if (`echo $LI | awk '{if ($1 <= 0.0) print 1; else print 0}'`) then
C --- no restart needed
#  /bin/rm restart_in.a   restart_in.b
  /bin/rm restart_out.a  restart_out.b
  /bin/rm restart_out1.a restart_out1.b
	

else if (`echo $LI $RI | awk '{if ($1-0.1 < $2 && $1+0.1 > $2) print 1; else print 0}'`) then
C --- restart is already in restart_in
  /bin/rm restart_out.a  restart_out.b
  /bin/rm restart_out1.a restart_out1.b
else if (`echo $LI $RO | awk '{if ($1-0.1 < $2 && $1+0.1 > $2) print 1; else print 0}'`) then
C --- restart is in restart_out
  /bin/mv restart_out.a  restart_in.a
  /bin/mv restart_out.b  restart_in.b
  /bin/rm restart_out1.a restart_out1.b
else if (`echo $LI $R1 | awk '{if ($1-0.1 < $2 && $1+0.1 > $2) print 1; else print 0}'`) then
C ---   restart is in restart_out1
  /bin/mv restart_out1.a restart_in.a
  /bin/mv restart_out1.b restart_in.b
  /bin/rm restart_out.a  restart_out.b
else
C ---   get restart from permenant storage
  /bin/rm restart_in.a   restart_in.b
  /bin/rm restart_out.a  restart_out.b
  /bin/rm restart_out1.a restart_out1.b
  /bin/cp ${ST}/../restart/${E}/restart_${Y01}.a restart_in.a &
  /bin/cp ${ST}/../restart/${E}/restart_${Y01}.b restart_in.b &
endif
#
# --- model executable
#
setenv HEXE  hycom
/bin/cp ${D}/../../src_${V}_${K}_mpi/hycom ${HEXE} &
#
# --- summary printout
#
touch   summary_out
/bin/mv summary_out summary_old
#
# --- heat transport output
#
touch   flxdp_out.a flxdp_out.b
/bin/mv flxdp_out.a flxdp_old.a
/bin/mv flxdp_out.b flxdp_old.b
#
touch   ovrtn_out
/bin/mv ovrtn_out ovrtn_old
#
# --- clean up old archive files, typically from batch system rerun.
#
mkdir KEEP
touch archv.dummy.b
foreach f (arch*)
  /bin/mv $f KEEP/$f
end
#   
# --- Nesting input archive files. (if needed)
#   
#if (-e ./nest) then
#  cd ./nest
#  touch rmu.a rmu.b
#  if (-z rmu.a) then
#     /bin/cp ${S}/../../relax/${E}/nest_rmu.a rmu.a &
#  endif
#  if (-z rmu.b) then
#     /bin/cp ${S}/../../relax/${E}/nest_rmu.b rmu.b &
#  endif
#  cd ..
#endif

wait


#
chmod ug+x ${HEXE}
/bin/ls -laFq
    
#
#
# --- run the model if one processor
#
#
if ($NMPI == 0 ) then 
./${HEXE}
endif 
#
# --- run the model if  MPI or SHMEM and perhaps also with OpenMP.
#
if ($NMPI != 0 ) then 
touch patch.input
if (-z patch.input) then
#
# --- patch.input is always required for MPI or SHMEM.
#
  cd $D/..
  /bin/mv LIST LIST_BADRUN
  echo "BADRUN" > LIST
  exit
endif
#
#
#   --- $NMPI MPI tasks and $NOMP THREADs, if compiled for OpenMP.
#

    /bin/rm -f core
    touch core
    setenv OMP_NUM_THREADS $NOMP
    /usr/mpi/pgi/openmpi/bin/mpirun -np $NMPI ./${HEXE}


endif 
#
touch   PIPE_DEBUG
/bin/rm PIPE_DEBUG
#
# --- archive output in a separate tar directory
#
touch archv.dummy.a archv.dummy.b archv.dummy.txt
#
if (-e ./SAVE) then
  foreach f (archv.*.a)
    /bin/ln ${f} SAVE/${f}
  end
  foreach f (archv.*.b)
    /bin/ln ${f} SAVE/${f}
  end
  foreach f (archv.*.txt)
    /bin/ln ${f} SAVE/${f}
  end
endif
#
mkdir ./tar_${Y01}${A}
#
foreach f (archv.*.a)
  /bin/mv ${f} ./tar_${Y01}${A}/${E}_${f}
end
foreach f (archv.*.b)
  /bin/mv ${f} ./tar_${Y01}${A}/${E}_${f}
end
foreach f (archv.*.txt)
  /bin/mv ${f} ./tar_${Y01}${A}/${E}_${f}
end
#
# --- build and run or submit the tar script
#
awk -f $D/../${E}.awk y01=${Y01} ab=${A} $D/../${E}A.com >! tar_${Y01}${A}.com
csh tar_${Y01}${A}.com >&! tar_${Y01}${A}.log &
#llsubmit ./tar_${Y01}${A}.com
#
# --- heat transport statistics output
#
if (-e flxdp_out.a) then
  ${pput} flxdp_out.a ${S}/flxdp_${Y01}${A}.a
endif
if (-e flxdp_out.b) then
  ${pput} flxdp_out.b ${S}/flxdp_${Y01}${A}.b
endif
if (-e ovrtn_out) then
  ${pput} ovrtn_out ${S}/ovrtn_${Y01}${A}
endif
#
# --- restart output
#
if (-e restart_out.a) then
  ${pput} restart_out.a ${S}/restart_${YXX}${B}.a
endif
if (-e restart_out.b) then
  ${pput} restart_out.b ${S}/restart_${YXX}${B}.b
endif
#
#
# --- HYCOM error stop is implied by the absence of a normal stop.
#
touch summary_out
tail -1 summary_out
tail -1 summary_out | grep -c "^normal stop"
if ( `tail -1 summary_out | grep -c "^normal stop"` == 0 ) then
  cd $D/..
  /bin/mv LIST LIST_BADRUN
  echo "BADRUN" > LIST
endif
#
# --- wait for tar bundles to complete
#
wait
#
#  --- END OF MODEL RUN SCRIPT
#
