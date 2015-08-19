#include "mex.h"
#include	<math.h>
/* ref: http://classes.soe.ucsc.edu/ee264/Fall11/cmex.pdf /*
/* [W_threshold, nonzero]=soft_threshold(W, lambda)
   W is an (p x K) feature matrix
*/
void CheckInput(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[])
{
  /* Check for proper number of arguments. */
  if (nrhs != 2)
     mexErrMsgTxt("W_thresh=tsoftvec(W, tau).\n");
  
  if(mxIsSparse(prhs[0]) || mxIsComplex(prhs[0]))
    mexErrMsgTxt("Input must be a dense real matrix\n");
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs,const mxArray *prhs[])
{
  double tau, rownorm;
  double *W, *W_thresh, *nz;
  long p, K, ik, ip, pK;
  
      
  CheckInput(nlhs, plhs, nrhs, prhs);
  
  p=mxGetM(prhs[0]); /* # row */
  K=mxGetN(prhs[0]); /* # col */
  W=mxGetPr(prhs[0]); /* pointer to the input array */
  tau=mxGetScalar(prhs[1]);
  
  plhs[0]=mxCreateDoubleMatrix(p,K,mxREAL); /* output p x K array */
  W_thresh=mxGetPr(plhs[0]); /* pointer to the data W_thresh*/
  pK=p*K;
   
  for (ip=0; ip<p; ip++) {
      /* compute the 2-norm of the ip-th row */
      for (ik=0, rownorm=0.0; ik<K; ik++)
         rownorm+=W[ip+p*ik]*W[ip+p*ik]; /* W(ip+1,ik+1)=W[ip + p*ik], ip=0,...,p, ik=0,...,K */
      rownorm=sqrt(rownorm);
      
      /* perform row-wise group-thresholding */
     if (rownorm > tau){
         for (ik=0; ik<K; ik++)
            W_thresh[ip+p*ik]=W[ip+p*ik]*(1-tau/rownorm); /* W(ip+1,ik+1)=W[ip + p*ik], ip=0,...,p, ik=0,...,K */
     }
     else {
         for (ik=0; ik<K; ik++)
            W_thresh[ip+p*ik]=0; /* W(ip+1,ik+1)=W[ip + p*ik], ip=0,...,p, ik=0,...,K */
     }
  }
}
