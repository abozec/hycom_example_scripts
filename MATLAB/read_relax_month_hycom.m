function res=read_relax_month_hycom(im,jm,km,io,file)

  %% Script to read the relax files (12 months)
  %% A. Bozec & D. Dukhovskoy Aug, 2011

  %% Get the id of the relax file
  fld=[io,file];
  relax_fid=fopen(fld,'r');
  IDM=im;
  JDM=jm;
  KDM=km;
  IJDM=IDM*JDM;
  npad=4096-mod(IJDM,4096);
  res=zeros(JDM,IDM,KDM,12);
  
  %% Read relax 
  for l=1:12
    for k=1:KDM
      [relax,count]=fread(relax_fid,IJDM,'float32','ieee-be');
      rel=reshape(relax,IDM,JDM);
      res(:,:,k,l)=rel(:,:)';
      fseek(relax_fid,l*k*4*(npad+IJDM),-1);
    end 
  end 
  
  %% Mask field
  y=find(res>1e20);
  res(y)=nan;

 
