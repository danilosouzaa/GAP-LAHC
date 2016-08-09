#include <stdio.h>
#include <stdlib.h>
#include <curand.h>
#include <curand_kernel.h>

#include "gpulib/types.h"
#include "gpulib/gpu.cuh"

#include "Instance.h"
#include "Solution.h"
#include "gSolution.cuh"
#include "guloso.h"


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
	Solution *d_solution;
	curandState_t* states;
	cudaMalloc((void**) &states, 10 * sizeof(curandState_t));


	Instance *inst = loadInstance(fileName);
	printf("teste\n");
	Solution *sol = allocationPointersSolution(inst);
	sol = guloso(inst,1,2);
	showInstance(inst);
	printf("Load data instance ok!\n");
	getchar();
	showSolution(sol,inst);
	printf("greedy solution ok!\n");
	getchar();

	d_instance = createGPUInstance(inst, inst->nJobs, inst->mAgents);
	d_solution = createGPUsolution(sol,inst->nJobs, inst->mAgents);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	SCHC<<<1,2>>>(d_instance,d_solution, time(NULL), states, 200);
	cudaEventRecord(stop);

	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	printf("time: %.4fms\n", milliseconds);

	gpuFree(d_instance);
	gpuFree(d_solution);
	free(inst);
	free(sol);
	printf("program finished successfully!\n");
	return 0;
}
