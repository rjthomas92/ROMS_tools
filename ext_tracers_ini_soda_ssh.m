function ext_tracers_ini_soda(ininame,grdname,seas_datafile,dataname,vname,type,tini);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% P. Marchesiello - 2005. Adapted from P. Penven's ext_tracers.m 
%
%  Ext tracers in a ROMS initial file
%  take seasonal data for the upper levels and annual data for the
%  lower levels
%
%  input:
%    ininame       : ROMS initial file name
%    grdname       : ROMS grid file name    
%    seas_datafile : regular longitude - latitude - z seasonal data 
%                    file used for the upper levels  (netcdf)
%    dataname      : variable name in data file
%    vname         : variable name in ROMS file
%    type          : position on C-grid ('r', 'u', 'v', 'p')
%    tini          : initialisation time [days]
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ')
%
% set the value of ro (oa decorrelation scale [m]) 
% and default (value if no data)
%
ro=0;
default=NaN;
disp([' Ext tracers: ro = ',num2str(ro/1000),...
      ' km - default value = ',num2str(default)])

% Open initial file
%
nc=netcdf(ininame,'write');
theta_s = nc{'theta_s'}(:);
theta_b =  nc{'theta_b'}(:);
hc  =  nc{'hc'}(:);
N =  length(nc('s_rho'));
vtransform = nc{'Vtransform'}(:);
if  ~exist('vtransform')
    vtransform=1; %Old Vtransform
    disp([' NO VTRANSFORM parameter found'])
    disp([' USE TRANSFORM default value vtransform = 1'])
end
%
% Open and Read grid file  
% 
ng=netcdf(grdname);
lon=ng{'lon_rho'}(:);
lat=ng{'lat_rho'}(:);
h=ng{'h'}(:);
close(ng);
[M,L]=size(lon);
%
% Read seasonal datafile 
%
ncseas=netcdf(seas_datafile);
X=ncseas{'xt_ocean'}(:);
Y=ncseas{'yt_ocean'}(:);
Zseas=-ncseas{'st_ocean'}(:);
Nzseas=length(Zseas);
%
% Determine time index to process
%
l=1;
%
% get a subgrid
%
dl=1;
lonmin=min(min(lon))-dl;
lonmax=max(max(lon))+dl;
latmin=min(min(lat))-dl;
latmax=max(max(lat))+dl;
%
j=find(Y>=latmin & Y<=latmax);
i1=find(X-360>=lonmin & X-360<=lonmax);
i2=find(X>=lonmin & X<=lonmax);
i3=find(X+360>=lonmin & X+360<=lonmax);
x=cat(1,X(i1)-360,X(i2),X(i3)+360);
y=Y(j);
%
%------------------------------------------------------------
% Horizontal interpolation
%------------------------------------------------------------
%
%
% interpole seasonal dataset on horizontal roms grid
%
disp(['   ext_tracers_ini: horizontal interpolation of seasonal data'])
missval=-9999;
%missval=ncseas{dataname}.missing_value(:);
datazgrid=zeros(Nzseas,M,L);
for k=1:Nzseas
  if ~isempty(i2)
    data=squeeze(ncseas{dataname}(l,j,i2));
  else
    data=[];
  end
  if ~isempty(i1)
    data=cat(2,squeeze(ncseas{dataname}(l,j,i1)),data);
  end
  if ~isempty(i3)
    data=cat(2,data,squeeze(ncseas{dataname}(l,j,i3)));
  end
  data(data>1e+7)=missval;
  data(data<-1e+7)=missval;
  data=get_missing_val(x,y,data,missval,ro,default);
  datazgrid(k,:,:)=interp2(x,y,data,lon,lat,'cubic');
end
close(ncseas);
%
%----------------------------------------------------
%  Vertical interpolation
%-----------------------------------------------------
%
disp('   ext_tracers_ini: vertical interpolation')
%
% Get the sigma depths
%
zroms=zlevs(h,0.*h,theta_s,theta_b,hc,N,'r',vtransform);
if type=='u'
  zroms=rho2u_3d(zroms);
end
if type=='v'
  zroms=rho2v_3d(zroms);
end
zmin=min(min(min(zroms)));
zmax=max(max(max(zroms)));
%
% Check if the min z level is below the min sigma level
%    (if not add a deep layer)
%
z=Zseas;
addsurf=max(z)<zmax;
addbot=min(z)>zmin;
if addsurf
 z=[100;z];
end
if addbot
 z=[z;-100000];
end
Nz=min(find(z<zmin));
z=z(1:Nz);
var=datazgrid; clear datazgrid;
if addsurf
  var=cat(1,var(1,:,:),var);
end
if addbot
  var=cat(1,var,var(end,:,:));
end
var=var(1:Nz,:,:);
%
% Do the vertical interpolation and write in inifile
%
flip = flipdim(var,1);
zzz = ztosigma(flipdim(var,1),zroms,flipud(z))
whos
nc{vname}(1,:,:,:)=zzz(1,:,:);
close(nc);

return
