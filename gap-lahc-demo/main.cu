#include <stdio.h>
#include <stdlib.h>
#include <curand.h>
#include <curand_kernel.h>
#include <sys/time.h>


#include "gpulib/types.h"
#include "gpulib/gpu.cuh"

#include "Instance.h"
#include "Solution.h"
#include "gSolution.cuh"
#include "guloso.h"

const int nThreads = 1024;
int main(int argc, char *argv[]){
//int main(){
	struct timeval inicio;
	struct timeval fim;
	int tmili;
	size_t size_solution;
	const char *fileName = argv[1];
	//const char *fileName = "a05100";
	int deviceCount = 0;
	int i,j;
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
	cudaMalloc((void**) &states, nThreads * sizeof(curandState_t));


	Instance *inst = loadInstance(fileName);
	//showInstance(inst);
	printf("Load data instance ok!\n");


	Solution *sol = allocationPointersSolution(inst);
	if(fileName[0]=='e'){
		sol = guloso(inst,1,20);
	}else{
		sol = guloso(inst,1,2);
	}
	//showSolution(sol,inst);
	//printf("greedy solution ok!\n");
	size_solution = sizeof(Solution)
							+ sizeof(Ts)*inst->nJobs //vector s
							+ sizeof(TresUsage)*inst->mAgents; //vector resUsage
	

	srand(time(NULL));
	//for(int i=0;i<=10;i++){
	//schc_cpu(sol, inst, 50);
	//}
	//getchar();
	d_instance = createGPUInstance(inst, inst->nJobs, inst->mAgents);
	d_solution = createGPUsolution(sol,inst->nJobs, inst->mAgents);
	unsigned int *h_rank = (unsigned int*)malloc(sizeof(unsigned int)*inst->nJobs*inst->mAgents);
	memset(h_rank,0,sizeof(unsigned int)*inst->nJobs*inst->mAgents);
	unsigned int *d_rank;
	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	gpuMalloc((void* ) &d_rank, sizeof(unsigned int)*inst->nJobs*inst->mAgents);
	gpuMemcpy(d_rank, h_rank,sizeof(unsigned int)*inst->nJobs*inst->mAgents , cudaMemcpyHostToDevice);


	gettimeofday(&inicio, NULL);
	//schc_cpu(sol,inst,100);
	cudaEventRecord(start);

	SCHC<<<1,nThreads>>>(d_instance,d_solution, time(NULL),d_rank, states, 100);

	cudaEventRecord(stop);

	gpuMemcpy(sol, d_solution, size_solution, cudaMemcpyDeviceToHost);
	gpuMemcpy(h_rank, d_rank,sizeof(unsigned int)*inst->nJobs*inst->mAgents , cudaMemcpyDeviceToHost);
	cudaEventSynchronize(stop);
	float milliseconds = 0;
	cudaEventElapsedTime(&milliseconds, start, stop);
	printf("time: %.4fms\n", milliseconds);
	gettimeofday(&fim, NULL);
	tmili = (int) (1000 * (fim.tv_sec - inicio.tv_sec) + (fim.tv_usec - inicio.tv_usec) / 1000);
	printf("tempo: %d\n",tmili);
	//reallocation pointers of Instance
	inst->cost = (Tcost*)(inst+1);
	inst->resourcesAgent =(TresourcesAgent*) (inst->cost +(inst->nJobs*inst->mAgents));
	inst->capacity =(Tcapacity*) (inst->resourcesAgent + (inst->nJobs*inst->mAgents));

	//reallocation pointers of Solution
	sol->s = (Ts*)(sol+1);
	sol->resUsage = (TresUsage*)(sol->s + inst->nJobs);

	showSolution(sol,inst);
	for(i=0;i<inst->nJobs;i++){
		for(j=0;j<inst->mAgents;j++){
			printf("Qnt Job %d foi alocada no Agente %d: %d\n",i+1,j+1,h_rank[i*inst->mAgents+j]);
		}
	}
	createDat(inst, h_rank, fileName);
	gpuFree(d_instance);
	gpuFree(d_solution);
	free(inst);
	free(sol);
	printf("program finished successfully!\n");
	return 0;
}
