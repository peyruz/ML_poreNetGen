function genDXF(polylines,DomainW,poreNetInfo, varargin)

% Add the DXF generating library
addpath('DXFLib_v0.9.1');

if isempty(varargin{1})
    fileName='Generated_DXF\poreNet.dxf';
else
    fileName=varargin{1};
end

% Find positions (rows) of NaNs
nanMask=isnan(polylines(:,1));
nanPos=find(nanMask);
nanPos=[0 nanPos' size(polylines,1)+1];

nPoly=sum(nanMask)+1; % Number of polylines

FID = dxf_open(fileName);

for ii=1:nPoly
    edgeNum=nanPos(ii+1)-1 - nanPos(ii)+1-1;
    dxf_polyline(FID,[polylines(nanPos(ii)+1:nanPos(ii+1)-1,1); polylines(nanPos(ii)+1,1)],...
                        [polylines(nanPos(ii)+1:nanPos(ii+1)-1,2);polylines(nanPos(ii)+1,2)],zeros(edgeNum+1,1));
end

% Add scale segment
dxf_polyline(FID, [DomainW-5000-500; DomainW-5000-500; DomainW-5000-500; ...
    DomainW-5000+500; DomainW-5000+500; DomainW-5000+500],...
    [-1300; -1700; -1500; -1500; -1300; -1700],zeros(6,1));

% Add scale segment text
dxf_text(FID, DomainW-5000-350, -1400, 0, '1 mm', 'TextHeight', 200)

% Add poreNetwork information
dxf_text(FID, 0, -900, 0, 'Pore Network Info:', 'TextHeight', 200)

str=strcat({'Mean pore diameter:'},{' '},num2str(poreNetInfo.porDistParam.meanDPor),{' '},'microns');
str=str{1};
dxf_text(FID, 0, -1500, 0, str, 'TextHeight', 200)

str=strcat({'StD of pore diameter:'},{' '},num2str(poreNetInfo.porDistParam.devDPor),{' '},'microns');
str=str{1};
dxf_text(FID, 0, -1900, 0, str, 'TextHeight', 200)

str=strcat({'Mean throat width:'},{' '},num2str(poreNetInfo.thDistParam.meanTh),{' '},'microns');
str=str{1};
dxf_text(FID, 0, -2300, 0, str, 'TextHeight', 200)

str=strcat({'StD of throat width:'},{' '},num2str(poreNetInfo.thDistParam.devTh),{' '},'microns');
str=str{1};
dxf_text(FID, 0, -2700, 0, str, 'TextHeight', 200)

str=strcat({'Porosity:'},{' '},num2str(poreNetInfo.porosity));
str=str{1};
dxf_text(FID, 0, -3100, 0, str, 'TextHeight', 200)


% Add copyright text
str=strcat({'Generated on'},{' '},datestr(datetime),{'.'});
str=str{1};
dxf_text(FID, DomainW/2, -2000, 0, str, 'TextHeight', 100)
dxf_text(FID, DomainW/2, -2200, 0, 'Source code by Peyruz Gasimov, April, 2018', 'TextHeight', 100)
dxf_close(FID);

