% The function essentially generates vertices of a circle
%
% by Peyruz Gasimov, April 2018

function x = circleGen(radii)

nCircles = max(size(radii));

lengthOfSegment = 5;    % microns

x=cell(1,nCircles);

parfor jj=1:nCircles
   
   nVertices = round(2*pi*radii(jj) / lengthOfSegment);
   angleLoop = linspace(0, 2*pi, nVertices);
   
   x{jj}(:,1)=radii(jj)*sin(angleLoop);
   x{jj}(:,2)=radii(jj)*cos(angleLoop);
   
   % Close the loop
   x{jj}=[ x{jj}; x{jj}(1,1:2)];
   
end


