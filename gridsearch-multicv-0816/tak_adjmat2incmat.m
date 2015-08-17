function C=tak_adjmat2incmat(A)
% C=tak_adjmat2incmat(A)
% - convert from |V|x|V| adjacency matrix A to |E|x|V| incidence matrix.
% - V = nodes, E = edges.
% (code from http://www.mathworks.com/matlabcentral/fileexchange/24661-graph-adjacency-matrix-to-incidence-matrix/content/adj2inc.m)
%%
n_nodes=size(A,1);
[vNodes1,vNodes2] = find(triu(A));     
n_edges=length(vNodes1);
C = sparse([1:n_edges, 1:n_edges]',[vNodes1; vNodes2], [-ones(n_edges,1);ones(n_edges,1)],n_edges,n_nodes);
