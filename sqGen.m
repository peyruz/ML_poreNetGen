function x = sqGen(eqRadii)


nSq=max(size(eqRadii));

% Preallocate
x=cell(1,nSq);

% Generate the triangle vertices
for jj=1:nSq
  
    xtemp=[-0.5 -0.5; 0.5 -0.5; 0.5 0.5; -0.5 0.5; -0.5 -0.5];
    
    % Scale the square
    orArea=1;
    
    scf=sqrt(pi*eqRadii(jj)^2/orArea);
    xtemp=xtemp*scf;
    
    % Random  rotation of the triangle
    theta=2*pi*rand;
    randRot=[cos(theta) -sin(theta); sin(theta) cos(theta)];
    x{jj}=(randRot*xtemp')';
    
end