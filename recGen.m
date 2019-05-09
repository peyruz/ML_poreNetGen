% length - microns
% mean - width_microns
% scale - microns/px
%
% version 1,
%
% by Peyruz Gasimov. April, 2018

function x = recGen(lengths, mean_widths, throatVecs)

throatVecs1=throatVecs(:,1);
throatVecs2=throatVecs(:,2);

nRec=size(lengths,1);

parfor jj=1:nRec
    % Compose the loop
    x{jj}= [-lengths(jj)/2, mean_widths(jj)/2; lengths(jj)/2, mean_widths(jj)/2;...
                lengths(jj)/2, -mean_widths(jj)/2; -lengths(jj)/2, -mean_widths(jj)/2;...
                -lengths(jj)/2, mean_widths(jj)/2];

    nv=cross([throatVecs1(jj), throatVecs2(jj) 0],[0 0 1]);
    Rth=[throatVecs1(jj), nv(1); throatVecs2(jj), nv(2)];
    
    % Rotate the rough rectangle
    x{jj} = ( Rth*x{jj}' )';
    
end