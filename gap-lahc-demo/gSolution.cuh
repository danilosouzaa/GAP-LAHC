#ifndef GSOLUTION_CUH_
#define GSOLUTION_CUH_

#include "gpulib/gpu.cuh"
#include <curand.h>
#include <curand_kernel.h>

extern "C" {

#include "Instance.h"
#include "Solution.h"


}

__global__ void SCHC(Instance *inst, Solution *sol, unsigned int *seed,unsigned int *rank, curandState_t* states, int L_c, int max_ite);


#endif /* GSOLUTION_CUH_ */
