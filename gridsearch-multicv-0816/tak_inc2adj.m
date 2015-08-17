% Function for converting an incidence matrix to an adjacency matrix
% mAdj = inc2adj(mInc) - conversion from incidence matrix mInc to
% adjacency matrix mAdj
%
% INPUT:   mInc - incidence matrix; rows = edges, columns = vertices
% OUTPUT:  mAdj - adjacency matrix of a graph; if
%                  -- directed    - elements from {-1,0,1}
%                  -- undirected  - elements from {0,1}
%
% example: Graph:   __(v1)<--
%                  /         \_e2/e4_
%               e1|                  |  
%                  \->(v2)-e3->(v3)<-/
%                
%                 v1  v2 v3  <- vertices 
%                  |  |  |
%          mInc = [1 -1  0   <- e1   |
%                  1  0 -1   <- e2   | edges
%                  0  1 -1   <- e3   |
%                 -1  0  1]; <- e4   |
%
%          mAdj = [0 1 1
%                  0 0 1
%                  1 0 0];
%
% 26 Mar 2011   - created:  Ondrej Sluciak <ondrej.sluciak@nt.tuwien.ac.at>
% 31 Mar 2011   - faster check of the input matrix
% 13 Dec 2012   - major code optimization (Thanks to Andreas Gunnel for inspiration)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% tak: modified porition of it (07/17/2015)
%% 
function mAdj = tak_inc2adj(mInc)
mInc = mInc.';

%undirected graph
L = mInc*mInc.';        %using Laplacian
mAdj = L-diag(diag(L));

%| below, i donno why, but i get error up to a sign...for now apply adhoc fix
%| (figure out why this sign disparaity is occuring later)
mAdj = -mAdj;
