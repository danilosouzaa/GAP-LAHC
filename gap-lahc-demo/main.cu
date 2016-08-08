#include <stdio.h>
#include <stdlib.h>
#include <curand.h>
#include <curand_kernel.h>

#include "gpulib/types.h"
#include "gpulib/gpu.cuh"

#include "Instance.h"

__global__ void teste(Instance *inst, unsigned int seed, curandState_t* states){
	int aux;
	curand_init(seed,threadIdx.x,0,&states[threadIdx.x]);
	if(threadIdx.x < 1){
		//aux = curand(&states[blockIdx.x])%10;
		printf("number of jobs: %d \n",inst->nJobs);
		printf("Valor randomico : %d \n", curand(&states[threadIdx.x])%10);
		printf("Valor randomico : %d \n", curand(&states[threadIdx.x])%10);
	}

}

int main(){
	const char *fileName = "a05100";

	int deviceCount = 0;
	//int i;
	cudaError_t error_id = cudaGetDeviceCount(&deviceCount);

	if (error_id != cudaSuccess)
	{
		printf("cudaGetDeviceCount returned %d\n-> %s\n", (int)error_id, cudaGetErrorString(error_id));
		printf("Result = FAIL\n");
		exit(1);
	}
	if(deviceCount == 0)
	{
		printf("No GPU found :(");
		exit(1);
	}
	else
	{
		printf("Found %d GPUs!\n", deviceCount);
		gpuSetDevice(0);
		printf("GPU 0 initialized!\n");
	}

	Instance *d_instance;
	curandState_t* states;
	cudaMalloc((void**) &states, 2 * sizeof(curandState_t));


	Instance *inst = loadInstance(fileName);
	showInstance(inst);
	printf("Load data instance ok!\n");
	getchar();

	d_instance = createGPUInstance(inst, inst->nJobs, inst->mAgents);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	teste<<<1,2>>>(d_instance, time(NULL), states);
	cudaEventRecord(stop);

	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	printf("time: %.4fms\n", milliseconds);

	gpuFree(d_instance);
	free(inst);
	printf("program finished successfully!\n");
	return 0;
}
