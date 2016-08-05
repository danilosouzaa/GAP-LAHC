#include <stdio.h>
#include <stdlib.h>

#include "gpulib/types.h"
#include "gpulib/gpu.cuh"

#include "Instance.h"

__global__ void teste(Instance *inst){
	printf("number of jobs: %d \n",inst->nJobs);

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

	Instance *inst = loadInstance(fileName);
	showInstance(inst);
	printf("Load data instance ok!\n");
	getchar();

	d_instance = createGPUInstance(inst, inst->nJobs, inst->mAgents);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	cudaEventRecord(start);
	teste<<<1,1>>>(d_instance);
	cudaEventRecord(stop);

	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	printf("time: %.4fms\n", milliseconds);

	gpuFree(d_instance);
	free(inst);
	printf("program finished successfully!\n");
	return 0;
}
