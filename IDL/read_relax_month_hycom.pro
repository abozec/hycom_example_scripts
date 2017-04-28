PRO read_relax_month_hycom, im, jm, km, io, file, res

   ;; Script to read the relax files (12 months)
   ;; A. Bozec Aug, 2011

   close,/all
   ;; Dimensions of the domain
   idm = im
   jdm = jm
   kdm = km
   idm1 = float(idm)
   ijdm = idm1*jdm


   ;; NPAD size
   npad=4096. - ijdm MOD 4096
   rr2 = fltarr(ijdm)
   if (npad NE 4096) then toto = fltarr(npad)
   res = fltarr(idm, jdm, kdm, 12)


   ;; Grid Directory and file 

   file1 = io+file

   ;; READING the file
   openu, 1, file1, /swap_endian
   FOR l = 0, 11 DO BEGIN                     ;; read 12 months
      FOR k = 0, kdm-1 DO BEGIN
         if (npad NE 4096) then begin
           readu, 1, rr2, toto
	 else
	   readu, 1, rr2
	 endif 
         FOR j = 0, jdm-1 DO BEGIN
            FOR i = 0, idm-1 DO res(i, j, k, l) = rr2(j*idm1+i)
         ENDFOR
      ENDFOR 
   ENDFOR 
   close, 1

END 
