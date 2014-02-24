 A1 = [0 1 0 0 0; -2 0 0 0 0; 0 0 -1 0 0; 0 0 0 0 0; 0 0 0 0 1];
 A2 = [-4 0 0 0 0; 0 -3 0 0 0; 0 0 0 0 0; 0 0 0 -1 1; 0 0 0 0 -1];
 A3 = [0 0 0 0 0; -1 0 0 0 0; 0 0 -2 0 0; 0 2 0 0 0; 0 0 0 0 1];
 A4 = [0 1 0 0 0; 0 0 1 0 0; 0 0 0 0 0; 0 0 0 0 1; 0 0 0 -1 0];

 A = [A1 zeros(5, 5) zeros(5, 5) zeros(5, 5)
      zeros(5, 5) A2 zeros(5, 5) zeros(5, 5)
      zeros(5, 5) zeros(5, 5) A3 zeros(5, 5)
      zeros(5, 5) zeros(5, 5) zeros(5, 5) A4];
 B = [1 0 0; 0 1 0; 0 0 1; -1 0 1; 0 0 0; 0 0 0; 1 1 1; 0 1 0; 0 0 0; 0 0 0];
 B = [B zeros(10, 3); zeros(10, 3) -B];
 U.center = {'sin(2*t)'; '1+cos(t)'; '-1'; '0'; '0'; 't^2'};
 U.shape  = [4 -1 0 0 0 0; -1 2 0 0 0 0; 0 0 9 0 0 0; 0 0 0 4 0 0; 0 0 0 0 4 0; 0 0 0 0 0 4];
 X0 = ell_unitball(20) + [4 1 0 7 -3 -2 1 2 0 0 1 -1 0 0 5 0 0 0 -1 -1]';

 s = elltool.linsys.LinSysContinuous(A, B, U);

 T = [0 5];

 L0 = [1 1 -1 0 1 0 0 0 -1 1 0 1 0 1 0 -1 0 -1 0 1]';
 L0 = [L0 [1 0 1 0 0 0 0 0 0 1 0 1 0 1 0 -1 0 -1 0 1]'];
 L0 = [L0 [0 0 1 -1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 -1]'];
 L0 = [L0 [-1 1 1 -1 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 -1]'];
 L0 = [L0 [-1 0 1 0 0 0 0 0 0 0 0 1 0 1 0 0 0 0 0 -1]'];
% L0 = eye(20); 

 rs = elltool.reach.ReachContinuous(s, X0, L0, T, 'isRegEnabled',true, 'isJustCheck', false ,'regTol',1e-3);

 BB = zeros(20, 2);
 %BB = zeros(20, 3);
 BB(2, 1) = 1;
 BB(18, 2) = 1;
 %BB(13, 3) = 1;

 ps=rs.projection(BB);

 ps.plotByEa(); hold on; ps.plotByIa();
