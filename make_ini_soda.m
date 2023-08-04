%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%  Build a ROMS initial file from Levitus Data
%
%  Extrapole and interpole temperature and salinity from a
%  Climatology to get initial conditions for
%  ROMS (initial netcdf files) .
%  Get the velocities and sea surface elevation via a 
%  geostrophic computation.
%
%  Data input format (netcdf):
%     temperature(T, Z, Y, X)
%     T : time [Months]
%     Z : Depth [m]
%     Y : Latitude [degree north]
%     X : Longitude [degree east]
%
%  Data source : IRI/LDEO Climate Data Library (World Ocean Atlas 1998)
%    http://ingrid.ldgo.columbia.edu/
%    http://iridl.ldeo.columbia.edu/SOURCES/.NOAA/.NODC/.WOA98/
%
%  P. Marchesiello & P. Penven - IRD 2005
%
%  Version of 21-Sep-2005
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all
close all
%%%%%%%%%%%%%%%%%%%%% USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%
%
%  Title 
%
title='Climatology';
%
% Common parameters
%
romstools_param

%  Data climatologies file names:
%
%    temp_month_data : monthly temperature climatology
%    temp_ann_data   : annual temperature climatology
%    salt_month_data : monthly salinity climatology
%    salt_ann_data   : annual salinity climatology
%
temp_month_data  = ['soda3.15.2_5dy_ocean_reg_2013_09_26.nc']; % SODA
insitu2pot       = 0;   %1: transform in-situ temperature to potential temperature
salt_month_data  = ['soda3.15.2_5dy_ocean_reg_2013_09_26.nc']; %SODA
%
%
%%%%%%%%%%%%%%%%%%% END USERS DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%
%
% Title
%
disp(' ')
disp([' Making initial file: ',ininame])
disp(' ')
disp([' Title: ',title])
%
% Initial file
%
if  ~exist('vtransform')
    vtransform=1; %Old Vtransform
    disp([' NO VTRANSFORM parameter found'])
    disp([' USE TRANSFORM default value vtransform = 1'])
end
create_inifile(ininame,grdname,title,...
               theta_s,theta_b,hc,N,...
               tini,'clobber',vtransform,vstretching);
%
% Horizontal and vertical interp/extrapolations 
%
disp(' ')
disp(' Interpolations / extrapolations')
disp(' ')
disp(' Temperature...')
ext_tracers_ini_soda(ininame,grdname,temp_month_data,...
            'temp','temp','r',tini);
disp(' ')
disp(' Salinity...')
ext_tracers_ini_soda(ininame,grdname,salt_month_data,...
             'salt','salt','r',tini);
disp(' ')
disp(' Density...')
ext_tracers_ini_soda(ininame,grdname,salt_month_data,...
             'prho','prho','r',tini);
disp(' ')
disp(' SSH...')
ext_tracers_ini_soda_ssh(ininame,grdname,temp_month_data,...
             'ssh','zeta','r',tini);

%
% Geostrophy
%
%  disp(' ')
%  disp(' Compute geostrophic currents')
%  geost_currents(ininame,grdname,temp_ann_data,frcname,zref,obc,1)
%
% Initial file
%
if (insitu2pot)
  disp(' ')
  disp(' Compute potential temperature from in-situ...')
  getpot(ininame,grdname)
end
%
% Make a few plots
%
disp(' ')
disp(' Make a few plots...')
test_clim(ininame,grdname,'temp',1,coastfileplot)
figure
test_clim(ininame,grdname,'salt',1,coastfileplot)
%
% End
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
